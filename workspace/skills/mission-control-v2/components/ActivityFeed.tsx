'use client';

import { useEffect, useRef, useState } from 'react';
import { useActivityStore } from '@/stores/activityStore';
import { Activity, ActivityType } from '@/types';
import { 
  CheckCircle2, 
  Plus, 
  Edit3, 
  User, 
  Bot,
  ArrowRight,
  Archive,
  Trash2,
  Filter,
  Bell,
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { cn } from '@/lib/utils';

const activityIcons: Record<ActivityType, React.ElementType> = {
  task_created: Plus,
  task_completed: CheckCircle2,
  task_updated: Edit3,
  task_moved: ArrowRight,
  task_assigned: User,
  project_created: Plus,
  project_updated: Edit3,
  project_completed: CheckCircle2,
  doc_created: Plus,
  doc_updated: Edit3,
  memory_created: Plus,
  agent_action: Bot,
  system_event: Archive,
};

const activityColors: Record<ActivityType, string> = {
  task_created: 'bg-blue-500/20 text-blue-400',
  task_completed: 'bg-green-500/20 text-green-400',
  task_updated: 'bg-yellow-500/20 text-yellow-400',
  task_moved: 'bg-purple-500/20 text-purple-400',
  task_assigned: 'bg-pink-500/20 text-pink-400',
  project_created: 'bg-blue-500/20 text-blue-400',
  project_updated: 'bg-yellow-500/20 text-yellow-400',
  project_completed: 'bg-green-500/20 text-green-400',
  doc_created: 'bg-blue-500/20 text-blue-400',
  doc_updated: 'bg-yellow-500/20 text-yellow-400',
  memory_created: 'bg-purple-500/20 text-purple-400',
  agent_action: 'bg-purple-500/20 text-purple-400',
  system_event: 'bg-gray-500/20 text-gray-400',
};

export function ActivityFeed() {
  const { 
    activities, 
    unreadCount, 
    filter, 
    setFilter,
    markAsRead,
    clearActivities,
    getFilteredActivities,
  } = useActivityStore();
  const scrollRef = useRef<HTMLDivElement>(null);
  const [showFilters, setShowFilters] = useState(false);

  // Auto-scroll to top when new activity added
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = 0;
    }
  }, [activities.length]);

  const filteredActivities = getFilteredActivities();

  const filters: { value: ActivityType | 'all'; label: string }[] = [
    { value: 'all', label: 'All' },
    { value: 'task_created', label: 'Tasks Created' },
    { value: 'task_completed', label: 'Tasks Completed' },
    { value: 'task_updated', label: 'Tasks Updated' },
    { value: 'agent_action', label: 'AI Actions' },
  ];

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-white/[0.06]">
        <div className="flex items-center gap-2">
          <Bell className={cn(
            'w-5 h-5',
            unreadCount > 0 ? 'text-purple-400' : 'text-white/40'
          )} />
          <div>
            <h3 className="font-medium text-white/90">Activity Feed</h3>
            {unreadCount > 0 && (
              <p className="text-xs text-purple-400">
                {unreadCount} new
              </p>
            )}
          </div>
        </div>
        
        <div className="flex items-center gap-1">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={cn(
              'p-2 rounded-lg transition-colors',
              showFilters ? 'bg-purple-500/20 text-purple-400' : 'hover:bg-white/[0.06]'
            )}
            title="Filter"
          >
            <Filter className="w-4 h-4" />
          </button>
          
          {unreadCount > 0 && (
            <button
              onClick={markAsRead}
              className="px-2 py-1 text-xs bg-purple-500/20 text-purple-400 rounded hover:bg-purple-500/30 transition-colors"
            >
              Mark read
            </button>
          )}
          
          {activities.length > 0 && (
            <button
              onClick={clearActivities}
              className="p-2 hover:bg-white/[0.06] rounded transition-colors"
              title="Clear all"
            >
              <Trash2 className="w-4 h-4 text-white/40" />
            </button>
          )}
        </div>
      </div>

      {/* Filters */}
      {showFilters && (
        <div className="px-4 py-2 border-b border-white/[0.06] flex flex-wrap gap-2">
          {filters.map((f) => (
            <button
              key={f.value}
              onClick={() => setFilter(f.value)}
              className={cn(
                'px-2 py-1 text-xs rounded transition-colors',
                filter === f.value
                  ? 'bg-purple-500 text-white'
                  : 'bg-white/[0.04] text-white/60 hover:bg-white/[0.08]'
              )}
            >
              {f.label}
            </button>
          ))}
        </div>
      )}

      {/* Activity List */}
      <div 
        ref={scrollRef}
        className="flex-1 overflow-y-auto p-4 space-y-3"
      >
        {filteredActivities.length === 0 ? (
          <div className="text-center py-12">
            <Archive className="w-12 h-12 text-white/20 mx-auto mb-3" />
            <p className="text-white/30">No activities yet</p>
            <p className="text-white/20 text-sm mt-1">
              Activities will appear here when tasks are created or updated
            </p>
          </div>
        ) : (
          filteredActivities.map((activity, index) => (
            <ActivityItem 
              key={activity.id} 
              activity={activity} 
              isUnread={index < unreadCount}
            />
          ))
        )}
      </div>
    </div>
  );
}

function ActivityItem({ 
  activity, 
  isUnread 
}: { 
  activity: Activity; 
  isUnread: boolean;
}) {
  const Icon = activityIcons[activity.type] || Archive;
  const colorClass = activityColors[activity.type] || 'bg-gray-500/20 text-gray-400';
  const isAI = activity.actor.type === 'ai';

  return (
    <div
      className={cn(
        'flex gap-3 p-3 rounded-lg transition-colors',
        isUnread ? 'bg-purple-500/5' : 'hover:bg-white/[0.02]'
      )}
    >
      {/* Icon */}
      <div 
        className={cn(
          'w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0',
          colorClass
        )}
      >
        <Icon className="w-4 h-4" />
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2">
          <p className="text-sm text-white/80">
            <span className={cn(
              'font-medium',
              isAI ? 'text-purple-400' : 'text-blue-400'
            )}>
              {activity.actor.name}
            </span>
            {' '}{activity.action}{' '}
            <span className="font-medium text-white">{activity.targetName}</span>
          </p>
          
          {isUnread && (
            <span className="w-2 h-2 rounded-full bg-purple-400 flex-shrink-0 mt-1" />
          )}
        </div>
        
        <div className="flex items-center gap-2 mt-1">
          <span className="text-xs text-white/30">
            {formatDistanceToNow(new Date(activity.timestamp), { addSuffix: true })}
          </span>
          {activity.metadata && Object.keys(activity.metadata).length > 0 && (
            <span className="text-xs text-white/20">
              • {Object.keys(activity.metadata).length} detail{Object.keys(activity.metadata).length !== 1 ? 's' : ''}
            </span>
          )}
        </div>
      </div>
    </div>
  );
}
