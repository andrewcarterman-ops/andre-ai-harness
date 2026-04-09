/**
 * Parallel Agent Orchestrator
 * Thread pool with dynamic scaling for parallel task execution
 * 
 * @module ParallelOrchestrator
 * @version 1.0.0
 */

import { EventEmitter } from 'events';

export interface Task<T> {
  id: string;
  type: string;
  params: Record<string, unknown>;
  priority?: number;
  timeout?: number;
  dependencies?: string[];
}

export interface TaskResult<T> {
  taskId: string;
  success: boolean;
  data?: T;
  error?: Error;
  executionTime: number;
  workerId: number;
}

export interface TaskNode extends Task<unknown> {
  children?: TaskNode[];
}

export interface PoolStatus {
  totalWorkers: number;
  activeWorkers: number;
  idleWorkers: number;
  queueLength: number;
  completedTasks: number;
  failedTasks: number;
  averageExecutionTime: number;
  utilization: number;
}

export interface OrchestratorConfig {
  minWorkers: number;
  maxWorkers: number;
  scaling: {
    strategy: 'adaptive' | 'fixed';
    thresholdUp: number;
    thresholdDown: number;
  };
  taskTypes: Record<string, {
    priority: 'high' | 'medium' | 'low';
    timeout: number;
  }>;
}

class Worker {
  id: number;
  active: boolean;
  currentTask: string | null;
  totalTasks: number;

  constructor(id: number) {
    this.id = id;
    this.active = false;
    this.currentTask = null;
    this.totalTasks = 0;
  }
}

export class ParallelOrchestrator extends EventEmitter {
  private config: OrchestratorConfig;
  private workers: Worker[];
  private taskQueue: Task<unknown>[];
  private results: Map<string, TaskResult<unknown>>;
  private running: boolean;
  private scaleInterval: NodeJS.Timeout | null;

  constructor(config: OrchestratorConfig) {
    super();
    this.config = config;
    this.workers = [];
    this.taskQueue = [];
    this.results = new Map();
    this.running = false;
    this.scaleInterval = null;

    // Initialize minimum workers
    this.scaleWorkers(config.minWorkers);
  }

  /**
   * Start the orchestrator
   */
  start(): void {
    if (this.running) return;
    
    this.running = true;
    this.emit('started');

    // Start adaptive scaling if configured
    if (this.config.scaling.strategy === 'adaptive') {
      this.scaleInterval = setInterval(() => {
        this.adaptiveScale();
      }, 5000); // Check every 5 seconds
    }

    // Process queue
    this.processQueue();
  }

  /**
   * Stop the orchestrator
   */
  stop(): void {
    this.running = false;
    
    if (this.scaleInterval) {
      clearInterval(this.scaleInterval);
      this.scaleInterval = null;
    }

    this.emit('stopped');
  }

  /**
   * Submit single task
   */
  async submit<T>(task: Task<T>): Promise<TaskResult<T>> {
    return new Promise((resolve, reject) => {
      const wrappedTask = {
        ...task,
        _resolve: resolve as (result: TaskResult<unknown>) => void,
        _reject: reject,
      };

      this.taskQueue.push(wrappedTask);
      this.taskQueue.sort((a, b) => (b.priority || 0) - (a.priority || 0));
      
      this.emit('task:queued', task);
      this.processQueue();
    });
  }

  /**
   * Submit multiple tasks
   */
  async submitAll<T>(tasks: Task<T>[]): Promise<TaskResult<T>[]> {
    const promises = tasks.map(task => this.submit(task));
    return Promise.all(promises);
  }

  /**
   * Submit tasks with dependencies
   */
  async submitGraph(tasks: TaskNode[]): Promise<Map<string, TaskResult<unknown>>> {
    const results = new Map<string, TaskResult<unknown>>();
    const completed = new Set<string>();
    const inProgress = new Map<string, Promise<void>>();

    const executeTask = async (task: TaskNode): Promise<void> => {
      // Wait for dependencies
      if (task.dependencies) {
        await Promise.all(
          task.dependencies.map(depId => inProgress.get(depId))
        );
      }

      // Execute task
      const result = await this.submit(task);
      results.set(task.id, result);
      completed.add(task.id);

      // Execute children
      if (task.children) {
        await Promise.all(task.children.map(child => executeTask(child)));
      }
    };

    // Start all root tasks
    await Promise.all(tasks.map(task => {
      const promise = executeTask(task);
      inProgress.set(task.id, promise);
      return promise;
    }));

    return results;
  }

  /**
   * Get pool status
   */
  getStatus(): PoolStatus {
    const activeWorkers = this.workers.filter(w => w.active).length;
    const idleWorkers = this.workers.length - activeWorkers;
    const completedResults = Array.from(this.results.values());
    
    const totalExecutionTime = completedResults.reduce(
      (sum, r) => sum + r.executionTime, 0
    );

    return {
      totalWorkers: this.workers.length,
      activeWorkers,
      idleWorkers,
      queueLength: this.taskQueue.length,
      completedTasks: completedResults.filter(r => r.success).length,
      failedTasks: completedResults.filter(r => !r.success).length,
      averageExecutionTime: completedResults.length > 0 
        ? totalExecutionTime / completedResults.length 
        : 0,
      utilization: this.workers.length > 0 
        ? activeWorkers / this.workers.length 
        : 0,
    };
  }

  /**
   * Scale worker pool
   */
  private scaleWorkers(targetCount: number): void {
    const currentCount = this.workers.length;

    if (targetCount > currentCount) {
      // Add workers
      for (let i = currentCount; i < targetCount; i++) {
        this.workers.push(new Worker(i));
        this.emit('worker:added', i);
      }
    } else if (targetCount < currentCount) {
      // Remove idle workers
      const toRemove = currentCount - targetCount;
      const idleWorkers = this.workers.filter(w => !w.active);
      
      for (let i = 0; i < Math.min(toRemove, idleWorkers.length); i++) {
        const worker = idleWorkers[i];
        this.workers = this.workers.filter(w => w.id !== worker.id);
        this.emit('worker:removed', worker.id);
      }
    }
  }

  /**
   * Adaptive scaling based on utilization
   */
  private adaptiveScale(): void {
    const status = this.getStatus();
    const { thresholdUp, thresholdDown } = this.config.scaling;

    if (status.utilization > thresholdUp && status.totalWorkers < this.config.maxWorkers) {
      // Scale up
      const newCount = Math.min(
        status.totalWorkers + 2,
        this.config.maxWorkers
      );
      this.scaleWorkers(newCount);
      this.emit('scaled:up', newCount);
    } else if (status.utilization < thresholdDown && status.totalWorkers > this.config.minWorkers) {
      // Scale down
      const newCount = Math.max(
        status.totalWorkers - 1,
        this.config.minWorkers
      );
      this.scaleWorkers(newCount);
      this.emit('scaled:down', newCount);
    }
  }

  /**
   * Process task queue
   */
  private async processQueue(): Promise<void> {
    if (!this.running) return;

    while (this.taskQueue.length > 0) {
      // Find idle worker
      const idleWorker = this.workers.find(w => !w.active);
      
      if (!idleWorker) {
        // No idle workers available
        if (this.workers.length < this.config.maxWorkers) {
          // Try to scale up
          this.scaleWorkers(this.workers.length + 1);
          continue;
        }
        // Wait and retry
        await new Promise(resolve => setTimeout(resolve, 100));
        continue;
      }

      // Get next task
      const task = this.taskQueue.shift();
      if (!task) continue;

      // Execute task
      this.executeTask(task, idleWorker);
    }

    // Schedule next check
    if (this.running) {
      setTimeout(() => this.processQueue(), 100);
    }
  }

  /**
   * Execute single task
   */
  private async executeTask(
    task: Task<unknown> & { _resolve?: (result: TaskResult<unknown>) => void; _reject?: (error: Error) => void },
    worker: Worker
  ): Promise<void> {
    worker.active = true;
    worker.currentTask = task.id;
    
    const startTime = Date.now();
    
    try {
      this.emit('task:started', task, worker.id);

      // Get timeout for task type
      const taskType = this.config.taskTypes[task.type];
      const timeout = task.timeout || taskType?.timeout || 30000;

      // Execute with timeout
      const data = await Promise.race([
        this.runTask(task),
        new Promise<never>((_, reject) => 
          setTimeout(() => reject(new Error('Task timeout')), timeout)
        ),
      ]);

      const executionTime = Date.now() - startTime;
      
      const result: TaskResult<unknown> = {
        taskId: task.id,
        success: true,
        data,
        executionTime,
        workerId: worker.id,
      };

      this.results.set(task.id, result);
      worker.totalTasks++;
      
      this.emit('task:completed', result);
      task._resolve?.(result);

    } catch (error) {
      const executionTime = Date.now() - startTime;
      
      const result: TaskResult<unknown> = {
        taskId: task.id,
        success: false,
        error: error instanceof Error ? error : new Error(String(error)),
        executionTime,
        workerId: worker.id,
      };

      this.results.set(task.id, result);
      
      this.emit('task:failed', result);
      task._reject?.(result.error);
    } finally {
      worker.active = false;
      worker.currentTask = null;
    }
  }

  /**
   * Run actual task logic
   */
  private async runTask(task: Task<unknown>): Promise<unknown> {
    // This would dispatch to actual task handlers
    // For now, simulating with delay
    await new Promise(resolve => setTimeout(resolve, 100));
    
    return {
      taskId: task.id,
      type: task.type,
      params: task.params,
    };
  }
}

export default ParallelOrchestrator;
