---
session_id: {{session_id}}
title: {{title}}
description: {{description}}
created: {{created}}
updated: {{updated}}
token_usage: {{token_usage}}
cost: {{cost}}
model: {{model}}
project: {{project}}
tags: [{{tags}}]
status: {{status}}
previous_session: {{previous_session}}
related_sessions: [{{related_sessions}}]
synced_at: {{synced_at}}
---

# {{title}}

{{description}}

## Zusammenfassung

**Token Usage:** {{token_usage}} | **Cost:** `${{cost}}` | **Model:** {{model}}

## Inhalt

{{content}}

## TODOs

{{todos}}

## Entscheidungen

{{decisions}}

## Code-Blocks

{{code_block_links}}

## Session-Architektur

```mermaid
flowchart TD
    S[{{title}}] --> C[Content]
    S --> D[Entscheidungen]
    S --> T[TODOs]
    S --> CB[Code-Blocks]
    {{#if previous_session}}
    P[{{previous_session}}] --> S
    {{/if}}
```

## Backlinks

{{backlinks}}

---

*Automatisch synchronisiert von OpenClaw am {{synced_at}}*
