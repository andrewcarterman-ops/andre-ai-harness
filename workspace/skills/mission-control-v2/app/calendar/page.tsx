'use client';

import { useEffect, useState } from 'react';
import FullCalendar from '@fullcalendar/react';
import dayGridPlugin from '@fullcalendar/daygrid';
import { MainLayout } from '@/components/layout/main-layout';
import { useTaskStore } from '@/stores/taskStore';
import { Calendar as CalendarIcon, Plus } from 'lucide-react';
import { useRouter } from 'next/navigation';

export default function CalendarPage() {
  const { tasks, fetchTasks } = useTaskStore();
  const [mounted, setMounted] = useState(false);
  const router = useRouter();

  useEffect(() => {
    setMounted(true);
    fetchTasks();
  }, [fetchTasks]);

  const events = tasks
    .filter((task) => task.dueDate)
    .map((task) => ({
      id: task.id,
      title: task.title,
      date: task.dueDate,
      backgroundColor: 
        task.status === 'done' ? '#10b981' :
        task.status === 'in_progress' ? '#3b82f6' :
        task.status === 'review' ? '#f59e0b' : '#8b5cf6',
      borderColor: 
        task.status === 'done' ? '#10b981' :
        task.status === 'in_progress' ? '#3b82f6' :
        task.status === 'review' ? '#f59e0b' : '#8b5cf6',
      textColor: '#ffffff',
    }));

  const stats = {
    scheduled: tasks.filter((t) => t.dueDate).length,
    overdue: tasks.filter((t) => {
      if (!t.dueDate || t.status === 'done') return false;
      return new Date(t.dueDate) < new Date();
    }).length,
  };

  if (!mounted) {
    return (
      <MainLayout>
        <div className="flex items-center justify-center h-96">
          <div className="text-white/40">Loading calendar...</div>
        </div>
      </MainLayout>
    );
  }

  return (
    <MainLayout>
      <div className="space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <CalendarIcon className="w-6 h-6 text-purple-500" />
            <h1 className="text-2xl font-semibold text-white/90">Calendar</h1>
          </div>

          <div className="flex items-center gap-3">
            <div className="bg-white/[0.02] border border-white/[0.06] rounded-lg px-3 py-2">
              <span className="text-white/60 text-sm">{stats.scheduled} scheduled • {stats.overdue} overdue</span>
            </div>

            <button
              onClick={() => router.push('/tasks')}
              className="flex items-center gap-2 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg"
            >
              <Plus className="w-4 h-4" />
              New Task
            </button>
          </div>
        </div>

        {/* Calendar with Dark Theme Styles */}
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4 dark-calendar">
          <style jsx global>{`
            .dark-calendar .fc {
              color: rgba(255, 255, 255, 0.9);
            }
            .dark-calendar .fc-theme-standard td,
            .dark-calendar .fc-theme-standard th {
              border-color: rgba(255, 255, 255, 0.1);
            }
            .dark-calendar .fc-col-header-cell {
              background: rgba(255, 255, 255, 0.05);
              color: rgba(255, 255, 255, 0.8);
              padding: 8px 0;
            }
            .dark-calendar .fc-day {
              background: transparent;
            }
            .dark-calendar .fc-day-number {
              color: rgba(255, 255, 255, 0.8);
              padding: 4px;
            }
            .dark-calendar .fc-toolbar-title {
              color: rgba(255, 255, 255, 0.9);
              font-size: 1.25rem;
            }
            .dark-calendar .fc-button {
              background: rgba(255, 255, 255, 0.1) !important;
              border-color: rgba(255, 255, 255, 0.2) !important;
              color: white !important;
            }
            .dark-calendar .fc-button:hover {
              background: rgba(255, 255, 255, 0.2) !important;
            }
            .dark-calendar .fc-today-button {
              background: rgba(139, 92, 246, 0.3) !important;
            }
            .dark-calendar .fc-event {
              border: none !important;
            }
            .dark-calendar .fc-day-today {
              background: rgba(139, 92, 246, 0.1) !important;
            }
          `}</style>
          
          <FullCalendar
            plugins={[dayGridPlugin]}
            initialView="dayGridMonth"
            headerToolbar={{
              left: 'prev,next today',
              center: 'title',
              right: ''
            }}
            events={events}
            height="auto"
            weekends={true}
          />
        </div>
      </div>
    </MainLayout>
  );
}
