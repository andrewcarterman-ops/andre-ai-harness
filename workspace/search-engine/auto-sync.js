/**
 * Auto-Sync für Sessions
 * 
 * Läuft automatisch und sync nur neue/geänderte Sessions
 * - Speichert letzten Sync-Zeitpunkt
 * - Vergleicht Modification-Time
 * - Sync nur was nötig ist
 * 
 * @author OpenClaw Agent
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PATHS = {
  memory: 'C:\\Users\\andre\\.openclaw\\workspace\\memory',
  sessions: 'C:\\Users\\andre\\.openclaw\\workspace\\obsidian-vault\\01-Sessions',
  state: 'C:\\Users\\andre\\.openclaw\\workspace\\search-engine\\.sync-state.json'
};

/**
 * Lädt Sync-State
 */
function loadState() {
  if (fs.existsSync(PATHS.state)) {
    return JSON.parse(fs.readFileSync(PATHS.state, 'utf-8'));
  }
  return {
    lastSync: 0,
    syncedFiles: []
  };
}

/**
 * Speichert Sync-State
 */
function saveState(state) {
  fs.writeFileSync(PATHS.state, JSON.stringify(state, null, 2));
}

/**
 * Prüft ob Sync nötig ist
 */
function needsSync(filePath, state) {
  const stats = fs.statSync(filePath);
  return stats.mtime.getTime() > state.lastSync;
}

/**
 * Führt Sync durch
 */
function autoSync() {
  console.log(`🔄 Auto-Sync: ${new Date().toLocaleString()}`);
  
  const state = loadState();
  const memoryFiles = fs.readdirSync(PATHS.memory)
    .filter(f => f.endsWith('.md'))
    .map(f => path.join(PATHS.memory, f));
  
  let synced = 0;
  let skipped = 0;
  let errors = 0;
  
  for (const filePath of memoryFiles) {
    const fileName = path.basename(filePath);
    
    if (!needsSync(filePath, state)) {
      skipped++;
      continue;
    }
    
    try {
      // Führe session-sync für diese Datei aus
      const cmd = `node "${path.join(__dirname, 'session-sync.js')}" "${fileName}"`;
      execSync(cmd, { cwd: __dirname, stdio: 'pipe' });
      synced++;
      console.log(`  ✅ ${fileName}`);
    } catch (err) {
      errors++;
      console.log(`  ❌ ${fileName}: ${err.message}`);
    }
  }
  
  // Update state
  state.lastSync = Date.now();
  saveState(state);
  
  console.log(`\n📊 Ergebnis:`);
  console.log(`   Synced: ${synced}`);
  console.log(`   Skipped: ${skipped}`);
  console.log(`   Errors: ${errors}`);
  console.log(`   Next: ${new Date(state.lastSync + 300000).toLocaleTimeString()}`);
}

// Führe aus
autoSync();
