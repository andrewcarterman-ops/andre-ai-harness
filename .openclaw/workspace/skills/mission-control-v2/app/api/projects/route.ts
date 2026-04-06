import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { projects } from '@/lib/db/schema';
import { nanoid } from 'nanoid';
import { eq } from 'drizzle-orm';

export async function GET() {
  try {
    const allProjects = await db.select().from(projects);
    return NextResponse.json(allProjects);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to fetch projects' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    const newProject = {
      id: nanoid(),
      name: body.name,
      description: body.description || '',
      status: body.status || 'planning',
      progress: 0,
      color: body.color || '#8b5cf6',
      taskCount: JSON.stringify({ total: 0, completed: 0 }),
      linkedMemories: JSON.stringify([]),
      linkedDocs: JSON.stringify([]),
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    await db.insert(projects).values(newProject);
    
    return NextResponse.json(newProject, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to create project' }, { status: 500 });
  }
}
