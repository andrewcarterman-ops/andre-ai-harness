'use client';

import { Task, TaskResult, ActivityType } from '@/types';
import { useActivityStore } from '@/stores/activityStore';

interface AIAgentConfig {
  id: string;
  name: string;
  capabilities: string[];
  maxConcurrentTasks: number;
}

interface TaskHandler {
  canHandle: (task: Task) => boolean;
  execute: (task: Task) => Promise<TaskResult>;
}

export class AIAgentService {
  private config: AIAgentConfig;
  private currentTasks: Map<string, Task> = new Map();
  private handlers: TaskHandler[] = [];
  private isRunning: boolean = false;
  private pollInterval: number = 5000; // 5 seconds

  constructor(config: AIAgentConfig) {
    this.config = config;
    this.registerDefaultHandlers();
  }

  private registerDefaultHandlers() {
    // Handler for research tasks
    this.registerHandler({
      canHandle: (task) => 
        task.tags.includes('research') || 
        task.title.toLowerCase().includes('research') ||
        task.title.toLowerCase().includes('investigate'),
      execute: async (task) => {
        console.log(`🔍 Researching: ${task.title}`);
        await this.simulateWork(3000, 8000);
        return {
          success: true,
          output: `Research completed for "${task.title}". Found relevant information and compiled summary.`,
          data: { researchTime: Date.now() },
        };
      },
    });

    // Handler for code tasks
    this.registerHandler({
      canHandle: (task) => 
        task.tags.includes('coding') || 
        task.tags.includes('development') ||
        task.title.toLowerCase().includes('implement') ||
        task.title.toLowerCase().includes('fix') ||
        task.title.toLowerCase().includes('code'),
      execute: async (task) => {
        console.log(`💻 Coding: ${task.title}`);
        await this.simulateWork(5000, 15000);
        return {
          success: true,
          output: `Code implementation completed for "${task.title}". Changes have been applied.`,
          data: { linesOfCode: Math.floor(Math.random() * 100) + 20 },
        };
      },
    });

    // Handler for documentation
    this.registerHandler({
      canHandle: (task) => 
        task.tags.includes('documentation') ||
        task.title.toLowerCase().includes('document') ||
        task.title.toLowerCase().includes('readme') ||
        task.title.toLowerCase().includes('guide'),
      execute: async (task) => {
        console.log(`📝 Documenting: ${task.title}`);
        await this.simulateWork(2000, 6000);
        return {
          success: true,
          output: `Documentation created for "${task.title}". Document is now available in the docs section.`,
          data: { wordCount: Math.floor(Math.random() * 500) + 100 },
        };
      },
    });

    // Default handler for generic tasks
    this.registerHandler({
      canHandle: () => true,
      execute: async (task) => {
        console.log(`⚙️ Processing: ${task.title}`);
        await this.simulateWork(2000, 5000);
        return {
          success: true,
          output: `Task "${task.title}" has been completed successfully.`,
          data: {},
        };
      },
    });
  }

  registerHandler(handler: TaskHandler) {
    this.handlers.push(handler);
  }

  start() {
    if (this.isRunning) {
      console.log('AI Agent is already running');
      return;
    }

    this.isRunning = true;
    console.log(`🤖 AI Agent "${this.config.name}" started`);
    console.log(`   Capabilities: ${this.config.capabilities.join(', ')}`);

    // Start polling loop
    this.pollLoop();
  }

  stop() {
    this.isRunning = false;
    console.log(`🛑 AI Agent "${this.config.name}" stopped`);
  }

  private async pollLoop() {
    while (this.isRunning) {
      try {
        await this.checkAndExecuteTasks();
      } catch (error) {
        console.error('Error in poll loop:', error);
      }

      // Wait before next poll
      await new Promise((resolve) => setTimeout(resolve, this.pollInterval));
    }
  }

  private async checkAndExecuteTasks() {
    // Don't take more tasks if at capacity
    if (this.currentTasks.size >= this.config.maxConcurrentTasks) {
      return;
    }

    try {
      // Fetch tasks assigned to AI
      const res = await fetch('/api/tasks');
      const tasks: Task[] = await res.json();
      
      const availableTasks = tasks.filter(
        (t) => 
          t.assignee.type === 'ai' && 
          t.status === 'backlog' &&
          !this.currentTasks.has(t.id)
      );

      if (availableTasks.length === 0) return;

      // Take the next available task
      const task = availableTasks[0];
      await this.executeTask(task);
    } catch (error) {
      console.error('Failed to fetch tasks:', error);
    }
  }

  private async executeTask(task: Task) {
    // Add to current tasks
    this.currentTasks.set(task.id, task);

    console.log(`🤖 Starting task: ${task.title}`);

    try {
      // Move to in_progress
      await this.updateTaskStatus(task.id, 'in_progress');

      // Log activity
      this.logActivity({
        type: 'agent_action',
        action: 'started working on',
        targetName: task.title,
        actor: {
          id: this.config.id,
          type: 'ai',
          name: this.config.name,
        },
      });

      // Find appropriate handler
      const handler = this.handlers.find((h) => h.canHandle(task));
      
      if (!handler) {
        throw new Error('No handler found for task');
      }

      // Execute the task
      const result = await handler.execute(task);

      if (result.success) {
        // Mark as done
        await this.updateTaskStatus(task.id, 'done');
        
        // Log success
        this.logActivity({
          type: 'task_completed',
          action: 'completed',
          targetName: task.title,
          actor: {
            id: this.config.id,
            type: 'ai',
            name: this.config.name,
          },
          metadata: result.data,
        });

        console.log(`✅ Task completed: ${task.title}`);
        console.log(`   Output: ${result.output}`);
      } else {
        throw new Error(result.error || 'Task failed');
      }
    } catch (error) {
      console.error(`❌ Task failed: ${task.title}`, error);
      
      // Move back to backlog
      await this.updateTaskStatus(task.id, 'backlog');
      
      // Log failure
      this.logActivity({
        type: 'agent_action',
        action: 'failed to complete',
        targetName: task.title,
        actor: {
          id: this.config.id,
          type: 'ai',
          name: this.config.name,
        },
        metadata: { error: error instanceof Error ? error.message : 'Unknown error' },
      });
    } finally {
      // Remove from current tasks
      this.currentTasks.delete(task.id);
    }
  }

  private async updateTaskStatus(taskId: string, status: string) {
    await fetch(`/api/tasks/${taskId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    });
  }

  private async simulateWork(minMs: number, maxMs: number) {
    const duration = minMs + Math.random() * (maxMs - minMs);
    await new Promise((resolve) => setTimeout(resolve, duration));
  }

  private logActivity(activityData: {
    type: ActivityType;
    action: string;
    targetName: string;
    actor: { id: string; type: 'user' | 'ai'; name: string };
    metadata?: Record<string, any>;
  }) {
    // Add to activity store
    const { addActivity } = useActivityStore.getState();
    
    addActivity({
      id: crypto.randomUUID(),
      ...activityData,
      targetType: 'task',
      targetId: '',
      timestamp: new Date(),
    });
  }

  getStatus() {
    return {
      isRunning: this.isRunning,
      currentTasks: this.currentTasks.size,
      maxConcurrent: this.config.maxConcurrentTasks,
      handlers: this.handlers.length,
    };
  }
}

// Create singleton instance
export const aiAgent = new AIAgentService({
  id: 'ai-agent-1',
  name: 'Mission AI',
  capabilities: ['research', 'coding', 'documentation', 'analysis'],
  maxConcurrentTasks: 3,
});
