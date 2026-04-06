import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { tasks, activities } from '@/lib/db/schema';
import { eq, and, not } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { advancedAIAgent } from '@/lib/ai/advancedAgent';
import { broadcast } from '@/lib/realtime/broadcast';

// Agent status
let isAgentRunning = false;
let lastRunTime: Date | null = null;
let processedCount = 0;

export async function GET() {
  return NextResponse.json({
    isRunning: isAgentRunning,
    lastRunTime,
    processedCount,
    circuitBreakerState: advancedAIAgent.getCircuitBreakerState(),
    availableHandlers: advancedAIAgent.getHandlers(),
  });
}

export async function POST() {
  if (isAgentRunning) {
    return NextResponse.json({ 
      success: false, 
      message: 'Agent is already running' 
    }, { status: 409 });
  }

  isAgentRunning = true;
  
  try {
    // Find AI-assigned tasks in backlog
    const aiTasks = await db
      .select()
      .from(tasks)
      .where(
        and(
          eq(tasks.assigneeType, 'ai'),
          not(eq(tasks.status, 'done'))
        )
      );

    if (aiTasks.length === 0) {
      isAgentRunning = false;
      return NextResponse.json({ 
        success: true, 
        message: 'No pending AI tasks',
        processed: 0 
      });
    }

    // Process tasks
    for (const task of aiTasks.slice(0, 3)) { // Process max 3 at a time
      try {
        // Move to in_progress
        await db
          .update(tasks)
          .set({ status: 'in_progress', updatedAt: new Date() })
          .where(eq(tasks.id, task.id));

        // Broadcast update
        broadcast({ 
          type: 'task-update', 
          taskId: task.id, 
          updates: { status: 'in_progress' } 
        });

        // Execute with advanced AI
        const result = await advancedAIAgent.executeTask(task);

        // Update task with results
        const existingMetadata = task.metadata ? JSON.parse(task.metadata as string) : {};
        const metadata = {
          ...existingMetadata,
          aiResult: result,
          processedAt: new Date().toISOString(),
        };

        await db
          .update(tasks)
          .set({
            status: result.success ? 'done' : 'backlog',
            updatedAt: new Date(),
            metadata: JSON.stringify(metadata),
          })
          .where(eq(tasks.id, task.id));

        // Log activity
        await db.insert(activities).values({
          id: nanoid(),
          type: result.success ? 'task_completed' : 'task_updated',
          actorId: 'ai-1',
          actorType: 'ai',
          actorName: 'Mission AI',
          targetType: 'task',
          targetId: task.id,
          targetName: task.title,
          action: result.success ? 'completed' : 'failed - returned to backlog',
          metadata: {
            aiResult: result.success,
            output: result.output?.slice(0, 500), // Truncate for DB
          },
          timestamp: new Date(),
        });

        // Broadcast completion
        broadcast({
          type: result.success ? 'task-completed' : 'task-update',
          taskId: task.id,
          updates: {
            status: result.success ? 'done' : 'backlog',
            metadata,
          },
        });

        processedCount++;
        
        // Small delay between tasks
        await new Promise((resolve) => setTimeout(resolve, 1000));
        
      } catch (error) {
        console.error(`Failed to process task ${task.id}:`, error);
        
        // Return to backlog on error
        await db
          .update(tasks)
          .set({ status: 'backlog', updatedAt: new Date() })
          .where(eq(tasks.id, task.id));
      }
    }

    lastRunTime = new Date();
    isAgentRunning = false;

    return NextResponse.json({
      success: true,
      message: 'Agent cycle completed',
      processed: Math.min(aiTasks.length, 3),
      remaining: Math.max(0, aiTasks.length - 3),
    });

  } catch (error) {
    isAgentRunning = false;
    console.error('Agent error:', error);
    return NextResponse.json(
      { error: 'Agent execution failed' },
      { status: 500 }
    );
  }
}
