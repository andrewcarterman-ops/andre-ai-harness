import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { documents } from '@/lib/db/schema';
import { eq } from 'drizzle-orm';

export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const updates = await request.json();
    
    const updateData: any = {
      updatedAt: new Date(),
    };
    
    if (updates.title !== undefined) updateData.title = updates.title;
    if (updates.content !== undefined) updateData.content = updates.content;
    if (updates.category !== undefined) updateData.category = updates.category;
    if (updates.tags !== undefined) updateData.tags = JSON.stringify(updates.tags);
    
    // Increment version
    const current = await db.select().from(documents).where(eq(documents.id, id)).limit(1);
    if (current.length > 0) {
      updateData.version = current[0].version + 1;
    }
    
    await db.update(documents)
      .set(updateData)
      .where(eq(documents.id, id));
    
    const updated = await db.select().from(documents).where(eq(documents.id, id)).limit(1);
    
    if (updated.length === 0) {
      return NextResponse.json({ error: 'Document not found' }, { status: 404 });
    }
    
    return NextResponse.json(updated[0]);
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to update document' }, { status: 500 });
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    await db.delete(documents).where(eq(documents.id, id));
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Database error:', error);
    return NextResponse.json({ error: 'Failed to delete document' }, { status: 500 });
  }
}
