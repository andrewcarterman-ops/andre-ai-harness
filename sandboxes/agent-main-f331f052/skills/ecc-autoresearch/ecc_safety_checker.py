#!/usr/bin/env python3
"""
ECC Safety Checker - Security validation for autonomous AI research
Prevents dangerous code execution while allowing legitimate ML experiments.

Usage:
    python ecc_safety_checker.py --file train.py
    python ecc_safety_checker.py --directory ./experiments
    python ecc_safety_checker.py --watch --directory ./src
"""

import ast
import re
import sys
import argparse
import json
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Tuple, Optional
from datetime import datetime


# =============================================================================
# CONFIGURATION
# =============================================================================

@dataclass
class SafetyConfig:
    """Configuration for safety checks"""
    # Forbidden Python patterns (regex)
    forbidden_patterns: List[Tuple[str, str]] = None
    
    # ML-specific safe patterns (these override forbidden patterns)
    ml_safe_patterns: List[Tuple[str, str]] = None
    
    # Allowed imports (whitelist)
    allowed_imports: List[str] = None
    
    # Allowed file paths
    allowed_paths: List[str] = None
    
    # Blacklisted paths
    blacklisted_paths: List[str] = None
    
    # Allowed network hosts
    allowed_hosts: List[str] = None
    
    # Resource limits
    max_runtime_minutes: int = 5
    max_memory_gb: float = 50.0
    max_disk_gb: float = 10.0
    
    def __post_init__(self):
        # DANGEROUS patterns (will be flagged)
        if self.forbidden_patterns is None:
            self.forbidden_patterns = [
                # True eval() - standalone function call
                (r'(?<!\.)eval\s*\(', "eval() code execution"),
                (r'(?<!model)\.eval\s*\(', "eval() code execution (suspected)"),
                (r'exec\s*\(', "exec() code execution"),
                (r'compile\s*\(', "compile() code execution"),
                (r'__import__\s*\(', "Dynamic import"),
                (r'subprocess', "Subprocess execution"),
                (r'os\.system', "os.system() shell execution"),
                (r'os\.popen', "os.popen() shell execution"),
                (r'os\.spawn', "os.spawn() process creation"),
                (r'socket\.', "Network socket access"),
                (r'urllib\.request', "urllib network access"),
                (r'requests\.(get|post|put|delete)', "HTTP requests"),
                (r'http\.client', "HTTP client access"),
                (r'ftplib', "FTP access"),
                (r'smtplib', "SMTP access"),
                (r'paramiko', "SSH access"),
                (r'pexpect', "Expect process control"),
                (r'pty', "Pseudo-terminal access"),
                (r'shutil\.rmtree\s*\([^)]*[\"\']~', "Home directory deletion"),
                (r'os\.remove\s*\([^)]*[\"\']~', "Home file deletion"),
                (r'open\s*\([^)]*[\"\']~\/\.', "Home directory file access"),
                (r'pickle\.load', "pickle deserialization (verify source!)"),
                (r'yaml\.load(?!_safe)', "yaml.load() use yaml.safe_load()"),
            ]
        
        # ML-safe patterns (these are OK and override forbidden matches)
        if self.ml_safe_patterns is None:
            self.ml_safe_patterns = [
                (r'model\.eval\(', "PyTorch eval mode (safe)"),
                (r'nn\.Module\.eval\(', "PyTorch eval mode (safe)"),
                (r'torch\.compile\(', "PyTorch JIT compilation (safe)"),
                (r'torch\._dynamo\.compile', "PyTorch compile internal (safe)"),
            ]
        
        # Extended imports list for ML
        if self.allowed_imports is None:
            self.allowed_imports = [
                # PyTorch ecosystem
                'torch', 'torchvision', 'torchaudio', 'torch.nn', 'torch.optim',
                'torch.utils', 'torch.distributed', 'torch.multiprocessing',
                'torch._dynamo', 'torch._inductor',
                # ML/Data
                'numpy', 'pandas', 'matplotlib', 'seaborn',
                'sklearn', 'scipy', 'sklearn.metrics',
                'transformers', 'datasets', 'tokenizers', 'accelerate',
                'tqdm', 'wandb', 'tensorboard', 'mlflow',
                # Vision
                'PIL', 'cv2', 'albumentations',
                # Standard lib
                'json', 're', 'math', 'random', 'datetime',
                'itertools', 'collections', 'functools',
                'typing', 'dataclasses', 'pathlib',
                'hashlib', 'uuid', 'time', 'os.path',
                'warnings', 'logging', 'gc', 'traceback',
                'typing_extensions', 'importlib',
                # Local modules
                'prepare', 'kernels', 'tokenizer',
            ]
        
        if self.allowed_paths is None:
            self.allowed_paths = [
                '~/.cache/autoresearch/',
                '~/.cache/torch/',
                '~/.cache/huggingface/',
                './results.tsv',
                './run.log',
                './train.py',
                './prepare.py',
                './',
                './.git/',
            ]
        
        if self.blacklisted_paths is None:
            self.blacklisted_paths = [
                '~/.ssh/',
                '~/.aws/',
                '~/.config/',
                '~/.bashrc',
                '~/.zshrc',
                '~/.profile',
                '/etc/',
                '/usr/',
                '/bin/',
                '/sbin/',
                '/lib/',
                '/var/',
                '/root/',
                '/boot/',
                '/sys/',
                '/proc/',
            ]
        
        if self.allowed_hosts is None:
            self.allowed_hosts = [
                'huggingface.co',
                'cdn.huggingface.co',
                'download.pytorch.org',
                'pypi.org',
                'pypi.python.org',
                'files.pythonhosted.org',
            ]


# =============================================================================
# SAFETY CHECK RESULTS
# =============================================================================

@dataclass
class Violation:
    """Represents a safety violation"""
    severity: str  # 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'WARNING', 'INFO'
    category: str  # 'code_execution', 'system_access', 'network', 'filesystem', 'injection'
    message: str
    line: int
    column: int
    code_snippet: str
    is_false_positive: bool = False
    
    def to_dict(self):
        return asdict(self)


@dataclass
class SafetyReport:
    """Complete safety analysis report"""
    file_path: str
    timestamp: str
    overall_score: int  # 0-100
    passed: bool
    violations: List[Violation]
    statistics: dict
    ml_patterns_found: List[str]
    
    def to_dict(self):
        return {
            'file_path': self.file_path,
            'timestamp': self.timestamp,
            'overall_score': self.overall_score,
            'passed': self.passed,
            'violations': [v.to_dict() for v in self.violations],
            'statistics': self.statistics,
            'ml_patterns_found': self.ml_patterns_found,
        }
    
    def to_json(self, indent=2):
        return json.dumps(self.to_dict(), indent=indent)
    
    def to_markdown(self):
        lines = [
            f"# Safety Report: {self.file_path}",
            f"",
            f"**Timestamp:** {self.timestamp}",
            f"**Overall Score:** {self.overall_score}/100",
            f"**Status:** {'PASSED' if self.passed else 'FAILED'}",
            f"**ML Patterns Found:** {len(self.ml_patterns_found)}",
            f"",
            f"## Summary",
            f"- Total Violations: {len(self.violations)}",
            f"- Critical: {sum(1 for v in self.violations if v.severity == 'CRITICAL')}",
            f"- High: {sum(1 for v in self.violations if v.severity == 'HIGH')}",
            f"- Medium: {sum(1 for v in self.violations if v.severity == 'MEDIUM')}",
            f"- False Positives: {sum(1 for v in self.violations if v.is_false_positive)}",
            f"",
        ]
        
        if self.ml_patterns_found:
            lines.extend([
                f"## ML Patterns Detected (Safe)",
                f"",
            ])
            for pattern in self.ml_patterns_found:
                lines.append(f"- {pattern}")
            lines.append("")
        
        if self.violations:
            lines.extend([
                f"## Violations",
                f"",
            ])
            for v in self.violations:
                if v.is_false_positive:
                    lines.append(f"### [LIKELY FALSE POSITIVE] {v.severity}: {v.category}")
                else:
                    lines.append(f"### [{v.severity}] {v.category}")
                lines.extend([
                    f"**Line {v.line}, Column {v.column}**",
                    f"**Message:** {v.message}",
                    f"**Code:** `{v.code_snippet[:80]}{'...' if len(v.code_snippet) > 80 else ''}`",
                    f"",
                ])
        
        return '\n'.join(lines)


# =============================================================================
# PATTERN CHECKER
# =============================================================================

class PatternChecker:
    """Regex-based pattern matching for security issues"""
    
    def __init__(self, config: SafetyConfig):
        self.config = config
        self.compiled_forbidden = [
            (re.compile(pattern, re.IGNORECASE), description, pattern)
            for pattern, description in config.forbidden_patterns
        ]
        self.compiled_ml_safe = [
            (re.compile(pattern, re.IGNORECASE), description)
            for pattern, description in config.ml_safe_patterns
        ]
    
    def check(self, source_code: str) -> Tuple[List[Violation], List[str]]:
        """Check source code against patterns, return violations and ML patterns found"""
        violations = []
        ml_patterns_found = []
        lines = source_code.split('\n')
        
        # First, find all ML-safe patterns
        for line_num, line in enumerate(lines, 1):
            for compiled_pattern, description in self.compiled_ml_safe:
                if compiled_pattern.search(line):
                    ml_patterns_found.append(f"Line {line_num}: {description}")
        
        # Then check forbidden patterns (but skip if ML-safe pattern present on same line)
        for line_num, line in enumerate(lines, 1):
            for compiled_pattern, description, original_pattern in self.compiled_forbidden:
                for match in compiled_pattern.finditer(line):
                    # Check if this line also has an ML-safe pattern (false positive)
                    is_false_positive = False
                    for ml_pattern, _ in self.compiled_ml_safe:
                        if ml_pattern.search(line):
                            is_false_positive = True
                            break
                    
                    # Check for model.eval() specifically
                    if 'eval' in original_pattern and ('model.eval' in line or 'nn.Module.eval' in line or '.eval()' in line):
                        is_false_positive = True
                    
                    # Check for torch.compile() specifically
                    if 'compile' in original_pattern and 'torch.compile' in line:
                        is_false_positive = True
                    
                    severity = self._get_severity(original_pattern)
                    category = self._get_category(original_pattern)
                    
                    # Downgrade severity for likely false positives
                    if is_false_positive:
                        severity = 'INFO'
                    
                    violations.append(Violation(
                        severity=severity,
                        category=category,
                        message=description,
                        line=line_num,
                        column=match.start(),
                        code_snippet=line.strip(),
                        is_false_positive=is_false_positive
                    ))
        
        return violations, ml_patterns_found
    
    def _get_severity(self, pattern: str) -> str:
        """Determine severity based on pattern type"""
        critical_patterns = ['eval', 'exec', 'subprocess', 'os\.system', 'os\.popen']
        high_patterns = ['socket', '__import__', 'urllib', 'requests']
        
        for cp in critical_patterns:
            if cp in pattern and not ('model.eval' in pattern or 'torch.compile' in pattern):
                return 'CRITICAL'
        
        for hp in high_patterns:
            if hp in pattern:
                return 'HIGH'
        
        return 'MEDIUM'
    
    def _get_category(self, pattern: str) -> str:
        """Determine category based on pattern"""
        if any(x in pattern for x in ['eval', 'exec', 'compile', '__import__']):
            return 'code_execution'
        elif any(x in pattern for x in ['subprocess', 'os\.system', 'os\.popen', 'os\.spawn']):
            return 'system_access'
        elif any(x in pattern for x in ['socket', 'urllib', 'requests', 'http']):
            return 'network'
        elif any(x in pattern for x in ['rmtree', 'remove', 'open']):
            return 'filesystem'
        else:
            return 'other'


# =============================================================================
# MAIN SAFETY CHECKER
# =============================================================================

class SafetyChecker:
    """Main safety checking orchestrator"""
    
    def __init__(self, config: Optional[SafetyConfig] = None):
        self.config = config or SafetyConfig()
        self.pattern_checker = PatternChecker(self.config)
    
    def check_file(self, file_path: str) -> SafetyReport:
        """Check a single file for safety violations"""
        path = Path(file_path)
        
        if not path.exists():
            return SafetyReport(
                file_path=file_path,
                timestamp=datetime.utcnow().isoformat(),
                overall_score=0,
                passed=False,
                violations=[Violation(
                    severity='CRITICAL',
                    category='file_access',
                    message=f"File not found: {file_path}",
                    line=0, column=0, code_snippet=""
                )],
                statistics={'lines_checked': 0, 'imports_found': 0},
                ml_patterns_found=[]
            )
        
        source_code = path.read_text(encoding='utf-8', errors='replace')
        return self.check_source(source_code, str(path))
    
    def check_source(self, source_code: str, file_path: str = "<string>") -> SafetyReport:
        """Check source code string for safety violations"""
        violations, ml_patterns = self.pattern_checker.check(source_code)
        
        # Filter out INFO-level violations for scoring (they're likely false positives)
        real_violations = [v for v in violations if v.severity != 'INFO']
        
        # Calculate score
        score = self._calculate_score(real_violations)
        
        # Passed if score >= 70 and no critical violations (or only false positives)
        has_critical = any(v.severity == 'CRITICAL' and not v.is_false_positive for v in real_violations)
        passed = score >= 70 and not has_critical
        
        # Statistics
        statistics = {
            'lines_checked': len(source_code.split('\n')),
            'critical_violations': sum(1 for v in real_violations if v.severity == 'CRITICAL'),
            'high_violations': sum(1 for v in real_violations if v.severity == 'HIGH'),
            'medium_violations': sum(1 for v in real_violations if v.severity == 'MEDIUM'),
            'false_positives': sum(1 for v in violations if v.is_false_positive),
        }
        
        return SafetyReport(
            file_path=file_path,
            timestamp=datetime.utcnow().isoformat(),
            overall_score=score,
            passed=passed,
            violations=violations,  # Include all for visibility
            statistics=statistics,
            ml_patterns_found=ml_patterns
        )
    
    def check_directory(self, directory: str, pattern: str = "*.py") -> List[SafetyReport]:
        """Check all files in a directory"""
        reports = []
        path = Path(directory)
        
        for file_path in path.rglob(pattern):
            report = self.check_file(str(file_path))
            reports.append(report)
        
        return reports
    
    def _calculate_score(self, violations: List[Violation]) -> int:
        """Calculate safety score (0-100)"""
        base_score = 100
        
        penalties = {
            'CRITICAL': 30,
            'HIGH': 15,
            'MEDIUM': 5,
            'LOW': 2,
            'WARNING': 1,
        }
        
        for v in violations:
            if not v.is_false_positive:  # Only penalize real violations
                base_score -= penalties.get(v.severity, 1)
        
        return max(0, base_score)


# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='ECC Safety Checker - Security validation for AI research code (ML-Enhanced)'
    )
    parser.add_argument('--file', '-f', help='Check a single file')
    parser.add_argument('--directory', '-d', help='Check all files in directory')
    parser.add_argument('--pattern', '-p', default='*.py', help='File pattern (default: *.py)')
    parser.add_argument('--config', '-c', help='Path to config file')
    parser.add_argument('--output', '-o', help='Output file for report')
    parser.add_argument('--format', choices=['json', 'markdown', 'text'], default='text',
                        help='Output format')
    parser.add_argument('--strict', action='store_true',
                        help='Fail on any violation (not just critical)')
    parser.add_argument('--ml-mode', action='store_true', default=True,
                        help='Enable ML-friendly mode (default: True)')
    
    args = parser.parse_args()
    
    # Load config if provided
    config = SafetyConfig()
    if args.config:
        with open(args.config) as f:
            config_dict = json.load(f)
            for key, value in config_dict.items():
                if hasattr(config, key):
                    setattr(config, key, value)
    
    # Create checker
    checker = SafetyChecker(config)
    
    # Run checks
    if args.file:
        report = checker.check_file(args.file)
        reports = [report]
    elif args.directory:
        reports = checker.check_directory(args.directory, args.pattern)
    else:
        # Read from stdin
        source = sys.stdin.read()
        report = checker.check_source(source, '<stdin>')
        reports = [report]
    
    # Output results
    for report in reports:
        if args.format == 'json':
            output = report.to_json()
        elif args.format == 'markdown':
            output = report.to_markdown()
        else:
            output = f"\n{'='*60}\n"
            output += f"File: {report.file_path}\n"
            output += f"Score: {report.overall_score}/100 | Status: {'PASS' if report.passed else 'FAIL'}\n"
            output += f"ML Patterns: {len(report.ml_patterns_found)}\n"
            output += f"Violations: {len(report.violations)} (False Positives: {report.statistics.get('false_positives', 0)})\n"
            output += f"{'='*60}\n"
            
            if report.ml_patterns_found:
                output += "\n[ML Patterns Detected (Safe)]:\n"
                for pattern in report.ml_patterns_found[:5]:  # Show first 5
                    output += f"  - {pattern}\n"
            
            real_violations = [v for v in report.violations if not v.is_false_positive and v.severity != 'INFO']
            for v in real_violations[:10]:  # Show first 10 real violations
                status = "[FP?]" if v.is_false_positive else f"[{v.severity}]"
                output += f"\n{status} Line {v.line}: {v.message}\n"
                output += f"    Code: {v.code_snippet[:60]}{'...' if len(v.code_snippet) > 60 else ''}\n"
            
            if len(real_violations) > 10:
                output += f"\n... and {len(real_violations) - 10} more\n"
        
        print(output)
        
        if args.output:
            with open(args.output, 'a') as f:
                f.write(output)
    
    # Exit code
    if args.strict:
        failed = any(not r.passed for r in reports)
    else:
        failed = any(
            any(v.severity == 'CRITICAL' and not v.is_false_positive for v in r.violations)
            for r in reports
        )
    
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
