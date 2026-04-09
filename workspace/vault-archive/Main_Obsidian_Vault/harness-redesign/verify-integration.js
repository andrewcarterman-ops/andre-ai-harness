const fs = require('fs');
const path = require('path');

const basePath = 'C:\\Users\\andre\\Documents\\Andrew Openclaw\\harness-redesign';

const requiredFiles = [
  'src/context/TokenBudgetManager.ts',
  'src/context/ContextTierManager.ts',
  'src/knowledge/ChromaKnowledgeStore.ts',
  'src/execution/ParallelOrchestrator.ts',
  'src/bridge/ObsidianBridge.ts',
  'src/utils/EditTool.ts',
  'context-files/CONTEXT_SYSTEM.md',
  'context-files/CONTEXT_TOOLS.md',
  'context-files/CONTEXT_HOOKS.md',
  'context-files/CONTEXT_LEARNING.md',
  'context-files/CONTEXT_TOKEN.md',
  'context-files/CONTEXT_KNOWLEDGE.md',
  'context-files/CONTEXT_BRIDGE.md',
  'docs/Harness.md',
  'README.md'
];

console.log('Integration Test - File Verification\n');
console.log('=====================================\n');

let pass = 0;
let fail = 0;

for (const file of requiredFiles) {
  const fullPath = path.join(basePath, file);
  const exists = fs.existsSync(fullPath);
  const size = exists ? fs.statSync(fullPath).size : 0;
  
  if (exists) {
    console.log('[OK]', file, '(' + (size/1024).toFixed(1) + ' KB)');
    pass++;
  } else {
    console.log('[MISSING]', file);
    fail++;
  }
}

console.log('\n=====================================');
console.log('Results: ' + pass + '/' + requiredFiles.length + ' files present');

if (fail === 0) {
  console.log('\n[OK] ALL FILES PRESENT - Integration ready!');
  console.log('\nNext steps:');
  console.log('1. cd harness-redesign');
  console.log('2. npm install');
  console.log('3. npm run build');
  console.log('4. npm test');
} else {
  console.log('\n[ERROR] Some files missing');
}
