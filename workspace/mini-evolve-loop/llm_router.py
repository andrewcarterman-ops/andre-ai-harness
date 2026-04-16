"""
Provider-agnostic LLM router with OpenAI-compatible clients.
"""

import json
import os
import re
import time
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from openai import OpenAI


@dataclass
class LLMResponse:
    content: str
    usage: Dict[str, int] = field(default_factory=dict)
    model: str = ""
    call_time: float = 0.0


class LLMClient:
    """Thin wrapper over OpenAI-compatible chat completions."""

    def __init__(
        self,
        api_key: str,
        base_url: str = "https://api.openai.com/v1",
        model: str = "gpt-4",
        timeout: int = 120,
        retry_times: int = 3,
        retry_delay: int = 5,
        **extra_params,
    ):
        self.model = model
        self.timeout = timeout
        self.retry_times = retry_times
        self.retry_delay = retry_delay
        self.extra_params = extra_params

        self.client = OpenAI(
            api_key=api_key,
            base_url=base_url,
            timeout=timeout,
        )

    def generate(
        self,
        prompt: str,
        system_prompt: Optional[str] = None,
        json_mode: bool = False,
        **kwargs,
    ) -> LLMResponse:
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        messages.append({"role": "user", "content": prompt})

        params = {
            "model": self.model,
            "messages": messages,
            **self.extra_params,
            **kwargs,
        }

        if json_mode:
            params["response_format"] = {"type": "json_object"}

        last_error = None
        for attempt in range(self.retry_times):
            try:
                start = time.time()
                resp = self.client.chat.completions.create(**params)
                call_time = time.time() - start

                content = resp.choices[0].message.content or ""
                usage = {}
                if resp.usage:
                    usage = {
                        "prompt_tokens": resp.usage.prompt_tokens or 0,
                        "completion_tokens": resp.usage.completion_tokens or 0,
                        "total_tokens": resp.usage.total_tokens or 0,
                    }

                return LLMResponse(
                    content=content,
                    usage=usage,
                    model=params["model"],
                    call_time=call_time,
                )
            except Exception as e:
                last_error = e
                if attempt < self.retry_times - 1:
                    time.sleep(self.retry_delay)

        raise last_error

    def extract_tags(self, prompt: str, system_prompt: Optional[str] = None) -> Dict[str, Any]:
        response = self.generate(prompt, system_prompt)
        content = response.content.strip()

        result = {}
        tag_pattern = r"<(\w+)>"
        pos = 0
        while True:
            match = re.search(tag_pattern, content[pos:])
            if not match:
                break
            tag_name = match.group(1)
            tag_start = pos + match.end()
            end_tag = f"</{tag_name}>"
            end_pos = content.find(end_tag, tag_start)
            if end_pos == -1:
                pos = tag_start
                continue
            result[tag_name] = content[tag_start:end_pos].strip()
            pos = end_pos + len(end_tag)

        if not result:
            raise ValueError("No valid tags found in LLM response")
        return result


class LLMRouter:
    """Routes tasks to configured model backends."""

    def __init__(self, config: Dict[str, Any]):
        self.clients: Dict[str, LLMClient] = {}
        for role, cfg in config.get("models", {}).items():
            resolved_cfg = self._resolve_env_vars(cfg)
            # Remove framework-only keys before passing to LLMClient
            resolved_cfg.pop("provider", None)
            self.clients[role] = LLMClient(**resolved_cfg)

    def get_client(self, role: str) -> LLMClient:
        if role not in self.clients:
            raise ValueError(f"No LLM client configured for role: {role}")
        return self.clients[role]

    @staticmethod
    def _resolve_env_vars(obj: Any) -> Any:
        if isinstance(obj, dict):
            return {k: LLMRouter._resolve_env_vars(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [LLMRouter._resolve_env_vars(item) for item in obj]
        elif isinstance(obj, str) and obj.startswith("${") and obj.endswith("}"):
            return os.environ.get(obj[2:-1], "")
        return obj
