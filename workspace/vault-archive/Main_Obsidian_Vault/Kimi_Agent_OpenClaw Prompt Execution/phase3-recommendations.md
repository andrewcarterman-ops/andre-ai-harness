# Phase 3: Implementation Programmer Recommendations

**Agent**: P1 (Implementation Programmer)  
**Date**: 2026-04-03  
**Purpose**: Concrete code refactoring plans based on Phases 1 & 2 findings

---

## Executive Summary

Based on analysis from all domain agents and integration critic, this document provides **actionable refactoring plans** with **risk classifications** and **specific implementation guidance**.

### Key Issues to Address

| Priority | Issue | Risk Level | Effort |
|----------|-------|------------|--------|
| P0 | Tool parameter mismatch (`new_string` vs `newText`) | **CRITICAL** | Small |
| P1 | Hook system - implement or document | **HIGH** | Medium |
| P1 | YAML registry loading verification | **HIGH** | Small |
| P2 | Rust/Node.js integration definition | **MEDIUM** | Large |
| P2 | Memory system feedback loop | **MEDIUM** | Medium |

---

## Safe Changes (Low Risk)

### 1. Fix Tool Parameter Naming Bug
**Effort**: Small (1-2 hours)  
**Risk**: Very Low - Pure naming fix  
**Impact**: Critical bug fix

#### Problem
- Documentation says `new_string` parameter for edit tool
- Error message says `Missing required parameter: newText`
- This causes tool calls to fail

#### Root Cause Analysis
Based on findings, the most likely causes are:
1. **Snake_case to camelCase transformation** at Rust/TypeScript boundary
2. **Multiple schema versions** (legacy vs new)
3. **Documentation drift** from actual implementation

#### Implementation Plan

**Step 1: Audit Tool Parameters**
```bash
# Search for all parameter definitions
grep -r "new_string" --include="*.ts" --include="*.js" --include="*.yaml" --include="*.md"
grep -r "newText" --include="*.ts" --include="*.js" --include="*.yaml" --include="*.md"
```

**Step 2: Choose Canonical Naming Convention**

| Option | Pros | Cons |
|--------|------|------|
| A: Use `new_string` everywhere | Matches docs, Rust convention | Breaking change if TS uses `newText` |
| B: Use `newText` everywhere | Matches error, TS convention | Docs need update |
| C: Support both (alias) | Backward compatible | More complex |

**Recommended**: Option C with deprecation path

**Step 3: Implementation**

```typescript
// File: src/tools/edit-file.ts (or equivalent)
interface EditFileParams {
  file_path: string;
  old_string: string;
  // Support both parameter names during transition
  new_string?: string;
  newText?: string;  // Deprecated, for backward compatibility
}

function validateEditParams(params: EditFileParams): void {
  // Normalize parameter name
  const newContent = params.new_string ?? params.newText;
  
  if (!newContent) {
    throw new Error('Missing required parameter: new_string (or deprecated newText)');
  }
  
  // Warn if using deprecated parameter
  if (params.newText && !params.new_string) {
    console.warn('Deprecation warning: newText is deprecated, use new_string');
  }
  
  // Continue with normalized value
  return { ...params, new_string: newContent };
}
```

**Files Affected**:
- Tool invocation code (location TBD - likely in Gateway)
- Tool schema definitions
- Documentation (TOOLS.md, SKILL.md files)

---

### 2. Add safe-file-ops to skills.yaml
**Effort**: Small (15 minutes)  
**Risk**: Very Low - Registry addition only  
**Impact**: Fixes skill count mismatch

#### Implementation

```yaml
# File: registry/skills.yaml
skills:
  # ... existing skills ...
  
  - id: safe-file-ops
    category: tooling
    function: "Sichere Dateioperationen mit Backup"
    trigger: ["safe file", "backup edit", "safe operations"]
    workflow_chain: "standalone"
```

**Files Affected**:
- `registry/skills.yaml`

---

### 3. Document Hook Execution Model
**Effort**: Small (30 minutes)  
**Risk**: Very Low - Documentation only  
**Impact**: Clarifies system behavior

#### Problem
Hooks are documented as "Aktiv" but no execution mechanism exists.

#### Implementation Plan

Add clarifying documentation to `AGENTS.md` or create `HOOKS.md`:

```markdown
# Hook System Documentation

## Execution Model

Hooks in this system are **MANUAL PROTOCOLS**, not automatic triggers.

### Current Behavior
- `hooks/session-start.md` - Protocol to follow when starting a session
- `hooks/session-end.md` - Protocol to follow when ending a session  
- `hooks/review-post-execution.md` - Protocol for post-execution review

### How to Use
1. At session start, read and follow `hooks/session-start.md`
2. At session end, read and follow `hooks/session-end.md`
3. After critical operations, read and follow `hooks/review-post-execution.md`

### Future Enhancement
Automatic hook execution may be implemented via:
- Node.js event emitters
- File watchers
- Gateway lifecycle callbacks
```

**Files Affected**:
- New file: `HOOKS.md` OR
- Update: `AGENTS.md`

---

### 4. Add YAML Schema Validation
**Effort**: Small-Medium (2-3 hours)  
**Risk**: Low - Adds validation, doesn't change behavior  
**Impact**: Catches config errors early

#### Implementation

```typescript
// File: src/config/registry-validator.ts
import { z } from 'zod';  // or similar validation library

const SkillSchema = z.object({
  id: z.string(),
  category: z.enum(['planning', 'development', 'quality', 'language', 'architecture', 
                    'communication', 'security', 'external-api', 'learning', 'tooling']),
  function: z.string(),
  trigger: z.array(z.string()),
  workflow_chain: z.string().optional()
});

const AgentSchema = z.object({
  id: z.string(),
  emoji: z.string(),
  purpose: z.string(),
  triggers: z.array(z.string())
});

const HookSchema = z.object({
  event: z.enum(['session:start', 'session:end', 'review:post_execution']),
  handler: z.string(),
  enabled: z.boolean().default(true)
});

export function validateRegistry(files: RegistryFiles): ValidationResult {
  const result = {
    valid: true,
    errors: [] as string[]
  };
  
  // Validate skills
  for (const skill of files.skills) {
    const parse = SkillSchema.safeParse(skill);
    if (!parse.success) {
      result.valid = false;
      result.errors.push(`Skill ${skill.id}: ${parse.error.message}`);
    }
  }
  
  // Validate agents
  for (const agent of files.agents) {
    const parse = AgentSchema.safeParse(agent);
    if (!parse.success) {
      result.valid = false;
      result.errors.push(`Agent ${agent.id}: ${parse.error.message}`);
    }
  }
  
  return result;
}
```

**Files Affected**:
- New file: `src/config/registry-validator.ts`
- Update: Startup code to call validator

---

### 5. Implement memory_search Tool Stub
**Effort**: Small (1 hour)  
**Risk**: Low - New functionality, no breaking changes  
**Impact**: Makes mandatory feature available

#### Implementation

```typescript
// File: src/tools/memory-search.ts
import { glob } from 'glob';
import { readFile } from 'fs/promises';

interface MemorySearchParams {
  query: string;
  paths?: string[];  // Default: ['MEMORY.md', 'memory/*.md']
  limit?: number;    // Default: 10
}

interface MemorySearchResult {
  file: string;
  line: number;
  content: string;
  relevance: number;  // Simple scoring
}

export async function memorySearch(params: MemorySearchParams): Promise<MemorySearchResult[]> {
  const { query, paths = ['MEMORY.md', 'memory/*.md'], limit = 10 } = params;
  
  // Expand glob patterns
  const files: string[] = [];
  for (const pattern of paths) {
    const matches = await glob(pattern);
    files.push(...matches);
  }
  
  // Search each file
  const results: MemorySearchResult[] = [];
  const queryLower = query.toLowerCase();
  
  for (const file of files) {
    try {
      const content = await readFile(file, 'utf-8');
      const lines = content.split('\n');
      
      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.toLowerCase().includes(queryLower)) {
          results.push({
            file,
            line: i + 1,
            content: line.trim(),
            relevance: calculateRelevance(line, query)
          });
        }
      }
    } catch (err) {
      console.warn(`Failed to read ${file}: ${err}`);
    }
  }
  
  // Sort by relevance and limit
  return results
    .sort((a, b) => b.relevance - a.relevance)
    .slice(0, limit);
}

function calculateRelevance(line: string, query: string): number {
  const lineLower = line.toLowerCase();
  const queryLower = query.toLowerCase();
  
  // Exact match gets highest score
  if (lineLower === queryLower) return 100;
  
  // Contains full query
  if (lineLower.includes(queryLower)) return 50;
  
  // Contains query words
  const queryWords = queryLower.split(/\s+/);
  const matches = queryWords.filter(w => lineLower.includes(w)).length;
  return (matches / queryWords.length) * 25;
}
```

**Files Affected**:
- New file: `src/tools/memory-search.ts`
- Update: Tool registry to include new tool

---

## Medium Risk Changes

### 6. Implement Self-Improving Feedback Loop
**Effort**: Medium (4-6 hours)  
**Risk**: Medium - Changes core behavior  
**Impact**: Makes learning from corrections operational

#### Problem
- `self-improving-andrew` skill claims to learn from corrections
- Trigger is "implicit on corrections" (which means it doesn't happen)
- No mechanism defined for detection, storage, or recall

#### Implementation Plan

**Step 1: Define Correction Detection**

```typescript
// File: src/learning/correction-detector.ts
interface Correction {
  timestamp: Date;
  originalResponse: string;
  correction: string;
  context: string;  // What was being discussed
  category: 'factual' | 'preference' | 'procedure' | 'other';
}

export function detectCorrection(userMessage: string): Correction | null {
  // Pattern-based detection
  const correctionPatterns = [
    /^(?:no|actually|wait|wrong|incorrect|that's not right)/i,
    /^(?:i meant|i said|what i meant was)/i,
    /^(?:don't|do not|never|always) do it that way/i,
    /^(?:the correct|correct|right) way is/i
  ];
  
  for (const pattern of correctionPatterns) {
    if (pattern.test(userMessage)) {
      return {
        timestamp: new Date(),
        originalResponse: '',  // Populated from session history
        correction: userMessage,
        context: '',  // Populated from session context
        category: categorizeCorrection(userMessage)
      };
    }
  }
  
  return null;
}
```

**Step 2: Implement Storage**

```typescript
// File: src/learning/correction-store.ts
import { writeFile, mkdir } from 'fs/promises';
import { existsSync } from 'fs';

const CORRECTIONS_DIR = 'memory/self-improving';

export async function storeCorrection(correction: Correction): Promise<void> {
  if (!existsSync(CORRECTIONS_DIR)) {
    await mkdir(CORRECTIONS_DIR, { recursive: true });
  }
  
  const date = correction.timestamp.toISOString().split('T')[0];
  const filename = `${CORRECTIONS_DIR}/${date}.json`;
  
  // Append to daily corrections file
  let corrections: Correction[] = [];
  try {
    const existing = await readFile(filename, 'utf-8');
    corrections = JSON.parse(existing);
  } catch {
    // File doesn't exist yet
  }
  
  corrections.push(correction);
  await writeFile(filename, JSON.stringify(corrections, null, 2));
  
  // Also update MEMORY.md with significant corrections
  if (isSignificantCorrection(correction)) {
    await updateMemoryMd(correction);
  }
}
```

**Step 3: Integrate with Session Flow**

```typescript
// In session message handler
async function handleUserMessage(message: string, session: Session): Promise<void> {
  // Check if message is a correction
  const correction = detectCorrection(message);
  if (correction) {
    correction.originalResponse = session.getLastAssistantMessage();
    correction.context = session.getCurrentContext();
    await storeCorrection(correction);
  }
  
  // Continue with normal processing
  // ...
}
```

**Files Affected**:
- New files: `src/learning/correction-detector.ts`, `src/learning/correction-store.ts`
- Update: Session message handler

---

### 7. Add Resource Limits for Sub-Agents
**Effort**: Medium (3-4 hours)  
**Risk**: Medium - May affect agent spawning behavior  
**Impact**: Prevents resource exhaustion

#### Implementation

```typescript
// File: src/agents/agent-pool.ts
interface AgentPoolConfig {
  maxConcurrentAgents: number;
  queueTimeoutMs: number;
  defaultAgentTimeoutMs: number;
}

interface QueuedAgent {
  id: string;
  agentType: string;
  resolve: (result: AgentResult) => void;
  reject: (error: Error) => void;
  queuedAt: Date;
}

class AgentPool {
  private running = new Map<string, AgentProcess>();
  private queue: QueuedAgent[] = [];
  private config: AgentPoolConfig;
  
  constructor(config: AgentPoolConfig = {
    maxConcurrentAgents: 3,
    queueTimeoutMs: 30000,
    defaultAgentTimeoutMs: 300000
  }) {
    this.config = config;
  }
  
  async spawn(agentType: string, params: AgentParams): Promise<AgentResult> {
    // Check if we can run immediately
    if (this.running.size < this.config.maxConcurrentAgents) {
      return this.runAgent(agentType, params);
    }
    
    // Queue the request
    return new Promise((resolve, reject) => {
      const queued: QueuedAgent = {
        id: generateId(),
        agentType,
        resolve,
        reject,
        queuedAt: new Date()
      };
      
      this.queue.push(queued);
      
      // Set timeout
      setTimeout(() => {
        const index = this.queue.findIndex(q => q.id === queued.id);
        if (index >= 0) {
          this.queue.splice(index, 1);
          reject(new Error(`Agent spawn timed out after ${this.config.queueTimeoutMs}ms`));
        }
      }, this.config.queueTimeoutMs);
    });
  }
  
  private async runAgent(agentType: string, params: AgentParams): Promise<AgentResult> {
    const id = generateId();
    
    // Track resource usage
    const startMemory = process.memoryUsage();
    const startTime = Date.now();
    
    try {
      const agent = await this.createAgentProcess(agentType, params);
      this.running.set(id, agent);
      
      const result = await agent.runWithTimeout(this.config.defaultAgentTimeoutMs);
      
      // Log resource usage
      const endMemory = process.memoryUsage();
      console.log(`Agent ${agentType} completed:`, {
        duration: Date.now() - startTime,
        memoryDelta: endMemory.heapUsed - startMemory.heapUsed
      });
      
      return result;
    } finally {
      this.running.delete(id);
      this.processQueue();
    }
  }
  
  private processQueue(): void {
    if (this.queue.length === 0) return;
    if (this.running.size >= this.config.maxConcurrentAgents) return;
    
    const next = this.queue.shift();
    if (next) {
      this.runAgent(next.agentType, {})
        .then(next.resolve)
        .catch(next.reject);
    }
  }
}
```

**Files Affected**:
- New file: `src/agents/agent-pool.ts`
- Update: Agent spawning code to use pool

---

## High Risk Changes

### 8. Define Rust/Node.js Integration Contract
**Effort**: Large (1-2 days)  
**Risk**: High - Core architectural change  
**Impact**: Enables proper Rust/TypeScript integration

#### Problem
- Rust ECC Framework claims 60+ tests passing
- No Rust code in uploaded workspace
- Integration mechanism undocumented (FFI? WASM? HTTP?)

#### Recommended Approach: HTTP/gRPC API

Based on manifest evidence (Gateway on port 18789, network hosts), HTTP/gRPC is most likely.

**Step 1: Define API Contract**

```protobuf
// File: crates/ecc-runtime/proto/ecc.proto (or shared proto file)
syntax = "proto3";

package ecc;

service EccRuntime {
  rpc StartConversation(StartRequest) returns (Conversation);
  rpc SendMessage(MessageRequest) returns (MessageResponse);
  rpc EndConversation(EndRequest) returns (EndResponse);
}

service ToolRegistry {
  rpc ListTools(ListToolsRequest) returns (ListToolsResponse);
  rpc ExecuteTool(ToolRequest) returns (ToolResponse);
}

service MemoryCompaction {
  rpc CompactSession(CompactRequest) returns (CompactResponse);
}

// Message definitions...
```

**Step 2: TypeScript Client**

```typescript
// File: src/ecc/ecc-client.ts
import { credentials } from '@grpc/grpc-js';

interface EccClientConfig {
  host: string;
  port: number;
  useTls: boolean;
}

class EccClient {
  private runtime: EccRuntimeClient;
  private tools: ToolRegistryClient;
  private compaction: MemoryCompactionClient;
  
  constructor(config: EccClientConfig) {
    const address = `${config.host}:${config.port}`;
    const creds = config.useTls 
      ? credentials.createSsl()
      : credentials.createInsecure();
    
    this.runtime = new EccRuntimeClient(address, creds);
    this.tools = new ToolRegistryClient(address, creds);
    this.compaction = new MemoryCompactionClient(address, creds);
  }
  
  async executeTool(toolName: string, params: unknown): Promise<unknown> {
    return new Promise((resolve, reject) => {
      this.tools.ExecuteTool(
        { name: toolName, parameters: JSON.stringify(params) },
        (err, response) => {
          if (err) reject(err);
          else resolve(JSON.parse(response.result));
        }
      );
    });
  }
}
```

**Files Affected**:
- New: Protocol definition file
- New: `src/ecc/ecc-client.ts`
- Update: Tool invocation to use client

---

### 9. Implement Hook Engine (If Hooks Should Be Automatic)
**Effort**: Large (1-2 days)  
**Risk**: High - Changes session lifecycle  
**Impact**: Enables automatic hook execution

#### Decision Required

First, decide: **Should hooks be automatic or manual?**

If **manual**: Document clearly (see Safe Change #3)

If **automatic**, implement:

```typescript
// File: src/hooks/hook-engine.ts
interface Hook {
  event: 'session:start' | 'session:end' | 'review:post_execution';
  handler: string;  // Path to handler file
  enabled: boolean;
  condition?: string;  // Optional condition for execution
}

interface HookContext {
  session: Session;
  trigger: string;
  metadata: Record<string, unknown>;
}

type HookHandler = (context: HookContext) => Promise<void>;

class HookEngine {
  private hooks: Map<string, Hook[]> = new Map();
  private handlers: Map<string, HookHandler> = new Map();
  
  async loadHooksFromYaml(yamlPath: string): Promise<void> {
    const content = await readFile(yamlPath, 'utf-8');
    const config = parseYaml(content);
    
    for (const hook of config.hooks) {
      if (!this.hooks.has(hook.event)) {
        this.hooks.set(hook.event, []);
      }
      this.hooks.get(hook.event)!.push(hook);
    }
  }
  
  registerHandler(event: string, handler: HookHandler): void {
    this.handlers.set(event, handler);
  }
  
  async trigger(event: string, context: HookContext): Promise<HookResult> {
    const hooks = this.hooks.get(event) || [];
    const results: HookResult = { executed: [], failed: [] };
    
    for (const hook of hooks) {
      if (!hook.enabled) continue;
      if (hook.condition && !evaluateCondition(hook.condition, context)) continue;
      
      try {
        const handler = this.handlers.get(hook.handler);
        if (handler) {
          await handler(context);
          results.executed.push(hook.handler);
        } else {
          // Try to load from markdown file
          await this.executeMarkdownHandler(hook.handler, context);
          results.executed.push(hook.handler);
        }
      } catch (err) {
        results.failed.push({ handler: hook.handler, error: err });
        console.error(`Hook ${hook.handler} failed:`, err);
      }
    }
    
    return results;
  }
  
  private async executeMarkdownHandler(path: string, context: HookContext): Promise<void> {
    // Parse markdown file and execute embedded instructions
    const content = await readFile(path, 'utf-8');
    const instructions = parseMarkdownInstructions(content);
    
    for (const instruction of instructions) {
      await this.executeInstruction(instruction, context);
    }
  }
}

// Integration with session lifecycle
class SessionManager {
  private hookEngine: HookEngine;
  
  async startSession(): Promise<Session> {
    const session = new Session();
    
    // Trigger session:start hook
    await this.hookEngine.trigger('session:start', {
      session,
      trigger: 'session_start',
      metadata: { timestamp: new Date() }
    });
    
    return session;
  }
  
  async endSession(session: Session): Promise<void> {
    // Trigger session:end hook BEFORE cleanup
    await this.hookEngine.trigger('session:end', {
      session,
      trigger: 'session_end',
      metadata: { timestamp: new Date() }
    });
    
    // Then clean up
    await session.cleanup();
  }
}
```

**Files Affected**:
- New files: `src/hooks/hook-engine.ts`, `src/hooks/session-lifecycle.ts`
- Update: Session manager to integrate hooks

---

### 10. Implement Event-Driven Sync (Replace 5-Minute Polling)
**Effort**: Medium-Large (1 day)  
**Risk**: Medium-High - Changes sync behavior  
**Impact**: More efficient sync, reduces race conditions

#### Implementation

```typescript
// File: src/sync/event-driven-sync.ts
import { watch } from 'chokidar';
import { debounce } from 'lodash';

interface SyncConfig {
  sourceDir: string;
  targetDir: string;
  debounceMs: number;
  excludePatterns: string[];
}

class EventDrivenSync {
  private watcher: ReturnType<typeof watch>;
  private config: SyncConfig;
  private isSyncing = false;
  
  constructor(config: SyncConfig) {
    this.config = config;
  }
  
  start(): void {
    const debouncedSync = debounce(
      (path: string) => this.syncFile(path),
      this.config.debounceMs
    );
    
    this.watcher = watch(this.config.sourceDir, {
      ignored: this.config.excludePatterns,
      persistent: true,
      ignoreInitial: true
    });
    
    this.watcher
      .on('add', debouncedSync)
      .on('change', debouncedSync)
      .on('unlink', debouncedSync);
    
    console.log(`Watching ${this.config.sourceDir} for changes...`);
  }
  
  private async syncFile(changedPath: string): Promise<void> {
    if (this.isSyncing) {
      console.log('Sync already in progress, queuing...');
      return;
    }
    
    this.isSyncing = true;
    
    try {
      // Calculate target path
      const relativePath = changedPath.replace(this.config.sourceDir, '');
      const targetPath = `${this.config.targetDir}${relativePath}`;
      
      // Check for conflicts (user edits in target)
      const conflict = await this.checkForConflict(targetPath);
      if (conflict) {
        await this.handleConflict(changedPath, targetPath, conflict);
        return;
      }
      
      // Perform sync
      await this.copyFile(changedPath, targetPath);
      console.log(`Synced: ${relativePath}`);
      
    } catch (err) {
      console.error(`Sync failed for ${changedPath}:`, err);
    } finally {
      this.isSyncing = false;
    }
  }
  
  private async checkForConflict(targetPath: string): Promise<ConflictInfo | null> {
    // Check if target file exists and has been modified since last sync
    // Return conflict info if user has made changes
    return null;  // Implement conflict detection
  }
  
  private async handleConflict(
    sourcePath: string, 
    targetPath: string, 
    conflict: ConflictInfo
  ): Promise<void> {
    // Create backup of target
    const backupPath = `${targetPath}.backup.${Date.now()}`;
    await copyFile(targetPath, backupPath);
    
    // Log conflict for manual resolution
    console.warn(`Conflict detected: ${targetPath}`);
    console.warn(`Backup created: ${backupPath}`);
    
    // Optionally: merge files or prompt user
  }
  
  stop(): void {
    this.watcher.close();
  }
}
```

**Files Affected**:
- New file: `src/sync/event-driven-sync.ts`
- Update: Cron job configuration to use new sync

---

## Code Examples: Before/After

### Example 1: Tool Parameter Handling

**Before (Current - Buggy)**
```typescript
// Tool receives params, validates with wrong name
function executeEdit(params: any) {
  if (!params.new_string) {  // Documentation says this
    throw new Error('Missing required parameter: newText');  // Error says this
  }
  // ...
}
```

**After (Fixed)**
```typescript
function executeEdit(params: EditParams) {
  // Normalize parameter name
  const newContent = params.new_string ?? params.newText;
  
  if (!newContent) {
    throw new Error('Missing required parameter: new_string');
  }
  
  // Use normalized value
  return performEdit(params.file_path, params.old_string, newContent);
}
```

---

### Example 2: Hook Execution

**Before (Current - Undefined)**
```typescript
// Hooks are mentioned but never called
class Session {
  start() {
    // No hook trigger
  }
  
  end() {
    // No hook trigger
  }
}
```

**After (With Hook Engine)**
```typescript
class Session {
  constructor(private hookEngine: HookEngine) {}
  
  async start() {
    await this.hookEngine.trigger('session:start', {
      session: this,
      trigger: 'session_start',
      metadata: { timestamp: new Date() }
    });
  }
  
  async end() {
    await this.hookEngine.trigger('session:end', {
      session: this,
      trigger: 'session_end',
      metadata: { timestamp: new Date() }
    });
  }
}
```

---

### Example 3: Agent Spawning

**Before (Current - No Limits)**
```typescript
async function spawnAgent(type: string, params: any) {
  // Spawns without limit
  return createAgentProcess(type, params);
}
```

**After (With Resource Limits)**
```typescript
const agentPool = new AgentPool({
  maxConcurrentAgents: 3,
  queueTimeoutMs: 30000
});

async function spawnAgent(type: string, params: any) {
  // Uses pool with limits and queuing
  return agentPool.spawn(type, params);
}
```

---

## Implementation Priority Matrix

| Change | Effort | Risk | Impact | Priority |
|--------|--------|------|--------|----------|
| 1. Fix tool parameter bug | Small | Very Low | Critical | **P0** |
| 2. Add safe-file-ops to registry | Small | Very Low | Low | P2 |
| 3. Document hook model | Small | Very Low | Medium | P1 |
| 4. Add YAML validation | Small | Low | Medium | P2 |
| 5. Implement memory_search | Small | Low | Medium | P1 |
| 6. Self-improving feedback | Medium | Medium | High | P2 |
| 7. Agent resource limits | Medium | Medium | High | P2 |
| 8. Define Rust/Node contract | Large | High | High | P3 |
| 9. Implement hook engine | Large | High | High | P3 |
| 10. Event-driven sync | Medium-Large | Medium-High | Medium | P3 |

---

## Testing Recommendations

For each change, add tests:

```typescript
// Example test for tool parameter fix
describe('Edit Tool Parameters', () => {
  it('should accept new_string parameter', async () => {
    const result = await executeEdit({
      file_path: 'test.txt',
      old_string: 'old',
      new_string: 'new'
    });
    expect(result.success).toBe(true);
  });
  
  it('should accept newText (deprecated) with warning', async () => {
    const consoleSpy = jest.spyOn(console, 'warn');
    const result = await executeEdit({
      file_path: 'test.txt',
      old_string: 'old',
      newText: 'new'
    });
    expect(result.success).toBe(true);
    expect(consoleSpy).toHaveBeenCalledWith(expect.stringContaining('deprecated'));
  });
  
  it('should reject when neither parameter provided', async () => {
    await expect(executeEdit({
      file_path: 'test.txt',
      old_string: 'old'
    })).rejects.toThrow('Missing required parameter: new_string');
  });
});
```

---

## Summary

### Immediate Actions (This Week)
1. **Fix tool parameter mismatch** - Critical bug affecting all edit operations
2. **Document hook execution model** - Clarify manual vs automatic
3. **Implement memory_search stub** - Make mandatory feature available

### Short-Term Actions (Next 2 Weeks)
4. Add YAML schema validation
5. Add safe-file-ops to skills.yaml
6. Implement self-improving feedback loop
7. Add agent resource limits

### Long-Term Actions (Next Month)
8. Define Rust/Node.js integration contract
9. Decide on and implement hook engine (if automatic)
10. Implement event-driven sync

---

*Recommendations generated by Agent P1 (Implementation Programmer)*
*Based on Phase 1 & 2 analysis from all domain agents*
