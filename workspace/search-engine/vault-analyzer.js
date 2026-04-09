/**
 * Vault Archive Analyzer
 * 
 * Analysiert vault-archive auf:
 * - Duplikate (gleiche Dateinamen)
 * - Leere/unnötige Dateien
 * - Große Dateien
 * - Bereinigungs-Empfehlungen
 * 
 * @author OpenClaw Agent
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

const ARCHIVE_PATH = 'C:\\Users\\andre\\.openclaw\\workspace\\vault-archive\\Main_Obsidian_Vault';

/**
 * Sammelt alle Dateien mit Metadaten
 */
function collectFiles(dir, files = []) {
  if (!fs.existsSync(dir)) return files;
  
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    
    if (entry.isDirectory()) {
      if (entry.name === '.git' || entry.name === 'node_modules') continue;
      collectFiles(fullPath, files);
    } else {
      const stats = fs.statSync(fullPath);
      files.push({
        name: entry.name,
        path: fullPath,
        relativePath: fullPath.replace(ARCHIVE_PATH + '\\', ''),
        size: stats.size,
        modified: stats.mtime
      });
    }
  }
  
  return files;
}

/**
 * Findet Duplikate nach Namen
 */
function findDuplicates(files) {
  const byName = {};
  
  for (const file of files) {
    if (!byName[file.name]) {
      byName[file.name] = [];
    }
    byName[file.name].push(file);
  }
  
  return Object.entries(byName)
    .filter(([name, group]) => group.length > 1)
    .sort((a, b) => b[1].length - a[1].length);
}

/**
 * Findet potenziell unwichtige Dateien
 */
function findNoise(files) {
  const noisePatterns = [
    /^LICENSE/i,
    /^CHANGELOG/i,
    /^CODE_OF_CONDUCT/i,
    /^CONTRIBUTING/i,
    /^SECURITY/i,
    /^SPONSOR/i,
    /^\.git/i,
    /^package-lock\.json$/i,
    /^yarn\.lock$/i,
    /^\.DS_Store$/i
  ];
  
  return files.filter(f => 
    noisePatterns.some(pattern => pattern.test(f.name))
  );
}

/**
 * Findet sehr große Dateien
 */
function findLargeFiles(files, threshold = 1024 * 1024) {
  return files
    .filter(f => f.size > threshold)
    .sort((a, b) => b.size - a.size);
}

/**
 * Findet leere oder minimale Dateien
 */
function findEmptyFiles(files) {
  return files.filter(f => f.size === 0 || f.size < 100);
}

/**
 * Haupt-Analyse
 */
function analyze() {
  console.log('🔍 Analysiere Vault-Archive...\n');
  
  const files = collectFiles(ARCHIVE_PATH);
  console.log(`📊 Gesamte Dateien: ${files.length}`);
  console.log(`📦 Gesamtgröße: ${(files.reduce((s, f) => s + f.size, 0) / 1024 / 1024).toFixed(2)} MB\n`);
  
  // Duplikate
  console.log('═'.repeat(60));
  console.log('📋 DUPLIKATE (nach Dateiname)');
  console.log('═'.repeat(60));
  
  const duplicates = findDuplicates(files);
  let duplicateCount = 0;
  
  for (const [name, group] of duplicates.slice(0, 20)) {
    console.log(`\n${name}: ${group.length} Vorkommen`);
    for (const f of group.slice(0, 3)) {
      console.log(`  → ${f.relativePath.substring(0, 80)}`);
    }
    if (group.length > 3) {
      console.log(`  ... und ${group.length - 3} weitere`);
    }
    duplicateCount += group.length;
  }
  
  if (duplicates.length > 20) {
    console.log(`\n... und ${duplicates.length - 20} weitere Duplikat-Gruppen`);
  }
  
  console.log(`\n📈 Statistik: ${duplicateCount} Dateien sind Duplikate (${(duplicateCount/files.length*100).toFixed(1)}%)\n`);
  
  // Noise-Dateien
  console.log('═'.repeat(60));
  console.log('🔇 NOISE (Standard-Dateien wie LICENSE, CHANGELOG)');
  console.log('═'.repeat(60));
  
  const noise = findNoise(files);
  const noiseByType = {};
  for (const f of noise) {
    noiseByType[f.name] = (noiseByType[f.name] || 0) + 1;
  }
  
  for (const [name, count] of Object.entries(noiseByType).sort((a, b) => b[1] - a[1]).slice(0, 10)) {
    console.log(`  ${name}: ${count}x`);
  }
  console.log(`\n📈 Statistik: ${noise.length} Noise-Dateien (${(noise.length/files.length*100).toFixed(1)}%)\n`);
  
  // Große Dateien
  console.log('═'.repeat(60));
  console.log('📦 GROßE DATEIEN (> 1 MB)');
  console.log('═'.repeat(60));
  
  const large = findLargeFiles(files);
  for (const f of large.slice(0, 10)) {
    console.log(`  ${(f.size / 1024 / 1024).toFixed(2)} MB - ${f.name}`);
    console.log(`    ${f.relativePath.substring(0, 60)}`);
  }
  console.log(`\n📈 Statistik: ${large.length} große Dateien\n`);
  
  // Leere Dateien
  console.log('═'.repeat(60));
  console.log('📄 LEERE/KLEINE DATEIEN (< 100 Bytes)');
  console.log('═'.repeat(60));
  
  const empty = findEmptyFiles(files);
  console.log(`  ${empty.length} Dateien sind leer oder sehr klein\n`);
  
  // Empfehlungen
  console.log('═'.repeat(60));
  console.log('💡 EMPFEHLUNGEN');
  console.log('═'.repeat(60));
  
  console.log(`
1. DUPLIKATE BEREINIGEN
   → ${duplicateCount} Dateien können potenziell entfernt werden
   → Bewahre nur die neueste Version pro Duplikat-Gruppe
   → Potenzielle Einsparung: ~${(duplicateCount * 10 / 1024).toFixed(1)} MB

2. NOISE-FILTER ANWENDEN
   → ${noise.length} Standard-Dateien (LICENSE, CHANGELOG, etc.)
   → Diese können aus dem Index ausgeschlossen werden
   → Quelle: vault-archive (nicht obsidian-vault)

3. INDEX-OPTIMIERUNG
   → Aktuell: ${files.length} Dateien im Index
   → Nach Bereinigung: ~${files.length - duplicateCount - Math.floor(noise.length * 0.5)} Dateien
   → Reduktion um ~${((duplicateCount + noise.length * 0.5) / files.length * 100).toFixed(0)}%
`);
  
  // Speichere Report
  const report = {
    date: new Date().toISOString(),
    summary: {
      totalFiles: files.length,
      totalSizeMB: files.reduce((s, f) => s + f.size, 0) / 1024 / 1024,
      duplicates: duplicateCount,
      noiseFiles: noise.length,
      largeFiles: large.length,
      emptyFiles: empty.length
    },
    topDuplicates: duplicates.slice(0, 10).map(([name, group]) => ({
      name,
      count: group.length,
      paths: group.map(f => f.relativePath)
    }))
  };
  
  fs.writeFileSync(
    path.join(__dirname, 'vault-analysis-report.json'),
    JSON.stringify(report, null, 2)
  );
  
  console.log('💾 Report gespeichert: vault-analysis-report.json');
}

// Führe Analyse aus
analyze();
