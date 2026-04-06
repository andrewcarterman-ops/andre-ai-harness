import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { agents } from '@/lib/db/schema';
import { nanoid } from 'nanoid';

export async function GET() {
  try {
    const allAgents = await db.select().from(agents);
    return NextResponse.json(allAgents);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to fetch agents' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    const newAgent = {
      id: nanoid(),
      ...body,
      createdAt: new Date(),
    };
    
    await db.insert(agents).values(newAgent);
    
    return NextResponse.json(newAgent, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to create agent' }, { status: 500 });
  }
}
