import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { tasks, activities } from '@/lib/db/schema';
import { eq } from 'drizzle-orm';
import { nanoid } from 'nanoid';
import { broadcast } from '@/lib/realtime/broadcast';

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const task = await db.select().from(tasks).where(eq(tasks.id, id)).limit(1);
    
    if (!task || task.length === 0) {
      return NextResponse.json({ error: 'Task not found' }, { status: 404 });
    }
    
    return NextResponse.json(task[0]);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to fetch task' }, { status: 500 });
  }
}

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const updates = await request.json();
    
    // Get current task for activity logging
    const currentTask = await db.select().from(tasks).where(eq(tasks.id, id)).limit(1);
    if (!currentTask || currentTask.length === 0) {
      return NextResponse.json({ error: 'Task not found' }, { status: 404 });
    }
    
    const oldTask = currentTask[0];
    
    await db.update(tasks)
      .set({ 
        ...updates, 
        updatedAt: new Date() 
      })
      .where(eq(tasks.id, id));
    
    // Log activity for status change
    if (updates.status && updates.status !== oldTask.status) {
      await db.insert(activities).values({
        id: nanoid(),
        type: updates.status === 'done' ? 'task_completed' : 'task_updated',
        actorId: 'user-1',
        actorType: 'user',
        actorName: 'You',
        targetType: 'task',
        targetId: id,
        targetName: oldTask.title,
        action: updates.status === 'done' ? 'completed' : `moved to ${updates.status}`,
        metadata: { from: oldTask.status, to: updates.status },
        timestamp: new Date(),
      });
    }
    
    // Broadcast update
    broadcast({ type: 'task-update', taskId: id, updates });
    
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to update task' }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    
    // Get task for activity logging
    const task = await db.select().from(tasks).where(eq(tasks.id, id)).limit(1);
    if (!task || task.length === 0) {
      return NextResponse.json({ error: 'Task not found' }, { status: 404 });
    }
    
    const deletedTask = task[0];
    
    await db.delete(tasks).where(eq(tasks.id, id));
    
    // Log activity
    await db.insert(activities).values({
      id: nanoid(),
      type: 'task_updated',
      actorId: 'user-1',
      actorType: 'user',
      actorName: 'You',
      targetType: 'task',
      targetId: id,
      targetName: deletedTask.title,
      action: 'deleted',
      timestamp: new Date(),
    });
    
    // Broadcast update
    broadcast({ type: 'task-deleted', taskId: id });
    
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to delete task' }, { status: 500 });
  }
}
