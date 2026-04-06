import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { memories } from '@/lib/db/schema';
import { nanoid } from 'nanoid';
import { eq, desc } from 'drizzle-orm';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    
    let query = db.select().from(memories).orderBy(desc(memories.date));
    
    // TODO: Add full-text search when needed
    
    const allMemories = await query;
    return NextResponse.json(allMemories);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to fetch memories' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    const newMemory = {
      id: nanoid(),
      ...body,
      createdAt: new Date(),
    };
    
    await db.insert(memories).values(newMemory);
    
    return NextResponse.json(newMemory, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to create memory' }, { status: 500 });
  }
}
