import { MainLayout } from '@/components/layout/main-layout'
import { KanbanBoard } from '@/components/kanban/KanbanBoard'
import { ActivityFeed } from '@/components/ActivityFeed'
import { useActivityStore } from '@/stores/activityStore'

export default function TasksPage() {
  const { activities } = useActivityStore();

  return (
    <MainLayout>
      <div className="flex h-[calc(100vh-8rem)] gap-6">
        <div className="flex-1">
          <KanbanBoard />
        </div>
        
        <div className="w-80 flex-shrink-0">
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4 h-full">
            <h3 className="text-sm font-medium text-white/60 uppercase tracking-wider mb-4">
              Activity Feed
            </h3>
            <div className="overflow-y-auto h-[calc(100%-2rem)]">
              <ActivityFeed activities={activities} />
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
