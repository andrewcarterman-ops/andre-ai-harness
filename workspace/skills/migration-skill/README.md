# Safe Migration Skill

Foolproof migration assistant with comprehensive safety checks and quality assurance.

## Quick Start

```powershell
# Import the module
Import-Module .\scripts\SafeMigration.psm1

# Start safe migration
Start-SafeMigration `
    -SourcePath "C:\OldVault" `
    -DestinationPath "C:\NewVault" `
    -BatchSize 5
```

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Full documentation and workflow |
| `scripts/SafeMigration.psm1` | PowerShell module with functions |
| `README.md` | This file |

## Safety Features

- **Automatic Backups** - Before any changes
- **Dry-Run Mode** - Test before full migration
- **Batch Processing** - Max 5 files per batch
- **Validation** - Automated content checks
- **Rollback** - Instant recovery if needed

## Functions

### Start-SafeMigration
Main entry point for migration.

### Test-MigrationFile
Validates a single migrated file.

### Invoke-SafeBatch
Processes files in batches with validation.

### Invoke-Rollback
Restores from backup if needed.

### Get-MigrationReport
Generates summary report.

## Best Practices

1. Always backup first
2. Dry-run with 3 files
3. Process in small batches
4. Validate after each batch
5. Never delete originals immediately
6. Document everything
7. Review with second pair of eyes

## Based On

Lessons learned from the Vault Migration failure (11-04-2026).

## Version

1.0.0 - Initial release
