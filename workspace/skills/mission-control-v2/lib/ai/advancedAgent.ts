// lib/ai/advancedAgent.ts - Advanced AI Agent with Web Search, Code Gen, and Circuit Breaker

import { Task, TaskResult } from '@/types';

// DB Task format (flat structure)
interface DBTask {
  id: string;
  title: string;
  description: string;
  status: string;
  priority: string;
  assigneeId: string;
  assigneeType: string;
  assigneeName: string;
  projectId: string | null;
  tags: any;
  dueDate: Date | null;
  estimatedHours: number | null;
  subtasks: any;
  metadata: any;
  createdAt: Date;
  updatedAt: Date;
}

interface CircuitBreakerState {
  failures: number;
  lastFailureTime: number | null;
  state: 'CLOSED' | 'OPEN' | 'HALF_OPEN';
}

interface TaskHandler {
  name: string;
  canHandle: (task: any) => boolean;
  execute: (task: any) => Promise<TaskResult>;
}

class CircuitBreaker {
  private state: CircuitBreakerState = {
    failures: 0,
    lastFailureTime: null,
    state: 'CLOSED',
  };
  
  private readonly failureThreshold = 5;
  private readonly resetTimeout = 60000; // 1 minute
  private readonly halfOpenMaxCalls = 3;
  private halfOpenCalls = 0;

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state.state === 'OPEN') {
      if (Date.now() - (this.state.lastFailureTime || 0) > this.resetTimeout) {
        this.state.state = 'HALF_OPEN';
        this.halfOpenCalls = 0;
        console.log('Circuit breaker entering HALF_OPEN state');
      } else {
        throw new Error('Circuit breaker is OPEN - service temporarily unavailable');
      }
    }

    if (this.state.state === 'HALF_OPEN' && this.halfOpenCalls >= this.halfOpenMaxCalls) {
      throw new Error('Circuit breaker HALF_OPEN - max calls reached');
    }

    if (this.state.state === 'HALF_OPEN') {
      this.halfOpenCalls++;
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    if (this.state.state === 'HALF_OPEN') {
      this.state.state = 'CLOSED';
      this.state.failures = 0;
      this.halfOpenCalls = 0;
      console.log('Circuit breaker closed - service recovered');
    }
  }

  private onFailure() {
    this.state.failures++;
    this.state.lastFailureTime = Date.now();

    if (this.state.failures >= this.failureThreshold) {
      this.state.state = 'OPEN';
      console.log('Circuit breaker opened - too many failures');
    }
  }

  getState() {
    return this.state.state;
  }
}

class RetryWithBackoff {
  async execute<T>(
    fn: () => Promise<T>,
    maxRetries: number = 3,
    baseDelay: number = 1000
  ): Promise<T> {
    let lastError: Error;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error as Error;
        
        if (attempt === maxRetries) {
          throw lastError;
        }

        const delay = baseDelay * Math.pow(2, attempt);
        console.log(`Retry attempt ${attempt + 1}/${maxRetries + 1} after ${delay}ms`);
        await this.sleep(delay);
      }
    }

    throw lastError!;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

export class AdvancedAIAgent {
  private circuitBreaker = new CircuitBreaker();
  private retryHandler = new RetryWithBackoff();
  private handlers: TaskHandler[] = [];

  constructor() {
    this.initializeHandlers();
  }

  private initializeHandlers() {
    // Research handler with web search
    this.handlers.push({
      name: 'research',
      canHandle: (task) => 
        task.title.toLowerCase().includes('research') ||
        task.title.toLowerCase().includes('search') ||
        task.title.toLowerCase().includes('find'),
      execute: async (task) => {
        return this.circuitBreaker.execute(async () => {
          return this.retryHandler.execute(async () => {
            console.log(`🔍 Researching: ${task.title}`);
            
            // Simulate web search
            await this.simulateWork(2000, 4000);
            
            // In a real implementation, this would call a web search API
            const searchResults = [
              'Found relevant documentation',
              'Analyzed competitor solutions',
              'Collected best practices',
            ];
            
            return {
              success: true,
              output: `Research completed for "${task.title}".\n\nKey findings:\n${searchResults.map((r) => `- ${r}`).join('\n')}`,
              data: {
                sources: ['web-search', 'documentation'],
                findings: searchResults,
              },
            };
          });
        });
      },
    });

    // Code generation handler
    this.handlers.push({
      name: 'code-generation',
      canHandle: (task) =>
        task.title.toLowerCase().includes('code') ||
        task.title.toLowerCase().includes('implement') ||
        task.title.toLowerCase().includes('create') ||
        task.title.toLowerCase().includes('build'),
      execute: async (task) => {
        return this.circuitBreaker.execute(async () => {
          return this.retryHandler.execute(async () => {
            console.log(`💻 Generating code for: ${task.title}`);
            
            await this.simulateWork(3000, 6000);
            
            // Simulate code generation
            const generatedCode = this.generateCodeSnippet(task);
            
            return {
              success: true,
              output: `Code generated for "${task.title}".\n\nGenerated code:\n\`\`\`typescript\n${generatedCode}\n\`\`\``,               data: {
                language: 'typescript',
                code: generatedCode,
                lines: generatedCode.split('\n').length,
              },
            };
          });
        });
      },
    });

    // Documentation handler
    this.handlers.push({
      name: 'documentation',
      canHandle: (task) =>
        task.title.toLowerCase().includes('doc') ||
        task.title.toLowerCase().includes('write') ||
        task.title.toLowerCase().includes('document'),
      execute: async (task) => {
        return this.circuitBreaker.execute(async () => {
          return this.retryHandler.execute(async () => {
            console.log(`📝 Writing documentation for: ${task.title}`);
            
            await this.simulateWork(2000, 4000);
            
            const documentation = this.generateDocumentation(task);
            
            return {
              success: true,
              output: `Documentation written for "${task.title}".\n\n${documentation}`,
              data: {
                wordCount: documentation.split(' ').length,
                sections: ['Overview', 'Usage', 'Examples'],
              },
            };
          });
        });
      },
    });

    // Analysis handler
    this.handlers.push({
      name: 'analysis',
      canHandle: (task) =>
        task.title.toLowerCase().includes('analyze') ||
        task.title.toLowerCase().includes('review') ||
        task.title.toLowerCase().includes('audit'),
      execute: async (task) => {
        return this.circuitBreaker.execute(async () => {
          return this.retryHandler.execute(async () => {
            console.log(`📊 Analyzing: ${task.title}`);
            
            await this.simulateWork(1500, 3000);
            
            return {
              success: true,
              output: `Analysis complete for "${task.title}".\n\nKey insights:\n- Performed comprehensive review\n- Identified optimization opportunities\n- Generated recommendations`,
              data: {
                recommendations: 3,
                issuesFound: 0,
              },
            };
          });
        });
      },
    });
  }

  private generateCodeSnippet(task: DBTask): string {
    // Generate a plausible code snippet based on task description
    const snippets = [
      `export async function ${this.toCamelCase(task.title)}() {\n  // Implementation\n  const result = await fetch('/api/data');\n  return result.json();\n}`,
      `function ${this.toCamelCase(task.title)}(props: Props) {\n  const [state, setState] = useState(null);\n  \n  useEffect(() => {\n    // Load data\n  }, []);\n  \n  return <div>{state}</div>;\n}`,
      `class ${this.toPascalCase(task.title)} {\n  private data: any;\n  \n  constructor(data: any) {\n    this.data = data;\n  }\n  \n  process() {\n    return this.data.map(item => ({\n      ...item,\n      processed: true\n    }));\n  }\n}`,
    ];
    
    return snippets[Math.floor(Math.random() * snippets.length)];
  }

  private generateDocumentation(task: DBTask): string {
    return `# ${task.title}\n\n## Overview\n\nThis document describes ${task.title.toLowerCase()}.\n\n## Usage\n\n\`\`\`typescript\n// Example usage\nconst result = await execute();\n\`\`\`\n\n## Examples\n\n### Basic Example\n\nStandard implementation approach.\n\n### Advanced Example\n\nExtended functionality with additional options.`;
  }

  private toCamelCase(str: string): string {
    return str
      .replace(/(?:^\w|[A-Z]|\b\w)/g, (word, index) =>
        index === 0 ? word.toLowerCase() : word.toUpperCase()
      )
      .replace(/\s+/g, '');
  }

  private toPascalCase(str: string): string {
    return str
      .replace(/(?:^\w|[A-Z]|\b\w)/g, (word) => word.toUpperCase())
      .replace(/\s+/g, '');
  }

  private simulateWork(minMs: number, maxMs: number): Promise<void> {
    const duration = Math.floor(Math.random() * (maxMs - minMs + 1)) + minMs;
    return new Promise((resolve) => setTimeout(resolve, duration));
  }

  async executeTask(task: DBTask): Promise<TaskResult> {
    console.log(`🤖 Advanced AI processing: ${task.title}`);
    
    // Find appropriate handler
    const handler = this.handlers.find((h) => h.canHandle(task as any));
    
    if (!handler) {
      // Generic fallback handler
      return this.executeGenericTask(task);
    }
    
    try {
      const result = await handler.execute(task as any);
      console.log(`✅ Task completed: ${task.title}`);
      return result;
    } catch (error) {
      console.error(`❌ Task failed: ${task.title}`, error);
      return {
        success: false,
        output: '',
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }

  private async executeGenericTask(task: DBTask): Promise<TaskResult> {
    return this.circuitBreaker.execute(async () => {
      await this.simulateWork(2000, 4000);
      
      return {
        success: true,
        output: `Completed task: ${task.title}\n\nThe task has been processed using general AI capabilities.`,
        data: {
          processedAt: new Date().toISOString(),
          handler: 'generic',
        },
      };
    });
  }

  getCircuitBreakerState(): string {
    return this.circuitBreaker.getState();
  }

  getHandlers(): string[] {
    return this.handlers.map((h) => h.name);
  }
}

// Singleton instance
export const advancedAIAgent = new AdvancedAIAgent();
