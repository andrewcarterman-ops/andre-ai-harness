/**
 * Search Engine - Suchfunktion für den Index
 * 
 * Verwendung:
 *   node search.js "Suchbegriff" [--limit=10] [--source=obsidian-vault]
 * 
 * @author OpenClaw Agent
 * @version 1.0.0
 */

const fs = require('fs');
const path = require('path');

const INDEX_PATH = path.join(__dirname, 'index', 'index.json');

/**
 * Lädt den Index
 */
function loadIndex() {
  if (!fs.existsSync(INDEX_PATH)) {
    console.error('❌ Index nicht gefunden. Führe zuerst indexer.js aus.');
    process.exit(1);
  }
  
  return JSON.parse(fs.readFileSync(INDEX_PATH, 'utf-8'));
}

/**
 * Tokenisiert Suchbegriff
 */
function tokenize(text) {
  return text
    .toLowerCase()
    .replace(/[^\w\säöüß]/g, ' ')
    .split(/\s+/)
    .filter(t => t.length > 2);
}

/**
 * Berechnet BM25 Score
 */
function bm25Score(queryTokens, docTokens, docFreq, totalDocs, avgDocLen) {
  const k1 = 1.2;
  const b = 0.75;
  
  const docLen = docTokens.length;
  const tf = {};
  for (const token of docTokens) {
    tf[token] = (tf[token] || 0) + 1;
  }
  
  let score = 0;
  for (const term of queryTokens) {
    const df = docFreq[term] || 0;
    if (df === 0) continue;
    
    const idf = Math.log((totalDocs - df + 0.5) / (df + 0.5) + 1);
    const termFreq = tf[term] || 0;
    
    score += idf * ((termFreq * (k1 + 1)) / 
      (termFreq + k1 * (1 - b + b * (docLen / avgDocLen))));
  }
  
  return score;
}

/**
 * Berechnet Cosine Similarity
 */
function cosineSimilarity(queryTokens, docVector) {
  // Create query vector
  const queryTf = {};
  for (const token of queryTokens) {
    queryTf[token] = (queryTf[token] || 0) + 1;
  }
  
  // Simple TF vector (no IDF for speed)
  const queryVec = {};
  for (const [term, count] of Object.entries(queryTf)) {
    queryVec[term] = count / queryTokens.length;
  }
  
  // Normalize query
  const qMag = Math.sqrt(Object.values(queryVec).reduce((s, v) => s + v * v, 0));
  for (const term in queryVec) {
    queryVec[term] /= (qMag || 1);
  }
  
  // Dot product
  let dotProduct = 0;
  for (const term in queryVec) {
    if (docVector[term]) {
      dotProduct += queryVec[term] * docVector[term];
    }
  }
  
  return dotProduct;
}

/**
 * Haupt-Suchfunktion
 */
function search(query, options = {}) {
  const { limit = 10, source = null } = options;
  
  console.log(`🔍 Suche: "${query}"\n`);
  
  const index = loadIndex();
  const queryTokens = tokenize(query);
  
  if (queryTokens.length === 0) {
    console.log('❌ Keine gültigen Suchbegriffe');
    return [];
  }
  
  const totalDocs = index.documentCount;
  const avgDocLen = index.documents.reduce((sum, d) => sum + (d.tokenCount || 0), 0) / totalDocs;
  
  // Score alle Dokumente
  const results = index.documents
    .filter(doc => !source || doc.source === source)
    .map(doc => {
      const bm25 = bm25Score(queryTokens, tokenize(doc.text), index.termDocFreq, totalDocs, avgDocLen);
      const semantic = cosineSimilarity(queryTokens, doc.vector);
      
      // Kombinierter Score: BM25 + 0.5 * Semantic, gewichtet nach Source-Priorität
      const combinedScore = (bm25 + 0.5 * semantic) * (doc.sourcePriority || 1.0);
      
      return {
        ...doc,
        scores: {
          bm25: bm25.toFixed(4),
          semantic: semantic.toFixed(4),
          combined: combinedScore.toFixed(4)
        }
      };
    })
    .filter(r => parseFloat(r.scores.combined) > 0)
    .sort((a, b) => parseFloat(b.scores.combined) - parseFloat(a.scores.combined))
    .slice(0, limit);
  
  // Ausgabe
  console.log(`📊 Gefunden: ${results.length} relevante Dokumente\n`);
  
  results.forEach((doc, i) => {
    const relativePath = doc.path.replace(/.*workspace[\\/]/, '');
    console.log(`${i + 1}. ${doc.title}`);
    console.log(`   📁 ${relativePath}`);
    console.log(`   🏷️  ${doc.source} | Scores: BM25=${doc.scores.bm25} SEM=${doc.scores.semantic} TOTAL=${doc.scores.combined}`);
    
    // Preview (erste 200 Zeichen)
    const preview = doc.text.substring(0, 200).replace(/\n/g, ' ');
    console.log(`   📝 ${preview}...\n`);
  });
  
  return results;
}

// CLI Argumente parsen
const args = process.argv.slice(2);
if (args.length === 0) {
  console.log(`
🔍 Semantic Search Engine

Verwendung:
  node search.js "Suchbegriff" [Optionen]

Optionen:
  --limit=N        Maximale Anzahl Ergebnisse (default: 10)
  --source=NAME    Nur bestimmte Quelle durchsuchen
                   (obsidian-vault, memory, vault-archive)

Beispiele:
  node search.js "Docker container"
  node search.js "autoresearch" --limit=5
  node search.js "ECC" --source=memory
  `);
  process.exit(0);
}

const query = args[0];
const options = {
  limit: 10,
  source: null
};

for (let i = 1; i < args.length; i++) {
  const arg = args[i];
  if (arg.startsWith('--limit=')) {
    options.limit = parseInt(arg.split('=')[1]) || 10;
  } else if (arg.startsWith('--source=')) {
    options.source = arg.split('=')[1];
  }
}

// Suche ausführen
search(query, options);
