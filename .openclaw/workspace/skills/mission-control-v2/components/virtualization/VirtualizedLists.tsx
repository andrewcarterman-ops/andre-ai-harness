'use client';

import { useRef, useCallback, useState } from 'react';
import { Doc, Memory } from '@/types';
import { 
  FileText, Book, Code, Lightbulb, MessageSquare, Archive, Folder
} from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const { FixedSizeList: List } = require('react-window');

const CATEGORY_ICONS: Record<string, React.ElementType> = {
  requirements: Book,
  architecture: Code,
  api: Code,
  guide: Book,
  meeting: MessageSquare,
  research: Lightbulb,
  other: FileText,
};

const CATEGORY_COLORS: Record<string, string> = {
  requirements: 'text-blue-400 bg-blue-500/10',
  architecture: 'text-purple-400 bg-purple-500/10',
  api: 'text-green-400 bg-green-500/10',
  guide: 'text-yellow-400 bg-yellow-500/10',
  meeting: 'text-pink-400 bg-pink-500/10',
  research: 'text-cyan-400 bg-cyan-500/10',
  other: 'text-gray-400 bg-gray-500/10',
};

interface VirtualizedDocListProps {
  docs: Doc[];
  selectedDocId?: string;
  onSelectDoc: (doc: Doc) => void;
  searchQuery?: string;
}

export function VirtualizedDocList({
  docs,
  selectedDocId,
  onSelectDoc,
}: VirtualizedDocListProps) {
  const listRef = useRef<any>(null);

  const ITEM_HEIGHT = 100;
  const MAX_HEIGHT = 600;

  const DocRow = useCallback(
    ({ index, style }: { index: number; style: React.CSSProperties }) => {
      const doc = docs[index];
      const Icon = CATEGORY_ICONS[doc.category] || FileText;
      const isSelected = selectedDocId === doc.id;

      return (
        <div
          style={style}
          className="px-2 py-2"
          onClick={() => onSelectDoc(doc)}
        >
          <div
            className={cn(
              'p-4 rounded-xl border cursor-pointer transition-all h-full',
              isSelected
                ? 'bg-purple-500/10 border-purple-500/30'
                : 'bg-white/[0.02] border-white/[0.06] hover:border-white/[0.1]'
            )}
          >
            <div className="flex items-start gap-3">
              <div className={cn('p-2 rounded-lg flex-shrink-0', CATEGORY_COLORS[doc.category] || CATEGORY_COLORS.other)}>
                <Icon className="w-4 h-4" />
              </div>

              <div className="flex-1 min-w-0">
                <h3 className="font-medium text-white/90 truncate">{doc.title}</h3>

                <div className="flex items-center gap-2 mt-1 text-xs text-white/40">
                  <span className="capitalize">{doc.category}</span>
                  <span>•</span>
                  <span>{format(new Date(doc.updatedAt), 'MMM dd')}</span>
                </div>

                {doc.tags.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-2">
                    {doc.tags.slice(0, 3).map((tag) => (
                      <span
                        key={tag}
                        className="px-2 py-0.5 bg-white/[0.04] rounded text-xs text-white/50"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      );
    },
    [docs, selectedDocId, onSelectDoc]
  );

  if (docs.length <= 20) {
    return (
      <div className="space-y-2">
        {docs.map((doc) => (
          <DocRow key={doc.id} index={docs.indexOf(doc)} style={{}} />
        ))}
      </div>
    );
  }

  return (
    <div className="relative">
      <List
        ref={listRef}
        height={Math.min(docs.length * ITEM_HEIGHT, MAX_HEIGHT)}
        itemCount={docs.length}
        itemSize={ITEM_HEIGHT}
        width="100%"
        overscanCount={5}
      >
        {DocRow}</List>
    </div>
  );
}

interface VirtualizedMemoryListProps {
  memories: Memory[];
  selectedMemoryId?: string;
  onSelectMemory: (memory: Memory) => void;
  groupByDate?: boolean;
}

export function VirtualizedMemoryList({
  memories,
  selectedMemoryId,
  onSelectMemory,
}: VirtualizedMemoryListProps) {
  const listRef = useRef<any>(null);

  const ITEM_HEIGHT = 80;
  const MAX_HEIGHT = 500;

  const MemoryRow = useCallback(
    ({ index, style }: { index: number; style: React.CSSProperties }) => {
      const memory = memories[index];
      const isSelected = selectedMemoryId === memory.id;

      return (
        <div
          style={style}
          className="px-2 py-1"
          onClick={() => onSelectMemory(memory)}
        >
          <div
            className={cn(
              'p-3 rounded-xl border cursor-pointer transition-all',
              isSelected
                ? 'bg-purple-500/10 border-purple-500/30'
                : 'bg-white/[0.02] border-white/[0.06] hover:border-white/[0.1]'
            )}
          >
            <div className="text-sm text-white/80 line-clamp-2">{memory.content}</div>
            
            <div className="flex items-center gap-2 mt-2 text-xs text-white/40">
              <span className="capitalize px-1.5 py-0.5 bg-white/[0.04] rounded">{memory.type}</span>
              <span>{format(new Date(memory.date), 'MMM dd, HH:mm')}</span>
              {memory.importance >= 8 && (
                <span className="text-yellow-400">★ {memory.importance}</span>
              )}
            </div>
          </div>
        </div>
      );
    },
    [memories, selectedMemoryId, onSelectMemory]
  );

  if (memories.length <= 20) {
    return (
      <div className="space-y-2">
        {memories.map((memory) => (
          <MemoryRow
            key={memory.id}
            index={memories.indexOf(memory)}
            style={{}}
          />
        ))}
      </div>
    );
  }

  return (
    <List
      ref={listRef}
      height={Math.min(memories.length * ITEM_HEIGHT, MAX_HEIGHT)}
      itemCount={memories.length}
      itemSize={ITEM_HEIGHT}
      width="100%"
      overscanCount={5}
    >
      {MemoryRow}</List>
  );
}
