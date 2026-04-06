import { 
  sqliteTable, 
  text, 
  integer,
  real,
} from 'drizzle-orm/sqlite-core';

// ==================== TASKS ====================
export const tasks = sqliteTable('tasks', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  description: text('description').notNull(),
  status: text('status').notNull(),
  priority: text('priority').notNull(),
  assigneeId: text('assignee_id').notNull(),
  assigneeType: text('assignee_type').notNull(),
  assigneeName: text('assignee_name').notNull(),
  projectId: text('project_id'),
  tags: text('tags', { mode: 'json' }).$type<string[]>().default([]),
  dueDate: integer('due_date', { mode: 'timestamp' }),
  estimatedHours: real('estimated_hours'),
  subtasks: text('subtasks', { mode: 'json' }).$type<string[]>().default([]),
  metadata: text('metadata', { mode: 'json' }).default({}),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull(),
});

// ==================== PROJECTS ====================
export const projects = sqliteTable('projects', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  description: text('description').notNull(),
  status: text('status').notNull(),
  progress: integer('progress').notNull().default(0),
  color: text('color').notNull().default('#3b82f6'),
  startDate: integer('start_date', { mode: 'timestamp' }),
  targetDate: integer('target_date', { mode: 'timestamp' }),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull(),
});

// ==================== MEMORIES ====================
export const memories = sqliteTable('memories', {
  id: text('id').primaryKey(),
  content: text('content').notNull(),
  type: text('type').notNull(),
  date: integer('date', { mode: 'timestamp' }).notNull(),
  tags: text('tags', { mode: 'json' }).$type<string[]>().default([]),
  importance: integer('importance').notNull().default(5),
  projectId: text('project_id'),
  taskId: text('task_id'),
  agentId: text('agent_id'),
  embedding: text('embedding'), // For vector search
  source: text('source').notNull(),
  relatedMemories: text('related_memories', { mode: 'json' }).$type<string[]>().default([]),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});

// ==================== DOCUMENTS ====================
export const documents = sqliteTable('documents', {
  id: text('id').primaryKey(),
  title: text('title').notNull(),
  content: text('content').notNull(),
  category: text('category').notNull(),
  tags: text('tags', { mode: 'json' }).$type<string[]>().default([]),
  projectId: text('project_id'),
  createdBy: text('created_by').notNull(),
  updatedBy: text('updated_by').notNull(),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
  updatedAt: integer('updated_at', { mode: 'timestamp' }).notNull(),
  version: integer('version').notNull().default(1),
  isArchived: integer('is_archived', { mode: 'boolean' }).default(false),
});

// ==================== AGENTS ====================
export const agents = sqliteTable('agents', {
  id: text('id').primaryKey(),
  name: text('name').notNull(),
  role: text('role').notNull(),
  avatar: text('avatar'),
  status: text('status').notNull().default('idle'),
  currentTaskId: text('current_task_id'),
  deviceType: text('device_type'),
  deviceOs: text('device_os'),
  capabilities: text('capabilities', { mode: 'json' }).$type<string[]>().default([]),
  tasksCompleted: integer('tasks_completed').default(0),
  avgCompletionTime: real('avg_completion_time'),
  successRate: real('success_rate'),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});

// ==================== ACTIVITIES ====================
export const activities = sqliteTable('activities', {
  id: text('id').primaryKey(),
  type: text('type').notNull(),
  actorId: text('actor_id').notNull(),
  actorType: text('actor_type').notNull(),
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

// Types
export type Task = typeof tasks.$inferSelect;
export type NewTask = typeof tasks.$inferInsert;
export type Project = typeof projects.$inferSelect;
export type NewProject = typeof projects.$inferInsert;
export type Memory = typeof memories.$inferSelect;
export type NewMemory = typeof memories.$inferInsert;
export type Document = typeof documents.$inferSelect;
export type NewDocument = typeof documents.$inferInsert;
export type Agent = typeof agents.$inferSelect;
export type NewAgent = typeof agents.$inferInsert;
export type Activity = typeof activities.$inferSelect;
export type NewActivity = typeof activities.$inferInsert;
export type ScheduledJob = typeof scheduledJobs.$inferSelect;
export type NewScheduledJob = typeof scheduledJobs.$inferInsert;
