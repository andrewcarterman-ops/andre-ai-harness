---
name: safe-migration
version: "1.0.0"
description: |
  Foolproof migration assistant with safety checks, validation, and quality assurance.
  Prevents data loss through backups, dry-runs, incremental batches, and automated validation.
author: Andrew
source: Based on lessons learned from vault migration failures
tags: [migration, safety, backup, validation, quality]
---

# Safe Migration Skill

Foolproof migration with comprehensive safety checks and quality assurance.

## When to Use

- Migrating files between directories or systems
- Converting file formats
- Restructuring vaults or projects
- Any operation that could result in data loss

## Safety Principles

1. **Backup FIRST** - Always backup before any changes
2. **Dry-Run** - Test with 3 files before full migration
3. **Incremental** - Max 5 files per batch
4. **Validate** - Automated checks after each batch
5. **Never Delete Originals** - Until validation is confirmed

## Workflow

### Phase 1: Preparation

```powershell
# 1. Create backup
$backupPath = "00-Meta/Backups/MIGRATION_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $backupPath -ItemType Directory
Copy-Item -Path "Source/*" -Destination $backupPath -Recurse

# 2. Create inventory
$files = Get-ChildItem -Path "Source" -Recurse -File
$files | Export-Csv -Path "$backupPath/inventory.csv"
```

### Phase 2: Dry-Run

1. Select 3 representative files
2. Perform complete migration
3. Validate:
   - File exists at destination
   - Content is complete (not empty)
   - No placeholder text
   - YAML frontmatter valid
4. Get GO from user for full migration

### Phase 3: Batch Migration

```powershell
# Process in batches of max 5 files
$batch = $files | Select-Object -First 5
foreach ($file in $batch) {
    # Migrate file
    # Validate immediately
    # Log result
}
# Pause - get GO for next batch
```

### Phase 4: Validation

```powershell
function Test-Migration {
    param($Source, $Destination)
    
    # Check file exists
    if (-not (Test-Path $Destination)) {
        throw "File missing: $Destination"
    }
    
    # Check not empty
    $size = (Get-Item $Destination).Length
    if ($size -lt 200) {
        throw "File too small/empty: $Destination ($size bytes)"
    }
    
    # Check no placeholders
    $content = Get-Content $Destination -Raw
    if ($content -match "Inhalt wurde nicht|TODO|FIXME|XXX") {
        throw "Incomplete content in: $Destination"
    }
    
    return $true
}
```

## Validation Checklist

- [ ] File exists at destination
- [ ] Size > 200 bytes
- [ ] No placeholder text
- [ ] YAML frontmatter valid (if applicable)
- [ ] Links working (check sample)
- [ ] Formatting intact

## Batch Sizes

| File Type | Batch Size | Validation Rate |
|-----------|------------|-----------------|
| Critical (ADRs) | 1-2 | 100% |
| Important (Projects) | 3 | 100% |
| Normal (Daily) | 3-5 | 50% |
| Archive | 5-10 | 25% |

## Rollback

If validation fails:

```powershell
function Invoke-Rollback {
    param($BackupPath, $TargetPath)
    Remove-Item -Path $TargetPath -Recurse -Force
    Copy-Item -Path $BackupPath -Destination $TargetPath -Recurse
}
```

## Best Practices

1. **Never skip backup**
2. **Always dry-run first**
3. **Validate after every batch**
4. **Keep originals until confirmed**
5. **Document all actions**
6. **Use checksums for verification**
7. **Review with second pair of eyes**

## Related

- [[migration-best-practices|Full Best Practices Guide]]
- [[vault-migration-analysis-task|Current Migration Task]]
