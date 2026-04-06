'use client';

import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import { Project } from '@/types';

interface ProjectState {
  projects: Project[];
  selectedProject: Project | null;
  isLoading: boolean;
  
  fetchProjects: () => Promise<void>;
  createProject: (project: Omit<Project, 'id' | 'createdAt' | 'updatedAt'>) => Promise<void>;
  updateProject: (id: string, updates: Partial<Project>) => Promise<void>;
  deleteProject: (id: string) => Promise<void>;
  selectProject: (project: Project | null) => void;
}

export const useProjectStore = create<ProjectState>()(
  immer(
    persist(
      (set, get) => ({
        projects: [],
        selectedProject: null,
        isLoading: false,

        fetchProjects: async () => {
          try {
            const res = await fetch('/api/projects');
            const projects = await res.json();
            set({ projects });
          } catch (error) {
            console.error('Failed to fetch projects:', error);
          }
        },

        createProject: async (projectData) => {
          const res = await fetch('/api/projects', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(projectData),
          });
          
          const newProject = await res.json();
          
          set((state) => {
            state.projects.push(newProject);
          });
        },

        updateProject: async (id, updates) => {
          await fetch(`/api/projects/${id}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(updates),
          });
          
          set((state) => {
            const index = state.projects.findIndex((p) => p.id === id);
            if (index !== -1) {
              state.projects[index] = { ...state.projects[index], ...updates };
            }
          });
        },

        deleteProject: async (id) => {
          await fetch(`/api/projects/${id}`, {
            method: 'DELETE',
          });
          
          set((state) => {
            state.projects = state.projects.filter((p) => p.id !== id);
          });
        },

        selectProject: (project) => set({ selectedProject: project }),
      }),
      {
        name: 'project-store',
      }
    )
  )
);
