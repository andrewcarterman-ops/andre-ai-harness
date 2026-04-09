/**
 * Semantic Search Engine für OpenClaw SecondBrain
 * 
 * Features:
 * - BM25 Keyword-Suche
 * - TF-IDF Vektorisierung
 * - Multi-Source Indexierung
 * 
 * @author OpenClaw Agent
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

// Konfiguration
const CONFIG = {
  sources: [
    { name: 'obsidian-vault', path: 'C:\\Users\\andre\\.openclaw\\workspace\\obsidian-vault', priority: 1.5 },
    { name: 'memory', path: 'C:\\Users\\andre\\.openclaw\\workspace\\memory', priority: 1.2 },
    { name: 'vault-archive', path: 'C:\\Users\\andre\\.openclaw\\workspace\\vault-archive\\Main_Obsidian_Vault', priority: 1.0 }
  ],
  indexDir: path.join(__dirname, 'index'),
  maxFileSize: 1024 * 1024, // 1MB
  includeExtensions: ['.md', '.txt'],
  excludePatterns: ['node_modules', '.git', '.obsidian', 'index']
};

/**
 * Extrahiert YAML Frontmatter aus Markdown
 */
function extractFrontmatter(content) {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) return {};
  
  const lines = match[1].split('\n');
  const metadata = {};
  
  for (const line of lines) {
    const [key, ...valueParts] = line.split(':');
    if (key && valueParts.length > 0) {
      metadata[key.trim()] = valueParts.join(':').trim();
    }
  }
  
  return metadata;
}

/**
 * Extrahiert reinen Text aus Markdown (ohne YAML, ohne Formatierung)
 */
function extractText(content) {
  // Remove YAML frontmatter
  let text = content.replace(/^---\s*\n[\s\S]*?\n---\s*/, '');
  
  // Remove markdown formatting
  text = text
    .replace(/```[\s\S]*?```/g, ' ')  // Code blocks
    .replace(/`([^`]+)`/g, '$1')       // Inline code
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')  // Links
    .replace(/\[\[([^\]|]+)\|?[^\]]*\]\]/g, '$1')  // Wikilinks
    .replace(/[#*_~|`]/g, ' ')          // Formatting chars
    .replace(/\n+/g, ' ')               // Newlines to spaces
    .replace(/\s+/g, ' ')               // Multiple spaces to one
    .trim();
  
  return text;
}

/**
 * Tokenisiert Text (einfache Version)
 */
function tokenize(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\säöüß]/g, ' ')
    .split(/\s+/)
    .filter(t => t.length > 2)
    .filter(t => !STOPWORDS.has(t));
}

// Deutsche + Englische Stopwords
const STOPWORDS = new Set([
  'der', 'die', 'das', 'ein', 'eine', 'und', 'oder', 'aber', 'mit', 'für',
  'von', 'zu', 'bei', 'nach', 'aus', 'wie', 'was', 'wer', 'wann', 'wo',
  'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can', 'had',
  'her', 'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his',
  'this', 'that', 'with', 'from', 'they', 'she', 'will', 'have', 'been',
  'werden', 'wurde', 'wurden', 'haben', 'hat', 'ist', 'sind', 'sein'
]);

/**
 * Berechnet TF-IDF Vektor für ein Dokument
 */
function computeTfIdf(tokens, docFreq, totalDocs) {
  const tf = {};
  const docLength = tokens.length;
  
  // Term Frequency
  for (const token of tokens) {
    tf[token] = (tf[token] || 0) + 1;
  }
  
  // Normalize TF and apply IDF
  const vector = {};
  for (const [term, count] of Object.entries(tf)) {
    const tfScore = count / docLength;
    const df = docFreq[term] || 1;
    const idf = Math.log(totalDocs / df);
    vector[term] = tfScore * idf;
  }
  
  // Normalize vector length
  const magnitude = Math.sqrt(Object.values(vector).reduce((sum, v) => sum + v * v, 0));
  for (const term in vector) {
    vector[term] = vector[term] / (magnitude || 1);
  }
  
  return vector;
}

/**
 * Berechnet Cosine Similarity zwischen zwei Vektoren
 */
function cosineSimilarity(vec1, vec2) {
  let dotProduct = 0;
  for (const term in vec1) {
    if (vec2[term]) {
      dotProduct += vec1[term] * vec2[term];
    }
  }
  return dotProduct;
}

/**
 * Durchsucht Verzeichnis nach Markdown-Dateien
 */
function findFiles(dir, files = []) {
  if (!fs.existsSync(dir)) return files;
  
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    
    if (entry.isDirectory()) {
      if (CONFIG.excludePatterns.some(p => entry.name.includes(p))) continue;
      findFiles(fullPath, files);
    } else if (entry.isFile()) {
      const ext = path.extname(entry.name).toLowerCase();
      if (CONFIG.includeExtensions.includes(ext)) {
        const stats = fs.statSync(fullPath);
        if (stats.size <= CONFIG.maxFileSize) {
          files.push(fullPath);
        }
      }
    }
  }
  
  return files;
}

/**
 * Haupt-Indexierungsfunktion
 */
async function buildIndex() {
  console.log('🔍 Starte Indexierung...\n');
  
  const documents = [];
  const termDocFreq = {};
  let totalTokens = 0;
  
  // Alle Quellen durchsuchen
  for (const source of CONFIG.sources) {
    console.log(`📁 Indexiere: ${source.name}`);
    
    if (!fs.existsSync(source.path)) {
      console.log(`   ⚠️  Pfad nicht gefunden: ${source.path}`);
      continue;
    }
    
    const files = findFiles(source.path);
    console.log(`   Gefunden: ${files.length} Dateien`);
    
    for (const filePath of files) {
      try {
        const content = fs.readFileSync(filePath, 'utf-8');
        const frontmatter = extractFrontmatter(content);
        const text = extractText(content);
        const tokens = tokenize(text);
        
        // Track document frequency
        const uniqueTerms = new Set(tokens);
        for (const term of uniqueTerms) {
          termDocFreq[term] = (termDocFreq[term] || 0) + 1;
        }
        
        documents.push({
          id: documents.length,
          path: filePath,
          source: source.name,
          sourcePriority: source.priority,
          title: path.basename(filePath, path.extname(filePath)),
          frontmatter,
          text: text.substring(0, 5000), // Limit storage
          tokens,
          tokenCount: tokens.length,
          lastModified: fs.statSync(filePath).mtime
        });
        
        totalTokens += tokens.length;
      } catch (err) {
        console.error(`   ❌ Fehler bei ${filePath}: ${err.message}`);
      }
    }
  }
  
  console.log(`\n📊 Statistik:`);
  console.log(`   Dokumente: ${documents.length}`);
  console.log(`   Einzigartige Begriffe: ${Object.keys(termDocFreq).length}`);
  console.log(`   Gesamt-Tokens: ${totalTokens}`);
  
  // TF-IDF Vektoren berechnen
  console.log('\n🔢 Berechne TF-IDF Vektoren...');
  for (const doc of documents) {
    doc.vector = computeTfIdf(doc.tokens, termDocFreq, documents.length);
  }
  
  // Index speichern
  if (!fs.existsSync(CONFIG.indexDir)) {
    fs.mkdirSync(CONFIG.indexDir, { recursive: true });
  }
  
  const indexData = {
    version: '1.0.0',
    created: new Date().toISOString(),
    documentCount: documents.length,
    termCount: Object.keys(termDocFreq).length,
    documents: documents.map(d => ({
      id: d.id,
      path: d.path,
      source: d.source,
      sourcePriority: d.sourcePriority,
      title: d.title,
      frontmatter: d.frontmatter,
      text: d.text.substring(0, 1000), // Preview
      vector: d.vector,
      lastModified: d.lastModified
    })),
    termDocFreq
  };
  
  fs.writeFileSync(
    path.join(CONFIG.indexDir, 'index.json'),
    JSON.stringify(indexData, null, 2)
  );
  
  console.log(`\n✅ Index gespeichert: ${path.join(CONFIG.indexDir, 'index.json')}`);
  console.log(`   Größe: ${(fs.statSync(path.join(CONFIG.indexDir, 'index.json')).size / 1024 / 1024).toFixed(2)} MB`);
}

// Starte Indexierung
buildIndex().catch(err => {
  console.error('❌ Fehler:', err);
  process.exit(1);
});
