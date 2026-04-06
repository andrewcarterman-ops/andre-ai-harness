import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { tasks, activities } from '@/lib/db/schema';
import { nanoid } from 'nanoid';
import { eq, desc } from 'drizzle-orm';
import { broadcast } from '@/lib/realtime/broadcast';

export async function GET() {
  try {
    const allTasks = await db.select().from(tasks).orderBy(desc(tasks.createdAt));
    return NextResponse.json(allTasks);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to fetch tasks' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    const newTask = {
      id: nanoid(),
      title: body.title,
      description: body.description || '',
      status: body.status || 'backlog',
      priority: body.priority || 'medium',
      assigneeId: body.assignee?.id || 'user-1',
      assigneeType: body.assignee?.type || 'user',
      assigneeName: body.assignee?.name || 'You',
      projectId: body.projectId || null,
      tags: body.tags || [],
      dueDate: body.dueDate ? new Date(body.dueDate) : null,
      estimatedHours: body.estimatedHours || null,
      subtasks: body.subtasks || [],
      metadata: body.metadata || {},
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    await db.insert(tasks).values(newTask);
    
    // Log activity
    await db.insert(activities).values({
      id: nanoid(),
      type: 'task_created',
      actorId: newTask.assigneeId,
      actorType: newTask.assigneeType,
      actorName: newTask.assigneeName,
      targetType: 'task',
      targetId: newTask.id,
      targetName: newTask.title,
      action: 'created',
      timestamp: new Date(),
    });
    
    // Broadcast update
    broadcast({ type: 'task-update', task: newTask });
    
    return NextResponse.json(newTask, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to create task' }, { status: 500 });
  }
}
