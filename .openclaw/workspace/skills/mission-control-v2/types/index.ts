// types/index.ts - Complete TypeScript Interfaces from original files
// Adapted with Linear-style dark theme

// ==================== TASK SYSTEM ====================

export type TaskStatus = 'backlog' | 'todo' | 'in_progress' | 'review' | 'done';
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
  scheduledAt?: Date;
  cronExpression?: string;
  estimatedHours?: number;
  actualHours?: number;
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;
  parentTaskId?: string;
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
  progress: number;
  startDate?: Date;
  targetDate?: Date;
  completedDate?: Date;
  taskCount: {
    total: number;
    completed: number;
  };
  linkedMemories: string[];
  linkedDocs: string[];
  color: string;
  createdAt: Date;
  updatedAt: Date;
}

// ==================== MEMORY SYSTEM ====================

export type MemoryType = 'observation' | 'action' | 'decision' | 'conversation' | 'insight';

export interface Memory {
  id: string;
  content: string;
  type: MemoryType;
  date: Date;
  tags: string[];
  importance: number;
  projectId?: string;
  taskId?: string;
  agentId?: string;
  embedding?: number[];
  source: string;
  relatedMemories: string[];
}

export interface MemoryDay {
  date: string;
  memories: Memory[];
  summary?: string;
}

// ==================== DOCUMENT SYSTEM ====================

export type DocCategory = 
  | 'requirements' 
  | 'architecture' 
  | 'api' 
  | 'guide' 
  | 'meeting' 
  | 'research' 
  | 'other';

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
  isEncrypted: boolean;
  allowSearch: boolean;
}

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

export type ActivityType = 
  | 'task_created'
  | 'task_updated'
  | 'task_completed'
  | 'task_moved'
  | 'task_assigned'
  | 'project_created'
  | 'project_updated'
  | 'project_completed'
  | 'doc_created'
  | 'doc_updated'
  | 'memory_created'
  | 'agent_action'
  | 'system_event';

export interface Activity {
  id: string;
  type: ActivityType;
  actor: Assignee;
  targetType: 'task' | 'project' | 'doc' | 'memory' | 'system';
  targetId: string;
  targetName: string;
  action: string;
  metadata?: Record<string, any>;
  timestamp: Date;
}

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

// ==================== API RESPONSES ====================

export interface ApiResponse<T> {
  data?: T;
  error?: string;
}

export interface TaskResult {
  success: boolean;
  output: string;
  error?: string;
  data?: Record<string, any>;
}

// ==================== CALENDAR ====================

export interface CalendarEvent {
  id: string;
  title: string;
  description?: string;
  startDate: Date;
  endDate?: Date;
  type: 'task' | 'cron' | 'meeting' | 'reminder';
  taskId?: string;
  recurrence?: 'daily' | 'weekly' | 'monthly';
}
