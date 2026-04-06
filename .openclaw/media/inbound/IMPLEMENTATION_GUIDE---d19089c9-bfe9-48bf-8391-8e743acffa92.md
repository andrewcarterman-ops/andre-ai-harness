# Mission Control Dashboard - Implementation Guide

## Table of Contents
1. [Project Structure](#1-project-structure)
2. [Data Models](#2-data-models)
3. [State Management](#3-state-management)
4. [Database Schema](#4-database-schema)
5. [API Routes](#5-api-routes)
6. [Component Architecture](#6-component-architecture)
7. [Code Examples](#7-code-examples)
8. [AI Integration](#8-ai-integration)

---

## 1. Project Structure

```
mission-control/
├── app/                          # Next.js 14 App Router
│   ├── (dashboard)/              # Dashboard layout group
│   │   ├── layout.tsx            # Dashboard shell with sidebar
│   │   ├── page.tsx              # Overview/Dashboard home
│   │   ├── tasks/
│   │   │   ├── page.tsx          # Task Board (Kanban)
│   │   │   └── loading.tsx
│   │   ├── calendar/
│   │   │   └── page.tsx          # Calendar view
│   │   ├── projects/
│   │   │   ├── page.tsx          # Projects list
│   │   │   └── [id]/
│   │   │       └── page.tsx      # Project detail
│   │   ├── memories/
│   │   │   └── page.tsx          # Memory viewer
│   │   ├── docs/
│   │   │   ├── page.tsx          # Document repository
│   │   │   └── [id]/
│   │   │       └── page.tsx      # Document viewer
│   │   ├── team/
│   │   │   └── page.tsx          # Team/Agents view
│   │   └── office/
│   │       └── page.tsx          # 2D Office visualization
│   ├── api/                      # API Routes
│   │   ├── tasks/
│   │   │   ├── route.ts          # GET, POST tasks
│   │   │   └── [id]/
│   │   │       └── route.ts      # GET, PATCH, DELETE task
│   │   ├── projects/
│   │   ├── memories/
│   │   ├── docs/
│   │   ├── agents/
│   │   ├── activities/
│   │   ├── schedule/
│   │   └── realtime/
│   │       └── route.ts          # Server-Sent Events
│   ├── layout.tsx                # Root layout
│   └── globals.css
├── components/                   # React Components
│   ├── ui/                       # shadcn/ui components
│   ├── kanban/                   # Kanban board components
│   ├── calendar/                 # Calendar components
│   ├── office/                   # 2D visualization components
│   ├── layout/                   # Layout components
│   └── shared/                   # Shared utilities
├── hooks/                        # Custom React hooks
│   ├── useRealtime.ts
│   ├── useDragAndDrop.ts
│   └── useSearch.ts
├── lib/                          # Utilities & Config
│   ├── db/                       # Database connection
│   │   ├── index.ts
│   │   ├── schema.ts
│   │   └── migrations/
│   ├── ai/                       # AI integration
│   │   ├── agent.ts
│   │   └── tasks.ts
│   ├── utils.ts
│   └── constants.ts
├── stores/                       # Zustand stores
│   ├── taskStore.ts
│   ├── projectStore.ts
│   ├── memoryStore.ts
│   └── uiStore.ts
├── types/                        # TypeScript types
│   └── index.ts
├── public/                       # Static assets
│   └── sprites/                  # Pixel art assets
└── scripts/                      # Utility scripts
    └── seed-db.ts
```

---

## 2. Data Models

### Core TypeScript Interfaces

```typescript
// types/index.ts

// ==================== TASK SYSTEM ====================

export type TaskStatus = 'backlog' | 'in_progress' | 'review' | 'done';
export type TaskPriority = 'low' | 'medium' | 'high' | 'urgent';
export type AssigneeType = 'user' | 'ai';

export interface Task {
  id: string;
  title: string;
  description: string;
  status: TaskStatus;
  priority: TaskPriority;
  assignee: Assignee;
  projectId?: string;
  tags: string[];
  dueDate?: Date;
  scheduledAt?: Date;           // For cron/scheduled tasks
  cronExpression?: string;      // Recurring task pattern
  estimatedHours?: number;
  actualHours?: number;
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;
  parentTaskId?: string;        // For subtasks
  subtasks: string[];
  metadata: Record<string, any>;
}

export interface Assignee {
  id: string;
  type: AssigneeType;
  name: string;
  avatar?: string;
}

// ==================== PROJECT SYSTEM ====================

export type ProjectStatus = 'planning' | 'active' | 'paused' | 'completed' | 'archived';

export interface Project {
  id: string;
  name: string;
  description: string;
  status: ProjectStatus;
  progress: number;             // 0-100
  startDate?: Date;
  targetDate?: Date;
  completedDate?: Date;
  taskCount: {
    total: number;
    completed: number;
  };
  linkedMemories: string[];     // Memory IDs
  linkedDocs: string[];         // Document IDs
  color: string;                // Theme color
  createdAt: Date;
  updatedAt: Date;
}

// ==================== MEMORY SYSTEM ====================

export interface Memory {
  id: string;
  content: string;
  type: 'observation' | 'action' | 'decision' | 'conversation' | 'insight';
  date: Date;
  tags: string[];
  importance: number;           // 1-10 for long-term storage
  projectId?: string;
  taskId?: string;
  agentId?: string;
  embedding?: number[];         // For semantic search
  source: string;               // Origin of memory
  relatedMemories: string[];    // Linked memory IDs
}

export interface MemoryDay {
  date: string;                 // YYYY-MM-DD
  memories: Memory[];
  summary?: string;             // AI-generated daily summary
}

// ==================== DOCUMENT SYSTEM ====================

export interface Doc {
  id: string;
  title: string;
  content: string;
  category: DocCategory;
  tags: string[];
  projectId?: string;
  createdBy: string;
  updatedBy: string;
  createdAt: Date;
  updatedAt: Date;
  version: number;
  isArchived: boolean;
  searchIndex: string;          // For full-text search
}

export type DocCategory = 
  | 'requirements' 
  | 'architecture' 
  | 'api' 
  | 'guide' 
  | 'meeting' 
  | 'research' 
  | 'other';

// ==================== AGENT/TEAM SYSTEM ====================

export type AgentStatus = 'idle' | 'working' | 'paused' | 'offline';

export interface Agent {
  id: string;
  name: string;
  role: string;
  avatar: string;
  status: AgentStatus;
  currentTask?: string;
  deviceInfo?: {
    type: string;
    os: string;
    lastSeen: Date;
  };
  capabilities: string[];
  performance: {
    tasksCompleted: number;
    avgCompletionTime: number;
    successRate: number;
  };
  officePosition?: {
    x: number;
    y: number;
  };
  createdAt: Date;
}

export interface Team {
  id: string;
  name: string;
  mission: string;
  agents: Agent[];
  hierarchy: TeamNode[];
}

export interface TeamNode {
  agentId: string;
  reportsTo?: string;
  role: string;
}

// ==================== ACTIVITY SYSTEM ====================

export interface Activity {
  id: string;
  type: ActivityType;
  actor: Assignee;
  targetType: 'task' | 'project' | 'doc' | 'memory' | 'system';
  targetId: string;
  targetName: string;
  action: string;
  metadata: Record<string, any>;
  timestamp: Date;
}

export type ActivityType = 
  | 'task_created'
  | 'task_updated'
  | 'task_completed'
  | 'task_assigned'
  | 'task_moved'
  | 'project_created'
  | 'project_updated'
  | 'doc_created'
  | 'doc_updated'
  | 'memory_created'
  | 'agent_action'
  | 'system_event';

// ==================== SCHEDULE SYSTEM ====================

export interface ScheduledJob {
  id: string;
  name: string;
  cronExpression: string;
  taskTemplate: Partial<Task>;
  isActive: boolean;
  lastRun?: Date;
  nextRun?: Date;
  runCount: number;
  createdAt: Date;
}

// ==================== OFFICE/VISUALIZATION ====================

export interface OfficeState {
  width: number;
  height: number;
  gridSize: number;
  agents: OfficeAgent[];
  furniture: Furniture[];
}

export interface OfficeAgent {
  agentId: string;
  position: { x: number; y: number };
  targetPosition?: { x: number; y: number };
  direction: 'up' | 'down' | 'left' | 'right';
  isMoving: boolean;
  currentDeskId?: string;
}

export interface Furniture {
  id: string;
  type: 'desk' | 'chair' | 'plant' | 'whiteboard' | 'door';
  position: { x: number; y: number };
  size: { width: number; height: number };
  assignedAgentId?: string;
}
```

---

## 3. State Management

### Zustand Store Architecture

```typescript
// stores/taskStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import { Task, TaskStatus, Activity } from '@/types';

interface TaskState {
  // State
  tasks: Task[];
  columns: Record<TaskStatus, string[]>; // task IDs by column
  isLoading: boolean;
  error: string | null;
  selectedTask: Task | null;
  
  // Actions
  fetchTasks: () => Promise<void>;
  createTask: (task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'>) => Promise<Task>;
  updateTask: (id: string, updates: Partial<Task>) => Promise<void>;
  deleteTask: (id: string) => Promise<void>;
  moveTask: (taskId: string, from: TaskStatus, to: TaskStatus) => Promise<void>;
  setSelectedTask: (task: Task | null) => void;
  
  // AI Integration
  getAITasks: () => Task[];
  claimNextAITask: () => Task | null;
}

export const useTaskStore = create<TaskState>()(
  immer(
    persist(
      (set, get) => ({
        tasks: [],
        columns: {
          backlog: [],
          in_progress: [],
          review: [],
          done: [],
        },
        isLoading: false,
        error: null,
        selectedTask: null,

        fetchTasks: async () => {
          set({ isLoading: true });
          try {
            const res = await fetch('/api/tasks');
            const tasks = await res.json();
            
            // Organize by columns
            const columns: Record<TaskStatus, string[]> = {
              backlog: [],
              in_progress: [],
              review: [],
              done: [],
            };
            
            tasks.forEach((task: Task) => {
              columns[task.status].push(task.id);
            });
            
            set({ tasks, columns, isLoading: false });
          } catch (error) {
            set({ error: 'Failed to fetch tasks', isLoading: false });
          }
        },

        createTask: async (taskData) => {
          const res = await fetch('/api/tasks', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(taskData),
          });
          const newTask = await res.json();
          
          set((state) => {
            state.tasks.push(newTask);
            state.columns[newTask.status].push(newTask.id);
          });
          
          return newTask;
        },

        updateTask: async (id, updates) => {
          const res = await fetch(`/api/tasks/${id}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(updates),
          });
          const updated = await res.json();
          
          set((state) => {
            const index = state.tasks.findIndex((t) => t.id === id);
            if (index !== -1) {
              // Handle status change
              if (updates.status && updates.status !== state.tasks[index].status) {
                const oldStatus = state.tasks[index].status;
                state.columns[oldStatus] = state.columns[oldStatus].filter(
                  (tid) => tid !== id
                );
                state.columns[updates.status].push(id);
              }
              state.tasks[index] = { ...state.tasks[index], ...updated };
            }
          });
        },

        moveTask: async (taskId, from, to) => {
          // Optimistic update
          set((state) => {
            state.columns[from] = state.columns[from].filter((id) => id !== taskId);
            state.columns[to].push(taskId);
            const task = state.tasks.find((t) => t.id === taskId);
            if (task) task.status = to;
          });

          // API call
          await fetch(`/api/tasks/${taskId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: to }),
          });
        },

        getAITasks: () => {
          return get().tasks.filter(
            (t) => t.assignee.type === 'ai' && t.status !== 'done'
          );
        },

        claimNextAITask: () => {
          const aiTasks = get().tasks.filter(
            (t) => t.assignee.type === 'ai' && t.status === 'backlog'
          );
          return aiTasks.length > 0 ? aiTasks[0] : null;
        },

        setSelectedTask: (task) => set({ selectedTask: task }),
      }),
      {
        name: 'task-store',
        partialize: (state) => ({ tasks: state.tasks, columns: state.columns }),
      }
    )
  )
);
```

```typescript
// stores/activityStore.ts - Real-time activity feed
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { Activity } from '@/types';

interface ActivityState {
  activities: Activity[];
  unreadCount: number;
  isConnected: boolean;
  
  addActivity: (activity: Activity) => void;
  markAsRead: () => void;
  connect: () => void;
  disconnect: () => void;
}

export const useActivityStore = create<ActivityState>()(
  immer((set, get) => ({
    activities: [],
    unreadCount: 0,
    isConnected: false,

    addActivity: (activity) => {
      set((state) => {
        state.activities.unshift(activity);
        if (state.activities.length > 100) {
          state.activities.pop();
        }
        state.unreadCount++;
      });
    },

    markAsRead: () => set({ unreadCount: 0 }),
    connect: () => set({ isConnected: true }),
    disconnect: () => set({ isConnected: false }),
  }))
);
```

```typescript
// stores/officeStore.ts - 2D office state
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { OfficeState, OfficeAgent } from '@/types';

interface OfficeStore extends OfficeState {
  updateAgentPosition: (agentId: string, position: { x: number; y: number }) => void;
  moveAgentToDesk: (agentId: string, deskId: string) => void;
  setAgentMoving: (agentId: string, isMoving: boolean) => void;
}

export const useOfficeStore = create<OfficeStore>()(
  immer((set) => ({
    width: 800,
    height: 600,
    gridSize: 32,
    agents: [],
    furniture: [],

    updateAgentPosition: (agentId, position) => {
      set((state) => {
        const agent = state.agents.find((a) => a.agentId === agentId);
        if (agent) {
          agent.position = position;
        }
      });
    },

    moveAgentToDesk: (agentId, deskId) => {
      set((state) => {
        const desk = state.furniture.find((f) => f.id === deskId);
        const agent = state.agents.find((a) => a.agentId === agentId);
        if (desk && agent) {
          agent.targetPosition = desk.position;
          agent.currentDeskId = deskId;
          agent.isMoving = true;
        }
      });
    },

    setAgentMoving: (agentId, isMoving) => {
      set((state) => {
        const agent = state.agents.find((a) => a.agentId === agentId);
        if (agent) agent.isMoving = isMoving;
      });
    },
  }))
);
```

---

## 4. Database Schema

### SQLite with Drizzle ORM

```typescript
// lib/db/schema.ts
import { 
  sqliteTable, 
  text, 
  integer, 
  real, 
  blob,
  primaryKey 
} from 'drizzle-orm/sqlite-core';
import { relations } from 'drizzle-orm';

// ==================== TASKS ====================
export const tasks = sqliteTable('tasks', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  description: text('description').notNull(),
  status: text('status').notNull().$type<'backlog' | 'in_progress' | 'review' | 'done'>(),
  priority: text('priority').notNull().$type<'low' | 'medium' | 'high' | 'urgent'>(),
  assigneeId: text('assignee_id').notNull(),
  assigneeType: text('assignee_type').notNull().$type<'user' | 'ai'>(),
  assigneeName: text('assignee_name').notNull(),
  projectId: text('project_id').references(() => projects.id),
  tags: text('tags', { mode: 'json' }).$type<string[]>().default([]),
  dueDate: integer('due_date', { mode: 'timestamp' }),
  scheduledAt: integer('scheduled_at', { mode: 'timestamp' }),
  cronExpression: text('cron_expression'),
  estimatedHours: real('estimated_hours'),
  actualHours: real('actual_hours'),
  parentTaskId: text('parent_task_id'),
  subtasks: text('subtasks', { mode: 'json' }).$type<string[]>().default([]),
  metadata: text('metadata', { mode: 'json' }).default({}),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull(),
  completedAt: integer('completed_at', { mode: 'timestamp' }),
});

// ==================== PROJECTS ====================
export const projects = sqliteTable('projects', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  description: text('description').notNull(),
  status: text('status').notNull().$type<'planning' | 'active' | 'paused' | 'completed' | 'archived'>(),
  progress: integer('progress').notNull().default(0),
  startDate: integer('start_date', { mode: 'timestamp' }),
  targetDate: integer('target_date', { mode: 'timestamp' }),
  completedDate: integer('completed_date', { mode: 'timestamp' }),
  color: text('color').notNull().default('#3b82f6'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull(),
});

// ==================== MEMORIES ====================
export const memories = sqliteTable('memories', {
  id: text('id').primaryKey(),
  content: text('content').notNull(),
  type: text('type').notNull().$type<'observation' | 'action' | 'decision' | 'conversation' | 'insight'>(),
  date: integer('date', { mode: 'timestamp' }).notNull(),
  tags: text('tags', { mode: 'json' }).$type<string[]>().default([]),
  importance: integer('importance').notNull().default(5),
  projectId: text('project_id').references(() => projects.id),
  taskId: text('task_id').references(() => tasks.id),
  agentId: text('agent_id').references(() => agents.id),
  embedding: blob('embedding'), // For vector search
  source: text('source').notNull(),
  relatedMemories: text('related_memories', { mode: 'json' }).$type<string[]>().default([]),
});

// ==================== DOCUMENTS ====================
export const docs = sqliteTable('docs', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  content: text('content').notNull(),
  category: text('category').notNull().$type<'requirements' | 'architecture' | 'api' | 'guide' | 'meeting' | 'research' | 'other'>(),
  tags: text('tags', { mode: 'json' }).$type<string[]>().default([]),
  projectId: text('project_id').references(() => projects.id),
  createdBy: text('created_by').notNull(),
  updatedBy: text('updated_by').notNull(),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull(),
  version: integer('version').notNull().default(1),
  isArchived: integer('is_archived', { mode: 'boolean' }).default(false),
  searchIndex: text('search_index').notNull(), // FTS5 virtual table reference
});

// ==================== AGENTS ====================
export const agents = sqliteTable('agents', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  role: text('role').notNull(),
  avatar: text('avatar'),
  status: text('status').notNull().$type<'idle' | 'working' | 'paused' | 'offline'>(),
  currentTaskId: text('current_task_id').references(() => tasks.id),
  deviceType: text('device_type'),
  deviceOs: text('device_os'),
  deviceLastSeen: integer('device_last_seen', { mode: 'timestamp' }),
  capabilities: text('capabilities', { mode: 'json' }).$type<string[]>().default([]),
  tasksCompleted: integer('tasks_completed').default(0),
  avgCompletionTime: real('avg_completion_time'),
  successRate: real('success_rate'),
  officeX: integer('office_x'),
  officeY: integer('office_y'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});

// ==================== ACTIVITIES ====================
export const activities = sqliteTable('activities', {
  id: text('id').primaryKey(),
  type: text('type').notNull(),
  actorId: text('actor_id').notNull(),
  actorType: text('actor_type').notNull().$type<'user' | 'ai'>(),
  actorName: text('actor_name').notNull(),
  targetType: text('target_type').notNull(),
  targetId: text('target_id').notNull(),
  targetName: text('target_name').notNull(),
  action: text('action').notNull(),
  metadata: text('metadata', { mode: 'json' }).default({}),
  timestamp: integer('timestamp', { mode: 'timestamp' }).notNull(),
});

// ==================== SCHEDULED JOBS ====================
export const scheduledJobs = sqliteTable('scheduled_jobs', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  cronExpression: text('cron_expression').notNull(),
  taskTemplate: text('task_template', { mode: 'json' }).notNull(),
  isActive: integer('is_active', { mode: 'boolean' }).default(true),
  lastRun: integer('last_run', { mode: 'timestamp' }),
  nextRun: integer('next_run', { mode: 'timestamp' }),
  runCount: integer('run_count').default(0),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});

// ==================== RELATIONS ====================
export const projectsRelations = relations(projects, ({ many }) => ({
  tasks: many(tasks),
  memories: many(memories),
  docs: many(docs),
}));

export const tasksRelations = relations(tasks, ({ one, many }) => ({
  project: one(projects, {
    fields: [tasks.projectId],
    references: [projects.id],
  }),
  memories: many(memories),
}));
```

### Full-Text Search Setup (FTS5)

```sql
-- migrations/002_add_fts.sql
-- Create FTS5 virtual table for document search
CREATE VIRTUAL TABLE docs_fts USING fts5(
  title,
  content,
  content_rowid,
  content='docs'
);

-- Create triggers to keep FTS index in sync
CREATE TRIGGER docs_ai AFTER INSERT ON docs BEGIN
  INSERT INTO docs_fts(rowid, title, content)
  VALUES (new.rowid, new.title, new.content);
END;

CREATE TRIGGER docs_ad AFTER DELETE ON docs BEGIN
  INSERT INTO docs_fts(docs_fts, rowid, title, content)
  VALUES ('delete', old.rowid, old.title, old.content);
END;

CREATE TRIGGER docs_au AFTER UPDATE ON docs BEGIN
  INSERT INTO docs_fts(docs_fts, rowid, title, content)
  VALUES ('delete', old.rowid, old.title, old.content);
  INSERT INTO docs_fts(rowid, title, content)
  VALUES (new.rowid, new.title, new.content);
END;
```

---

## 5. API Routes

```typescript
// app/api/tasks/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { tasks } from '@/lib/db/schema';
import { eq, desc, and } from 'drizzle-orm';
import { nanoid } from 'nanoid';

// GET /api/tasks - List all tasks
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const status = searchParams.get('status');
  const assignee = searchParams.get('assignee');
  const projectId = searchParams.get('projectId');

  let query = db.select().from(tasks);
  
  const conditions = [];
  if (status) conditions.push(eq(tasks.status, status));
  if (assignee) conditions.push(eq(tasks.assigneeId, assignee));
  if (projectId) conditions.push(eq(tasks.projectId, projectId));
  
  if (conditions.length > 0) {
    query = query.where(and(...conditions));
  }

  const result = await query.orderBy(desc(tasks.createdAt));
  return NextResponse.json(result);
}

// POST /api/tasks - Create new task
export async function POST(request: NextRequest) {
  const body = await request.json();
  
  const newTask = {
    id: nanoid(),
    ...body,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  await db.insert(tasks).values(newTask);
  
  // Broadcast activity
  await broadcastActivity({
    type: 'task_created',
    actor: body.assignee,
    targetType: 'task',
    targetId: newTask.id,
    targetName: body.title,
    action: 'created',
  });

  return NextResponse.json(newTask, { status: 201 });
}
```

```typescript
// app/api/realtime/route.ts - Server-Sent Events
import { NextRequest } from 'next/server';

const clients = new Map<string, ReadableStreamDefaultController>();

export async function GET(request: NextRequest) {
  const clientId = crypto.randomUUID();
  
  const stream = new ReadableStream({
    start(controller) {
      clients.set(clientId, controller);
      
      // Send initial connection message
      controller.enqueue(
        `data: ${JSON.stringify({ type: 'connected', clientId })}\n\n`
      );
      
      // Heartbeat
      const heartbeat = setInterval(() => {
        controller.enqueue(`data: ${JSON.stringify({ type: 'ping' })}\n\n`);
      }, 30000);
      
      // Cleanup on close
      request.signal.addEventListener('abort', () => {
        clearInterval(heartbeat);
        clients.delete(clientId);
      });
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}

// Helper function to broadcast to all clients
export function broadcastToClients(data: any) {
  const message = `data: ${JSON.stringify(data)}\n\n`;
  clients.forEach((controller) => {
    try {
      controller.enqueue(message);
    } catch (e) {
      // Client disconnected
    }
  });
}
```

```typescript
// app/api/memories/search/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { memories } from '@/lib/db/schema';
import { like, desc, gte, lte, sql } from 'drizzle-orm';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get('q');
  const dateFrom = searchParams.get('from');
  const dateTo = searchParams.get('to');
  const tags = searchParams.get('tags')?.split(',');

  let dbQuery = db.select().from(memories);
  const conditions = [];

  if (query) {
    // Full-text search using LIKE (or use FTS5 for better performance)
    conditions.push(
      like(memories.content, `%${query}%`)
    );
  }

  if (dateFrom) {
    conditions.push(gte(memories.date, new Date(dateFrom)));
  }

  if (dateTo) {
    conditions.push(lte(memories.date, new Date(dateTo)));
  }

  const results = await dbQuery
    .where(conditions.length > 0 ? sql.join(conditions, ' AND ') : undefined)
    .orderBy(desc(memories.date))
    .limit(100);

  // Group by date for day-organized view
  const grouped = results.reduce((acc, memory) => {
    const dateKey = memory.date.toISOString().split('T')[0];
    if (!acc[dateKey]) acc[dateKey] = [];
    acc[dateKey].push(memory);
    return acc;
  }, {} as Record<string, typeof results>);

  return NextResponse.json(grouped);
}
```

```typescript
// app/api/docs/search/route.ts - Full-text search
import { NextRequest, NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { sql } from 'drizzle-orm';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const query = searchParams.get('q');
  const category = searchParams.get('category');

  if (!query) {
    return NextResponse.json({ error: 'Query required' }, { status: 400 });
  }

  // Use FTS5 for full-text search
  const results = await db.all(sql`
    SELECT d.*, rank
    FROM docs_fts
    JOIN docs d ON docs_fts.rowid = d.rowid
    WHERE docs_fts MATCH ${query}
    ${category ? sql`AND d.category = ${category}` : sql``}
    ORDER BY rank
    LIMIT 50
  `);

  return NextResponse.json(results);
}
```

---

## 6. Component Architecture

### Key Component Hierarchy

```
DashboardLayout
├── Sidebar
│   ├── Navigation
│   ├── ActivityFeed (collapsible)
│   └── TeamStatus
├── Header
│   ├── SearchBar
│   ├── Notifications
│   └── UserMenu
└── MainContent (varies by route)

TaskBoardPage
├── KanbanBoard
│   ├── KanbanColumn (x4)
│   │   └── TaskCard (draggable)
│   │       ├── TaskHeader
│   │       ├── TaskMeta
│   │       └── TaskActions
│   └── DragOverlay
├── TaskDetailModal
└── CreateTaskButton

CalendarPage
├── CalendarHeader
│   ├── ViewToggle (Month/Week)
│   └── Navigation
├── CalendarGrid
│   └── CalendarCell
│       └── ScheduledTask
└── TaskScheduleModal

ProjectsPage
├── ProjectGrid
│   └── ProjectCard
│       ├── ProgressBar
│       ├── QuickStats
│       └── ActionLinks
└── CreateProjectModal

MemoriesPage
├── MemorySearch
├── MemoryDateNavigator
└── MemoryList
    └── MemoryDayGroup
        └── MemoryItem

DocsPage
├── DocSearchBar
├── DocFilterChips
├── ViewToggle (List/Grid)
└── DocList/DocGrid
    └── DocCard

TeamPage
├── MissionStatement
├── TeamHierarchy
│   └── TeamNode
└── AgentGrid
    └── AgentCard

OfficePage
├── OfficeCanvas (or CSS Grid)
│   ├── FurnitureLayer
│   │   └── Desk/Chair/etc
│   └── AgentLayer
│       └── AgentAvatar (animated)
└── OfficeControls
```

---

## 7. Code Examples

### 7.1 Kanban Board with Drag-and-Drop

```tsx
// components/kanban/KanbanBoard.tsx
'use client';

import { useEffect } from 'react';
import {
  DndContext,
  DragOverlay,
  closestCorners,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragStartEvent,
  DragOverEvent,
  DragEndEvent,
} from '@dnd-kit/core';
import {
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { useTaskStore } from '@/stores/taskStore';
import { TaskStatus } from '@/types';
import { KanbanColumn } from './KanbanColumn';
import { TaskCard } from './TaskCard';

const COLUMNS: TaskStatus[] = ['backlog', 'in_progress', 'review', 'done'];

export function KanbanBoard() {
  const { tasks, columns, fetchTasks, moveTask } = useTaskStore();
  const [activeId, setActiveId] = useState<string | null>(null);

  useEffect(() => {
    fetchTasks();
  }, []);

  const sensors = useSensors(
    useSensor(PointerSensor, {
      activationConstraint: { distance: 5 },
    }),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  );

  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string);
  };

  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveId(null);

    if (!over) return;

    const taskId = active.id as string;
    const overId = over.id as string;

    // Find which column the task was dropped in
    let targetColumn: TaskStatus | null = null;
    
    if (COLUMNS.includes(overId as TaskStatus)) {
      targetColumn = overId as TaskStatus;
    } else {
      // Dropped on another task - find its column
      for (const col of COLUMNS) {
        if (columns[col].includes(overId)) {
          targetColumn = col;
          break;
        }
      }
    }

    if (targetColumn) {
      const task = tasks.find((t) => t.id === taskId);
      if (task && task.status !== targetColumn) {
        await moveTask(taskId, task.status, targetColumn);
      }
    }
  };

  const activeTask = activeId ? tasks.find((t) => t.id === activeId) : null;

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCorners}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
    >
      <div className="flex gap-4 h-full overflow-x-auto p-4">
        {COLUMNS.map((status) => (
          <KanbanColumn
            key={status}
            status={status}
            taskIds={columns[status]}
            tasks={tasks.filter((t) => t.status === status)}
          />
        ))}
      </div>

      <DragOverlay>
        {activeTask ? <TaskCard task={activeTask} isDragging /> : null}
      </DragOverlay>
    </DndContext>
  );
}
```

```tsx
// components/kanban/KanbanColumn.tsx
'use client';

import { useDroppable } from '@dnd-kit/core';
import {
  SortableContext,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { Task, TaskStatus } from '@/types';
import { TaskCard } from './TaskCard';
import { cn } from '@/lib/utils';

const COLUMN_TITLES: Record<TaskStatus, string> = {
  backlog: 'Backlog',
  in_progress: 'In Progress',
  review: 'Review',
  done: 'Done',
};

const COLUMN_COLORS: Record<TaskStatus, string> = {
  backlog: 'bg-gray-100 border-gray-200',
  in_progress: 'bg-blue-50 border-blue-200',
  review: 'bg-yellow-50 border-yellow-200',
  done: 'bg-green-50 border-green-200',
};

interface KanbanColumnProps {
  status: TaskStatus;
  taskIds: string[];
  tasks: Task[];
}

export function KanbanColumn({ status, taskIds, tasks }: KanbanColumnProps) {
  const { setNodeRef, isOver } = useDroppable({ id: status });

  return (
    <div
      ref={setNodeRef}
      className={cn(
        'flex-shrink-0 w-80 rounded-lg border-2 p-3',
        COLUMN_COLORS[status],
        isOver && 'ring-2 ring-blue-400'
      )}
    >
      <div className="flex items-center justify-between mb-3">
        <h3 className="font-semibold text-gray-700">
          {COLUMN_TITLES[status]}
        </h3>
        <span className="bg-white px-2 py-1 rounded-full text-sm text-gray-500">
          {tasks.length}
        </span>
      </div>

      <SortableContext
        items={taskIds}
        strategy={verticalListSortingStrategy}
      >
        <div className="space-y-2 min-h-[100px]">
          {tasks.map((task) => (
            <TaskCard key={task.id} task={task} />
          ))}
        </div>
      </SortableContext>
    </div>
  );
}
```

```tsx
// components/kanban/TaskCard.tsx
'use client';

import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Task } from '@/types';
import { cn } from '@/lib/utils';
import { Calendar, Clock, User, Bot } from 'lucide-react';

interface TaskCardProps {
  task: Task;
  isDragging?: boolean;
}

export function TaskCard({ task, isDragging }: TaskCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging: isSortableDragging,
  } = useSortable({ id: task.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  const priorityColors = {
    low: 'bg-gray-200 text-gray-700',
    medium: 'bg-blue-200 text-blue-700',
    high: 'bg-orange-200 text-orange-700',
    urgent: 'bg-red-200 text-red-700',
  };

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      className={cn(
        'bg-white rounded-lg p-3 shadow-sm border cursor-grab',
        'hover:shadow-md transition-shadow',
        (isDragging || isSortableDragging) && 'opacity-50 rotate-2 shadow-lg'
      )}
    >
      <div className="flex items-start justify-between mb-2">
        <h4 className="font-medium text-gray-800 text-sm line-clamp-2">
          {task.title}
        </h4>
        <span className={cn('text-xs px-2 py-0.5 rounded-full', priorityColors[task.priority])}>
          {task.priority}
        </span>
      </div>

      <p className="text-gray-500 text-xs mb-3 line-clamp-2">
        {task.description}
      </p>

      <div className="flex items-center justify-between text-xs text-gray-400">
        <div className="flex items-center gap-2">
          {task.assignee.type === 'ai' ? (
            <Bot className="w-4 h-4 text-purple-500" />
          ) : (
            <User className="w-4 h-4 text-blue-500" />
          )}
          <span>{task.assignee.name}</span>
        </div>

        {task.dueDate && (
          <div className="flex items-center gap-1">
            <Calendar className="w-3 h-3" />
            <span>{new Date(task.dueDate).toLocaleDateString()}</span>
          </div>
        )}
      </div>

      {task.tags.length > 0 && (
        <div className="flex flex-wrap gap-1 mt-2">
          {task.tags.slice(0, 3).map((tag) => (
            <span
              key={tag}
              className="text-xs bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded"
            >
              {tag}
            </span>
          ))}
        </div>
      )}
    </div>
  );
}
```

### 7.2 Real-time Activity Feed

```tsx
// hooks/useRealtime.ts
'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useActivityStore } from '@/stores/activityStore';

export function useRealtime() {
  const eventSourceRef = useRef<EventSource | null>(null);
  const { addActivity, connect, disconnect } = useActivityStore();

  useEffect(() => {
    const connectSSE = () => {
      const es = new EventSource('/api/realtime');
      eventSourceRef.current = es;

      es.onopen = () => {
        connect();
        console.log('SSE connected');
      };

      es.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          
          if (data.type === 'activity') {
            addActivity(data.payload);
          }
        } catch (e) {
          console.error('Failed to parse SSE message:', e);
        }
      };

      es.onerror = () => {
        disconnect();
        es.close();
        // Reconnect after 3 seconds
        setTimeout(connectSSE, 3000);
      };
    };

    connectSSE();

    return () => {
      eventSourceRef.current?.close();
    };
  }, [addActivity, connect, disconnect]);

  return { isConnected: useActivityStore((s) => s.isConnected) };
}
```

```tsx
// components/ActivityFeed.tsx
'use client';

import { useRealtime } from '@/hooks/useRealtime';
import { useActivityStore } from '@/stores/activityStore';
import { cn } from '@/lib/utils';
import { 
  CheckCircle2, 
  Plus, 
  Edit3, 
  User, 
  Bot,
  Archive 
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const activityIcons = {
  task_created: Plus,
  task_completed: CheckCircle2,
  task_updated: Edit3,
  task_assigned: User,
  agent_action: Bot,
  system_event: Archive,
};

export function ActivityFeed() {
  useRealtime();
  const { activities, unreadCount, markAsRead } = useActivityStore();

  return (
    <div className="w-80 bg-white border-l h-full flex flex-col">
      <div className="p-4 border-b flex items-center justify-between">
        <h3 className="font-semibold">Activity Feed</h3>
        {unreadCount > 0 && (
          <button
            onClick={markAsRead}
            className="text-xs text-blue-500 hover:text-blue-600"
          >
            Mark all read ({unreadCount})
          </button>
        )}
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {activities.length === 0 ? (
          <p className="text-gray-400 text-center text-sm">No activity yet</p>
        ) : (
          activities.map((activity) => {
            const Icon = activityIcons[activity.type] || Archive;
            
            return (
              <div
                key={activity.id}
                className="flex gap-3 p-3 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors"
              >
                <div className={cn(
                  'w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0',
                  activity.actor.type === 'ai' ? 'bg-purple-100' : 'bg-blue-100'
                )}>
                  <Icon className="w-4 h-4" />
                </div>
                
                <div className="flex-1 min-w-0">
                  <p className="text-sm text-gray-800">
                    <span className="font-medium">{activity.actor.name}</span>
                    {' '}{activity.action}{' '}
                    <span className="font-medium">{activity.targetName}</span>
                  </p>
                  <p className="text-xs text-gray-400 mt-1">
                    {formatDistanceToNow(new Date(activity.timestamp), { addSuffix: true })}
                  </p>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
```

### 7.3 Calendar with Scheduled Tasks

```tsx
// components/calendar/Calendar.tsx
'use client';

import { useState, useMemo } from 'react';
import {
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  format,
  isSameMonth,
  isSameDay,
  addMonths,
  subMonths,
} from 'date-fns';
import { useTaskStore } from '@/stores/taskStore';
import { Task } from '@/types';
import { cn } from '@/lib/utils';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon } from 'lucide-react';

export function Calendar() {
  const [currentDate, setCurrentDate] = useState(new Date());
  const [view, setView] = useState<'month' | 'week'>('month');
  const { tasks } = useTaskStore();

  // Get scheduled tasks
  const scheduledTasks = useMemo(() => {
    return tasks.filter((t) => t.scheduledAt || t.dueDate);
  }, [tasks]);

  const calendarDays = useMemo(() => {
    const monthStart = startOfMonth(currentDate);
    const monthEnd = endOfMonth(monthStart);
    const calendarStart = startOfWeek(monthStart);
    const calendarEnd = endOfWeek(monthEnd);

    return eachDayOfInterval({ start: calendarStart, end: calendarEnd });
  }, [currentDate]);

  const getTasksForDay = (day: Date): Task[] => {
    return scheduledTasks.filter((task) => {
      const taskDate = task.scheduledAt || task.dueDate;
      return taskDate && isSameDay(new Date(taskDate), day);
    });
  };

  const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  return (
    <div className="bg-white rounded-lg shadow">
      {/* Header */}
      <div className="p-4 border-b flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h2 className="text-xl font-semibold">
            {format(currentDate, 'MMMM yyyy')}
          </h2>
          <div className="flex gap-1">
            <button
              onClick={() => setCurrentDate(subMonths(currentDate, 1))}
              className="p-1 hover:bg-gray-100 rounded"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <button
              onClick={() => setCurrentDate(new Date())}
              className="px-3 py-1 text-sm hover:bg-gray-100 rounded"
            >
              Today
            </button>
            <button
              onClick={() => setCurrentDate(addMonths(currentDate, 1))}
              className="p-1 hover:bg-gray-100 rounded"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>
        </div>

        <div className="flex gap-2">
          <button
            onClick={() => setView('month')}
            className={cn(
              'px-3 py-1 text-sm rounded',
              view === 'month' ? 'bg-blue-500 text-white' : 'hover:bg-gray-100'
            )}
          >
            Month
          </button>
          <button
            onClick={() => setView('week')}
            className={cn(
              'px-3 py-1 text-sm rounded',
              view === 'week' ? 'bg-blue-500 text-white' : 'hover:bg-gray-100'
            )}
          >
            Week
          </button>
        </div>
      </div>

      {/* Calendar Grid */}
      <div className="p-4">
        {/* Weekday headers */}
        <div className="grid grid-cols-7 gap-1 mb-2">
          {weekDays.map((day) => (
            <div key={day} className="text-center text-sm font-medium text-gray-500 py-2">
              {day}
            </div>
          ))}
        </div>

        {/* Days */}
        <div className="grid grid-cols-7 gap-1">
          {calendarDays.map((day) => {
            const dayTasks = getTasksForDay(day);
            const isCurrentMonth = isSameMonth(day, currentDate);
            const isToday = isSameDay(day, new Date());

            return (
              <div
                key={day.toISOString()}
                className={cn(
                  'min-h-[100px] p-2 border rounded-lg',
                  isCurrentMonth ? 'bg-white' : 'bg-gray-50',
                  isToday && 'ring-2 ring-blue-400'
                )}
              >
                <div className={cn(
                  'text-sm font-medium mb-1',
                  isToday ? 'text-blue-600' : 'text-gray-700',
                  !isCurrentMonth && 'text-gray-400'
                )}>
                  {format(day, 'd')}
                </div>

                <div className="space-y-1">
                  {dayTasks.slice(0, 3).map((task) => (
                    <div
                      key={task.id}
                      className={cn(
                        'text-xs px-2 py-1 rounded truncate cursor-pointer',
                        task.status === 'done' && 'bg-green-100 text-green-700',
                        task.status === 'in_progress' && 'bg-blue-100 text-blue-700',
                        task.status === 'review' && 'bg-yellow-100 text-yellow-700',
                        task.status === 'backlog' && 'bg-gray-100 text-gray-700'
                      )}
                    >
                      {task.title}
                    </div>
                  ))}
                  {dayTasks.length > 3 && (
                    <div className="text-xs text-gray-400 px-2">
                      +{dayTasks.length - 3} more
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Legend */}
      <div className="px-4 py-3 border-t flex gap-4 text-sm">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded bg-gray-100" />
          <span>Backlog</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded bg-blue-100" />
          <span>In Progress</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded bg-yellow-100" />
          <span>Review</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 rounded bg-green-100" />
          <span>Done</span>
        </div>
      </div>
    </div>
  );
}
```

### 7.4 Memory Search/Indexing

```tsx
// components/memories/MemoryViewer.tsx
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useDebounce } from '@/hooks/useDebounce';
import { Memory, MemoryDay } from '@/types';
import { format, parseISO } from 'date-fns';
import { Search, Calendar, Tag, ChevronDown, ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils';

export function MemoryViewer() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDate, setSelectedDate] = useState<string | null>(null);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [memories, setMemories] = useState<Record<string, Memory[]>>({});
  const [expandedDays, setExpandedDays] = useState<Set<string>>(new Set());
  const [isLoading, setIsLoading] = useState(false);

  const debouncedQuery = useDebounce(searchQuery, 300);

  const fetchMemories = useCallback(async () => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      if (debouncedQuery) params.append('q', debouncedQuery);
      if (selectedDate) {
        params.append('from', selectedDate);
        params.append('to', selectedDate);
      }

      const res = await fetch(`/api/memories/search?${params}`);
      const data = await res.json();
      setMemories(data);
    } finally {
      setIsLoading(false);
    }
  }, [debouncedQuery, selectedDate]);

  useEffect(() => {
    fetchMemories();
  }, [fetchMemories]);

  const toggleDay = (date: string) => {
    setExpandedDays((prev) => {
      const next = new Set(prev);
      if (next.has(date)) next.delete(date);
      else next.add(date);
      return next;
    });
  };

  const allTags = useCallback(() => {
    const tags = new Set<string>();
    Object.values(memories).flat().forEach((m) => {
      m.tags.forEach((t) => tags.add(t));
    });
    return Array.from(tags);
  }, [memories]);

  const filteredMemories = useCallback(() => {
    if (selectedTags.length === 0) return memories;
    
    const filtered: Record<string, Memory[]> = {};
    Object.entries(memories).forEach(([date, dayMemories]) => {
      const matching = dayMemories.filter((m) =>
        selectedTags.some((tag) => m.tags.includes(tag))
      );
      if (matching.length > 0) filtered[date] = matching;
    });
    return filtered;
  }, [memories, selectedTags]);

  const sortedDates = Object.keys(filteredMemories()).sort().reverse();

  return (
    <div className="flex h-full">
      {/* Sidebar */}
      <div className="w-64 border-r p-4 space-y-6">
        {/* Search */}
        <div>
          <label className="text-sm font-medium mb-2 block">Search</label>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search memories..."
              className="w-full pl-9 pr-3 py-2 border rounded-lg text-sm"
            />
          </div>
        </div>

        {/* Date Filter */}
        <div>
          <label className="text-sm font-medium mb-2 block">Date</label>
          <input
            type="date"
            value={selectedDate || ''}
            onChange={(e) => setSelectedDate(e.target.value || null)}
            className="w-full px-3 py-2 border rounded-lg text-sm"
          />
        </div>

        {/* Tags Filter */}
        <div>
          <label className="text-sm font-medium mb-2 block">Tags</label>
          <div className="flex flex-wrap gap-2">
            {allTags().map((tag) => (
              <button
                key={tag}
                onClick={() => {
                  setSelectedTags((prev) =>
                    prev.includes(tag)
                      ? prev.filter((t) => t !== tag)
                      : [...prev, tag]
                  );
                }}
                className={cn(
                  'text-xs px-2 py-1 rounded-full transition-colors',
                  selectedTags.includes(tag)
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                )}
              >
                {tag}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 overflow-y-auto p-6">
        {isLoading ? (
          <div className="text-center py-12 text-gray-400">Loading...</div>
        ) : sortedDates.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            No memories found
          </div>
        ) : (
          <div className="space-y-4">
            {sortedDates.map((date) => {
              const dayMemories = filteredMemories()[date];
              const isExpanded = expandedDays.has(date);

              return (
                <div key={date} className="border rounded-lg overflow-hidden">
                  <button
                    onClick={() => toggleDay(date)}
                    className="w-full px-4 py-3 bg-gray-50 flex items-center justify-between hover:bg-gray-100"
                  >
                    <div className="flex items-center gap-3">
                      {isExpanded ? (
                        <ChevronDown className="w-4 h-4" />
                      ) : (
                        <ChevronRight className="w-4 h-4" />
                      )}
                      <span className="font-medium">
                        {format(parseISO(date), 'EEEE, MMMM d, yyyy')}
                      </span>
                      <span className="text-sm text-gray-500">
                        ({dayMemories.length} memories)
                      </span>
                    </div>
                  </button>

                  {isExpanded && (
                    <div className="p-4 space-y-3">
                      {dayMemories.map((memory) => (
                        <MemoryItem key={memory.id} memory={memory} />
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}

function MemoryItem({ memory }: { memory: Memory }) {
  const typeColors = {
    observation: 'bg-blue-100 text-blue-700',
    action: 'bg-green-100 text-green-700',
    decision: 'bg-purple-100 text-purple-700',
    conversation: 'bg-yellow-100 text-yellow-700',
    insight: 'bg-pink-100 text-pink-700',
  };

  return (
    <div className="p-4 bg-white border rounded-lg hover:shadow-sm transition-shadow">
      <div className="flex items-start justify-between mb-2">
        <span className={cn('text-xs px-2 py-1 rounded-full', typeColors[memory.type])}>
          {memory.type}
        </span>
        <div className="flex items-center gap-1 text-yellow-500">
          {'★'.repeat(memory.importance)}
          {'☆'.repeat(10 - memory.importance)}
        </div>
      </div>

      <p className="text-gray-800 mb-3">{memory.content}</p>

      <div className="flex items-center justify-between text-sm">
        <div className="flex items-center gap-2">
          <Tag className="w-4 h-4 text-gray-400" />
          <div className="flex gap-1">
            {memory.tags.map((tag) => (
              <span key={tag} className="text-gray-500">
                #{tag}
              </span>
            ))}
          </div>
        </div>
        <span className="text-gray-400 text-xs">{memory.source}</span>
      </div>
    </div>
  );
}
```

### 7.5 Document Storage/Retrieval

```tsx
// components/docs/DocRepository.tsx
'use client';

import { useState, useEffect } from 'react';
import { Doc, DocCategory } from '@/types';
import { format } from 'date-fns';
import { 
  Search, 
  Grid, 
  List, 
  FileText, 
  Filter,
  Plus,
  MoreVertical 
} from 'lucide-react';
import { cn } from '@/lib/utils';

const CATEGORIES: { value: DocCategory; label: string; color: string }[] = [
  { value: 'requirements', label: 'Requirements', color: 'bg-blue-100 text-blue-700' },
  { value: 'architecture', label: 'Architecture', color: 'bg-purple-100 text-purple-700' },
  { value: 'api', label: 'API Docs', color: 'bg-green-100 text-green-700' },
  { value: 'guide', label: 'Guides', color: 'bg-yellow-100 text-yellow-700' },
  { value: 'meeting', label: 'Meetings', color: 'bg-pink-100 text-pink-700' },
  { value: 'research', label: 'Research', color: 'bg-orange-100 text-orange-700' },
  { value: 'other', label: 'Other', color: 'bg-gray-100 text-gray-700' },
];

export function DocRepository() {
  const [docs, setDocs] = useState<Doc[]>([]);
  const [view, setView] = useState<'grid' | 'list'>('grid');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<DocCategory | 'all'>('all');
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    fetchDocs();
  }, [searchQuery, selectedCategory]);

  const fetchDocs = async () => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      if (searchQuery) params.append('q', searchQuery);
      if (selectedCategory !== 'all') params.append('category', selectedCategory);

      const endpoint = searchQuery ? '/api/docs/search' : '/api/docs';
      const res = await fetch(`${endpoint}?${params}`);
      const data = await res.json();
      setDocs(data);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredDocs = docs.filter((doc) => {
    if (selectedCategory !== 'all' && doc.category !== selectedCategory) return false;
    return true;
  });

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="p-4 border-b flex items-center justify-between gap-4">
        <div className="flex-1 max-w-xl relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search documents..."
            className="w-full pl-10 pr-4 py-2 border rounded-lg"
          />
        </div>

        <div className="flex items-center gap-2">
          {/* Category Filter */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value as DocCategory | 'all')}
            className="px-3 py-2 border rounded-lg text-sm"
          >
            <option value="all">All Categories</option>
            {CATEGORIES.map((cat) => (
              <option key={cat.value} value={cat.value}>
                {cat.label}
              </option>
            ))}
          </select>

          {/* View Toggle */}
          <div className="flex border rounded-lg overflow-hidden">
            <button
              onClick={() => setView('grid')}
              className={cn(
                'p-2',
                view === 'grid' ? 'bg-blue-500 text-white' : 'hover:bg-gray-100'
              )}
            >
              <Grid className="w-4 h-4" />
            </button>
            <button
              onClick={() => setView('list')}
              className={cn(
                'p-2',
                view === 'list' ? 'bg-blue-500 text-white' : 'hover:bg-gray-100'
              )}
            >
              <List className="w-4 h-4" />
            </button>
          </div>

          <button className="flex items-center gap-2 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
            <Plus className="w-4 h-4" />
            New Doc
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4">
        {isLoading ? (
          <div className="text-center py-12 text-gray-400">Loading...</div>
        ) : filteredDocs.length === 0 ? (
          <div className="text-center py-12 text-gray-400">
            No documents found
          </div>
        ) : view === 'grid' ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
            {filteredDocs.map((doc) => (
              <DocCard key={doc.id} doc={doc} />
            ))}
          </div>
        ) : (
          <div className="space-y-2">
            {filteredDocs.map((doc) => (
              <DocListItem key={doc.id} doc={doc} />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function DocCard({ doc }: { doc: Doc }) {
  const category = CATEGORIES.find((c) => c.value === doc.category);

  return (
    <div className="bg-white border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer">
      <div className="flex items-start justify-between mb-3">
        <div className={cn('text-xs px-2 py-1 rounded-full', category?.color)}>
          {category?.label}
        </div>
        <button className="text-gray-400 hover:text-gray-600">
          <MoreVertical className="w-4 h-4" />
        </button>
      </div>

      <div className="flex items-center gap-3 mb-3">
        <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center">
          <FileText className="w-5 h-5 text-gray-500" />
        </div>
        <h3 className="font-medium line-clamp-2">{doc.title}</h3>
      </div>

      <p className="text-sm text-gray-500 line-clamp-2 mb-3">
        {doc.content.slice(0, 100)}...
      </p>

      <div className="flex items-center justify-between text-xs text-gray-400">
        <span>v{doc.version}</span>
        <span>{format(new Date(doc.updatedAt), 'MMM d, yyyy')}</span>
      </div>
    </div>
  );
}

function DocListItem({ doc }: { doc: Doc }) {
  const category = CATEGORIES.find((c) => c.value === doc.category);

  return (
    <div className="flex items-center gap-4 p-3 bg-white border rounded-lg hover:shadow-sm transition-shadow cursor-pointer">
      <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
        <FileText className="w-5 h-5 text-gray-500" />
      </div>

      <div className="flex-1 min-w-0">
        <h3 className="font-medium truncate">{doc.title}</h3>
        <p className="text-sm text-gray-500 truncate">{doc.content.slice(0, 80)}...</p>
      </div>

      <div className={cn('text-xs px-2 py-1 rounded-full', category?.color)}>
        {category?.label}
      </div>

      <div className="text-xs text-gray-400">
        v{doc.version} • {format(new Date(doc.updatedAt), 'MMM d, yyyy')}
      </div>
    </div>
  );
}
```

### 7.6 2D Office Visualization

```tsx
// components/office/OfficeCanvas.tsx
'use client';

import { useEffect, useRef, useCallback } from 'react';
import { useOfficeStore } from '@/stores/officeStore';
import { Agent, Furniture } from '@/types';

const GRID_SIZE = 32;
const CANVAS_WIDTH = 800;
const CANVAS_HEIGHT = 600;

interface OfficeCanvasProps {
  agents: Agent[];
  furniture: Furniture[];
}

export function OfficeCanvas({ agents, furniture }: OfficeCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animationRef = useRef<number>();
  const { updateAgentPosition, setAgentMoving } = useOfficeStore();

  // Initialize agent positions
  useEffect(() => {
    agents.forEach((agent) => {
      if (!agent.officePosition) {
        // Assign to random desk
        const desks = furniture.filter((f) => f.type === 'desk');
        const desk = desks[Math.floor(Math.random() * desks.length)];
        if (desk) {
          updateAgentPosition(agent.id, {
            x: desk.position.x,
            y: desk.position.y,
          });
        }
      }
    });
  }, [agents, furniture]);

  // Animation loop
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const animate = () => {
      // Clear canvas
      ctx.fillStyle = '#f3f4f6';
      ctx.fillRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);

      // Draw grid
      ctx.strokeStyle = '#e5e7eb';
      ctx.lineWidth = 1;
      for (let x = 0; x <= CANVAS_WIDTH; x += GRID_SIZE) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, CANVAS_HEIGHT);
        ctx.stroke();
      }
      for (let y = 0; y <= CANVAS_HEIGHT; y += GRID_SIZE) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(CANVAS_WIDTH, y);
        ctx.stroke();
      }

      // Draw furniture
      furniture.forEach((item) => {
        drawFurniture(ctx, item);
      });

      // Draw agents
      agents.forEach((agent) => {
        if (agent.officePosition) {
          drawAgent(ctx, agent, agent.officePosition);
        }
      });

      animationRef.current = requestAnimationFrame(animate);
    };

    animate();

    return () => {
      if (animationRef.current) {
        cancelAnimationFrame(animationRef.current);
      }
    };
  }, [agents, furniture]);

  const drawFurniture = (ctx: CanvasRenderingContext2D, item: Furniture) => {
    const x = item.position.x * GRID_SIZE;
    const y = item.position.y * GRID_SIZE;
    const w = item.size.width * GRID_SIZE;
    const h = item.size.height * GRID_SIZE;

    switch (item.type) {
      case 'desk':
        ctx.fillStyle = '#8b5cf6';
        ctx.fillRect(x, y, w, h);
        // Desk surface
        ctx.fillStyle = '#a78bfa';
        ctx.fillRect(x + 2, y + 2, w - 4, h - 4);
        break;
      case 'chair':
        ctx.fillStyle = '#6b7280';
        ctx.beginPath();
        ctx.arc(x + w / 2, y + h / 2, w / 2, 0, Math.PI * 2);
        ctx.fill();
        break;
      case 'plant':
        ctx.fillStyle = '#10b981';
        ctx.beginPath();
        ctx.arc(x + w / 2, y + h / 2, w / 2, 0, Math.PI * 2);
        ctx.fill();
        // Pot
        ctx.fillStyle = '#92400e';
        ctx.fillRect(x + w / 4, y + h / 2, w / 2, h / 2);
        break;
      case 'whiteboard':
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(x, y, w, h);
        ctx.strokeStyle = '#d1d5db';
        ctx.lineWidth = 2;
        ctx.strokeRect(x, y, w, h);
        break;
    }
  };

  const drawAgent = (
    ctx: CanvasRenderingContext2D,
    agent: Agent,
    position: { x: number; y: number }
  ) => {
    const x = position.x * GRID_SIZE + GRID_SIZE / 2;
    const y = position.y * GRID_SIZE + GRID_SIZE / 2;
    const radius = GRID_SIZE / 2 - 4;

    // Status indicator ring
    const statusColors = {
      idle: '#10b981',
      working: '#3b82f6',
      paused: '#f59e0b',
      offline: '#6b7280',
    };

    ctx.beginPath();
    ctx.arc(x, y, radius + 3, 0, Math.PI * 2);
    ctx.fillStyle = statusColors[agent.status];
    ctx.fill();

    // Agent body (pixel art style)
    ctx.fillStyle = '#1f2937';
    ctx.fillRect(x - radius + 4, y - radius + 4, radius * 2 - 8, radius * 2 - 8);

    // Eyes
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(x - 4, y - 4, 3, 3);
    ctx.fillRect(x + 1, y - 4, 3, 3);

    // Name label
    ctx.fillStyle = '#1f2937';
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(agent.name.slice(0, 8), x, y + radius + 12);
  };

  return (
    <div className="relative">
      <canvas
        ref={canvasRef}
        width={CANVAS_WIDTH}
        height={CANVAS_HEIGHT}
        className="border rounded-lg shadow-lg"
      />
      
      {/* Legend */}
      <div className="absolute bottom-4 left-4 bg-white/90 p-3 rounded-lg shadow">
        <h4 className="text-sm font-medium mb-2">Status</h4>
        <div className="space-y-1 text-xs">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-green-500" />
            <span>Idle</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-blue-500" />
            <span>Working</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-yellow-500" />
            <span>Paused</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full bg-gray-500" />
            <span>Offline</span>
          </div>
        </div>
      </div>
    </div>
  );
}
```

```tsx
// Alternative: CSS Grid-based Office (simpler, no canvas)
// components/office/OfficeGrid.tsx
'use client';

import { useOfficeStore } from '@/stores/officeStore';
import { Agent, Furniture } from '@/types';
import { cn } from '@/lib/utils';

const GRID_COLS = 25;
const GRID_ROWS = 19;

interface OfficeGridProps {
  agents: Agent[];
  furniture: Furniture[];
}

export function OfficeGrid({ agents, furniture }: OfficeGridProps) {
  const gridCells = Array.from({ length: GRID_ROWS * GRID_COLS }, (_, i) => i);

  const getCellContent = (row: number, col: number) => {
    // Check for furniture
    const furnitureItem = furniture.find(
      (f) => f.position.x === col && f.position.y === row
    );
    if (furnitureItem) {
      return <FurnitureCell item={furnitureItem} />;
    }

    // Check for agent
    const agent = agents.find(
      (a) => a.officePosition?.x === col && a.officePosition?.y === row
    );
    if (agent) {
      return <AgentCell agent={agent} />;
    }

    return null;
  };

  return (
    <div
      className="inline-grid gap-0.5 bg-gray-200 p-2 rounded-lg"
      style={{
        gridTemplateColumns: `repeat(${GRID_COLS}, 24px)`,
        gridTemplateRows: `repeat(${GRID_ROWS}, 24px)`,
      }}
    >
      {gridCells.map((i) => {
        const row = Math.floor(i / GRID_COLS);
        const col = i % GRID_COLS;
        const content = getCellContent(row, col);

        return (
          <div
            key={i}
            className={cn(
              'w-6 h-6 flex items-center justify-center',
              !content && 'bg-gray-50'
            )}
          >
            {content}
          </div>
        );
      })}
    </div>
  );
}

function FurnitureCell({ item }: { item: Furniture }) {
  const styles = {
    desk: 'bg-purple-400 rounded-sm',
    chair: 'bg-gray-400 rounded-full',
    plant: 'bg-green-500 rounded-full',
    whiteboard: 'bg-white border border-gray-300',
    door: 'bg-amber-600',
  };

  return (
    <div
      className={cn('w-full h-full', styles[item.type])}
      style={{
        gridColumn: `span ${item.size.width}`,
        gridRow: `span ${item.size.height}`,
      }}
      title={item.type}
    />
  );
}

function AgentCell({ agent }: { agent: Agent }) {
  const statusColors = {
    idle: 'bg-green-400',
    working: 'bg-blue-400',
    paused: 'bg-yellow-400',
    offline: 'bg-gray-400',
  };

  return (
    <div
      className={cn(
        'w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold text-white cursor-pointer hover:scale-110 transition-transform',
        statusColors[agent.status]
      )}
      title={`${agent.name} - ${agent.status}`}
    >
      {agent.name.charAt(0).toUpperCase()}
    </div>
  );
}
```

---

## 8. AI Integration

### AI Agent Service

```typescript
// lib/ai/agent.ts
import { Task, Activity, Memory } from '@/types';
import { useTaskStore } from '@/stores/taskStore';

interface AIAgentConfig {
  id: string;
  name: string;
  capabilities: string[];
  maxConcurrentTasks: number;
}

export class AIAgentService {
  private config: AIAgentConfig;
  private currentTasks: Map<string, Task> = new Map();

  constructor(config: AIAgentConfig) {
    this.config = config;
  }

  // Main loop - continuously check for tasks
  async start() {
    console.log(`AI Agent ${this.config.name} started`);
    
    setInterval(async () => {
      await this.checkAndExecuteTasks();
    }, 5000); // Check every 5 seconds
  }

  private async checkAndExecuteTasks() {
    // Get available tasks from store
    const store = useTaskStore.getState();
    const availableTasks = store.getAITasks().filter(
      (t) => t.status === 'backlog' && !this.currentTasks.has(t.id)
    );

    if (availableTasks.length === 0) return;

    // Claim next task
    const task = availableTasks[0];
    await this.claimTask(task);
  }

  private async claimTask(task: Task) {
    this.currentTasks.set(task.id, task);

    // Update task status
    const store = useTaskStore.getState();
    await store.updateTask(task.id, {
      status: 'in_progress',
      assignee: {
        id: this.config.id,
        type: 'ai',
        name: this.config.name,
      },
    });

    // Log activity
    await this.logActivity({
      type: 'task_assigned',
      actor: { id: this.config.id, type: 'ai', name: this.config.name },
      targetType: 'task',
      targetId: task.id,
      targetName: task.title,
      action: 'claimed',
    });

    // Execute task
    await this.executeTask(task);
  }

  private async executeTask(task: Task) {
    console.log(`AI executing task: ${task.title}`);

    try {
      // Simulate task execution (replace with actual AI logic)
      await this.simulateTaskExecution(task);

      // Mark as complete
      const store = useTaskStore.getState();
      await store.updateTask(task.id, {
        status: 'done',
        completedAt: new Date(),
      });

      // Create memory of completion
      await this.createMemory({
        content: `Completed task: ${task.title}. ${task.description}`,
        type: 'action',
        taskId: task.id,
        importance: 7,
      });

      // Log activity
      await this.logActivity({
        type: 'task_completed',
        actor: { id: this.config.id, type: 'ai', name: this.config.name },
        targetType: 'task',
        targetId: task.id,
        targetName: task.title,
        action: 'completed',
      });

    } catch (error) {
      console.error(`Task execution failed: ${task.title}`, error);
      
      // Move back to backlog
      const store = useTaskStore.getState();
      await store.updateTask(task.id, {
        status: 'backlog',
      });
    } finally {
      this.currentTasks.delete(task.id);
    }
  }

  private async simulateTaskExecution(task: Task): Promise<void> {
    // Simulate work time based on estimated hours
    const workTime = (task.estimatedHours || 1) * 1000; // 1 second per hour for demo
    await new Promise((resolve) => setTimeout(resolve, Math.min(workTime, 5000)));
  }

  private async logActivity(activity: Partial<Activity>) {
    await fetch('/api/activities', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(activity),
    });
  }

  private async createMemory(memory: Partial<Memory>) {
    await fetch('/api/memories', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...memory,
        agentId: this.config.id,
        date: new Date(),
        source: this.config.name,
      }),
    });
  }
}

// Initialize AI agent
export const aiAgent = new AIAgentService({
  id: 'ai-agent-1',
  name: 'Mission AI',
  capabilities: ['coding', 'research', 'documentation', 'analysis'],
  maxConcurrentTasks: 3,
});
```

### AI Task Handlers

```typescript
// lib/ai/taskHandlers.ts
import { Task } from '@/types';

interface TaskHandler {
  canHandle: (task: Task) => boolean;
  execute: (task: Task) => Promise<void>;
}

// Handler for code-related tasks
const codeHandler: TaskHandler = {
  canHandle: (task) => 
    task.tags.includes('coding') || 
    task.title.toLowerCase().includes('implement') ||
    task.title.toLowerCase().includes('fix'),
  
  execute: async (task) => {
    // Integrate with code generation API
    console.log(`Generating code for: ${task.title}`);
    // Call LLM API, generate code, create PR, etc.
  },
};

// Handler for documentation tasks
const docHandler: TaskHandler = {
  canHandle: (task) => 
    task.tags.includes('documentation') ||
    task.title.toLowerCase().includes('document') ||
    task.title.toLowerCase().includes('readme'),
  
  execute: async (task) => {
    console.log(`Creating documentation for: ${task.title}`);
    // Generate docs, update wiki, etc.
  },
};

// Handler for research tasks
const researchHandler: TaskHandler = {
  canHandle: (task) => 
    task.tags.includes('research') ||
    task.title.toLowerCase().includes('research') ||
    task.title.toLowerCase().includes('investigate'),
  
  execute: async (task) => {
    console.log(`Researching: ${task.title}`);
    // Search web, analyze data, compile findings
  },
};

export const taskHandlers: TaskHandler[] = [
  codeHandler,
  docHandler,
  researchHandler,
];

export function findHandler(task: Task): TaskHandler | null {
  return taskHandlers.find((h) => h.canHandle(task)) || null;
}
```

### AI Memory Integration

```typescript
// lib/ai/memoryIntegration.ts
import { Memory } from '@/types';

export class AIMemoryService {
  // Store a new memory
  async storeMemory(content: string, metadata: Partial<Memory>): Promise<Memory> {
    const memory: Memory = {
      id: crypto.randomUUID(),
      content,
      type: metadata.type || 'observation',
      date: new Date(),
      tags: metadata.tags || [],
      importance: metadata.importance || 5,
      projectId: metadata.projectId,
      taskId: metadata.taskId,
      agentId: metadata.agentId,
      source: metadata.source || 'ai-agent',
      relatedMemories: [],
    };

    await fetch('/api/memories', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(memory),
    });

    return memory;
  }

  // Search memories by content
  async searchMemories(query: string, limit: number = 10): Promise<Memory[]> {
    const res = await fetch(`/api/memories/search?q=${encodeURIComponent(query)}&limit=${limit}`);
    const grouped = await res.json();
    return Object.values(grouped).flat();
  }

  // Get memories for a specific date range
  async getMemoriesByDateRange(from: Date, to: Date): Promise<Memory[]> {
    const params = new URLSearchParams({
      from: from.toISOString(),
      to: to.toISOString(),
    });
    const res = await fetch(`/api/memories/search?${params}`);
    const grouped = await res.json();
    return Object.values(grouped).flat();
  }

  // Get recent memories for context
  async getRecentContext(hours: number = 24): Promise<string> {
    const from = new Date(Date.now() - hours * 60 * 60 * 1000);
    const memories = await this.getMemoriesByDateRange(from, new Date());
    
    return memories
      .sort((a, b) => b.date.getTime() - a.date.getTime())
      .map((m) => `[${m.type}] ${m.content}`)
      .join('\n');
  }

  // Link related memories
  async linkMemories(memoryId: string, relatedIds: string[]): Promise<void> {
    await fetch(`/api/memories/${memoryId}/link`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ relatedIds }),
    });
  }
}

export const aiMemory = new AIMemoryService();
```

---

## Installation & Setup

### 1. Initialize Project

```bash
# Create Next.js project with shadcn
echo "my-app" | npx shadcn@latest init --yes --template next --base-color slate

# Install dependencies
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
npm install zustand immer
npm install drizzle-orm better-sqlite3
npm install date-fns
npm install nanoid
npm install lucide-react
```

### 2. Database Setup

```bash
# Create drizzle config
# drizzle.config.ts
import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './lib/db/schema.ts',
  out: './lib/db/migrations',
  dialect: 'sqlite',
  dbCredentials: {
    url: './sqlite.db',
  },
});
```

```bash
# Generate and run migrations
npx drizzle-kit generate
npx drizzle-kit migrate
```

### 3. Environment Variables

```bash
# .env.local
DATABASE_URL=./sqlite.db
AI_API_KEY=your_ai_api_key
```

### 4. Start Development

```bash
npm run dev
```

---

## Summary

This implementation guide provides:

1. **Complete project structure** for a scalable Next.js 14 dashboard
2. **TypeScript interfaces** for all data models
3. **Zustand stores** with Immer for state management
4. **SQLite schema** with Drizzle ORM and FTS5 search
5. **RESTful API routes** with real-time SSE support
6. **Component architecture** for all 7 dashboard features
7. **Working code examples** for:
   - Drag-and-drop Kanban board
   - Real-time activity feed
   - Calendar with task scheduling
   - Memory search and day-organized view
   - Document repository with full-text search
   - 2D office visualization (Canvas & CSS Grid)
8. **AI integration patterns** for autonomous task execution

The architecture supports real-time updates, AI automation, and scales from prototype to production.
