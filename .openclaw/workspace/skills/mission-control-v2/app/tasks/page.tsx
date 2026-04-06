'use client';

import { useEffect, useState } from 'react';
import { MainLayout } from '@/components/layout/main-layout'
import { KanbanBoard } from '@/components/kanban/KanbanBoard'
import { ActivityFeed } from '@/components/ActivityFeed'
import { useRealtime } from '@/hooks/useRealtime';

export default function TasksPage() {
  useRealtime();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <MainLayout>
      <div className="relative">
        {/* Kanban Board - nimmt verfügbaren Platz ein */}
        <div className="pr-[340px]">
          <KanbanBoard />
        </div>

        {/* Activity Feed - fixiert rechts */}
        <div className="fixed right-6 top-[88px] w-80 h-[calc(100vh-120px)]">
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4 h-full">
            <h3 className="text-sm font-medium text-white/60 uppercase tracking-wider mb-4">
              Activity Feed
            </h3>
            <div className="overflow-y-auto h-[calc(100%-2rem)]">
              {mounted && <ActivityFeed />}
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
