'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import { Task, TaskStatus, Activity, ActivityType } from '@/types';

interface TaskState {
  // State
  tasks: Task[];
  columns: Record<TaskStatus, string[]>;
  isLoading: boolean;
  error: string | null;
  selectedTask: Task | null;
  
  // Actions
  fetchTasks: () => Promise<void>;
  addTask: (task: Omit<Task, 'id' | 'createdAt' | 'updatedAt'>) => Promise<Task | null>;
  updateTask: (id: string, updates: Partial<Task>) => Promise<void>;
  deleteTask: (id: string) => Promise<void>;
  moveTask: (taskId: string, newStatus: TaskStatus) => Promise<void>;
  reorderTasks: (status: TaskStatus, oldIndex: number, newIndex: number) => void;
  setSelectedTask: (task: Task | null) => void;
  
  // AI Integration
  getAITasks: () => Task[];
  claimNextAITask: () => Task | null;
}

export const useTaskStore = create<TaskState>()(
  immer(
    persist(
      (set, get) => ({
        tasks: [],
        columns: {
          backlog: [],
          todo: [],
          in_progress: [],
          review: [],
          done: [],
        },
        isLoading: false,
        error: null,
        selectedTask: null,

        fetchTasks: async () => {
          set({ isLoading: true, error: null });
          try {
            const res = await fetch('/api/tasks');
            if (!res.ok) throw new Error('Failed to fetch tasks');
            const tasks = await res.json();
            
            // Organize by columns
            const columns: Record<TaskStatus, string[]> = {
              backlog: [],
              todo: [],
              in_progress: [],
              review: [],
              done: [],
            };
            
            tasks.forEach((task: Task) => {
              if (columns[task.status]) {
                columns[task.status].push(task.id);
              }
            });
            
            set({ tasks, columns, isLoading: false });
          } catch (error) {
            set({ 
              error: error instanceof Error ? error.message : 'Failed to fetch tasks', 
              isLoading: false 
            });
          }
        },

        addTask: async (taskData) => {
          try {
            const res = await fetch('/api/tasks', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(taskData),
            });
            
            if (!res.ok) throw new Error('Failed to create task');
            
            const newTask = await res.json();
            
            set((state) => {
              state.tasks.push(newTask);
              const status = newTask.status as TaskStatus;
              state.columns[status].push(newTask.id);
            });
            
            return newTask;
          } catch (error) {
            console.error('Failed to create task:', error);
            set({ error: error instanceof Error ? error.message : 'Failed to create task' });
            return null;
          }
        },

        updateTask: async (id, updates) => {
          try {
            const res = await fetch(`/api/tasks/${id}`, {
              method: 'PATCH',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(updates),
            });
            
            if (!res.ok) throw new Error('Failed to update task');
            
            const updated = await res.json();
            
            set((state) => {
              const index = state.tasks.findIndex((t) => t.id === id);
              if (index !== -1) {
                // Handle status change
                if (updates.status && updates.status !== state.tasks[index].status) {
                  const oldStatus = state.tasks[index].status;
                  state.columns[oldStatus] = state.columns[oldStatus].filter(
                    (tid) => tid !== id
                  );
                  state.columns[updates.status].push(id);
                }
                state.tasks[index] = { ...state.tasks[index], ...updated };
              }
            });
          } catch (error) {
            console.error('Failed to update task:', error);
            set({ error: error instanceof Error ? error.message : 'Failed to update task' });
          }
        },

        deleteTask: async (id) => {
          try {
            const res = await fetch(`/api/tasks/${id}`, {
              method: 'DELETE',
            });
            
            if (!res.ok) throw new Error('Failed to delete task');
            
            set((state) => {
              const task = state.tasks.find((t) => t.id === id);
              if (task) {
                state.columns[task.status] = state.columns[task.status].filter(
                  (tid) => tid !== id
                );
              }
              state.tasks = state.tasks.filter((t) => t.id !== id);
            });
          } catch (error) {
            console.error('Failed to delete task:', error);
            set({ error: error instanceof Error ? error.message : 'Failed to delete task' });
          }
        },

        moveTask: async (taskId, newStatus) => {
          const task = get().tasks.find((t) => t.id === taskId);
          if (!task || task.status === newStatus) return;

          // Optimistic update
          set((state) => {
            state.columns[task.status] = state.columns[task.status].filter(
              (id) => id !== taskId
            );
            state.columns[newStatus].push(taskId);
            const t = state.tasks.find((t) => t.id === taskId);
            if (t) t.status = newStatus;
          });

          try {
            const res = await fetch(`/api/tasks/${taskId}`, {
              method: 'PATCH',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ status: newStatus }),
            });
            
            if (!res.ok) throw new Error('Failed to move task');
          } catch (error) {
            // Revert on error
            set((state) => {
              state.columns[newStatus] = state.columns[newStatus].filter(
                (id) => id !== taskId
              );
              state.columns[task.status].push(taskId);
              const t = state.tasks.find((t) => t.id === taskId);
              if (t) t.status = task.status;
            });
            console.error('Failed to move task:', error);
          }
        },

        reorderTasks: (status, oldIndex, newIndex) => {
          set((state) => {
            const column = state.columns[status];
            const [moved] = column.splice(oldIndex, 1);
            column.splice(newIndex, 0, moved);
          });
        },

        setSelectedTask: (task) => set({ selectedTask: task }),

        getAITasks: () => {
          return get().tasks.filter(
            (t) => t.assignee.type === 'ai' && t.status !== 'done'
          );
        },

        claimNextAITask: () => {
          const aiTasks = get().tasks.filter(
            (t) => t.assignee.type === 'ai' && t.status === 'backlog'
          );
          return aiTasks.length > 0 ? aiTasks[0] : null;
        },
      }),
      {
        name: 'task-store',
        partialize: (state) => ({ tasks: state.tasks, columns: state.columns }),
      }
    )
  )
);
