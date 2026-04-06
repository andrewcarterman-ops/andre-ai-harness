import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { documents } from '@/lib/db/schema';
import { nanoid } from 'nanoid';
import { eq } from 'drizzle-orm';

export async function GET(request: Request) {
  try {
    const allDocs = await db.select().from(documents);
    return NextResponse.json(allDocs);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to fetch documents' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    
    const newDoc = {
      id: nanoid(),
      title: body.title,
      content: body.content || '',
      category: body.category || 'other',
      tags: body.tags || [],
      version: 1,
      isArchived: false,
      createdBy: 'user-1',
      updatedBy: 'user-1',
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    await db.insert(documents).values(newDoc);
    
    return NextResponse.json(newDoc, { status: 201 });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to create document' }, { status: 500 });
  }
}
