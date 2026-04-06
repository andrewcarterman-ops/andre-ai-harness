'use client';

import { useState } from 'react';
import { useTaskStore } from '@/stores/taskStore';
import { Task, TaskStatus, TaskPriority, Assignee } from '@/types';
import { cn } from '@/lib/utils';
import { X, User, Bot } from 'lucide-react';

interface CreateTaskDialogProps {
  isOpen: boolean;
  onClose: () => void;
  initialStatus?: TaskStatus;
}

const PRIORITIES: { value: TaskPriority; label: string; color: string }[] = [
  { value: 'low', label: 'Low', color: 'bg-white/[0.06] text-white/60' },
  { value: 'medium', label: 'Medium', color: 'bg-blue-500/20 text-blue-400' },
  { value: 'high', label: 'High', color: 'bg-orange-500/20 text-orange-400' },
  { value: 'urgent', label: 'Urgent', color: 'bg-red-500/20 text-red-400' },
];

const ASSIGNEES: Assignee[] = [
  { id: 'user-1', type: 'user', name: 'You', avatar: '' },
  { id: 'ai-1', type: 'ai', name: 'Mission AI', avatar: '' },
];

export function CreateTaskDialog({ 
  isOpen, 
  onClose, 
  initialStatus = 'backlog' 
}: CreateTaskDialogProps) {
  const { addTask } = useTaskStore();
  const [isSubmitting, setIsSubmitting] = useState(false);
  
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    status: initialStatus,
    priority: 'medium' as TaskPriority,
    assignee: ASSIGNEES[0],
    tags: [] as string[],
    dueDate: '',
    estimatedHours: '',
  });

  const [tagInput, setTagInput] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.title.trim()) return;

    setIsSubmitting(true);
    try {
      await addTask({
        title: formData.title,
        description: formData.description,
        status: formData.status,
        priority: formData.priority,
        assignee: formData.assignee,
        tags: formData.tags,
        dueDate: formData.dueDate ? new Date(formData.dueDate) : undefined,
        estimatedHours: formData.estimatedHours ? parseFloat(formData.estimatedHours) : undefined,
        subtasks: [],
        metadata: {},
      });
      
      onClose();
      // Reset form
      setFormData({
        title: '',
        description: '',
        status: initialStatus,
        priority: 'medium',
        assignee: ASSIGNEES[0],
        tags: [],
        dueDate: '',
        estimatedHours: '',
      });
    } catch (error) {
      console.error('Failed to create task:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const addTag = () => {
    if (tagInput.trim() && !formData.tags.includes(tagInput.trim())) {
      setFormData({ ...formData, tags: [...formData.tags, tagInput.trim()] });
      setTagInput('');
    }
  };

  const removeTag = (tag: string) => {
    setFormData({ ...formData, tags: formData.tags.filter((t) => t !== tag) });
  };

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-[#0a0a0a] rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-auto border border-white/[0.06]">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-white/[0.06]">
          <h3 className="text-lg font-semibold text-white/90">Create New Task</h3>
          <button
            onClick={onClose}
            className="p-1 hover:bg-white/[0.06] rounded transition-colors"
          >
            <X className="w-5 h-5 text-white/40" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-4 space-y-4">
          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-white/60 mb-1">
              Title <span className="text-red-400">*</span>
            </label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="What needs to be done?"
              className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-lg text-white placeholder:text-white/30 focus:outline-none focus:border-purple-500/50"
              autoFocus
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-white/60 mb-1">
              Description
            </label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              placeholder="Add more details..."
              rows={3}
              className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-lg text-white placeholder:text-white/30 focus:outline-none focus:border-purple-500/50 resize-none"
            />
          </div>

          {/* Priority */}
          <div>
            <label className="block text-sm font-medium text-white/60 mb-2">
              Priority
            </label>
            <div className="flex gap-2">
              {PRIORITIES.map((p) => (
                <button
                  key={p.value}
                  type="button"
                  onClick={() => setFormData({ ...formData, priority: p.value })}
                  className={cn(
                    'px-3 py-1.5 rounded-lg text-sm font-medium transition-colors',
                    p.color,
                    formData.priority === p.value && 'ring-2 ring-offset-1 ring-offset-[#0a0a0a] ring-white/20'
                  )}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          {/* Assignee */}
          <div>
            <label className="block text-sm font-medium text-white/60 mb-2">
              Assignee
            </label>
            <div className="flex gap-2">
              {ASSIGNEES.map((a) => (
                <button
                  key={a.id}
                  type="button"
                  onClick={() => setFormData({ ...formData, assignee: a })}
                  className={cn(
                    'flex items-center gap-2 px-3 py-2 rounded-lg border transition-colors',
                    formData.assignee.id === a.id
                      ? 'border-purple-500 bg-purple-500/10'
                      : 'border-white/[0.08] hover:bg-white/[0.04]'
                  )}
                >
                  {a.type === 'ai' ? (
                    <Bot className="w-4 h-4 text-purple-400" />
                  ) : (
                    <User className="w-4 h-4 text-blue-400" />
                  )}
                  <span className="text-sm text-white/80">{a.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* Due Date & Estimated Hours */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-white/60 mb-1">
                Due Date
              </label>
              <input
                type="date"
                value={formData.dueDate}
                onChange={(e) => setFormData({ ...formData, dueDate: e.target.value })}
                className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-lg text-white focus:outline-none focus:border-purple-500/50"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-white/60 mb-1">
                Estimated Hours
              </label>
              <input
                type="number"
                min="0"
                step="0.5"
                value={formData.estimatedHours}
                onChange={(e) => setFormData({ ...formData, estimatedHours: e.target.value })}
                placeholder="e.g., 4"
                className="w-full px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-lg text-white placeholder:text-white/30 focus:outline-none focus:border-purple-500/50"
              />
            </div>
          </div>

          {/* Tags */}
          <div>
            <label className="block text-sm font-medium text-white/60 mb-1">
              Tags
            </label>
            <div className="flex gap-2 mb-2">
              <input
                type="text"
                value={tagInput}
                onChange={(e) => setTagInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    addTag();
                  }
                }}
                placeholder="Add a tag and press Enter"
                className="flex-1 px-3 py-2 bg-white/[0.04] border border-white/[0.08] rounded-lg text-white placeholder:text-white/30 focus:outline-none focus:border-purple-500/50"
              />
              <button
                type="button"
                onClick={addTag}
                className="px-3 py-2 bg-white/[0.08] text-white/70 rounded-lg hover:bg-white/[0.12] transition-colors"
              >
                Add
              </button>
            </div>
            <div className="flex flex-wrap gap-2">
              {formData.tags.map((tag) => (
                <span
                  key={tag}
                  className="inline-flex items-center gap-1 px-2 py-1 bg-purple-500/20 text-purple-400 rounded-full text-sm"
                >
                  {tag}
                  <button
                    type="button"
                    onClick={() => removeTag(tag)}
                    className="hover:text-purple-300"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </span>
              ))}
            </div>
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-3 pt-4 border-t border-white/[0.06]">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-white/60 hover:bg-white/[0.04] rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={!formData.title.trim() || isSubmitting}
              className={cn(
                'px-4 py-2 bg-purple-500 text-white rounded-lg transition-colors',
                (!formData.title.trim() || isSubmitting) && 'opacity-50 cursor-not-allowed',
                'hover:bg-purple-600'
              )}
            >
              {isSubmitting ? 'Creating...' : 'Create Task'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
