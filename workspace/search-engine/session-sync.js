/**
 * Session Sync - Automatischer Export von OpenClaw Sessions
 * 
 * Exportiert aktuelle Sessions aus memory/ in das Obsidian Vault:
 * - Liest aktuelle Session (memory/YYYY-MM-DD.md)
 * - Wendet Smart Tagger an
 * - Speichert strukturiert in obsidian-vault/01-Sessions/
 * 
 * @author OpenClaw Agent
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

const PATHS = {
  memory: 'C:\\Users\\andre\\.openclaw\\workspace\\memory',
  vault: 'C:\\Users\\andre\\.openclaw\\workspace\\obsidian-vault',
  sessions: 'C:\\Users\\andre\\.openclaw\\workspace\\obsidian-vault\\01-Sessions'
};

// Lade Tagger-Funktionen
const { generateFrontmatter, formatYAML } = require('./tagger');

// Lade Scrubber
const { scrub, analyze } = require('./scrubber');

/**
 * Findet die neueste Session-Datei
 */
function findLatestSession() {
  const files = fs.readdirSync(PATHS.memory)
    .filter(f => f.endsWith('.md'))
    .map(f => ({
      name: f,
      path: path.join(PATHS.memory, f),
      mtime: fs.statSync(path.join(PATHS.memory, f)).mtime
    }))
    .sort((a, b) => b.mtime - a.mtime);
  
  return files[0] || null;
}

/**
 * Parst Session-Inhalt
 */
function parseSession(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  
  // Extrahiere wichtige Sektionen
  const sections = {
    decisions: extractSection(content, ['entscheidung', 'decision', 'beschlossen']),
    todos: extractSection(content, ['todo', 'task', 'aufgabe', 'next step']),
    code: extractCodeBlocks(content),
    summary: extractSummary(content)
  };
  
  return {
    content,
    sections,
    raw: content
  };
}

/**
 * Extrahiert Sektion nach Keywords
 */
function extractSection(content, keywords) {
  const lines = content.split('\n');
  const result = [];
  let inSection = false;
  
  for (const line of lines) {
    const lowerLine = line.toLowerCase();
    
    // Check if line starts a relevant section
    if (keywords.some(kw => lowerLine.includes(kw) && (line.startsWith('#') || line.startsWith('-')))) {
      inSection = true;
      result.push(line);
      continue;
    }
    
    // Check if line ends section (new heading)
    if (inSection && line.startsWith('#') && !keywords.some(kw => lowerLine.includes(kw))) {
      inSection = false;
      continue;
    }
    
    if (inSection && line.trim()) {
      result.push(line);
    }
  }
  
  return result.join('\n').trim();
}

/**
 * Extrahiert Code-Blöcke
 */
function extractCodeBlocks(content) {
  const blocks = [];
  const regex = /```(\w+)?\n([\s\S]*?)```/g;
  let match;
  
  while ((match = regex.exec(content)) !== null) {
    blocks.push({
      language: match[1] || 'text',
      code: match[2].trim()
    });
  }
  
  return blocks;
}

/**
 * Erstellt Zusammenfassung
 */
function extractSummary(content) {
  // Take first non-empty paragraph
  const paragraphs = content.split('\n\n');
  for (const p of paragraphs) {
    const clean = p.trim();
    if (clean && !clean.startsWith('#') && !clean.startsWith('---')) {
      return clean.substring(0, 200) + (clean.length > 200 ? '...' : '');
    }
  }
  return '';
}

/**
 * Generiert Session-Notiz
 */
function generateSessionNote(sessionData, sourceFile) {
  const title = path.basename(sourceFile, '.md');
  
  // Generiere Frontmatter mit Tagger
  const frontmatter = generateFrontmatter({
    type: 'session',
    title: `Session ${title}`,
    content: sessionData.content
  });
  
  // Session-spezifische Ergänzungen
  frontmatter.source_file = sourceFile;
  frontmatter.decisions = sessionData.sections.decisions ? 'extracted' : 'none';
  frontmatter.todos = sessionData.sections.todos ? 'extracted' : 'none';
  frontmatter.code_blocks = sessionData.sections.code.length;
  
  // Build note content
  const sections = [
    formatYAML(frontmatter),
    '',
    `# Session ${title}`,
    '',
    '## Zusammenfassung',
    sessionData.sections.summary || 'Keine Zusammenfassung verfügbar.',
    ''
  ];
  
  // Add decisions if found
  if (sessionData.sections.decisions) {
    sections.push(
      '## Getroffene Entscheidungen',
      sessionData.sections.decisions,
      ''
    );
  }
  
  // Add TODOs if found
  if (sessionData.sections.todos) {
    sections.push(
      '## Offene Aufgaben',
      sessionData.sections.todos,
      ''
    );
  }
  
  // Add code blocks if found
  if (sessionData.sections.code.length > 0) {
    sections.push('## Code-Blöcke', '');
    for (const block of sessionData.sections.code.slice(0, 5)) {
      sections.push(
        `### ${block.language}`,
        '```' + block.language,
        block.code.substring(0, 500) + (block.code.length > 500 ? '\n...' : ''),
        '```',
        ''
      );
    }
  }
  
  // Add original content
  sections.push(
    '---',
    '',
    '## Original',
    '',
    '```',
    sessionData.raw.substring(0, 1000) + (sessionData.raw.length > 1000 ? '\n... (truncated)' : ''),
    '```'
  );
  
  return sections.join('\n');
}

/**
 * Sync-Funktion
 */
function syncLatestSession() {
  console.log('🔄 Session Sync gestartet...\n');
  
  // Finde neueste Session
  const latest = findLatestSession();
  if (!latest) {
    console.log('❌ Keine Session-Dateien gefunden');
    return;
  }
  
  console.log(`📁 Quelle: ${latest.name}`);
  console.log(`📅 Modified: ${latest.mtime.toLocaleString()}`);
  
  // Parse Session
  const sessionData = parseSession(latest.path);
  console.log(`📊 Decisions: ${sessionData.sections.decisions ? 'Ja' : 'Nein'}`);
  console.log(`📊 TODOs: ${sessionData.sections.todos ? 'Ja' : 'Nein'}`);
  console.log(`📊 Code-Blöcke: ${sessionData.sections.code.length}`);
  
  // Generiere Notiz
  let noteContent = generateSessionNote(sessionData, latest.name);
  
  // 🔒 PII Scrubbing
  console.log('\n🔒 Prüfe auf sensitive Daten...');
  const scrubResult = scrub(noteContent);
  if (scrubResult.totalMasked > 0) {
    console.log(`   ⚠️  ${scrubResult.totalMasked} sensitive Daten maskiert`);
    noteContent = scrubResult.scrubbed;
  } else {
    console.log('   ✅ Keine sensitiven Daten gefunden');
  }
  
  // Speichere
  const targetFile = path.join(PATHS.sessions, `Session-${latest.name}`);
  fs.mkdirSync(PATHS.sessions, { recursive: true });
  fs.writeFileSync(targetFile, noteContent);
  
  console.log(`\n✅ Gespeichert: ${targetFile}`);
  console.log(`📦 Größe: ${(fs.statSync(targetFile).size / 1024).toFixed(2)} KB`);
}

/**
 * Batch-Sync: Alle Sessions
 */
function syncAllSessions() {
  console.log('🔄 Batch-Sync aller Sessions...\n');
  
  const files = fs.readdirSync(PATHS.memory)
    .filter(f => f.endsWith('.md'))
    .map(f => ({
      name: f,
      path: path.join(PATHS.memory, f)
    }));
  
  let synced = 0;
  let skipped = 0;
  
  for (const file of files) {
    const targetFile = path.join(PATHS.sessions, `Session-${file.name}`);
    
    // Skip if already exists and is newer
    if (fs.existsSync(targetFile)) {
      const sourceStat = fs.statSync(file.path);
      const targetStat = fs.statSync(targetFile);
      if (targetStat.mtime >= sourceStat.mtime) {
        skipped++;
        continue;
      }
    }
    
    try {
      const sessionData = parseSession(file.path);
      const noteContent = generateSessionNote(sessionData, file.name);
      fs.writeFileSync(targetFile, noteContent);
      synced++;
      console.log(`✅ ${file.name}`);
    } catch (err) {
      console.log(`❌ ${file.name}: ${err.message}`);
    }
  }
  
  console.log(`\n📊 Ergebnis:`);
  console.log(`   Synced: ${synced}`);
  console.log(`   Skipped: ${skipped}`);
  console.log(`   Total: ${files.length}`);
}

// CLI
const args = process.argv.slice(2);
const command = args[0] || 'latest';

if (command === 'latest') {
  syncLatestSession();
} else if (command === 'all') {
  syncAllSessions();
} else if (command === 'help') {
  console.log(`
🔄 Session Sync

Verwendung:
  node session-sync.js [Befehl]

Befehle:
  latest    Sync neueste Session (default)
  all       Sync alle Sessions
  help      Zeige Hilfe

Beispiele:
  node session-sync.js
  node session-sync.js latest
  node session-sync.js all
  `);
} else {
  console.log(`❌ Unbekannter Befehl: ${command}`);
  console.log('Verwende "help" für Hilfe');
}

module.exports = {
  syncLatestSession,
  syncAllSessions,
  parseSession,
  generateSessionNote
};
