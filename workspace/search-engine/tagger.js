/**
 * Smart Tagger - Automatische Klassifikation und Tagging
 * 
 * Analysiert Inhalte und schlägt vor:
 * - PARA-Kategorie (Project, Area, Resource, Archive)
 * - Tags basierend auf Keyword-Matching
 * - Verwandte Notizen (via Search Engine)
 * - YAML Frontmatter
 * 
 * @author OpenClaw Agent
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

// Keyword-Kategorien für automatisches Tagging
const TAG_CATEGORIES = {
  // Technologie
  docker: ['docker', 'container', 'containerization', 'dockerfile', 'docker-compose'],
  kubernetes: ['kubernetes', 'k8s', 'pod', 'deployment', 'helm'],
  coding: ['code', 'programming', 'function', 'class', 'api', 'implementation'],
  ai: ['ai', 'llm', 'gpt', 'claude', 'openai', 'machine-learning', 'neural'],
  security: ['security', 'cve', 'vulnerability', 'exploit', 'sandbox', 'encryption'],
  
  // Konzepte
  architecture: ['architecture', 'system', 'design', 'pattern', 'microservice'],
  research: ['research', 'experiment', 'benchmark', 'analysis', 'comparison'],
  workflow: ['workflow', 'process', 'automation', 'pipeline', 'ci/cd'],
  
  // Projekte (spezifisch für Parzival)
  ecc: ['ecc', 'everything-claude-code', 'second-brain', 'framework'],
  autoresearch: ['autoresearch', 'karpathy', 'auto-research', 'experiment-loop'],
  openclaw: ['openclaw', 'claw', 'agent', 'session', 'mcp'],
  
  // Meta
  decision: ['decision', 'adr', 'architecture-decision', 'chosen', 'rejected'],
  todo: ['todo', 'task', 'action-item', 'next-step', 'follow-up'],
  bug: ['bug', 'error', 'issue', 'fix', 'problem'],
};

// PARA-Klassifikations-Keywords
const PARA_CLASSIFIERS = {
  project: {
    keywords: ['project', 'projekt', 'goal', 'ziel', 'deadline', 'frist', 'outcome', 'ergebnis', 'milestone'],
    indicators: ['due:', 'deadline:', 'goal:', 'outcome:'],
    weight: 1.0
  },
  area: {
    keywords: ['area', 'bereich', 'responsibility', 'verantwortung', 'ongoing', 'kontinuierlich', 'standard'],
    indicators: ['status: active', 'priority:'],
    weight: 0.8
  },
  resource: {
    keywords: ['resource', 'ressource', 'reference', 'referenz', 'snippet', 'code-block', 'how-to', 'guide'],
    indicators: ['language:', 'source:', 'topic:'],
    weight: 0.6
  },
  archive: {
    keywords: ['archive', 'archiv', 'completed', 'abgeschlossen', 'deprecated', 'obsolete', 'old'],
    indicators: ['status: completed', 'status: archived', 'status: deprecated'],
    weight: 0.4
  }
};

/**
 * Extrahiert Text aus Inhalt (Markdown-Unterstützung)
 */
function extractText(content) {
  // Remove code blocks
  let text = content.replace(/```[\s\S]*?```/g, ' ');
  // Remove inline code
  text = text.replace(/`[^`]+`/g, ' ');
  // Remove links but keep text
  text = text.replace(/\[([^\]]+)\]\([^)]+\)/g, '$1');
  text = text.replace(/\[\[([^\]|]+)\|?[^\]]*\]\]/g, '$1');
  // Normalize
  return text.toLowerCase().replace(/[^\w\säöüß]/g, ' ').replace(/\s+/g, ' ').trim();
}

/**
 * Findet passende Tags für Inhalt
 */
function suggestTags(content) {
  const text = extractText(content);
  const words = new Set(text.split(/\s+/));
  const tags = [];
  const scores = {};
  
  for (const [tag, keywords] of Object.entries(TAG_CATEGORIES)) {
    let score = 0;
    for (const keyword of keywords) {
      const keywordWords = keyword.toLowerCase().split(/[-\s]+/);
      const matches = keywordWords.filter(kw => text.includes(kw)).length;
      if (matches === keywordWords.length) {
        score += 1; // Full phrase match
      } else if (matches > 0) {
        score += 0.3 * matches; // Partial match
      }
    }
    
    if (score > 0) {
      scores[tag] = score;
    }
  }
  
  // Sort by score, take top 5
  const sortedTags = Object.entries(scores)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([tag]) => tag);
  
  return sortedTags;
}

/**
 * Bestimmt PARA-Kategorie
 */
function classifyPARA(content, frontmatter = {}) {
  const text = extractText(content);
  const scores = {};
  
  // Check frontmatter indicators first
  const contentStr = JSON.stringify(frontmatter).toLowerCase();
  
  for (const [category, config] of Object.entries(PARA_CLASSIFIERS)) {
    let score = 0;
    
    // Keyword matching
    for (const keyword of config.keywords) {
      const matches = (text.match(new RegExp(keyword, 'g')) || []).length;
      score += matches * config.weight;
    }
    
    // Indicator matching in frontmatter/content
    for (const indicator of config.indicators) {
      if (contentStr.includes(indicator.toLowerCase())) {
        score += 2 * config.weight; // Strong indicator
      }
      if (text.includes(indicator.toLowerCase())) {
        score += config.weight;
      }
    }
    
    scores[category] = score;
  }
  
  // Find highest score
  const sorted = Object.entries(scores).sort((a, b) => b[1] - a[1]);
  return sorted[0][0]; // Return category with highest score
}

/**
 * Findet existierende Notizen für Wikilinks mit Kontext
 */
function findRelatedNotes(content, indexPath) {
  if (!fs.existsSync(indexPath)) {
    return [];
  }
  
  const index = JSON.parse(fs.readFileSync(indexPath, 'utf-8'));
  const text = extractText(content);
  const contentTokens = text.split(/\s+/).filter(t => t.length > 2);
  const contentTokenSet = new Set(contentTokens);
  
  const scored = [];
  const seenTitles = new Set(); // Für Duplikat-Erkennung
  
  for (const doc of index.documents) {
    // Überspringe Duplikate (gleicher Titel)
    if (seenTitles.has(doc.title)) {
      continue;
    }
    
    const docTokens = extractText(doc.text).split(/\s+/);
    const docTokenSet = new Set(docTokens);
    
    // Gemeinsame Begriffe finden
    const overlap = [...contentTokenSet].filter(t => docTokenSet.has(t));
    const score = overlap.length / Math.sqrt(docTokens.length + 1);
    
    if (score > 0.1) {
      seenTitles.add(doc.title);
      
      // Kontext: Top-3 gemeinsame Begriffe
      const topOverlap = overlap.slice(0, 3).join(', ');
      
      scored.push({
        title: doc.title,
        path: doc.path,
        source: doc.source,
        score: score,
        context: topOverlap,
        sharedTerms: overlap.length
      });
    }
  }
  
  return scored
    .sort((a, b) => b.score - a.score)
    .slice(0, 5);
}

/**
 * Generiert vollständiges Frontmatter
 */
function generateFrontmatter(options) {
  const {
    type = 'note',
    title = 'Untitled',
    content = '',
    indexPath = path.join(__dirname, 'index', 'index.json')
  } = options;
  
  const now = new Date();
  const date = now.toISOString().split('T')[0];
  const time = now.toTimeString().slice(0, 5);
  
  // Auto-classify
  const category = classifyPARA(content);
  const tags = suggestTags(content);
  const relatedNotes = findRelatedNotes(content, indexPath);
  
  // Format related notes with context
  const formattedRelated = relatedNotes.slice(0, 3).map(r => {
    const sourceIcon = r.source === 'obsidian-vault' ? '📁' : 
                      r.source === 'memory' ? '📝' : '📦';
    return `${sourceIcon} [[${r.title}]] (${r.sharedTerms} gemeinsame Begriffe: ${r.context})`;
  });
  
  // Type-specific fields
  const typeFields = {
    session: {
      session_id: `${date}-${time.replace(':', '')}`,
      agent: 'andrew-main',
      user: 'parzival',
      status: 'active'
    },
    adr: {
      adr_id: `ADR-${date.replace(/-/g, '')}-001`,
      status: 'Proposed',
      priority: 'Medium'
    },
    project: {
      project_id: `PROJ-${date.replace(/-/g, '')}-001`,
      status: 'Active',
      progress: 0
    },
    code: {
      language: detectLanguage(content),
      component: extractComponentName(content)
    }
  };
  
  const frontmatter = {
    date,
    time,
    type,
    title,
    category, // PARA category
    tags: [...new Set([...tags, category, type])],
    related_notes: formattedRelated,
    related_count: relatedNotes.length,
    ...(typeFields[type] || {})
  };
  
  return frontmatter;
}

/**
 * Detektiert Programmiersprache aus Code
 */
function detectLanguage(content) {
  const patterns = {
    python: /def |import |class.*\(|print\(|\.py$/m,
    javascript: /const |let |var |function |=> |\.js$/m,
    typescript: /interface |type |: \w+ = |\.ts$/m,
    powershell: /Get-|Set-|Function |\$\w+ |\.ps1$/m,
    rust: /fn |let mut |impl |use |\.rs$/m,
    go: /func |package |import |\.go$/m
  };
  
  for (const [lang, pattern] of Object.entries(patterns)) {
    if (pattern.test(content)) return lang;
  }
  return 'unknown';
}

/**
 * Extrahiert Komponenten-Name aus Inhalt
 */
function extractComponentName(content) {
  const patterns = [
    /class\s+(\w+)/,
    /function\s+(\w+)/,
    /def\s+(\w+)/,
    /fn\s+(\w+)/,
    /component\s*[:\-]?\s*(\w+)/i
  ];
  
  for (const pattern of patterns) {
    const match = content.match(pattern);
    if (match) return match[1];
  }
  return 'unknown';
}

/**
 * Formatiert Frontmatter als YAML
 */
function formatYAML(frontmatter) {
  const lines = ['---'];
  
  for (const [key, value] of Object.entries(frontmatter)) {
    if (Array.isArray(value)) {
      if (value.length === 0) {
        lines.push(`${key}: []`);
      } else {
        lines.push(`${key}:`);
        for (const item of value) {
          lines.push(`  - ${item}`);
        }
      }
    } else if (typeof value === 'object' && value !== null) {
      lines.push(`${key}:`);
      for (const [k, v] of Object.entries(value)) {
        lines.push(`  ${k}: ${v}`);
      }
    } else {
      lines.push(`${key}: ${value}`);
    }
  }
  
  lines.push('---');
  return lines.join('\n');
}

// CLI Interface
if (require.main === module) {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.log(`
🏷️  Smart Tagger

Verwendung:
  node tagger.js "<Inhalt>" [Optionen]
  
Optionen:
  --type=TYPE        Notiz-Typ (session, adr, project, code)
  --title="Titel"    Titel der Notiz
  --save=PATH        Speichert Ergebnis als Datei

Beispiele:
  node tagger.js "Docker container setup für ECC Framework" --type=adr --title="Docker-Entscheidung"
  node tagger.js "Session über API Design Patterns" --type=session --save=01-Sessions/test.md
  `);
    process.exit(0);
  }

  const content = args[0];
  const options = {
    type: 'note',
    title: 'Untitled',
    content: content
  };

  for (let i = 1; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith('--type=')) {
      options.type = arg.split('=')[1];
    } else if (arg.startsWith('--title=')) {
      options.title = arg.split('=')[1].replace(/^"|"$/g, '');
    } else if (arg.startsWith('--save=')) {
      options.savePath = arg.split('=')[1];
    }
  }

  // Generiere Frontmatter
  const frontmatter = generateFrontmatter(options);

  // Ausgabe
  console.log('\n🏷️  Smart Tagging Ergebnis\n');
  console.log('📋 Generiertes Frontmatter:');
  console.log(formatYAML(frontmatter));
  console.log('\n📊 Analyse:');
  console.log(`   PARA-Kategorie: ${frontmatter.category}`);
  console.log(`   Vorgeschlagene Tags: ${frontmatter.tags.join(', ')}`);
  console.log(`   Verwandte Notizen: ${frontmatter.related_notes.join(', ') || 'keine gefunden'}`);

  // Speichern falls gewünscht
  if (options.savePath) {
    const output = formatYAML(frontmatter) + '\n\n# ' + options.title + '\n\n' + content;
    const fullPath = path.join('C:\\Users\\andre\\.openclaw\\workspace\\obsidian-vault', options.savePath);
    fs.mkdirSync(path.dirname(fullPath), { recursive: true });
    fs.writeFileSync(fullPath, output);
    console.log(`\n💾 Gespeichert: ${fullPath}`);
  }
}

module.exports = {
  suggestTags,
  classifyPARA,
  findRelatedNotes,
  generateFrontmatter,
  formatYAML
};
