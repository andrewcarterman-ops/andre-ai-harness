# Mission Control Dashboard - Security & Quality Guide

## Executive Summary

This document provides comprehensive security and code quality guidelines for the Mission Control Dashboard - an AI agent management system with components for Task Board, Calendar, Projects, Memories, Docs, Team, and Office visualization.

---

## 1. SECURITY CHECKLIST

### 1.1 Authentication & Authorization

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| AUTH-001 | Implement JWT-based authentication with short-lived access tokens (15 min) | Critical | ☐ |
| AUTH-002 | Use refresh tokens with rotation (7-day expiry, single-use) | Critical | ☐ |
| AUTH-003 | Enforce multi-factor authentication (MFA) for admin accounts | High | ☐ |
| AUTH-004 | Implement role-based access control (RBAC) with 4 roles: Admin, Manager, User, AI-Agent | Critical | ☐ |
| AUTH-005 | Session timeout after 30 minutes of inactivity | High | ☐ |
| AUTH-006 | Secure password policy (min 12 chars, complexity requirements) | High | ☐ |
| AUTH-007 | Account lockout after 5 failed attempts (15-min cooldown) | High | ☐ |
| AUTH-008 | API key management for AI agent access (rotatable, scope-limited) | Critical | ☐ |

### 1.2 Data Encryption

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| ENC-001 | TLS 1.3 for all data in transit | Critical | ☐ |
| ENC-002 | AES-256-GCM for data at rest | Critical | ☐ |
| ENC-003 | Encrypt sensitive memories with user-specific keys | Critical | ☐ |
| ENC-004 | Encrypt document content before storage | Critical | ☐ |
| ENC-005 | Secure key management (environment variables or KMS) | Critical | ☐ |
| ENC-006 | Database encryption for all PII fields | High | ☐ |
| ENC-007 | Encrypted backups with separate key management | High | ☐ |

### 1.3 AI Agent Security

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| AI-001 | AI operates in sandboxed environment with limited permissions | Critical | ☐ |
| AI-002 | Define explicit allow-list of actions AI can perform | Critical | ☐ |
| AI-003 | AI cannot access data outside assigned project scope | Critical | ☐ |
| AI-004 | Rate limit AI API calls (100 requests/minute per agent) | High | ☐ |
| AI-005 | AI actions require human approval for destructive operations | Critical | ☐ |
| AI-006 | AI session tokens expire after 1 hour | High | ☐ |
| AI-007 | AI cannot modify its own permissions or configuration | Critical | ☐ |
| AI-008 | Quarantine suspicious AI behavior patterns | High | ☐ |

### 1.4 API Security

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| API-001 | Implement API rate limiting per user/IP (100 req/min) | Critical | ☐ |
| API-002 | Use API versioning (/api/v1/) | High | ☐ |
| API-003 | Validate all request payloads with strict schemas | Critical | ☐ |
| API-004 | Implement CORS with explicit allowlist | High | ☐ |
| API-005 | Use Helmet.js for security headers | High | ☐ |
| API-006 | Disable server information headers (X-Powered-By) | Medium | ☐ |
| API-007 | Implement request size limits (10MB max) | High | ☐ |
| API-008 | Use parameterized queries (prevent SQL/NoSQL injection) | Critical | ☐ |

### 1.5 Input Validation

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| VAL-001 | Validate all inputs on server-side (never trust client) | Critical | ☐ |
| VAL-002 | Sanitize HTML content (use DOMPurify) | Critical | ☐ |
| VAL-003 | Escape output to prevent XSS | Critical | ☐ |
| VAL-004 | Validate file uploads (type, size, content scanning) | Critical | ☐ |
| VAL-005 | Reject unexpected fields in JSON payloads | High | ☐ |
| VAL-006 | Implement max length limits for all text fields | High | ☐ |
| VAL-007 | Validate date formats and ranges | Medium | ☐ |
| VAL-008 | Sanitize AI-generated content before storage | Critical | ☐ |

### 1.6 Audit & Logging

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| LOG-001 | Log all authentication events (success/failure) | Critical | ☐ |
| LOG-002 | Log all AI agent actions with context | Critical | ☐ |
| LOG-003 | Log data access (who accessed what, when) | Critical | ☐ |
| LOG-004 | Log configuration changes | High | ☐ |
| LOG-005 | Retain logs for 90 days (security), 1 year (compliance) | High | ☐ |
| LOG-006 | Encrypt sensitive log data | High | ☐ |
| LOG-007 | Implement log integrity checks | Medium | ☐ |
| LOG-008 | Enable undo functionality for AI modifications | High | ☐ |

### 1.7 Infrastructure Security

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| INF-001 | Run with minimal privileges (non-root user) | High | ☐ |
| INF-002 | Container security (read-only filesystem, no new privileges) | High | ☐ |
| INF-003 | Network segmentation (isolate AI processing) | Medium | ☐ |
| INF-004 | Regular security updates and patching | Critical | ☐ |
| INF-005 | Disable unused services and ports | Medium | ☐ |
| INF-006 | Implement health checks and monitoring | High | ☐ |
| INF-007 | Backup strategy with encryption (daily incremental, weekly full) | Critical | ☐ |

---

## 2. AUTHENTICATION & AUTHORIZATION PATTERN

### 2.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  User/AI Agent                                                  │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │   Login     │───▶│    Auth     │───▶│   JWT Token Pair    │ │
│  │   Request   │    │   Service   │    │ (Access + Refresh)  │ │
│  └─────────────┘    └─────────────┘    └─────────────────────┘ │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │   API       │───▶│   JWT       │───▶│   Permission        │ │
│  │   Request   │    │   Verify    │    │   Check (RBAC)      │ │
│  └─────────────┘    └─────────────┘    └─────────────────────┘ │
│                                               │                 │
│                                               ▼                 │
│                                       ┌─────────────┐          │
│                                       │   Resource  │          │
│                                       │   Access    │          │
│                                       └─────────────┘          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Role-Based Access Control (RBAC)

#### Role Definitions

```typescript
enum UserRole {
  ADMIN = 'admin',           // Full system access
  MANAGER = 'manager',       // Project management, team oversight
  USER = 'user',             // Personal task/data access
  AI_AGENT = 'ai_agent'      // Limited, scoped access
}

enum Permission {
  // Task Board
  TASK_READ = 'task:read',
  TASK_CREATE = 'task:create',
  TASK_UPDATE = 'task:update',
  TASK_DELETE = 'task:delete',
  
  // Calendar
  CALENDAR_READ = 'calendar:read',
  CALENDAR_CREATE = 'calendar:create',
  CALENDAR_UPDATE = 'calendar:update',
  CALENDAR_DELETE = 'calendar:delete',
  
  // Projects
  PROJECT_READ = 'project:read',
  PROJECT_CREATE = 'project:create',
  PROJECT_UPDATE = 'project:update',
  PROJECT_DELETE = 'project:delete',
  
  // Memories
  MEMORY_READ = 'memory:read',
  MEMORY_CREATE = 'memory:create',
  MEMORY_UPDATE = 'memory:update',
  MEMORY_DELETE = 'memory:delete',
  
  // Documents
  DOC_READ = 'doc:read',
  DOC_CREATE = 'doc:create',
  DOC_UPDATE = 'doc:update',
  DOC_DELETE = 'doc:delete',
  
  // Team
  TEAM_READ = 'team:read',
  TEAM_MANAGE = 'team:manage',
  
  // Admin
  ADMIN_SETTINGS = 'admin:settings',
  ADMIN_USERS = 'admin:users',
  ADMIN_LOGS = 'admin:logs'
}
```

#### Permission Matrix

| Resource | Admin | Manager | User | AI Agent |
|----------|-------|---------|------|----------|
| Task Board (all) | CRUD | CRUD | CRUD (own) | RU (assigned) |
| Calendar (all) | CRUD | CRUD | CRUD (own) | R (assigned) |
| Projects (all) | CRUD | CRUD | R (member) | RU (assigned) |
| Memories (all) | CRUD | - | CRUD (own) | CR (scoped) |
| Documents (all) | CRUD | CR | CRUD (own) | R (scoped) |
| Team Management | Full | Read | Read | - |
| Admin Settings | Full | - | - | - |

### 2.3 JWT Token Structure

```typescript
interface AccessTokenPayload {
  sub: string;           // User ID
  role: UserRole;        // User role
  scope: string[];       // Granted permissions
  projectId?: string;    // Optional: scoped to project
  iat: number;           // Issued at
  exp: number;           // Expiration (15 min)
  jti: string;           // Unique token ID
}

interface RefreshTokenPayload {
  sub: string;           // User ID
  tokenVersion: number;  // For invalidation
  iat: number;
  exp: number;           // Expiration (7 days)
  jti: string;
}

// AI Agent Token (specialized)
interface AIAgentTokenPayload {
  sub: string;           // Agent ID
  role: 'ai_agent';
  allowedActions: string[];  // Explicit allow-list
  projectScope: string[];    // Accessible projects
  userId: string;            // Owning user
  sessionId: string;
  iat: number;
  exp: number;           // Expiration (1 hour)
}
```

### 2.4 Middleware Implementation

```typescript
// auth.middleware.ts
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

interface AuthenticatedRequest extends Request {
  user?: AccessTokenPayload;
}

export const authenticate = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid authorization header' });
    return;
  }
  
  const token = authHeader.substring(7);
  
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET!) as AccessTokenPayload;
    
    // Check token blacklist (for logout/revocation)
    if (isTokenRevoked(payload.jti)) {
      res.status(401).json({ error: 'Token has been revoked' });
      return;
    }
    
    req.user = payload;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

// permission.middleware.ts
export const requirePermission = (...permissions: Permission[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }
    
    const hasPermission = permissions.every(p => 
      req.user!.scope.includes(p) || req.user!.role === UserRole.ADMIN
    );
    
    if (!hasPermission) {
      res.status(403).json({ error: 'Insufficient permissions' });
      return;
    }
    
    next();
  };
};

// AI-specific authorization
export const authorizeAIAction = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): void => {
  if (req.user?.role !== UserRole.AI_AGENT) {
    next();
    return;
  }
  
  const action = `${req.method.toLowerCase()}:${req.path}`;
  const allowedActions = (req.user as AIAgentTokenPayload).allowedActions;
  
  if (!allowedActions.includes(action)) {
    // Log unauthorized AI attempt
    auditLog.warn('AI attempted unauthorized action', {
      agentId: req.user.sub,
      action,
      timestamp: new Date().toISOString()
    });
    
    res.status(403).json({ error: 'Action not permitted for AI agent' });
    return;
  }
  
  next();
};
```

---

## 3. DATA ENCRYPTION STRATEGY

### 3.1 Encryption Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    ENCRYPTION ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Layer 1: Transport Encryption (TLS 1.3)                       │
│  ├── Certificate pinning for mobile clients                     │
│  ├── HSTS headers (max-age=31536000)                            │
│  └── Perfect forward secrecy (ECDHE)                            │
│                                                                 │
│  Layer 2: Application Encryption                                │
│  ├── Field-level encryption for PII                            │
│  ├── Encrypted search tokens for queryable fields              │
│  └── Tokenization for sensitive identifiers                    │
│                                                                 │
│  Layer 3: Database Encryption                                   │
│  ├── Transparent Data Encryption (TDE)                         │
│  ├── Column-level encryption for sensitive fields              │
│  └── Encrypted backups                                         │
│                                                                 │
│  Layer 4: File Storage Encryption                               │
│  ├── Client-side encryption before upload                      │
│  ├── Server-side encryption at rest (AES-256-GCM)              │
│  └── Signed URLs for temporary access                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Field-Level Encryption

```typescript
// encryption.service.ts
import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const KEY_LENGTH = 32;
const IV_LENGTH = 16;
const AUTH_TAG_LENGTH = 16;

interface EncryptedField {
  ciphertext: string;
  iv: string;
  authTag: string;
  version: number;
}

class EncryptionService {
  private masterKey: Buffer;
  
  constructor() {
    const keyHex = process.env.ENCRYPTION_KEY;
    if (!keyHex || keyHex.length !== 64) {
      throw new Error('Invalid encryption key configuration');
    }
    this.masterKey = Buffer.from(keyHex, 'hex');
  }
  
  // Derive user-specific key for personal data
  deriveUserKey(userId: string): Buffer {
    return crypto.pbkdf2Sync(
      this.masterKey,
      userId,
      100000,
      KEY_LENGTH,
      'sha256'
    );
  }
  
  encrypt(plaintext: string, userId?: string): EncryptedField {
    const key = userId ? this.deriveUserKey(userId) : this.masterKey;
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
    
    let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
    ciphertext += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return {
      ciphertext,
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex'),
      version: 1
    };
  }
  
  decrypt(encrypted: EncryptedField, userId?: string): string {
    const key = userId ? this.deriveUserKey(userId) : this.masterKey;
    const decipher = crypto.createDecipheriv(
      ALGORITHM,
      key,
      Buffer.from(encrypted.iv, 'hex')
    );
    
    decipher.setAuthTag(Buffer.from(encrypted.authTag, 'hex'));
    
    let plaintext = decipher.update(encrypted.ciphertext, 'hex', 'utf8');
    plaintext += decipher.final('utf8');
    
    return plaintext;
  }
}

export const encryptionService = new EncryptionService();
```

### 3.3 Encrypted Memory Storage

```typescript
// memory.model.ts
import mongoose, { Schema, Document } from 'mongoose';
import { encryptionService } from './encryption.service';

interface IMemory extends Document {
  userId: string;
  content: string;           // Encrypted
  category: string;
  tags: string[];
  isSensitive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const MemorySchema = new Schema<IMemory>({
  userId: { type: String, required: true, index: true },
  content: { type: String, required: true },  // Stored encrypted
  category: { type: String, required: true },
  tags: [{ type: String }],
  isSensitive: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}, {
  toJSON: { 
    transform: function(doc, ret) {
      // Decrypt on retrieval (in application layer)
      delete ret.__v;
      return ret;
    }
  }
});

// Pre-save hook for encryption
MemorySchema.pre('save', function(next) {
  if (this.isModified('content')) {
    const encrypted = encryptionService.encrypt(this.content, this.userId);
    this.content = JSON.stringify(encrypted);
  }
  next();
});

// Post-find hook for decryption
MemorySchema.post('find', function(docs) {
  docs.forEach((doc: IMemory) => {
    try {
      const encrypted = JSON.parse(doc.content);
      doc.content = encryptionService.decrypt(encrypted, doc.userId);
    } catch (e) {
      // Content might already be decrypted or invalid
    }
  });
});

export const Memory = mongoose.model<IMemory>('Memory', MemorySchema);
```

### 3.4 Document Encryption Strategy

```typescript
// document.service.ts
interface DocumentEncryptionConfig {
  encryptContent: boolean;
  encryptMetadata: boolean;
  allowSearch: boolean;
}

class DocumentService {
  async storeDocument(
    file: Buffer,
    metadata: DocumentMetadata,
    config: DocumentEncryptionConfig,
    userId: string
  ): Promise<string> {
    const documentId = generateUUID();
    
    // Generate search tokens if search enabled
    let searchTokens: string[] = [];
    if (config.allowSearch) {
      searchTokens = await this.generateSearchTokens(metadata, userId);
    }
    
    // Encrypt file content
    const encryptedFile = config.encryptContent
      ? encryptionService.encrypt(file.toString('base64'), userId)
      : null;
    
    // Encrypt metadata if needed
    const encryptedMetadata = config.encryptMetadata
      ? encryptionService.encrypt(JSON.stringify(metadata), userId)
      : null;
    
    // Store with appropriate encryption
    await this.saveToStorage({
      documentId,
      content: encryptedFile || file.toString('base64'),
      metadata: encryptedMetadata || metadata,
      searchTokens,
      encryptionConfig: config,
      userId,
      createdAt: new Date()
    });
    
    return documentId;
  }
  
  private async generateSearchTokens(
    metadata: DocumentMetadata,
    userId: string
  ): Promise<string[]> {
    // Create blind index tokens for encrypted search
    const searchableFields = [
      metadata.title,
      metadata.description,
      ...metadata.tags
    ].filter(Boolean);
    
    return searchableFields.map(field => 
      crypto.createHmac('sha256', process.env.SEARCH_KEY!)
        .update(`${userId}:${field.toLowerCase()}`)
        .digest('hex')
    );
  }
}
```

---

## 4. AI PERMISSION MODEL

### 4.1 AI Agent Scope Definition

```typescript
// ai-permission.model.ts

interface AIActionScope {
  action: AIAction;
  resources: ResourceType[];
  conditions?: ActionCondition[];
}

type AIAction = 
  | 'task:create'
  | 'task:update'
  | 'task:read'
  | 'calendar:read'
  | 'calendar:create'
  | 'memory:create'
  | 'memory:read'
  | 'doc:read'
  | 'project:read';

type ResourceType = 'task' | 'calendar' | 'memory' | 'doc' | 'project';

interface ActionCondition {
  type: 'ownership' | 'project_membership' | 'time_window' | 'rate_limit';
  params: Record<string, unknown>;
}

// Default AI permission template
const DEFAULT_AI_PERMISSIONS: AIActionScope[] = [
  {
    action: 'task:read',
    resources: ['task'],
    conditions: [
      { type: 'project_membership', params: {} },
      { type: 'rate_limit', params: { maxPerMinute: 60 } }
    ]
  },
  {
    action: 'task:create',
    resources: ['task'],
    conditions: [
      { type: 'project_membership', params: {} },
      { type: 'rate_limit', params: { maxPerMinute: 10 } }
    ]
  },
  {
    action: 'task:update',
    resources: ['task'],
    conditions: [
      { type: 'ownership', params: { allowAssigned: true } },
      { type: 'rate_limit', params: { maxPerMinute: 20 } }
    ]
  },
  {
    action: 'calendar:read',
    resources: ['calendar'],
    conditions: [
      { type: 'project_membership', params: {} },
      { type: 'time_window', params: { daysAhead: 30 } }
    ]
  },
  {
    action: 'memory:create',
    resources: ['memory'],
    conditions: [
      { type: 'rate_limit', params: { maxPerHour: 50 } }
    ]
  },
  {
    action: 'memory:read',
    resources: ['memory'],
    conditions: [
      { type: 'ownership', params: { scope: 'user' } }
    ]
  },
  {
    action: 'doc:read',
    resources: ['doc'],
    conditions: [
      { type: 'project_membership', params: {} }
    ]
  },
  {
    action: 'project:read',
    resources: ['project'],
    conditions: [
      { type: 'project_membership', params: {} }
    ]
  }
];
```

### 4.2 AI Sandbox Implementation

```typescript
// ai-sandbox.service.ts

interface SandboxContext {
  agentId: string;
  userId: string;
  projectIds: string[];
  sessionId: string;
  permissions: AIActionScope[];
  createdAt: Date;
  expiresAt: Date;
}

class AISandboxService {
  private activeSessions: Map<string, SandboxContext> = new Map();
  
  async createSession(
    agentId: string,
    userId: string,
    projectIds: string[],
    customPermissions?: AIActionScope[]
  ): Promise<string> {
    const sessionId = generateUUID();
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 60 * 60 * 1000); // 1 hour
    
    const context: SandboxContext = {
      agentId,
      userId,
      projectIds,
      sessionId,
      permissions: customPermissions || DEFAULT_AI_PERMISSIONS,
      createdAt: now,
      expiresAt
    };
    
    this.activeSessions.set(sessionId, context);
    
    // Log session creation
    await auditLog.info('AI sandbox session created', {
      agentId,
      userId,
      projectIds,
      sessionId,
      timestamp: now.toISOString()
    });
    
    return sessionId;
  }
  
  async validateAction(
    sessionId: string,
    action: AIAction,
    resourceType: ResourceType,
    resourceId?: string
  ): Promise<{ allowed: boolean; reason?: string }> {
    const context = this.activeSessions.get(sessionId);
    
    if (!context) {
      return { allowed: false, reason: 'Invalid or expired session' };
    }
    
    if (new Date() > context.expiresAt) {
      this.activeSessions.delete(sessionId);
      return { allowed: false, reason: 'Session expired' };
    }
    
    // Check if action is in allowed permissions
    const permission = context.permissions.find(p => 
      p.action === action && p.resources.includes(resourceType)
    );
    
    if (!permission) {
      await this.logUnauthorizedAttempt(context, action, resourceType);
      return { allowed: false, reason: 'Action not permitted' };
    }
    
    // Check conditions
    for (const condition of permission.conditions || []) {
      const conditionMet = await this.checkCondition(
        condition,
        context,
        resourceId
      );
      
      if (!conditionMet) {
        return { allowed: false, reason: `Condition not met: ${condition.type}` };
      }
    }
    
    return { allowed: true };
  }
  
  private async checkCondition(
    condition: ActionCondition,
    context: SandboxContext,
    resourceId?: string
  ): Promise<boolean> {
    switch (condition.type) {
      case 'ownership':
        return await this.checkOwnership(context, resourceId);
      
      case 'project_membership':
        return await this.checkProjectMembership(context, resourceId);
      
      case 'time_window':
        return this.checkTimeWindow(condition.params);
      
      case 'rate_limit':
        return await this.checkRateLimit(context, condition.params);
      
      default:
        return false;
    }
  }
  
  private async logUnauthorizedAttempt(
    context: SandboxContext,
    action: AIAction,
    resourceType: ResourceType
  ): Promise<void> {
    await auditLog.warn('AI unauthorized action attempt', {
      agentId: context.agentId,
      sessionId: context.sessionId,
      action,
      resourceType,
      timestamp: new Date().toISOString()
    });
    
    // Alert if multiple violations
    const recentViolations = await this.getRecentViolations(context.agentId, 5);
    if (recentViolations >= 5) {
      await this.quarantineAgent(context.agentId);
    }
  }
  
  private async quarantineAgent(agentId: string): Promise<void> {
    // Disable agent and alert admin
    await auditLog.critical('AI agent quarantined due to violations', {
      agentId,
      timestamp: new Date().toISOString()
    });
    
    // Invalidate all sessions
    for (const [sessionId, context] of this.activeSessions.entries()) {
      if (context.agentId === agentId) {
        this.activeSessions.delete(sessionId);
      }
    }
  }
}

export const aiSandbox = new AISandboxService();
```

### 4.3 AI Action Execution Wrapper

```typescript
// ai-action-wrapper.ts

interface AIActionResult<T> {
  success: boolean;
  data?: T;
  error?: string;
  actionId: string;
  executionTime: number;
}

export async function executeAIAction<T>(
  sessionId: string,
  action: AIAction,
  resourceType: ResourceType,
  resourceId: string | undefined,
  operation: () => Promise<T>
): Promise<AIActionResult<T>> {
  const actionId = generateUUID();
  const startTime = Date.now();
  
  // Validate permission
  const validation = await aiSandbox.validateAction(
    sessionId,
    action,
    resourceType,
    resourceId
  );
  
  if (!validation.allowed) {
    await auditLog.warn('AI action blocked', {
      actionId,
      sessionId,
      action,
      resourceType,
      reason: validation.reason,
      timestamp: new Date().toISOString()
    });
    
    return {
      success: false,
      error: validation.reason,
      actionId,
      executionTime: Date.now() - startTime
    };
  }
  
  try {
    // Execute with timeout
    const result = await Promise.race([
      operation(),
      new Promise<never>((_, reject) => 
        setTimeout(() => reject(new Error('Action timeout')), 30000)
      )
    ]);
    
    const executionTime = Date.now() - startTime;
    
    // Log successful action
    await auditLog.info('AI action executed', {
      actionId,
      sessionId,
      action,
      resourceType,
      resourceId,
      executionTime,
      timestamp: new Date().toISOString()
    });
    
    // Store for undo capability
    await storeActionForUndo(actionId, action, resourceType, resourceId);
    
    return {
      success: true,
      data: result,
      actionId,
      executionTime
    };
  } catch (error) {
    const executionTime = Date.now() - startTime;
    
    await auditLog.error('AI action failed', {
      actionId,
      sessionId,
      action,
      resourceType,
      error: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString()
    });
    
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      actionId,
      executionTime
    };
  }
}
```

---

## 5. INPUT SANITIZATION RULES

### 5.1 Validation Schema Definitions

```typescript
// validation.schemas.ts
import { z } from 'zod';
import DOMPurify from 'isomorphic-dompurify';

// Common sanitization helpers
const sanitizeString = (val: string) => 
  DOMPurify.sanitize(val.trim(), { ALLOWED_TAGS: [] });

const sanitizeHtml = (val: string) =>
  DOMPurify.sanitize(val, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li'],
    ALLOWED_ATTR: ['href', 'target']
  });

// Task validation schema
export const TaskSchema = z.object({
  title: z.string()
    .min(1, 'Title is required')
    .max(200, 'Title too long')
    .transform(sanitizeString),
  
  description: z.string()
    .max(5000, 'Description too long')
    .optional()
    .transform(val => val ? sanitizeHtml(val) : val),
  
  status: z.enum(['todo', 'in_progress', 'done', 'archived']),
  
  priority: z.enum(['low', 'medium', 'high', 'urgent']),
  
  dueDate: z.string()
    .datetime()
    .optional()
    .refine(val => {
      if (!val) return true;
      return new Date(val) > new Date();
    }, 'Due date must be in the future'),
  
  assigneeId: z.string()
    .uuid()
    .optional(),
  
  projectId: z.string()
    .uuid()
    .optional(),
  
  tags: z.array(
    z.string()
      .min(1)
      .max(30)
      .transform(sanitizeString)
  )
    .max(10, 'Maximum 10 tags allowed')
    .optional(),
  
  // Reject unknown fields
}).strict();

// Memory validation schema
export const MemorySchema = z.object({
  content: z.string()
    .min(1, 'Content is required')
    .max(10000, 'Content too long')
    .transform(sanitizeHtml),
  
  category: z.enum([
    'personal',
    'work',
    'idea',
    'meeting',
    'reference'
  ]),
  
  isSensitive: z.boolean().default(false),
  
  tags: z.array(
    z.string()
      .min(1)
      .max(30)
      .transform(sanitizeString)
  )
    .max(10)
    .optional(),
  
  // Additional metadata
  source: z.string()
    .max(100)
    .optional()
    .transform(val => val ? sanitizeString(val) : val)
  
}).strict();

// Document validation schema
export const DocumentSchema = z.object({
  title: z.string()
    .min(1)
    .max(200)
    .transform(sanitizeString),
  
  content: z.string()
    .max(50000)
    .optional()
    .transform(val => val ? sanitizeHtml(val) : val),
  
  folderId: z.string()
    .uuid()
    .optional(),
  
  isEncrypted: z.boolean().default(false),
  
  allowSearch: z.boolean().default(true)
  
}).strict();

// Calendar event schema
export const CalendarEventSchema = z.object({
  title: z.string()
    .min(1)
    .max(200)
    .transform(sanitizeString),
  
  description: z.string()
    .max(2000)
    .optional()
    .transform(val => val ? sanitizeHtml(val) : val),
  
  startTime: z.string().datetime(),
  
  endTime: z.string().datetime(),
  
  location: z.string()
    .max(200)
    .optional()
    .transform(sanitizeString),
  
  attendees: z.array(z.string().email())
    .max(50)
    .optional(),
  
  recurrence: z.enum(['none', 'daily', 'weekly', 'monthly'])
    .optional(),
  
  isPrivate: z.boolean().default(false)
  
}).refine(data => {
  return new Date(data.endTime) > new Date(data.startTime);
}, 'End time must be after start time').strict();

// AI-generated content schema
export const AIGeneratedContentSchema = z.object({
  content: z.string()
    .min(1)
    .max(50000),
  
  contentType: z.enum([
    'task_description',
    'memory_note',
    'document_draft',
    'calendar_summary'
  ]),
  
  confidence: z.number()
    .min(0)
    .max(1)
    .optional(),
  
  sourceContext: z.string()
    .max(1000)
    .optional()
    .transform(sanitizeString),
  
  // Flag for human review
  requiresReview: z.boolean().default(true)
  
}).strict();
```

### 5.2 File Upload Validation

```typescript
// file-upload.validator.ts

interface FileValidationConfig {
  maxSize: number;           // bytes
  allowedTypes: string[];    // MIME types
  allowedExtensions: string[];
  scanForMalware: boolean;
}

const DEFAULT_FILE_CONFIG: Record<string, FileValidationConfig> = {
  document: {
    maxSize: 10 * 1024 * 1024,  // 10MB
    allowedTypes: [
      'application/pdf',
      'text/plain',
      'text/markdown',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ],
    allowedExtensions: ['.pdf', '.txt', '.md', '.docx'],
    scanForMalware: true
  },
  image: {
    maxSize: 5 * 1024 * 1024,   // 5MB
    allowedTypes: [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp'
    ],
    allowedExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
    scanForMalware: true
  },
  attachment: {
    maxSize: 50 * 1024 * 1024,  // 50MB
    allowedTypes: ['*/*'],
    allowedExtensions: ['*'],
    scanForMalware: true
  }
};

class FileUploadValidator {
  async validateFile(
    file: Express.Multer.File,
    category: keyof typeof DEFAULT_FILE_CONFIG
  ): Promise<{ valid: boolean; errors: string[] }> {
    const config = DEFAULT_FILE_CONFIG[category];
    const errors: string[] = [];
    
    // Check file size
    if (file.size > config.maxSize) {
      errors.push(`File size exceeds maximum of ${config.maxSize / 1024 / 1024}MB`);
    }
    
    // Check MIME type
    if (!config.allowedTypes.includes('*/*') && 
        !config.allowedTypes.includes(file.mimetype)) {
      errors.push(`File type ${file.mimetype} not allowed`);
    }
    
    // Check extension
    const ext = path.extname(file.originalname).toLowerCase();
    if (!config.allowedExtensions.includes('*') &&
        !config.allowedExtensions.includes(ext)) {
      errors.push(`File extension ${ext} not allowed`);
    }
    
    // Verify MIME type matches extension
    if (!await this.verifyMimeType(file, ext)) {
      errors.push('File content does not match extension');
    }
    
    // Malware scan (placeholder for integration)
    if (config.scanForMalware) {
      const scanResult = await this.scanForMalware(file);
      if (!scanResult.clean) {
        errors.push('File failed security scan');
      }
    }
    
    return {
      valid: errors.length === 0,
      errors
    };
  }
  
  private async verifyMimeType(
    file: Express.Multer.File,
    extension: string
  ): Promise<boolean> {
    // Read file magic numbers to verify type
    const buffer = file.buffer.slice(0, 8);
    
    const signatures: Record<string, number[]> = {
      '.pdf': [0x25, 0x50, 0x44, 0x46],
      '.png': [0x89, 0x50, 0x4E, 0x47],
      '.jpg': [0xFF, 0xD8, 0xFF],
      '.gif': [0x47, 0x49, 0x46, 0x38]
    };
    
    const signature = signatures[extension];
    if (!signature) return true;  // Unknown extension
    
    return signature.every((byte, i) => buffer[i] === byte);
  }
  
  private async scanForMalware(
    file: Express.Multer.File
  ): Promise<{ clean: boolean; threats?: string[] }> {
    // Integration point for malware scanning service
    // e.g., ClamAV, VirusTotal API
    
    // Placeholder implementation
    const dangerousPatterns = [
      /eval\s*\(/i,
      /exec\s*\(/i,
      /<script/i,
      /javascript:/i
    ];
    
    const content = file.buffer.toString('utf8', 0, Math.min(file.buffer.length, 10000));
    
    for (const pattern of dangerousPatterns) {
      if (pattern.test(content)) {
        return {
          clean: false,
          threats: ['Suspicious pattern detected']
        };
      }
    }
    
    return { clean: true };
  }
}

export const fileValidator = new FileUploadValidator();
```

### 5.3 AI Content Sanitization

```typescript
// ai-content-sanitizer.ts

interface SanitizationResult {
  sanitized: string;
  warnings: string[];
  blocked: boolean;
}

class AIContentSanitizer {
  private blockedPatterns: RegExp[] = [
    // Potential injection patterns
    /<script[^>]*>.*?<\/script>/gi,
    /javascript:/gi,
    /on\w+\s*=/gi,  // Event handlers
    /data:text\/html/gi,
    
    // Potential data exfiltration
    /\b(?:api[_-]?key|password|secret|token)\s*[:=]/gi,
    
    // Suspicious commands
    /\b(?:rm\s+-rf|format|del\s+\/f|\$\{.*\})/gi,
    
    // SQL injection patterns
    /(\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION)\b.*){2,}/gi
  ];
  
  private sensitiveKeywords = [
    'password',
    'secret',
    'api_key',
    'private_key',
    'credit_card',
    'ssn',
    'social security'
  ];
  
  sanitize(content: string, contentType: string): SanitizationResult {
    const warnings: string[] = [];
    let sanitized = content;
    let blocked = false;
    
    // Check for blocked patterns
    for (const pattern of this.blockedPatterns) {
      if (pattern.test(sanitized)) {
        warnings.push(`Blocked pattern detected: ${pattern.source}`);
        blocked = true;
      }
    }
    
    // Sanitize HTML if present
    sanitized = DOMPurify.sanitize(sanitized, {
      ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li', 'code'],
      ALLOWED_ATTR: ['href', 'target', 'class']
    });
    
    // Check for sensitive content
    const lowerContent = sanitized.toLowerCase();
    for (const keyword of this.sensitiveKeywords) {
      if (lowerContent.includes(keyword)) {
        warnings.push(`Potentially sensitive content detected: ${keyword}`);
      }
    }
    
    // Length validation
    if (sanitized.length > 50000) {
      warnings.push('Content exceeds maximum length');
      sanitized = sanitized.substring(0, 50000);
    }
    
    // Content-type specific validation
    switch (contentType) {
      case 'task_description':
        if (sanitized.length > 5000) {
          sanitized = sanitized.substring(0, 5000);
        }
        break;
      
      case 'memory_note':
        // Additional memory-specific checks
        break;
    }
    
    return {
      sanitized,
      warnings,
      blocked
    };
  }
  
  // Validate AI output before storage
  async validateAIOutput(
    content: string,
    expectedType: string
  ): Promise<{ valid: boolean; reason?: string }> {
    const result = this.sanitize(content, expectedType);
    
    if (result.blocked) {
      return {
        valid: false,
        reason: `Content blocked: ${result.warnings.join(', ')}`
      };
    }
    
    if (result.warnings.length > 0) {
      // Log warnings but allow
      await auditLog.warn('AI content warnings', {
        warnings: result.warnings,
        contentType: expectedType,
        timestamp: new Date().toISOString()
      });
    }
    
    return { valid: true };
  }
}

export const aiSanitizer = new AIContentSanitizer();
```

---

## 6. AUDIT LOGGING REQUIREMENTS

### 6.1 Audit Event Types

```typescript
// audit.types.ts

enum AuditEventType {
  // Authentication events
  AUTH_LOGIN_SUCCESS = 'auth:login:success',
  AUTH_LOGIN_FAILURE = 'auth:login:failure',
  AUTH_LOGOUT = 'auth:logout',
  AUTH_TOKEN_REFRESH = 'auth:token:refresh',
  AUTH_TOKEN_REVOKED = 'auth:token:revoked',
  AUTH_MFA_ENABLED = 'auth:mfa:enabled',
  AUTH_PASSWORD_CHANGED = 'auth:password:changed',
  
  // AI Agent events
  AI_SESSION_CREATED = 'ai:session:created',
  AI_SESSION_EXPIRED = 'ai:session:expired',
  AI_ACTION_EXECUTED = 'ai:action:executed',
  AI_ACTION_BLOCKED = 'ai:action:blocked',
  AI_ACTION_FAILED = 'ai:action:failed',
  AI_AGENT_QUARANTINED = 'ai:agent:quarantined',
  
  // Data access events
  DATA_READ = 'data:read',
  DATA_CREATED = 'data:created',
  DATA_UPDATED = 'data:updated',
  DATA_DELETED = 'data:deleted',
  DATA_EXPORTED = 'data:exported',
  
  // Resource-specific
  TASK_CREATED = 'task:created',
  TASK_UPDATED = 'task:updated',
  TASK_DELETED = 'task:deleted',
  MEMORY_CREATED = 'memory:created',
  MEMORY_ACCESSED = 'memory:accessed',
  DOC_UPLOADED = 'doc:uploaded',
  DOC_DOWNLOADED = 'doc:downloaded',
  
  // Admin events
  ADMIN_USER_CREATED = 'admin:user:created',
  ADMIN_USER_DELETED = 'admin:user:deleted',
  ADMIN_PERMISSION_CHANGED = 'admin:permission:changed',
  ADMIN_SETTINGS_UPDATED = 'admin:settings:updated',
  
  // Security events
  SECURITY_RATE_LIMIT_EXCEEDED = 'security:rate_limit:exceeded',
  SECURITY_SUSPICIOUS_ACTIVITY = 'security:suspicious:activity',
  SECURITY_PERMISSION_VIOLATION = 'security:permission:violation'
}

interface AuditEvent {
  eventId: string;
  eventType: AuditEventType;
  timestamp: string;
  severity: 'info' | 'warn' | 'error' | 'critical';
  
  // Actor information
  actor: {
    type: 'user' | 'ai_agent' | 'system';
    id: string;
    ip?: string;
    userAgent?: string;
  };
  
  // Resource information
  resource?: {
    type: string;
    id: string;
    ownerId?: string;
  };
  
  // Action details
  action?: {
    name: string;
    params?: Record<string, unknown>;
    result?: 'success' | 'failure' | 'blocked';
    errorMessage?: string;
  };
  
  // Context
  context?: {
    sessionId?: string;
    requestId?: string;
    projectId?: string;
  };
  
  // Change tracking for updates
  changes?: {
    before: Record<string, unknown>;
    after: Record<string, unknown>;
  };
  
  // Metadata
  metadata?: Record<string, unknown>;
}
```

### 6.2 Audit Logger Implementation

```typescript
// audit-logger.service.ts
import winston from 'winston';

class AuditLogger {
  private logger: winston.Logger;
  private buffer: AuditEvent[] = [];
  private readonly BUFFER_SIZE = 100;
  
  constructor() {
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
      ),
      transports: [
        // Write to audit log file
        new winston.transports.File({
          filename: 'logs/audit.log',
          maxsize: 5242880,  // 5MB
          maxFiles: 10
        }),
        
        // Critical events to separate file
        new winston.transports.File({
          filename: 'logs/audit-critical.log',
          level: 'critical',
          maxsize: 5242880,
          maxFiles: 20
        }),
        
        // Console for development
        new winston.transports.Console({
          level: process.env.NODE_ENV === 'development' ? 'info' : 'warn'
        })
      ]
    });
    
    // Flush buffer periodically
    setInterval(() => this.flushBuffer(), 5000);
  }
  
  async log(event: Omit<AuditEvent, 'eventId' | 'timestamp'>): Promise<void> {
    const fullEvent: AuditEvent = {
      ...event,
      eventId: generateUUID(),
      timestamp: new Date().toISOString()
    };
    
    // Add to buffer for batch processing
    this.buffer.push(fullEvent);
    
    if (this.buffer.length >= this.BUFFER_SIZE) {
      await this.flushBuffer();
    }
    
    // Immediately log critical events
    if (event.severity === 'critical') {
      this.logger.critical(fullEvent);
      await this.alertCriticalEvent(fullEvent);
    }
  }
  
  private async flushBuffer(): Promise<void> {
    if (this.buffer.length === 0) return;
    
    const events = [...this.buffer];
    this.buffer = [];
    
    // Write to persistent storage
    for (const event of events) {
      this.logger.log(event.severity, event.eventType, event);
    }
    
    // Also store in database for querying
    await this.storeInDatabase(events);
  }
  
  private async storeInDatabase(events: AuditEvent[]): Promise<void> {
    try {
      await AuditEventModel.insertMany(events);
    } catch (error) {
      this.logger.error('Failed to store audit events in database', { error });
    }
  }
  
  private async alertCriticalEvent(event: AuditEvent): Promise<void> {
    // Send alerts for critical security events
    // Integration with email, Slack, PagerDuty, etc.
    
    const alertChannels = [];
    
    if (process.env.SLACK_WEBHOOK_URL) {
      alertChannels.push(this.sendSlackAlert(event));
    }
    
    if (process.env.ADMIN_EMAIL) {
      alertChannels.push(this.sendEmailAlert(event));
    }
    
    await Promise.all(alertChannels);
  }
  
  // Convenience methods
  async info(
    eventType: AuditEventType,
    details: Partial<AuditEvent>
  ): Promise<void> {
    await this.log({
      eventType,
      severity: 'info',
      ...details
    } as Omit<AuditEvent, 'eventId' | 'timestamp'>);
  }
  
  async warn(
    eventType: AuditEventType,
    details: Partial<AuditEvent>
  ): Promise<void> {
    await this.log({
      eventType,
      severity: 'warn',
      ...details
    } as Omit<AuditEvent, 'eventId' | 'timestamp'>);
  }
  
  async error(
    eventType: AuditEventType,
    details: Partial<AuditEvent>
  ): Promise<void> {
    await this.log({
      eventType,
      severity: 'error',
      ...details
    } as Omit<AuditEvent, 'eventId' | 'timestamp'>);
  }
  
  async critical(
    eventType: AuditEventType,
    details: Partial<AuditEvent>
  ): Promise<void> {
    await this.log({
      eventType,
      severity: 'critical',
      ...details
    } as Omit<AuditEvent, 'eventId' | 'timestamp'>);
  }
  
  // Query methods
  async getEvents(filters: {
    actorId?: string;
    resourceType?: string;
    eventType?: AuditEventType;
    startDate?: Date;
    endDate?: Date;
    severity?: string;
  }): Promise<AuditEvent[]> {
    const query: Record<string, unknown> = {};
    
    if (filters.actorId) query['actor.id'] = filters.actorId;
    if (filters.resourceType) query['resource.type'] = filters.resourceType;
    if (filters.eventType) query['eventType'] = filters.eventType;
    if (filters.severity) query['severity'] = filters.severity;
    if (filters.startDate || filters.endDate) {
      query['timestamp'] = {};
      if (filters.startDate) (query['timestamp'] as Record<string, Date>)['$gte'] = filters.startDate;
      if (filters.endDate) (query['timestamp'] as Record<string, Date>)['$lte'] = filters.endDate;
    }
    
    return await AuditEventModel.find(query)
      .sort({ timestamp: -1 })
      .limit(1000)
      .lean();
  }
}

export const auditLog = new AuditLogger();
```

### 6.3 Undo System for AI Actions

```typescript
// undo-system.service.ts

interface UndoableAction {
  actionId: string;
  eventType: AuditEventType;
  actor: {
    type: 'ai_agent';
    id: string;
  };
  originalState: Record<string, unknown>;
  resource: {
    type: string;
    id: string;
  };
  timestamp: string;
  expiresAt: string;  // Undo window
}

class UndoSystem {
  private readonly UNDO_WINDOW_HOURS = 24;
  
  async storeActionForUndo(
    actionId: string,
    eventType: AuditEventType,
    resourceType: string,
    resourceId: string,
    originalState: Record<string, unknown>
  ): Promise<void> {
    const undoable: UndoableAction = {
      actionId,
      eventType,
      actor: { type: 'ai_agent', id: 'ai-agent-id' },
      originalState,
      resource: { type: resourceType, id: resourceId },
      timestamp: new Date().toISOString(),
      expiresAt: new Date(Date.now() + this.UNDO_WINDOW_HOURS * 60 * 60 * 1000).toISOString()
    };
    
    await UndoableActionModel.create(undoable);
  }
  
  async undoAction(actionId: string, userId: string): Promise<{ success: boolean; message: string }> {
    const undoable = await UndoableActionModel.findOne({ actionId });
    
    if (!undoable) {
      return { success: false, message: 'Action not found or undo window expired' };
    }
    
    if (new Date() > new Date(undoable.expiresAt)) {
      await UndoableActionModel.deleteOne({ actionId });
      return { success: false, message: 'Undo window has expired' };
    }
    
    try {
      // Perform undo based on resource type
      switch (undoable.resource.type) {
        case 'task':
          await this.undoTaskAction(undoable);
          break;
        case 'memory':
          await this.undoMemoryAction(undoable);
          break;
        case 'doc':
          await this.undoDocumentAction(undoable);
          break;
        default:
          return { success: false, message: 'Unsupported resource type for undo' };
      }
      
      // Log the undo
      await auditLog.info(AuditEventType.DATA_UPDATED, {
        actor: { type: 'user', id: userId },
        action: {
          name: 'undo',
          params: { originalActionId: actionId },
          result: 'success'
        },
        resource: undoable.resource
      });
      
      // Remove from undoable actions
      await UndoableActionModel.deleteOne({ actionId });
      
      return { success: true, message: 'Action successfully undone' };
    } catch (error) {
      await auditLog.error(AuditEventType.DATA_UPDATED, {
        actor: { type: 'user', id: userId },
        action: {
          name: 'undo',
          params: { originalActionId: actionId },
          result: 'failure',
          errorMessage: error instanceof Error ? error.message : 'Unknown error'
        },
        resource: undoable.resource
      });
      
      return { success: false, message: 'Failed to undo action' };
    }
  }
  
  private async undoTaskAction(undoable: UndoableAction): Promise<void> {
    await TaskModel.findByIdAndUpdate(
      undoable.resource.id,
      undoable.originalState,
      { new: true }
    );
  }
  
  private async undoMemoryAction(undoable: UndoableAction): Promise<void> {
    await MemoryModel.findByIdAndUpdate(
      undoable.resource.id,
      undoable.originalState,
      { new: true }
    );
  }
  
  private async undoDocumentAction(undoable: UndoableAction): Promise<void> {
    await DocumentModel.findByIdAndUpdate(
      undoable.resource.id,
      undoable.originalState,
      { new: true }
    );
  }
  
  // Cleanup expired undoable actions
  async cleanupExpiredActions(): Promise<number> {
    const result = await UndoableActionModel.deleteMany({
      expiresAt: { $lt: new Date().toISOString() }
    });
    
    return result.deletedCount || 0;
  }
}

export const undoSystem = new UndoSystem();
```

### 6.4 Log Retention Policy

```typescript
// log-retention.service.ts

interface RetentionPolicy {
  logType: string;
  retentionDays: number;
  archiveBeforeDelete: boolean;
  encryptionRequired: boolean;
}

const RETENTION_POLICIES: RetentionPolicy[] = [
  {
    logType: 'audit',
    retentionDays: 365,  // 1 year for compliance
    archiveBeforeDelete: true,
    encryptionRequired: true
  },
  {
    logType: 'security',
    retentionDays: 365,
    archiveBeforeDelete: true,
    encryptionRequired: true
  },
  {
    logType: 'application',
    retentionDays: 30,
    archiveBeforeDelete: false,
    encryptionRequired: false
  },
  {
    logType: 'access',
    retentionDays: 90,
    archiveBeforeDelete: true,
    encryptionRequired: true
  },
  {
    logType: 'error',
    retentionDays: 60,
    archiveBeforeDelete: false,
    encryptionRequired: false
  }
];

class LogRetentionService {
  async enforceRetentionPolicies(): Promise<void> {
    for (const policy of RETENTION_POLICIES) {
      await this.applyPolicy(policy);
    }
  }
  
  private async applyPolicy(policy: RetentionPolicy): Promise<void> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - policy.retentionDays);
    
    if (policy.archiveBeforeDelete) {
      await this.archiveLogs(policy.logType, cutoffDate, policy.encryptionRequired);
    }
    
    await this.deleteOldLogs(policy.logType, cutoffDate);
  }
  
  private async archiveLogs(
    logType: string,
    beforeDate: Date,
    encrypt: boolean
  ): Promise<void> {
    const logs = await this.fetchLogs(logType, beforeDate);
    
    if (logs.length === 0) return;
    
    const archiveData = JSON.stringify(logs);
    const archiveContent = encrypt
      ? await encryptionService.encrypt(archiveData)
      : archiveData;
    
    const archivePath = `archives/${logType}/${beforeDate.toISOString().split('T')[0]}.json${encrypt ? '.enc' : ''}`;
    
    await this.storeArchive(archivePath, archiveContent);
    
    await auditLog.info(AuditEventType.ADMIN_SETTINGS_UPDATED, {
      actor: { type: 'system', id: 'retention-service' },
      action: {
        name: 'archive_logs',
        params: { logType, count: logs.length, path: archivePath },
        result: 'success'
      }
    });
  }
  
  private async deleteOldLogs(logType: string, beforeDate: Date): Promise<void> {
    // Implementation depends on logging storage
    // Example for MongoDB:
    await AuditEventModel.deleteMany({
      timestamp: { $lt: beforeDate.toISOString() }
    });
  }
  
  private async fetchLogs(logType: string, beforeDate: Date): Promise<unknown[]> {
    // Fetch logs from storage
    return await AuditEventModel.find({
      timestamp: { $lt: beforeDate.toISOString() }
    }).lean();
  }
  
  private async storeArchive(path: string, content: string | EncryptedField): Promise<void> {
    // Store to S3, local filesystem, etc.
    // Implementation depends on infrastructure
  }
}

// Schedule retention job
export function scheduleRetentionJob(): void {
  // Run daily at 2 AM
  const rule = new schedule.RecurrenceRule();
  rule.hour = 2;
  rule.minute = 0;
  
  schedule.scheduleJob(rule, async () => {
    const service = new LogRetentionService();
    await service.enforceRetentionPolicies();
  });
}
```

---

## 7. CODE QUALITY STANDARDS

### 7.1 TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@config/*": ["src/config/*"],
      "@services/*": ["src/services/*"],
      "@models/*": ["src/models/*"],
      "@middleware/*": ["src/middleware/*"],
      "@utils/*": ["src/utils/*"],
      "@types/*": ["src/types/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}
```

### 7.2 ESLint Configuration

```javascript
// .eslintrc.js
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    project: './tsconfig.json',
    tsconfigRootDir: __dirname,
    sourceType: 'module',
    ecmaVersion: 2022
  },
  plugins: [
    '@typescript-eslint',
    'security',
    'import',
    'no-secrets',
    'sonarjs'
  ],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking',
    'plugin:security/recommended',
    'plugin:import/errors',
    'plugin:import/warnings',
    'plugin:import/typescript',
    'plugin:sonarjs/recommended'
  ],
  rules: {
    // TypeScript strict rules
    '@typescript-eslint/explicit-function-return-type': 'error',
    '@typescript-eslint/no-explicit-any': 'error',
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/prefer-nullish-coalescing': 'error',
    '@typescript-eslint/prefer-optional-chain': 'error',
    '@typescript-eslint/strict-boolean-expressions': 'error',
    '@typescript-eslint/no-floating-promises': 'error',
    '@typescript-eslint/await-thenable': 'error',
    '@typescript-eslint/no-misused-promises': 'error',
    '@typescript-eslint/prefer-readonly': 'error',
    
    // Security rules
    'security/detect-object-injection': 'error',
    'security/detect-non-literal-regexp': 'error',
    'security/detect-unsafe-regex': 'error',
    'security/detect-buffer-noassert': 'error',
    'security/detect-eval-with-expression': 'error',
    'security/detect-no-csrf-before-method-override': 'error',
    'security/detect-non-literal-fs-filename': 'error',
    'security/detect-non-literal-require': 'error',
    'security/detect-possible-timing-attacks': 'warn',
    'security/detect-pseudoRandomBytes': 'error',
    
    // Secrets detection
    'no-secrets/no-secrets': ['error', { tolerance: 4.5 }],
    
    // Import rules
    'import/no-unresolved': 'error',
    'import/named': 'error',
    'import/namespace': 'error',
    'import/default': 'error',
    'import/export': 'error',
    'import/no-cycle': 'error',
    'import/no-self-import': 'error',
    'import/order': ['error', {
      groups: [
        'builtin',
        'external',
        'internal',
        'parent',
        'sibling',
        'index'
      ],
      'newlines-between': 'always'
    }],
    
    // SonarJS rules
    'sonarjs/no-duplicate-string': 'warn',
    'sonarjs/prefer-single-boolean-return': 'error',
    'sonarjs/no-redundant-jump': 'error',
    'sonarjs/no-identical-functions': 'error',
    'sonarjs/cognitive-complexity': ['error', 15],
    
    // General rules
    'no-console': ['warn', { allow: ['error', 'warn'] }],
    'no-debugger': 'error',
    'no-var': 'error',
    'prefer-const': 'error',
    'eqeqeq': ['error', 'always'],
    'curly': ['error', 'all'],
    'no-throw-literal': 'error',
    'prefer-promise-reject-errors': 'error'
  },
  settings: {
    'import/resolver': {
      typescript: {
        alwaysTryTypes: true,
        project: './tsconfig.json'
      }
    }
  },
  overrides: [
    {
      files: ['**/*.test.ts', '**/*.spec.ts'],
      rules: {
        '@typescript-eslint/no-explicit-any': 'off',
        'no-secrets/no-secrets': 'off'
      }
    }
  ]
};
```

### 7.3 Error Handling Patterns

```typescript
// errors.ts

// Custom error classes
export class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details?: Record<string, unknown>) {
    super('VALIDATION_ERROR', message, 400, details);
  }
}

export class AuthenticationError extends AppError {
  constructor(message: string = 'Authentication required') {
    super('AUTHENTICATION_ERROR', message, 401);
  }
}

export class AuthorizationError extends AppError {
  constructor(message: string = 'Insufficient permissions') {
    super('AUTHORIZATION_ERROR', message, 403);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    super('NOT_FOUND', `${resource}${id ? ` (${id})` : ''} not found`, 404);
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super('CONFLICT', message, 409);
  }
}

export class RateLimitError extends AppError {
  constructor(retryAfter: number) {
    super('RATE_LIMIT_EXCEEDED', 'Too many requests', 429, { retryAfter });
  }
}

// Error handler middleware
export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // Log error
  logger.error('Request error', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    userId: (req as AuthenticatedRequest).user?.sub
  });
  
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details
      }
    });
    return;
  }
  
  // Handle specific error types
  if (err.name === 'ValidationError') {
    res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: err.message
      }
    });
    return;
  }
  
  if (err.name === 'UnauthorizedError') {
    res.status(401).json({
      error: {
        code: 'AUTHENTICATION_ERROR',
        message: 'Invalid or expired token'
      }
    });
    return;
  }
  
  // Default: internal server error
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: process.env.NODE_ENV === 'production' 
        ? 'An unexpected error occurred' 
        : err.message
    }
  });
};

// Async handler wrapper
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

// Result type for explicit error handling
export type Result<T, E = AppError> = 
  | { success: true; data: T }
  | { success: false; error: E };

export function ok<T>(data: T): Result<T> {
  return { success: true, data };
}

export function err<E = AppError>(error: E): Result<never, E> {
  return { success: false, error };
}
```

### 7.4 Project Structure

```
src/
├── config/
│   ├── database.ts
│   ├── redis.ts
│   ├── security.ts
│   └── index.ts
├── controllers/
│   ├── auth.controller.ts
│   ├── task.controller.ts
│   ├── calendar.controller.ts
│   ├── memory.controller.ts
│   ├── document.controller.ts
│   └── ai.controller.ts
├── middleware/
│   ├── auth.middleware.ts
│   ├── validation.middleware.ts
│   ├── rate-limit.middleware.ts
│   ├── audit.middleware.ts
│   └── error.middleware.ts
├── models/
│   ├── user.model.ts
│   ├── task.model.ts
│   ├── memory.model.ts
│   ├── document.model.ts
│   └── audit-event.model.ts
├── services/
│   ├── auth.service.ts
│   ├── encryption.service.ts
│   ├── ai-sandbox.service.ts
│   ├── audit-logger.service.ts
│   └── undo-system.service.ts
├── utils/
│   ├── validators.ts
│   ├── sanitizers.ts
│   ├── crypto.ts
│   └── logger.ts
├── types/
│   ├── auth.types.ts
│   ├── api.types.ts
│   └── index.ts
├── routes/
│   ├── auth.routes.ts
│   ├── task.routes.ts
│   └── index.ts
└── app.ts
```

---

## 8. TESTING STRATEGY

### 8.1 Testing Pyramid

```
                    /\
                   /  \
                  / E2E \          (5% - Critical paths)
                 /________\
                /          \
               / Integration \    (15% - API, DB, Services)
              /______________\
             /                \
            /     Unit Tests    \  (80% - Business logic)
           /____________________\
```

### 8.2 Unit Testing Configuration

```typescript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.test.ts', '**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest'
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.test.ts',
    '!src/**/*.spec.ts',
    '!src/config/**',
    '!src/types/**'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  coverageReporters: ['text', 'text-summary', 'lcov', 'html'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@config/(.*)$': '<rootDir>/src/config/$1',
    '^@services/(.*)$': '<rootDir>/src/services/$1',
    '^@models/(.*)$': '<rootDir>/src/models/$1'
  },
  setupFilesAfterEnv: ['<rootDir>/src/test/setup.ts'],
  testTimeout: 10000
};
```

### 8.3 Unit Test Examples

```typescript
// encryption.service.test.ts
import { encryptionService } from '@services/encryption.service';

describe('EncryptionService', () => {
  const testUserId = 'user-123';
  
  describe('encrypt', () => {
    it('should encrypt plaintext successfully', () => {
      const plaintext = 'sensitive data';
      const encrypted = encryptionService.encrypt(plaintext, testUserId);
      
      expect(encrypted).toHaveProperty('ciphertext');
      expect(encrypted).toHaveProperty('iv');
      expect(encrypted).toHaveProperty('authTag');
      expect(encrypted.ciphertext).not.toBe(plaintext);
    });
    
    it('should produce different ciphertexts for same plaintext', () => {
      const plaintext = 'test data';
      const encrypted1 = encryptionService.encrypt(plaintext, testUserId);
      const encrypted2 = encryptionService.encrypt(plaintext, testUserId);
      
      expect(encrypted1.ciphertext).not.toBe(encrypted2.ciphertext);
      expect(encrypted1.iv).not.toBe(encrypted2.iv);
    });
  });
  
  describe('decrypt', () => {
    it('should decrypt to original plaintext', () => {
      const plaintext = 'sensitive data';
      const encrypted = encryptionService.encrypt(plaintext, testUserId);
      const decrypted = encryptionService.decrypt(encrypted, testUserId);
      
      expect(decrypted).toBe(plaintext);
    });
    
    it('should fail to decrypt with wrong user key', () => {
      const plaintext = 'sensitive data';
      const encrypted = encryptionService.encrypt(plaintext, testUserId);
      
      expect(() => {
        encryptionService.decrypt(encrypted, 'wrong-user');
      }).toThrow();
    });
    
    it('should fail to decrypt tampered ciphertext', () => {
      const plaintext = 'sensitive data';
      const encrypted = encryptionService.encrypt(plaintext, testUserId);
      encrypted.ciphertext = encrypted.ciphertext.slice(0, -4) + '0000';
      
      expect(() => {
        encryptionService.decrypt(encrypted, testUserId);
      }).toThrow();
    });
  });
});

// ai-sandbox.service.test.ts
import { aiSandbox } from '@services/ai-sandbox.service';

describe('AISandboxService', () => {
  const mockAgentId = 'agent-123';
  const mockUserId = 'user-456';
  const mockProjectIds = ['project-1', 'project-2'];
  
  describe('createSession', () => {
    it('should create a valid session', async () => {
      const sessionId = await aiSandbox.createSession(
        mockAgentId,
        mockUserId,
        mockProjectIds
      );
      
      expect(sessionId).toBeDefined();
      expect(typeof sessionId).toBe('string');
    });
  });
  
  describe('validateAction', () => {
    let sessionId: string;
    
    beforeEach(async () => {
      sessionId = await aiSandbox.createSession(
        mockAgentId,
        mockUserId,
        mockProjectIds
      );
    });
    
    it('should allow permitted action', async () => {
      const result = await aiSandbox.validateAction(
        sessionId,
        'task:read',
        'task',
        'task-123'
      );
      
      expect(result.allowed).toBe(true);
    });
    
    it('should block unauthorized action', async () => {
      const result = await aiSandbox.validateAction(
        sessionId,
        'admin:settings',
        'settings',
        undefined
      );
      
      expect(result.allowed).toBe(false);
      expect(result.reason).toContain('not permitted');
    });
    
    it('should reject expired session', async () => {
      // Fast-forward time
      jest.advanceTimersByTime(61 * 60 * 1000);
      
      const result = await aiSandbox.validateAction(
        sessionId,
        'task:read',
        'task',
        undefined
      );
      
      expect(result.allowed).toBe(false);
      expect(result.reason).toContain('expired');
    });
  });
});
```

### 8.4 Integration Testing

```typescript
// task.api.test.ts
import request from 'supertest';
import { app } from '../app';
import { generateTestToken } from './helpers/auth';

describe('Task API Integration', () => {
  let authToken: string;
  let userId: string;
  
  beforeAll(async () => {
    // Setup test database
    await setupTestDatabase();
    
    // Create test user and get token
    const testUser = await createTestUser();
    userId = testUser.id;
    authToken = generateTestToken(testUser);
  });
  
  afterAll(async () => {
    await teardownTestDatabase();
  });
  
  describe('POST /api/v1/tasks', () => {
    it('should create a new task', async () => {
      const taskData = {
        title: 'Test Task',
        description: 'Test description',
        status: 'todo',
        priority: 'high'
      };
      
      const response = await request(app)
        .post('/api/v1/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send(taskData)
        .expect(201);
      
      expect(response.body).toHaveProperty('id');
      expect(response.body.title).toBe(taskData.title);
      expect(response.body.createdBy).toBe(userId);
    });
    
    it('should reject invalid task data', async () => {
      const invalidData = {
        title: '',  // Empty title
        status: 'invalid_status'
      };
      
      await request(app)
        .post('/api/v1/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidData)
        .expect(400);
    });
    
    it('should reject unauthorized request', async () => {
      await request(app)
        .post('/api/v1/tasks')
        .send({ title: 'Test' })
        .expect(401);
    });
  });
  
  describe('GET /api/v1/tasks', () => {
    it('should return user tasks', async () => {
      const response = await request(app)
        .get('/api/v1/tasks')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      expect(Array.isArray(response.body)).toBe(true);
    });
    
    it('should filter tasks by status', async () => {
      const response = await request(app)
        .get('/api/v1/tasks?status=todo')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      response.body.forEach((task: Task) => {
        expect(task.status).toBe('todo');
      });
    });
  });
});
```

### 8.5 Security Testing

```typescript
// security.test.ts
import request from 'supertest';
import { app } from '../app';

describe('Security Tests', () => {
  describe('Input Sanitization', () => {
    it('should sanitize XSS attempts in task title', async () => {
      const xssAttempt = '<script>alert("xss")</script>Task';
      const token = await getTestToken();
      
      const response = await request(app)
        .post('/api/v1/tasks')
        .set('Authorization', `Bearer ${token}`)
        .send({ title: xssAttempt, status: 'todo' });
      
      expect(response.body.title).not.toContain('<script>');
    });
    
    it('should reject SQL injection patterns', async () => {
      const sqlInjection = "'; DROP TABLE tasks; --";
      const token = await getTestToken();
      
      await request(app)
        .get(`/api/v1/tasks?id=${sqlInjection}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(400);
    });
  });
  
  describe('Rate Limiting', () => {
    it('should block requests exceeding rate limit', async () => {
      const token = await getTestToken();
      
      // Make 101 requests (limit is 100)
      const requests = Array(101).fill(null).map(() =>
        request(app)
          .get('/api/v1/tasks')
          .set('Authorization', `Bearer ${token}`)
      );
      
      const responses = await Promise.all(requests);
      const rateLimited = responses.some(r => r.status === 429);
      
      expect(rateLimited).toBe(true);
    });
  });
  
  describe('Authentication', () => {
    it('should reject expired tokens', async () => {
      const expiredToken = generateExpiredToken();
      
      await request(app)
        .get('/api/v1/tasks')
        .set('Authorization', `Bearer ${expiredToken}`)
        .expect(401);
    });
    
    it('should reject tampered tokens', async () => {
      const tamperedToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.tampered.signature';
      
      await request(app)
        .get('/api/v1/tasks')
        .set('Authorization', `Bearer ${tamperedToken}`)
        .expect(401);
    });
  });
  
  describe('Authorization', () => {
    it('should prevent accessing other user data', async () => {
      const user1Token = await getTestToken('user1');
      const user2Task = await createTask('user2');
      
      await request(app)
        .get(`/api/v1/tasks/${user2Task.id}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .expect(403);
    });
  });
});
```

### 8.6 E2E Testing

```typescript
// e2e/dashboard.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Mission Control Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/login');
    await page.fill('[data-testid="email"]', 'test@example.com');
    await page.fill('[data-testid="password"]', 'password123');
    await page.click('[data-testid="login-button"]');
    await page.waitForURL('/dashboard');
  });
  
  test('should create and display a new task', async ({ page }) => {
    // Navigate to task board
    await page.click('[data-testid="task-board-nav"]');
    
    // Create new task
    await page.click('[data-testid="add-task-button"]');
    await page.fill('[data-testid="task-title"]', 'E2E Test Task');
    await page.fill('[data-testid="task-description"]', 'Created by E2E test');
    await page.selectOption('[data-testid="task-priority"]', 'high');
    await page.click('[data-testid="save-task-button"]');
    
    // Verify task appears
    await expect(page.locator('text=E2E Test Task')).toBeVisible();
  });
  
  test('should search memories', async ({ page }) => {
    await page.click('[data-testid="memories-nav"]');
    await page.fill('[data-testid="memory-search"]', 'test');
    await page.press('[data-testid="memory-search"]', 'Enter');
    
    // Verify search results
    await expect(page.locator('[data-testid="memory-list"]')).toBeVisible();
  });
  
  test('should handle AI agent interactions', async ({ page }) => {
    // Trigger AI action
    await page.click('[data-testid="ai-assistant-button"]');
    await page.fill('[data-testid="ai-input"]', 'Create a task for tomorrow');
    await page.click('[data-testid="ai-submit"]');
    
    // Wait for AI response
    await expect(page.locator('[data-testid="ai-response"]')).toBeVisible();
    
    // Verify undo option is available
    await expect(page.locator('[data-testid="undo-button"]')).toBeVisible();
  });
});
```

---

## 9. VULNERABILITY ASSESSMENT

### 9.1 Attack Surface Analysis

```
┌─────────────────────────────────────────────────────────────────┐
│                    ATTACK SURFACE MAP                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  EXTERNAL ATTACK VECTORS                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. Web Interface                                         │   │
│  │    - XSS via task descriptions, memories                │   │
│  │    - CSRF on state-changing operations                  │   │
│  │    - Clickjacking on sensitive actions                  │   │
│  │                                                          │   │
│  │ 2. API Endpoints                                         │   │
│  │    - Injection attacks (SQL, NoSQL, Command)            │   │
│  │    - Broken authentication                              │   │
│  │    - Mass assignment vulnerabilities                    │   │
│  │    - Insecure direct object references                  │   │
│  │                                                          │   │
│  │ 3. File Uploads                                          │   │
│  │    - Malware upload                                     │   │
│  │    - Path traversal                                     │   │
│  │    - DoS via large files                                │   │
│  │                                                          │   │
│  │ 4. AI Agent Interface                                    │   │
│  │    - Prompt injection                                   │   │
│  │    - Unauthorized data access                           │   │
│  │    - Resource exhaustion                                │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  INTERNAL ATTACK VECTORS                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 5. Data Storage                                          │   │
│  │    - Unencrypted sensitive data                         │   │
│  │    - Weak access controls                               │   │
│  │    - Backup exposure                                    │   │
│  │                                                          │   │
│  │ 6. Authentication System                                 │   │
│  │    - Weak password policies                             │   │
│  │    - Session fixation                                   │   │
│  │    - Token theft/replay                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 9.2 Vulnerability Matrix

| ID | Vulnerability | Severity | Likelihood | Risk | Mitigation |
|----|---------------|----------|------------|------|------------|
| V1 | XSS via AI-generated content | High | Medium | High | DOMPurify, CSP headers |
| V2 | SQL/NoSQL injection | Critical | Low | High | Parameterized queries, ORM |
| V3 | Broken authentication | Critical | Low | High | JWT best practices, MFA |
| V4 | IDOR (Insecure Direct Object Reference) | High | Medium | High | Authorization checks |
| V5 | AI prompt injection | High | High | Critical | Input validation, sandboxing |
| V6 | Sensitive data exposure | Critical | Low | High | Encryption at rest/transit |
| V7 | Missing rate limiting | Medium | High | Medium | Implement rate limiter |
| V8 | CSRF attacks | Medium | Medium | Medium | CSRF tokens, SameSite cookies |
| V9 | Unrestricted file upload | High | Low | Medium | File validation, scanning |
| V10 | Security misconfiguration | Medium | Medium | Medium | Security headers, hardening |
| V11 | Insufficient logging | Medium | Medium | Medium | Comprehensive audit logging |
| V12 | AI agent privilege escalation | Critical | Low | High | Strict permission model |

### 9.3 OWASP Top 10 Mapping

| OWASP Category | Applicable | Mitigations |
|----------------|------------|-------------|
| A01: Broken Access Control | Yes | RBAC, authorization middleware, IDOR prevention |
| A02: Cryptographic Failures | Yes | AES-256-GCM, TLS 1.3, secure key management |
| A03: Injection | Yes | Parameterized queries, input validation, sanitization |
| A04: Insecure Design | Yes | Security by design, threat modeling |
| A05: Security Misconfiguration | Yes | Hardening guides, automated scanning |
| A06: Vulnerable Components | Yes | Dependency scanning, regular updates |
| A07: Auth Failures | Yes | JWT best practices, MFA, session management |
| A08: Data Integrity Failures | Yes | Signatures, checksums, audit logging |
| A09: Logging Failures | Yes | Comprehensive audit logging, monitoring |
| A10: SSRF | Partial | URL validation, network segmentation |

### 9.4 Security Controls Implementation

```typescript
// security-controls.ts

// Content Security Policy
export const cspConfig = {
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'", "'unsafe-inline'"],  // Review for production
    styleSrc: ["'self'", "'unsafe-inline'"],
    imgSrc: ["'self'", 'data:', 'blob:'],
    fontSrc: ["'self'"],
    connectSrc: ["'self'", process.env.API_URL],
    frameSrc: ["'none'"],
    objectSrc: ["'none'"],
    baseUri: ["'self'"],
    formAction: ["'self'"]
  }
};

// Security headers middleware
export const securityHeaders = (req: Request, res: Response, next: NextFunction): void => {
  // Prevent MIME type sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // Prevent clickjacking
  res.setHeader('X-Frame-Options', 'DENY');
  
  // XSS protection
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  // HSTS
  res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains; preload');
  
  // Referrer policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  // Permissions policy
  res.setHeader('Permissions-Policy', 
    'camera=(), microphone=(), geolocation=(), interest-cohort=()'
  );
  
  // CSP
  const cspString = Object.entries(cspConfig.directives)
    .map(([key, values]) => `${key} ${values.join(' ')}`)
    .join('; ');
  res.setHeader('Content-Security-Policy', cspString);
  
  next();
};

// Rate limiter configuration
export const rateLimiterConfig = {
  // General API rate limit
  api: {
    windowMs: 60 * 1000,  // 1 minute
    max: 100,  // requests per window
    message: 'Too many requests, please try again later',
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req: Request, res: Response) => {
      res.status(429).json({
        error: {
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'Too many requests',
          retryAfter: Math.ceil(60)  // seconds
        }
      });
    }
  },
  
  // Stricter limit for auth endpoints
  auth: {
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 5,  // 5 attempts
    skipSuccessfulRequests: true
  },
  
  // AI agent rate limit
  ai: {
    windowMs: 60 * 1000,
    max: 60,
    keyGenerator: (req: Request) => {
      return (req as AuthenticatedRequest).user?.sub || req.ip || 'unknown';
    }
  }
};

// CSRF protection
export const csrfConfig = {
  cookie: {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict'
  },
  value: (req: Request) => req.headers['x-csrf-token'] as string
};
```

### 9.5 Penetration Testing Checklist

| Category | Test Case | Tool/Method |
|----------|-----------|-------------|
| **Authentication** | Brute force protection | Burp Suite, custom scripts |
| | Session fixation | OWASP ZAP |
| | Token expiration | Manual testing |
| | Password reset flow | Manual testing |
| **Authorization** | Horizontal privilege escalation | Burp Suite |
| | Vertical privilege escalation | Custom scripts |
| | IDOR vulnerabilities | Burp Suite, manual |
| **Input Validation** | XSS payloads | XSStrike, manual |
| | SQL injection | SQLMap |
| | Command injection | Commix |
| | Path traversal | DotDotPwn |
| **API Security** | Mass assignment | Postman, Burp |
| | Parameter pollution | Manual testing |
| | HTTP method tampering | curl, Burp |
| **File Upload** | Malware upload | Custom payloads |
| | Path traversal in filenames | Manual testing |
| | MIME type bypass | Manual testing |
| **AI Security** | Prompt injection | Manual testing |
| | Context manipulation | Custom scripts |
| | Rate limit bypass | Custom scripts |

---

## 10. DEPLOYMENT SECURITY

### 10.1 Environment Configuration

```bash
# .env.example - Safe to commit (no secrets)
NODE_ENV=development
PORT=3000
API_URL=http://localhost:3000
CLIENT_URL=http://localhost:3001

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mission_control

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Logging
LOG_LEVEL=info
AUDIT_LOG_RETENTION_DAYS=90
```

```bash
# .env.local - NEVER COMMIT (contains secrets)
# Database
DB_USER=db_user
DB_PASSWORD=your_secure_password_here

# JWT
JWT_SECRET=your_256_bit_secret_key_here_min_32_chars
JWT_REFRESH_SECRET=your_refresh_token_secret_here

# Encryption
ENCRYPTION_KEY=your_64_char_hex_encryption_key
SEARCH_KEY=your_search_tokenization_key

# External Services
OPENAI_API_KEY=sk-...
SENDGRID_API_KEY=SG...

# Monitoring
SENTRY_DSN=https://...
```

### 10.2 Docker Security

```dockerfile
# Dockerfile
FROM node:18-alpine AS builder

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy source
COPY --chown=nodejs:nodejs . .

# Build
RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Security: Run as non-root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

WORKDIR /app

# Copy only necessary files
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Read-only filesystem
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

EXPOSE 3000

CMD ["node", "dist/app.js"]
```

```yaml
# docker-compose.security.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    read_only: true
    user: "1001:1001"
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    environment:
      - NODE_ENV=production
    networks:
      - backend
    depends_on:
      - db
      - redis

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - backend
    security_opt:
      - no-new-privileges:true

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    networks:
      - backend
    security_opt:
      - no-new-privileges:true

networks:
  backend:
    internal: true  # No external access

volumes:
  postgres_data:
```

---

## 11. INCIDENT RESPONSE

### 11.1 Security Incident Classification

| Severity | Description | Response Time | Examples |
|----------|-------------|---------------|----------|
| Critical | System compromise, data breach | 15 minutes | Unauthorized admin access, ransomware |
| High | Active attack in progress | 1 hour | Brute force attack, AI agent escape |
| Medium | Security policy violation | 4 hours | Unauthorized data access, policy bypass |
| Low | Minor security concern | 24 hours | Failed login attempts, suspicious activity |

### 11.2 Incident Response Playbook

```
┌─────────────────────────────────────────────────────────────────┐
│              SECURITY INCIDENT RESPONSE FLOW                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. DETECTION                                                   │
│     ├── Automated alerts (monitoring, SIEM)                    │
│     ├── User reports                                            │
│     └── Security testing findings                               │
│                        │                                        │
│                        ▼                                        │
│  2. ASSESSMENT                                                  │
│     ├── Classify severity                                       │
│     ├── Identify affected systems                               │
│     ├── Determine impact scope                                  │
│     └── Preserve evidence                                       │
│                        │                                        │
│                        ▼                                        │
│  3. CONTAINMENT                                                 │
│     ├── Isolate affected systems                                │
│     ├── Revoke compromised credentials                          │
│     ├── Block malicious IPs                                     │
│     └── Disable compromised AI agents                           │
│                        │                                        │
│                        ▼                                        │
│  4. ERADICATION                                                 │
│     ├── Remove malware/backdoors                                │
│     ├── Patch vulnerabilities                                   │
│     ├── Reset passwords/tokens                                  │
│     └── Update security controls                                │
│                        │                                        │
│                        ▼                                        │
│  5. RECOVERY                                                    │
│     ├── Restore from clean backups                              │
│     ├── Verify system integrity                                 │
│     ├── Resume operations                                       │
│     └── Monitor for recurrence                                  │
│                        │                                        │
│                        ▼                                        │
│  6. POST-INCIDENT                                               │
│     ├── Document lessons learned                                │
│     ├── Update security policies                                │
│     ├── Implement preventive measures                           │
│     └── Conduct security review                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 12. COMPLIANCE CONSIDERATIONS

### 12.1 Data Privacy Requirements

| Regulation | Key Requirements | Implementation |
|------------|------------------|----------------|
| GDPR | Consent, right to deletion, data portability | User consent flows, data export, deletion APIs |
| CCPA | Disclosure, opt-out, deletion | Privacy policy, opt-out mechanisms |
| HIPAA | PHI protection, audit logs | Encryption, access controls, audit logging |

### 12.2 Data Retention Policy

| Data Type | Retention Period | Deletion Method |
|-----------|------------------|-----------------|
| User accounts | Until deletion + 30 days | Soft delete, then purge |
| Task data | Until project deletion + 90 days | Cascading delete |
| Memories | User-configurable, max 5 years | User-initiated or scheduled |
| Documents | Until deletion + 1 year | Secure wipe |
| Audit logs | 1 year (compliance) | Archive then delete |
| AI interaction logs | 90 days | Automatic purge |

---

## SUMMARY

This security and quality guide provides comprehensive coverage for securing the Mission Control Dashboard:

### Critical Security Requirements
1. **Authentication**: JWT with short-lived tokens, MFA for admins
2. **Authorization**: RBAC with 4 roles, permission matrix
3. **AI Security**: Sandboxed environment, explicit allow-list, rate limiting
4. **Data Protection**: AES-256-GCM encryption, TLS 1.3, field-level encryption
5. **Input Validation**: Zod schemas, DOMPurify sanitization
6. **Audit Logging**: Comprehensive event logging, 24-hour undo window
7. **Rate Limiting**: 100 req/min general, 60 req/min for AI

### Code Quality Standards
1. **TypeScript**: Strict mode, explicit return types
2. **Linting**: ESLint with security plugins
3. **Testing**: 80% unit, 15% integration, 5% E2E coverage
4. **Error Handling**: Custom error classes, async handler wrapper

### Key Files to Implement
- `auth.middleware.ts` - JWT verification
- `ai-sandbox.service.ts` - AI permission enforcement
- `encryption.service.ts` - Data encryption
- `audit-logger.service.ts` - Activity logging
- `validation.schemas.ts` - Input validation

---

*Document Version: 1.0*
*Last Updated: 2024*
*Classification: Internal Use*
