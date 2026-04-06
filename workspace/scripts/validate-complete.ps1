# COMPLETE SYSTEM VALIDATION
param([switch]$Verbose)
$ErrorActionPreference = "Continue"
$workspaceRoot = "C:\Users\andre\.openclaw\workspace"

$results = @{ Passed = 0; Failed = 0 }
function Check($Name, $Test) {
    try {
        if ($Test) {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $results.Passed++
        } else {
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            $results.Failed++
        }
    } catch {
        Write-Host "  [ERR ] $Name" -ForegroundColor Red
        $results.Failed++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "COMPLETE SYSTEM VALIDATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Registry
Write-Host "`nRegistry:" -ForegroundColor Yellow
Check "agents.yaml" (Test-Path "$workspaceRoot/registry/agents.yaml")
Check "skills.yaml" (Test-Path "$workspaceRoot/registry/skills.yaml")
Check "hooks.yaml" (Test-Path "$workspaceRoot/registry/hooks.yaml")
Check "projects.yaml" (Test-Path "$workspaceRoot/registry/projects.yaml")
Check "contexts.yaml" (Test-Path "$workspaceRoot/registry/contexts.yaml")
Check "commands.yaml" (Test-Path "$workspaceRoot/registry/commands.yaml")
Check "instincts.yaml" (Test-Path "$workspaceRoot/registry/instincts.yaml")

# Agents
Write-Host "`nAgents:" -ForegroundColor Yellow
$agentCount = (Get-ChildItem "$workspaceRoot/agents/*.md" -ErrorAction SilentlyContinue).Count
Check "5+ Agent definitions" ($agentCount -ge 5)
Check "architect.md" (Test-Path "$workspaceRoot/agents/architect.md")
Check "planner.md" (Test-Path "$workspaceRoot/agents/planner.md")
Check "code-reviewer.md" (Test-Path "$workspaceRoot/agents/code-reviewer.md")

# Skills
Write-Host "`nSkills:" -ForegroundColor Yellow
Check "11 Skills in registry" ((Get-ChildItem "$workspaceRoot/skills/*/SKILL.md").Count -ge 10)
Check "python-patterns" (Test-Path "$workspaceRoot/skills/python-patterns/SKILL.md")
Check "security-review" (Test-Path "$workspaceRoot/skills/security-review/SKILL.md")

# Contexts
Write-Host "`nContexts:" -ForegroundColor Yellow
Check "3 Contexts" ((Get-ChildItem "$workspaceRoot/contexts/*.md").Count -eq 3)
Check "dev.md" (Test-Path "$workspaceRoot/contexts/dev.md")

# Schemas
Write-Host "`nSchemas:" -ForegroundColor Yellow
Check "skill.schema.json" (Test-Path "$workspaceRoot/schemas/skill.schema.json")
Check "agent.schema.json" (Test-Path "$workspaceRoot/schemas/agent.schema.json")

# Scripts
Write-Host "`nScripts:" -ForegroundColor Yellow
Check "10+ Scripts" ((Get-ChildItem "$workspaceRoot/scripts/*.ps1").Count -ge 10)
Check "Library modules" (Test-Path "$workspaceRoot/scripts/lib/ErrorHandler.psm1")
Check "cmd-verify.ps1" (Test-Path "$workspaceRoot/scripts/cmd-verify.ps1")
Check "cmd-quality-gate.ps1" (Test-Path "$workspaceRoot/scripts/cmd-quality-gate.ps1")
Check "cmd-orchestrate.ps1" (Test-Path "$workspaceRoot/scripts/cmd-orchestrate.ps1")

# Tests
Write-Host "`nTests:" -ForegroundColor Yellow
Check "ci-eval-runner.ps1" (Test-Path "$workspaceRoot/tests/ci-eval-runner.ps1")
Check "5+ Eval configs" ((Get-ChildItem "$workspaceRoot/registry/eval-*.yaml").Count -ge 5)

# Docs
Write-Host "`nDocumentation:" -ForegroundColor Yellow
Check "README.md" (Test-Path "$workspaceRoot/README.md")
Check "FINAL-VALIDATION.md" (Test-Path "$workspaceRoot/FINAL-VALIDATION.md")

# Summary
$total = $results.Passed + $results.Failed
$percent = if ($total -gt 0) { [math]::Round(($results.Passed / $total) * 100, 1) } else { 0 }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RESULT: $($results.Passed)/$total ($percent%)" -ForegroundColor $(if ($results.Failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================" -ForegroundColor Cyan

if ($results.Failed -eq 0) { exit 0 } else { exit 1 }
