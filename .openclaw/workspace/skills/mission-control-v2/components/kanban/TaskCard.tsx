'use client';

import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import { Task } from '@/types';
import { cn } from '@/lib/utils';
import { 
  Calendar, 
  Clock, 
  User, 
  Bot, 
  AlertCircle,
  MessageSquare,
} from 'lucide-react';

interface TaskCardProps {
  task: Task;
  isDragging?: boolean;
}

export function TaskCard({ task, isDragging }: TaskCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging: isSortableDragging,
  } = useSortable({ id: task.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  const priorityConfig = {
    low: { color: 'bg-white/[0.06] text-white/50', label: 'Low' },
    medium: { color: 'bg-blue-500/20 text-blue-400', label: 'Medium' },
    high: { color: 'bg-orange-500/20 text-orange-400', label: 'High' },
    urgent: { color: 'bg-red-500/20 text-red-400', label: 'Urgent' },
  };

  const isOverdue = task.dueDate && new Date(task.dueDate) < new Date() && task.status !== 'done';

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      {...listeners}
      className={cn(
        'bg-white/[0.04] rounded-lg p-3 border border-white/[0.06] cursor-grab select-none',
        'hover:bg-white/[0.06] hover:border-white/[0.1] transition-all',
        (isDragging || isSortableDragging) && 'opacity-50 rotate-2 cursor-grabbing'
      )}
    >
      {/* Header */}
      <div className="flex items-start justify-between gap-2 mb-2">
        <h4 className="font-medium text-white/90 text-sm line-clamp-2 flex-1">
          {task.title}
        </h4>
        <span className={cn(
          'text-[10px] px-1.5 py-0.5 rounded-full font-medium flex-shrink-0',
          priorityConfig[task.priority].color
        )}>
          {priorityConfig[task.priority].label}
        </span>
      </div>

      {/* Description */}
      {task.description && (
        <p className="text-white/40 text-xs mb-3 line-clamp-2">
          {task.description}
        </p>
      )}

      {/* Meta Info */}
      <div className="flex items-center justify-between text-xs text-white/30">
        <div className="flex items-center gap-2">
          {/* Assignee */}
          <div className="flex items-center gap-1">
            {task.assignee.type === 'ai' ? (
              <Bot className="w-3.5 h-3.5 text-purple-400" />
            ) : (
              <User className="w-3.5 h-3.5 text-blue-400" />
            )}
            <span className="truncate max-w-[80px]">{task.assignee.name}</span>
          </div>
        </div>

        {/* Due Date */}
        {task.dueDate && (
          <div className={cn(
            'flex items-center gap-1',
            isOverdue && 'text-red-400 font-medium'
          )}>
            <Calendar className="w-3 h-3" />
            <span>{new Date(task.dueDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}</span>
            {isOverdue && <AlertCircle className="w-3 h-3" />}
          </div>
        )}
      </div>

      {/* Tags */}
      {task.tags.length > 0 && (
        <div className="flex flex-wrap gap-1 mt-2">
          {task.tags.slice(0, 3).map((tag) => (
            <span
              key={tag}
              className="text-[10px] bg-white/[0.06] text-white/50 px-1.5 py-0.5 rounded"
            >
              {tag}
            </span>
          ))}
          {task.tags.length > 3 && (
            <span className="text-[10px] text-white/30">
              +{task.tags.length - 3}
            </span>
          )}
        </div>
      )}

      {/* Footer Stats */}
      <div className="flex items-center justify-between mt-2 pt-2 border-t border-white/[0.04]">
        <div className="flex items-center gap-3 text-white/30">
          {task.estimatedHours && (
            <div className="flex items-center gap-1" title="Estimated hours">
              <Clock className="w-3 h-3" />
              <span className="text-[10px]">{task.estimatedHours}h</span>
            </div>
          )}
          {task.subtasks?.length > 0 && (
            <div className="flex items-center gap-1" title="Subtasks">
              <MessageSquare className="w-3 h-3" />
              <span className="text-[10px]">{task.subtasks.length}</span>
            </div>
          )}
        </div>

        {/* Project indicator if linked */}
        {task.projectId && (
          <div className="w-2 h-2 rounded-full bg-blue-400" title="Linked to project" />
        )}
      </div>
    </div>
  );
}
