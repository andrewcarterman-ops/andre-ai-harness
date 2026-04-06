'use client';

import { useEffect, useState } from 'react';
import { useProjectStore } from '@/stores/projectStore';
import { useTaskStore } from '@/stores/taskStore';
import { Project, ProjectStatus } from '@/types';
import { 
  FolderKanban, 
  Plus, 
  MoreHorizontal, 
  Calendar,
  CheckCircle2,
  Clock,
  AlertCircle,
  Archive
} from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';

const STATUS_COLORS: Record<ProjectStatus, { bg: string; text: string; icon: any }> = {
  planning: { bg: 'bg-blue-500/20', text: 'text-blue-400', icon: Clock },
  active: { bg: 'bg-green-500/20', text: 'text-green-400', icon: CheckCircle2 },
  paused: { bg: 'bg-yellow-500/20', text: 'text-yellow-400', icon: AlertCircle },
  completed: { bg: 'bg-purple-500/20', text: 'text-purple-400', icon: CheckCircle2 },
  archived: { bg: 'bg-gray-500/20', text: 'text-gray-400', icon: Archive },
};

const CHART_COLORS = ['#8b5cf6', '#3b82f6', '#10b981', '#f59e0b', '#ef4444'];

export default function ProjectsPage() {
  const { projects, fetchProjects, createProject } = useProjectStore();
  const { tasks } = useTaskStore();
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);

  useEffect(() => {
    fetchProjects();
  }, [fetchProjects]);

  const getProjectStats = (projectId: string) => {
    const projectTasks = tasks.filter((t) => t.projectId === projectId);
    const completed = projectTasks.filter((t) => t.status === 'done').length;
    const total = projectTasks.length;
    const progress = total > 0 ? Math.round((completed / total) * 100) : 0;
    
    return { total, completed, progress };
  };

  const getProjectTaskData = (projectId: string) => {
    const projectTasks = tasks.filter((t) => t.projectId === projectId);
    const statusCounts = {
      backlog: projectTasks.filter((t) => t.status === 'backlog').length,
      todo: projectTasks.filter((t) => t.status === 'todo').length,
      in_progress: projectTasks.filter((t) => t.status === 'in_progress').length,
      review: projectTasks.filter((t) => t.status === 'review').length,
      done: projectTasks.filter((t) => t.status === 'done').length,
    };
    
    return [
      { name: 'Backlog', value: statusCounts.backlog, color: '#8b5cf6' },
      { name: 'To Do', value: statusCounts.todo, color: '#6366f1' },
      { name: 'In Progress', value: statusCounts.in_progress, color: '#3b82f6' },
      { name: 'Review', value: statusCounts.review, color: '#f59e0b' },
      { name: 'Done', value: statusCounts.done, color: '#10b981' },
    ].filter((item) => item.value > 0);
  };

  const handleCreateProject = async (e: React.FormEvent) => {
    e.preventDefault();
    const formData = new FormData(e.target as HTMLFormElement);
    
    await createProject({
      name: formData.get('name') as string,
      description: formData.get('description') as string,
      status: 'planning',
      color: formData.get('color') as string,
      progress: 0,
      taskCount: { total: 0, completed: 0 },
      linkedMemories: [],
      linkedDocs: [],
    });
    
    setIsCreateOpen(false);
  };

  const overallStats = {
    total: projects.length,
    active: projects.filter((p) => p.status === 'active').length,
    completed: projects.filter((p) => p.status === 'completed').length,
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold text-white/90 flex items-center gap-3">
            <FolderKanban className="w-6 h-6 text-purple-500" />
            Projects
          </h1>
          <p className="text-white/40 text-sm mt-1">
            Manage your projects and track progress
          </p>
        </div>
        
        <button
          onClick={() => setIsCreateOpen(true)}
          className="flex items-center gap-2 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
        >
          <Plus className="w-4 h-4" />
          New Project
        </button>
      </div>

      {/* Overall Stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="text-3xl font-semibold text-white/90">{overallStats.total}</div>
          <div className="text-sm text-white/40">Total Projects</div>
        </div>
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="text-3xl font-semibold text-blue-400">{overallStats.active}</div>
          <div className="text-sm text-white/40">Active</div>
        </div>
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="text-3xl font-semibold text-green-400">{overallStats.completed}</div>
          <div className="text-sm text-white/40">Completed</div>
        </div>
      </div>

      {/* Projects Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 overflow-auto">
        {projects.map((project) => {
          const stats = getProjectStats(project.id);
          const chartData = getProjectTaskData(project.id);
          const StatusIcon = STATUS_COLORS[project.status].icon;
          
          return (
            <div
              key={project.id}
              onClick={() => setSelectedProject(project)}
              className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5 hover:border-purple-500/30 transition-colors cursor-pointer"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div
                    className="w-10 h-10 rounded-lg flex items-center justify-center"
                    style={{ backgroundColor: `${project.color}20` }}
                  >
                    <FolderKanban className="w-5 h-5" style={{ color: project.color }} />
                  </div>
                  <div>
                    <h3 className="font-semibold text-white/90">{project.name}</h3>
                    <div className="flex items-center gap-2 text-sm text-white/40">
                      <StatusIcon className="w-3 h-3" />
                      <span className="capitalize">{project.status}</span>
                    </div>
                  </div>
                </div>
                
                <button className="p-1 hover:bg-white/[0.06] rounded">
                  <MoreHorizontal className="w-4 h-4 text-white/40" />
                </button>
              </div>
              
              <p className="text-sm text-white/60 mb-4 line-clamp-2">
                {project.description || 'No description'}
              </p>
              
              {/* Progress */}
              <div className="mb-4">
                <div className="flex items-center justify-between text-sm mb-2">
                  <span className="text-white/40">Progress</span>
                  <span className="text-white/90 font-medium">{stats.progress}%</span>
                </div>
                <div className="h-2 bg-white/[0.06] rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all"
                    style={{
                      width: `${stats.progress}%`,
                      backgroundColor: project.color,
                    }}
                  />
                </div>
                <div className="flex items-center gap-4 mt-2 text-xs text-white/40">
                  <span>{stats.completed} / {stats.total} tasks</span>
                </div>
              </div>
              
              {/* Mini Chart */}
              {chartData.length > 0 && (
                <div className="h-24">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={chartData}
                        cx="50%"
                        cy="50%"
                        innerRadius={25}
                        outerRadius={35}
                        dataKey="value"
                      >
                        {chartData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                      <Tooltip
                        contentStyle={{
                          backgroundColor: '#1a1a1a',
                          border: '1px solid rgba(255,255,255,0.1)',
                          borderRadius: '8px',
                        }}
                        itemStyle={{ color: '#fff' }}
                      />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Create Project Modal */}
      {isCreateOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-[#0a0a0a] border border-white/[0.06] rounded-xl p-6 w-full max-w-md">
            <h2 className="text-xl font-semibold text-white/90 mb-4">Create New Project</h2>
            
            <form onSubmit={handleCreateProject}>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm text-white/60 mb-1">Name</label>
                  <input
                    name="name"
                    type="text"
                    required
                    className="w-full px-3 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 focus:outline-none focus:border-purple-500/50"
                    placeholder="Project name"
                  />
                </div>
                
                <div>
                  <label className="block text-sm text-white/60 mb-1">Description</label>
                  <textarea
                    name="description"
                    rows={3}
                    className="w-full px-3 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 focus:outline-none focus:border-purple-500/50"
                    placeholder="Project description"
                  />
                </div>
                
                <div>
                  <label className="block text-sm text-white/60 mb-1">Color</label>
                  <select
                    name="color"
                    className="w-full px-3 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/90 focus:outline-none focus:border-purple-500/50"
                  >
                    <option value="#8b5cf6">Purple</option>
                    <option value="#3b82f6">Blue</option>
                    <option value="#10b981">Green</option>
                    <option value="#f59e0b">Yellow</option>
                    <option value="#ef4444">Red</option>
                  </select>
                </div>
              </div>
              
              <div className="flex gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => setIsCreateOpen(false)}
                  className="flex-1 px-4 py-2 bg-white/[0.02] border border-white/[0.06] rounded-lg text-white/60 hover:bg-white/[0.04] transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
                >
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
