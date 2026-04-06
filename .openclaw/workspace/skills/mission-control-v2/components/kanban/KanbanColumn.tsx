'use client';

import { useDroppable } from '@dnd-kit/core';
import {
  SortableContext,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable';
import { Task, TaskStatus } from '@/types';
import { TaskCard } from './TaskCard';
import { cn } from '@/lib/utils';
import { Plus } from 'lucide-react';

const COLUMN_COLORS: Record<TaskStatus, { bg: string; border: string; header: string }> = {
  backlog: { 
    bg: 'bg-white/[0.02]', 
    border: 'border-white/[0.06]',
    header: 'text-white/70'
  },
  todo: { 
    bg: 'bg-white/[0.02]', 
    border: 'border-white/[0.06]',
    header: 'text-white/70'
  },
  in_progress: { 
    bg: 'bg-blue-500/[0.05]', 
    border: 'border-blue-500/20',
    header: 'text-blue-400'
  },
  review: { 
    bg: 'bg-yellow-500/[0.05]', 
    border: 'border-yellow-500/20',
    header: 'text-yellow-400'
  },
  done: { 
    bg: 'bg-green-500/[0.05]', 
    border: 'border-green-500/20',
    header: 'text-green-400'
  },
};

interface KanbanColumnProps {
  status: TaskStatus;
  title: string;
  taskIds: string[];
  tasks: Task[];
  onCreateClick: () => void;
}

export function KanbanColumn({ 
  status, 
  title, 
  taskIds, 
  tasks,
  onCreateClick 
}: KanbanColumnProps) {
  const { setNodeRef, isOver } = useDroppable({ id: status });
  const colors = COLUMN_COLORS[status];

  // Calculate stats
  const totalEstimated = tasks.reduce((sum, t) => sum + (t.estimatedHours || 0), 0);
  const highPriorityCount = tasks.filter((t) => 
    t.priority === 'high' || t.priority === 'urgent'
  ).length;

  return (
    <div
      ref={setNodeRef}
      className={cn(
        'flex-shrink-0 w-80 rounded-xl border flex flex-col max-h-full',
        colors.bg,
        colors.border,
        isOver && 'ring-2 ring-purple-500/50'
      )}
    >
      {/* Column Header */}
      <div className="p-3 border-b border-white/[0.06]">
        <div className="flex items-center justify-between mb-1">
          <h3 className={cn('font-semibold', colors.header)}>
            {title}
          </h3>
          <div className="flex items-center gap-2">
            <span className="bg-white/[0.08] px-2 py-0.5 rounded-full text-sm font-medium text-white/60">
              {tasks.length}
            </span>
            <button
              onClick={onCreateClick}
              className="p-1 hover:bg-white/[0.08] rounded transition-colors"
              title="Add task"
            >
              <Plus className="w-4 h-4 text-white/40" />
            </button>
          </div>
        </div>
        
        {/* Stats */}
        {(totalEstimated > 0 || highPriorityCount > 0) && (
          <div className="flex items-center gap-3 text-xs text-white/40">
            {totalEstimated > 0 && (
              <span>{totalEstimated}h estimated</span>
            )}
            {highPriorityCount > 0 && (
              <span className="text-red-400 font-medium">
                {highPriorityCount} high priority
              </span>
            )}
          </div>
        )}
      </div>

      {/* Tasks List */}
      <div className="flex-1 p-2 overflow-y-auto">
        <SortableContext
          items={taskIds}
          strategy={verticalListSortingStrategy}
        >
          <div className="space-y-2 min-h-[50px]">
            {tasks.map((task) => (
              <TaskCard key={task.id} task={task} />
            ))}
          </div>
        </SortableContext>
        
        {tasks.length === 0 && (
          <div className="text-center py-8 text-white/30 text-sm">
            Drop tasks here
          </div>
        )}
      </div>
    </div>
  );
}
