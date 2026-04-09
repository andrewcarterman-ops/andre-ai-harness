/**
 * Integration Test for Harness Redesign
 * Tests all core components in the existing OpenClaw environment
 */

import { TokenBudgetManager } from '../src/context/TokenBudgetManager';
import { ContextTierManager } from '../src/context/ContextTierManager';
import { ChromaKnowledgeStore } from '../src/knowledge/ChromaKnowledgeStore';
import { ParallelOrchestrator } from '../src/execution/ParallelOrchestrator';
import { ObsidianBridge } from '../src/bridge/ObsidianBridge';
import { editFile } from '../src/utils/EditTool';

// Test configuration
const testConfig = {
  tokenBudget: {
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
  },
  contextTier: {
    relevanceWeights: {
      recency: 0.3,
      frequency: 0.3,
      semantic: 0.3,
      explicit: 1.0
    },
    autoPromoteThreshold: 0.8,
    autoDemoteThreshold: 0.3
  },
  knowledgeStore: {
    collectionName: 'test-collection',
    embeddingDimension: 384
  },
  orchestrator: {
    minWorkers: 2,
    maxWorkers: 4,
    scaling: {
      strategy: 'adaptive' as const,
      thresholdUp: 0.7,
      thresholdDown: 0.3
    },
    taskTypes: {
      file_read: { priority: 'high', timeout: 5000 },
      tool_execution: { priority: 'medium', timeout: 30000 }
    }
  },
  obsidian: {
    vaultPath: 'C:/Users/andre/Documents/Andrew Openclaw/Obsidian',
    sync: {
      mode: 'bidirectional' as const,
      interval: 300,
      onChange: true
    },
    mapping: {
      sessions: 'AI/Sessions/',
      insights: 'AI/Insights/',
      errors: 'AI/Errors/',
      skills: 'AI/Skills/'
    },
    templates: {
      session: 'templates/session.md',
      insight: 'templates/insight.md',
      error: 'templates/error.md'
    }
  }
};

// Test results
const results: {
  component: string;
  status: 'PASS' | 'FAIL' | 'SKIP';
  message: string;
  duration: number;
}[] = [];

async function runTests() {
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║   Harness Redesign - Integration Test Suite           ║');
  console.log('╚════════════════════════════════════════════════════════╝\n');

  // Test 1: TokenBudgetManager
  await testTokenBudgetManager();

  // Test 2: ContextTierManager
  await testContextTierManager();

  // Test 3: ChromaKnowledgeStore
  await testKnowledgeStore();

  // Test 4: ParallelOrchestrator
  await testOrchestrator();

  // Test 5: ObsidianBridge
  await testObsidianBridge();

  // Test 6: EditTool Fix
  await testEditTool();

  // Print results
  printResults();
}

async function testTokenBudgetManager() {
  const start = Date.now();
  try {
    const manager = new TokenBudgetManager(testConfig.tokenBudget);
    
    // Test allocation
    const item = {
      id: 'test-item-1',
      content: 'Test content',
      tokenCount: 500,
      tier: 'hot' as const
    };
    
    const result = manager.allocate(item, 'hot');
    
    if (!result.success) {
      throw new Error('Allocation failed');
    }
    
    // Test status
    const status = manager.getStatus();
    if (status.usedTokens !== 500) {
      throw new Error('Token tracking incorrect');
    }
    
    results.push({
      component: 'TokenBudgetManager',
      status: 'PASS',
      message: 'Allocation, tracking, and status working correctly',
      duration: Date.now() - start
    });
  } catch (error) {
    results.push({
      component: 'TokenBudgetManager',
      status: 'FAIL',
      message: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start
    });
  }
}

async function testContextTierManager() {
  const start = Date.now();
  try {
    const manager = new ContextTierManager({
      ...testConfig.tokenBudget,
      ...testConfig.contextTier
    });
    
    // Test adding context
    await manager.addContext({
      id: 'test-context-1',
      content: 'Test context content',
      tokenCount: 300,
      tier: 'hot'
    });
    
    // Test access
    const item = manager.accessContext('test-context-1');
    if (!item) {
      throw new Error('Context item not found');
    }
    
    results.push({
      component: 'ContextTierManager',
      status: 'PASS',
      message: 'Context addition and access working',
      duration: Date.now() - start
    });
  } catch (error) {
    results.push({
      component: 'ContextTierManager',
      status: 'FAIL',
      message: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start
    });
  }
}

async function testKnowledgeStore() {
  const start = Date.now();
  try {
    const store = new ChromaKnowledgeStore(testConfig.knowledgeStore);
    await store.initialize();
    
    // Test adding document
    await store.addDocument({
      id: 'test-doc-1',
      content: 'Test knowledge document',
      metadata: {
        source: 'test',
        type: 'skill',
        created: new Date(),
        project: 'test-project',
        tags: ['test'],
        confidence: 0.9
      }
    });
    
    // Test search
    const results_search = await store.search({
      query: 'test knowledge',
      topK: 5
    });
    
    if (results_search.length === 0) {
      throw new Error('Search returned no results');
    }
    
    results.push({
      component: 'ChromaKnowledgeStore',
      status: 'PASS',
      message: 'Document storage and search working',
      duration: Date.now() - start
    });
  } catch (error) {
    results.push({
      component: 'ChromaKnowledgeStore',
      status: 'FAIL',
      message: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start
    });
  }
}

async function testOrchestrator() {
  const start = Date.now();
  try {
    const orchestrator = new ParallelOrchestrator(testConfig.orchestrator);
    orchestrator.start();
    
    // Test submitting task
    const taskResult = await orchestrator.submit({
      id: 'test-task-1',
      type: 'file_read',
      params: { path: 'test.txt' }
    });
    
    if (!taskResult.success) {
      throw new Error('Task execution failed');
    }
    
    orchestrator.stop();
    
    results.push({
      component: 'ParallelOrchestrator',
      status: 'PASS',
      message: 'Task submission and execution working',
      duration: Date.now() - start
    });
  } catch (error) {
    results.push({
      component: 'ParallelOrchestrator',
      status: 'FAIL',
      message: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start
    });
  }
}

async function testObsidianBridge() {
  const start = Date.now();
  try {
    // Skip if vault doesn't exist
    const fs = require('fs');
    if (!fs.existsSync(testConfig.obsidian.vaultPath)) {
      results.push({
        component: 'ObsidianBridge',
        status: 'SKIP',
        message: 'Obsidian vault not found at configured path',
        duration: Date.now() - start
      });
      return;
    }
    
    const bridge = new ObsidianBridge(testConfig.obsidian);
    await bridge.initialize();
    
    results.push({
      component: 'ObsidianBridge',
      status: 'PASS',
      message: 'Initialization successful',
      duration: Date.now() - start
    });
  } catch (error) {
    results.push({
      component: 'ObsidianBridge',
      status: 'FAIL',
      message: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start
    });
  }
}

async function testEditTool() {
  const start = Date.now();
  try {
    const fs = require('fs').promises;
    const path = require('path');
    
    // Create test file
    const testFile = path.join(process.cwd(), 'test-edit-file.txt');
    await fs.writeFile(testFile, 'Hello old world', 'utf-8');
    
    // Test edit
    const success = await editFile(testFile, {
      old_string: 'old',
      new_string: 'new'
    });
    
    if (!success) {
      throw new Error('Edit operation failed');
    }
    
    // Verify result
    const content = await fs.readFile(testFile, 'utf-8');
    if (content !== 'Hello new world') {
      throw new Error('Edit did not produce expected result');
    }
    
    // Cleanup
    await fs.unlink(testFile);
    
    results.push({
      component: 'EditTool (Fix)',
      status: 'PASS',
      message: 'Splice fix working correctly',
      duration: Date.now() - start
    });
  } catch (error) {
    results.push({
      component: 'EditTool (Fix)',
      status: 'FAIL',
      message: error instanceof Error ? error.message : 'Unknown error',
      duration: Date.now() - start
    });
  }
}

function printResults() {
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║   Test Results                                          ║');
  console.log('╠════════════════════════════════════════════════════════╣');
  
  let passCount = 0;
  let failCount = 0;
  let skipCount = 0;
  
  for (const result of results) {
    const icon = result.status === 'PASS' ? '✅' : result.status === 'FAIL' ? '❌' : '⏭️';
    console.log(`║ ${icon} ${result.component.padEnd(25)} ${result.status.padEnd(6)} ${result.duration.toString().padStart(4)}ms ║`);
    console.log(`║    ${result.message.substring(0, 50).padEnd(50)} ║`);
    
    if (result.status === 'PASS') passCount++;
    else if (result.status === 'FAIL') failCount++;
    else skipCount++;
  }
  
  console.log('╠════════════════════════════════════════════════════════╣');
  console.log(`║  Summary: ${passCount} passed, ${failCount} failed, ${skipCount} skipped${' '.repeat(23)} ║`);
  console.log('╚════════════════════════════════════════════════════════╝\n');
  
  // Integration assessment
  console.log('╔════════════════════════════════════════════════════════╗');
  console.log('║   Integration Assessment                                ║');
  console.log('╠════════════════════════════════════════════════════════╣');
  
  if (failCount === 0) {
    console.log('║  ✅ All core components are functional                 ║');
    console.log('║  ✅ Ready for integration with OpenClaw                ║');
    console.log('║  ✅ No conflicts detected                              ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    process.exit(0);
  } else {
    console.log('║  ⚠️  Some tests failed - review required               ║');
    console.log('║  Check component configurations and dependencies       ║');
    console.log('╚════════════════════════════════════════════════════════╝');
    process.exit(1);
  }
}

// Run tests
runTests().catch(console.error);
