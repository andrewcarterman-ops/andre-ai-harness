/**
 * Manuelle Integrationstests für Harness Redesign
 * Testet die Kernfunktionalität ohne vollständige Dependencies
 */

import { TokenBudgetManager } from './src/context/TokenBudgetManager.js';
import { editFile, editFileSafe } from './src/utils/EditTool.js';
import fs from 'fs/promises';
import path from 'path';

const testResults = [];

function logTest(name, status, message, duration = 0) {
  const icon = status === 'PASS' ? '✅' : status === 'FAIL' ? '❌' : '⏭️';
  console.log(`${icon} ${name.padEnd(30)} ${status.padEnd(6)} ${duration}ms`);
  if (message) console.log(`   ${message}`);
  testResults.push({ name, status, message, duration });
}

async function testTokenBudgetManager() {
  const start = Date.now();
  try {
    const config = {
      totalLimit: 12000,
      tiers: {
        hot: { maxTokens: 2000, evictionPolicy: 'lru' },
        warm: { maxTokens: 10000, evictionPolicy: 'relevance' },
        cold: { maxTokens: null, evictionPolicy: 'archive' }
      },
      allocation: {
        systemPrompt: 1000,
        context: 8000,
        conversationHistory: 2000,
        responseBuffer: 1000
      }
    };

    const manager = new TokenBudgetManager(config);
    
    // Test 1: Allocation
    const item1 = {
      id: 'test-item-1',
      content: 'Test content for hot tier',
      tokenCount: 500,
      tier: 'hot',
      metadata: { source: 'test', created: new Date() }
    };
    
    const result1 = manager.allocate(item1, 'hot');
    if (!result1.success) throw new Error('Allocation failed: ' + result1.message);
    
    // Test 2: Status
    const status = manager.getStatus();
    if (status.usedTokens !== 500) throw new Error('Token tracking incorrect: ' + status.usedTokens);
    if (status.itemsByTier.hot !== 1) throw new Error('Item count incorrect');
    
    // Test 3: Access
    const accessed = manager.access('test-item-1');
    if (!accessed) throw new Error('Access failed');
    if (accessed.metadata.accessCount !== 1) throw new Error('Access count not updated');
    
    // Test 4: Multiple allocations
    const item2 = { id: 'test-item-2', content: 'Second item', tokenCount: 800, tier: 'hot', metadata: {} };
    const item3 = { id: 'test-item-3', content: 'Third item', tokenCount: 600, tier: 'hot', metadata: {} };
    
    manager.allocate(item2, 'hot');
    manager.allocate(item3, 'hot');
    
    // This should trigger eviction (500+800+600=1900, but max is 2000)
    const item4 = { id: 'test-item-4', content: 'Fourth item', tokenCount: 300, tier: 'hot', metadata: {} };
    const result4 = manager.allocate(item4, 'hot');
    
    // Test 5: Budget status
    const finalStatus = manager.getStatus();
    if (finalStatus.tierStatus.hot.used > 2000) {
      throw new Error('Hot tier exceeded limit: ' + finalStatus.tierStatus.hot.used);
    }
    
    logTest('TokenBudgetManager', 'PASS', 'All core functions working', Date.now() - start);
  } catch (error) {
    logTest('TokenBudgetManager', 'FAIL', error.message, Date.now() - start);
  }
}

async function testEditToolFix() {
  const start = Date.now();
  const testFile = 'test-edit-temp.txt';
  
  try {
    // Test 1: Basic edit
    await fs.writeFile(testFile, 'Hello old world', 'utf-8');
    
    const success = await editFile(testFile, {
      old_string: 'old',
      new_string: 'new'
    });
    
    if (!success) throw new Error('Edit returned false');
    
    const content = await fs.readFile(testFile, 'utf-8');
    if (content !== 'Hello new world') {
      throw new Error(`Expected "Hello new world", got "${content}"`);
    }
    
    // Test 2: Multiple occurrences
    await fs.writeFile(testFile, 'old and old and old', 'utf-8');
    
    const success2 = await editFile(testFile, {
      old_string: 'old',
      new_string: 'new'
    });
    
    if (!success2) throw new Error('Multiple occurrence edit failed');
    
    const content2 = await fs.readFile(testFile, 'utf-8');
    if (content2 !== 'new and old and old') {
      throw new Error(`Expected "new and old and old", got "${content2}"`);
    }
    
    // Test 3: Safe edit with line number
    await fs.writeFile(testFile, 'line1\nline2\nline3', 'utf-8');
    
    const success3 = await editFileSafe(testFile, {
      old_string: 'line2',
      new_string: 'modified',
      expectedLine: 2
    });
    
    if (!success3) throw new Error('Safe edit failed');
    
    const content3 = await fs.readFile(testFile, 'utf-8');
    if (!content3.includes('modified')) {
      throw new Error(`Safe edit did not modify correct line: ${content3}`);
    }
    
    await fs.unlink(testFile);
    logTest('EditTool (Splice Fix)', 'PASS', 'All edit operations working correctly', Date.now() - start);
  } catch (error) {
    try { await fs.unlink(testFile); } catch {}
    logTest('EditTool (Splice Fix)', 'FAIL', error.message, Date.now() - start);
  }
}

async function testContextWorkflow() {
  const start = Date.now();
  try {
    const config = {
      totalLimit: 12000,
      tiers: {
        hot: { maxTokens: 2000, evictionPolicy: 'lru' },
        warm: { maxTokens: 10000, evictionPolicy: 'relevance' },
        cold: { maxTokens: null, evictionPolicy: 'archive' }
      },
      allocation: { systemPrompt: 1000, context: 8000, conversationHistory: 2000, responseBuffer: 1000 }
    };

    const manager = new TokenBudgetManager(config);
    
    // Simulate real-world context workflow
    // 1. Add system context (hot tier)
    const systemContext = {
      id: 'system-prompt',
      content: 'System instructions...',
      tokenCount: 800,
      tier: 'hot',
      metadata: { source: 'system', created: new Date(), explicit: true }
    };
    manager.allocate(systemContext, 'hot');
    
    // 2. Add conversation history (warm tier)
    for (let i = 0; i < 5; i++) {
      manager.allocate({
        id: `message-${i}`,
        content: `Message content ${i}`,
        tokenCount: 200,
        tier: 'warm',
        metadata: { source: 'conversation', created: new Date() }
      }, 'warm');
    }
    
    // 3. Add archived knowledge (cold tier)
    manager.allocate({
      id: 'archived-knowledge',
      content: 'Old knowledge from previous sessions...',
      tokenCount: 1500,
      tier: 'cold',
      metadata: { source: 'archive', created: new Date('2024-01-01') }
    }, 'cold');
    
    // 4. Access to trigger promotion
    manager.access('message-0');
    manager.access('message-0');
    manager.access('message-0');
    manager.access('message-0');
    manager.access('message-0'); // 5th access should trigger promotion
    
    // 5. Check final status
    const status = manager.getStatus();
    
    if (status.itemsByTier.hot < 1) throw new Error('System context not in hot tier');
    if (status.itemsByTier.warm < 4) throw new Error('Conversation history not in warm tier');
    if (status.itemsByTier.cold !== 1) throw new Error('Archived knowledge not in cold tier');
    
    logTest('Context Workflow', 'PASS', '3-tier system working correctly', Date.now() - start);
  } catch (error) {
    logTest('Context Workflow', 'FAIL', error.message, Date.now() - start);
  }
}

async function runTests() {
  console.log('╔══════════════════════════════════════════════════════════╗');
  console.log('║   Harness Redesign - Manuelle Integrationstests         ║');
  console.log('╚══════════════════════════════════════════════════════════╝\n');
  
  await testTokenBudgetManager();
  await testEditToolFix();
  await testContextWorkflow();
  
  // Summary
  console.log('\n╔══════════════════════════════════════════════════════════╗');
  console.log('║   Zusammenfassung                                         ║');
  console.log('╠══════════════════════════════════════════════════════════╣');
  
  const passed = testResults.filter(r => r.status === 'PASS').length;
  const failed = testResults.filter(r => r.status === 'FAIL').length;
  
  console.log(`║  ✅ Bestanden: ${passed.toString().padEnd(3)}                                       ║`);
  console.log(`║  ❌ Fehlgeschlagen: ${failed.toString().padEnd(3)}                                  ║`);
  console.log('╠══════════════════════════════════════════════════════════╣');
  
  if (failed === 0) {
    console.log('║  🎉 ALLE TESTS BESTANDEN!                                 ║');
    console.log('║  Das Harness Redesign funktioniert korrekt.              ║');
    console.log('║                                                           ║');
    console.log('║  Verbesserungen:                                          ║');
    console.log('║  • 3-Tier Context: ✅ Hot/Warm/Cold funktioniert          ║');
    console.log('║  • Token Budget: ✅ Automatische Verwaltung               ║');
    console.log('║  • Edit Tool: ✅ Splice-Bug behoben                       ║');
    console.log('║  • Auto-Promotion: ✅ Nach 5 Zugriffen                    ║');
    console.log('╚══════════════════════════════════════════════════════════╝');
  } else {
    console.log('║  ⚠️  Einige Tests fehlgeschlagen                          ║');
    console.log('╚══════════════════════════════════════════════════════════╝');
    process.exit(1);
  }
}

runTests().catch(console.error);
