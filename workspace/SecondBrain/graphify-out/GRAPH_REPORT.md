# Graph Report - C:/Users/andre/.openclaw/workspace/SecondBrain  (2026-04-13)

## Corpus Check
- Large corpus: 328 files · ~89,067 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 139 nodes · 167 edges · 22 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_00 Meta 01 Daily|00 Meta 01 Daily]]
- [[_COMMUNITY_MOC Startseite Kimi Agent OpenClaw GitHub OPENCLAW CLAWCODE INTEGRATION MASTERPLAN| MOC Startseite Kimi Agent OpenClaw GitHub OPENCLAW CLAWCODE INTEGRATION MASTERPLAN]]
- [[_COMMUNITY_ecc-stability.ps1 Initialize-EccEnvironment()|ecc-stability.ps1 Initialize-EccEnvironment()]]
- [[_COMMUNITY_sync-openclaw-to-obsidian.ps1 ConvertTo-YamlFrontmatter()|sync-openclaw-to-obsidian.ps1 ConvertTo-YamlFrontmatter()]]
- [[_COMMUNITY_ConvertFrom-Yaml() Get-BackupConfig()|ConvertFrom-Yaml() Get-BackupConfig()]]
- [[_COMMUNITY_drift-detection.ps1 drift-detection.ps1|drift-detection.ps1 drift-detection.ps1]]
- [[_COMMUNITY_eval-runner.ps1 Export-EvalReport()|eval-runner.ps1 Export-EvalReport()]]
- [[_COMMUNITY_cmd-backup.ps1 Clear-OldBackups()|cmd-backup.ps1 Clear-OldBackups()]]
- [[_COMMUNITY_Daily Decision|Daily Decision]]
- [[_COMMUNITY_vault-reorganize.ps1 Extract-Decisions()|vault-reorganize.ps1 Extract-Decisions()]]
- [[_COMMUNITY_setup-symlinks.ps1 New-VaultSymlink()|setup-symlinks.ps1 New-VaultSymlink()]]
- [[_COMMUNITY_context-switch.ps1 Extract-KeyInfo()|context-switch.ps1 Extract-KeyInfo()]]
- [[_COMMUNITY_check-vault-health.ps1 Test-SymlinkHealth()|check-vault-health.ps1 Test-SymlinkHealth()]]
- [[_COMMUNITY_graphify_extract_ast.py|graphify_extract_ast.py]]
- [[_COMMUNITY_migrate-obsidian-vault.ps1|migrate-obsidian-vault.ps1]]
- [[_COMMUNITY_analyze-vault.ps1|analyze-vault.ps1]]
- [[_COMMUNITY_sync-openclaw-to-secondbrain.20260406-234527.ps1|sync-openclaw-to-secondbrain.20260406-234527.ps1]]
- [[_COMMUNITY_sync-openclaw-to-secondbrain.ps1|sync-openclaw-to-secondbrain.ps1]]
- [[_COMMUNITY_vault-reorganize-simple.ps1|vault-reorganize-simple.ps1]]
- [[_COMMUNITY_example-usage.ps1|example-usage.ps1]]
- [[_COMMUNITY_create-dirs.ps1|create-dirs.ps1]]
- [[_COMMUNITY_MOC Startseite| MOC Startseite]]

## God Nodes (most connected - your core abstractions)
1. `Graphify Output` - 33 edges
2. `New-SessionNote()` - 7 edges
3. `Templates` - 7 edges
4. `Write-EccLog()` - 6 edges
5. `Write-SyncLog()` - 6 edges
6. `Start-Sync()` - 6 edges
7. `BATCH1 20260411 013011` - 6 edges
8. `Write-BackupLog()` - 5 edges
9. `Start-VaultMigration()` - 5 edges
10. `Invoke-WithRetry()` - 5 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "00 Meta 01 Daily"
Cohesion: 0.06
Nodes (32): 00 Meta, 01 Daily, 02 04 2026, 02 04 2026 FINAL, 02 04 2026 SESSION LOG, 03 04 2026, 04 04 2026, 05 04 2026 v1 (+24 more)

### Community 1 - " MOC Startseite Kimi Agent OpenClaw GitHub OPENCLAW CLAWCODE INTEGRATION MASTERPLAN"
Cohesion: 0.12
Nodes (17):  MOC Startseite, Kimi Agent OpenClaw GitHub OPENCLAW CLAWCODE INTEGRATION MASTERPLAN, Kimi Agent OpenClaw GitHub SUBAGENT COMPACTION SPEC, Kimi Agent OpenClaw GitHub SUBAGENT CONVERSATION RUNTIME SPEC, Kimi Agent OpenClaw GitHub SUBAGENT PERMISSIONS SPEC, Kimi Agent OpenClaw GitHub SUBAGENT SSE STREAMING SPEC, drift report 20260411 155836, drift report 20260412 080754 (+9 more)

### Community 2 - "ecc-stability.ps1 Initialize-EccEnvironment()"
Cohesion: 0.27
Nodes (6): Initialize-EccEnvironment(), Invoke-EncryptMode(), Invoke-FullCheck(), Show-Status(), Test-Prerequisites(), Write-EccLog()

### Community 3 - "sync-openclaw-to-obsidian.ps1 ConvertTo-YamlFrontmatter()"
Cohesion: 0.45
Nodes (10): ConvertTo-YamlFrontmatter(), Get-BacklinksSection(), Get-OpenClawSessionsFromRegistry(), Get-SyncStatus(), Invoke-WithRetry(), New-DecisionNote(), New-SessionNote(), Save-SyncStatus() (+2 more)

### Community 4 - "ConvertFrom-Yaml() Get-BackupConfig()"
Cohesion: 0.36
Nodes (7): ConvertFrom-Yaml(), Get-BackupConfig(), Get-BackupMetadata(), Invoke-RetentionCleanup(), New-VaultBackup(), Restore-VaultBackup(), Write-BackupLog()

### Community 5 - "drift-detection.ps1 drift-detection.ps1"
Cohesion: 0.43
Nodes (5): Get-TemplateForFile(), Get-VaultStructure(), Repair-Drift(), Test-Drift(), Write-DriftLog()

### Community 6 - "eval-runner.ps1 Export-EvalReport()"
Cohesion: 0.36
Nodes (4): Export-EvalReport(), Import-EvalConfig(), Invoke-EvalSuite(), Write-EvalLog()

### Community 7 - "cmd-backup.ps1 Clear-OldBackups()"
Cohesion: 0.52
Nodes (5): Clear-OldBackups(), Invoke-Backup(), Invoke-Restore(), Test-BackupIntegrity(), Write-BackupLog()

### Community 8 - "Daily Decision"
Cohesion: 0.29
Nodes (7): Daily, Decision, Knowledge, Meeting, Project, Session Retrospektive, Templates

### Community 9 - "vault-reorganize.ps1 Extract-Decisions()"
Cohesion: 0.6
Nodes (5): Extract-Decisions(), Get-YamlFrontMatter(), New-CompactNote(), Start-VaultMigration(), Test-UUIDFileName()

### Community 10 - "setup-symlinks.ps1 New-VaultSymlink()"
Cohesion: 0.7
Nodes (3): New-VaultSymlink(), Test-SymlinkExists(), Test-SymlinkHealthy()

### Community 11 - "context-switch.ps1 Extract-KeyInfo()"
Cohesion: 0.7
Nodes (4): Extract-KeyInfo(), Get-RecentSessions(), New-ContextSummary(), Write-ContextLog()

### Community 12 - "check-vault-health.ps1 Test-SymlinkHealth()"
Cohesion: 0.67
Nodes (0): 

### Community 13 - "graphify_extract_ast.py"
Cohesion: 1.0
Nodes (0): 

### Community 14 - "migrate-obsidian-vault.ps1"
Cohesion: 1.0
Nodes (0): 

### Community 15 - "analyze-vault.ps1"
Cohesion: 1.0
Nodes (0): 

### Community 16 - "sync-openclaw-to-secondbrain.20260406-234527.ps1"
Cohesion: 1.0
Nodes (0): 

### Community 17 - "sync-openclaw-to-secondbrain.ps1"
Cohesion: 1.0
Nodes (0): 

### Community 18 - "vault-reorganize-simple.ps1"
Cohesion: 1.0
Nodes (0): 

### Community 19 - "example-usage.ps1"
Cohesion: 1.0
Nodes (0): 

### Community 20 - "create-dirs.ps1"
Cohesion: 1.0
Nodes (0): 

### Community 21 - " MOC Startseite"
Cohesion: 1.0
Nodes (1):  MOC Startseite

## Knowledge Gaps
- **49 isolated node(s):** ` MOC Startseite`, `Capabilities Index`, `SYSTEM STATUS`, `vault config`, `Daily` (+44 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `graphify_extract_ast.py`** (1 nodes): `graphify_extract_ast.py`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `migrate-obsidian-vault.ps1`** (1 nodes): `migrate-obsidian-vault.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `analyze-vault.ps1`** (1 nodes): `analyze-vault.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `sync-openclaw-to-secondbrain.20260406-234527.ps1`** (1 nodes): `sync-openclaw-to-secondbrain.20260406-234527.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `sync-openclaw-to-secondbrain.ps1`** (1 nodes): `sync-openclaw-to-secondbrain.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `vault-reorganize-simple.ps1`** (1 nodes): `vault-reorganize-simple.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `example-usage.ps1`** (1 nodes): `example-usage.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `create-dirs.ps1`** (1 nodes): `create-dirs.ps1`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community ` MOC Startseite`** (1 nodes): ` MOC Startseite`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Graphify Output` connect `00 Meta 01 Daily` to ` MOC Startseite Kimi Agent OpenClaw GitHub OPENCLAW CLAWCODE INTEGRATION MASTERPLAN`?**
  _High betweenness centrality (0.134) - this node is a cross-community bridge._
- **Why does `00 Meta` connect ` MOC Startseite Kimi Agent OpenClaw GitHub OPENCLAW CLAWCODE INTEGRATION MASTERPLAN` to `00 Meta 01 Daily`?**
  _High betweenness centrality (0.087) - this node is a cross-community bridge._
- **What connects ` MOC Startseite`, `Capabilities Index`, `SYSTEM STATUS` to the rest of the system?**
  _49 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `00 Meta 01 Daily` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should ` MOC Startseite Kimi Agent OpenClaw GitHub OPENCLAW CLAWCODE INTEGRATION MASTERPLAN` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._