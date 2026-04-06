'use client';

import { useEffect } from 'react';
import { useTaskStore } from '@/stores/taskStore';
import { useProjectStore } from '@/stores/projectStore';
import { 
  LayoutDashboard, 
  CheckCircle2, 
  Clock, 
  AlertCircle,
  TrendingUp,
  Users,
  FolderKanban,
  Calendar
} from 'lucide-react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area
} from 'recharts';
import { format, subDays, startOfDay } from 'date-fns';

export default function DashboardPage() {
  const { tasks, fetchTasks } = useTaskStore();
  const { projects, fetchProjects } = useProjectStore();

  useEffect(() => {
    fetchTasks();
    fetchProjects();
  }, [fetchTasks, fetchProjects]);

  // Calculate stats
  const stats = {
    totalTasks: tasks.length,
    completedTasks: tasks.filter((t) => t.status === 'done').length,
    inProgressTasks: tasks.filter((t) => t.status === 'in_progress').length,
    overdueTasks: tasks.filter((t) => {
      if (!t.dueDate || t.status === 'done') return false;
      return new Date(t.dueDate) < new Date();
    }).length,
    totalProjects: projects.length,
    activeProjects: projects.filter((p) => p.status === 'active').length,
  };

  const completionRate = stats.totalTasks > 0 
    ? Math.round((stats.completedTasks / stats.totalTasks) * 100) 
    : 0;

  // Task status distribution
  const statusData = [
    { name: 'Backlog', value: tasks.filter((t) => t.status === 'backlog').length, color: '#8b5cf6' },
    { name: 'To Do', value: tasks.filter((t) => t.status === 'todo').length, color: '#6366f1' },
    { name: 'In Progress', value: tasks.filter((t) => t.status === 'in_progress').length, color: '#3b82f6' },
    { name: 'Review', value: tasks.filter((t) => t.status === 'review').length, color: '#f59e0b' },
    { name: 'Done', value: tasks.filter((t) => t.status === 'done').length, color: '#10b981' },
  ].filter((item) => item.value > 0);

  // Priority distribution
  const priorityData = [
    { name: 'Low', value: tasks.filter((t) => t.priority === 'low').length, color: '#6b7280' },
    { name: 'Medium', value: tasks.filter((t) => t.priority === 'medium').length, color: '#3b82f6' },
    { name: 'High', value: tasks.filter((t) => t.priority === 'high').length, color: '#f59e0b' },
    { name: 'Urgent', value: tasks.filter((t) => t.priority === 'urgent').length, color: '#ef4444' },
  ].filter((item) => item.value > 0);

  // Tasks by project
  const projectTaskData = projects.map((project) => ({
    name: project.name.length > 15 ? project.name.slice(0, 15) + '...' : project.name,
    total: tasks.filter((t) => t.projectId === project.id).length,
    completed: tasks.filter((t) => t.projectId === project.id && t.status === 'done').length,
  })).slice(0, 6);

  // Activity over time (last 7 days)
  const activityData = Array.from({ length: 7 }, (_, i) => {
    const date = subDays(new Date(), 6 - i);
    const dayTasks = tasks.filter((t) => {
      const taskDate = new Date(t.createdAt);
      return taskDate >= startOfDay(date) && taskDate < startOfDay(subDays(date, -1));
    });
    
    return {
      date: format(date, 'MMM dd'),
      created: dayTasks.length,
      completed: dayTasks.filter((t) => t.status === 'done').length,
    };
  });

  // Assignee distribution
  const assigneeData = [
    { name: 'You', value: tasks.filter((t) => t.assignee.type === 'user').length, color: '#3b82f6' },
    { name: 'AI Agent', value: tasks.filter((t) => t.assignee.type === 'ai').length, color: '#8b5cf6' },
  ].filter((item) => item.value > 0);

  return (
    <div className="min-h-[calc(100vh-7rem)]">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-semibold text-white/90 flex items-center gap-3">
          <LayoutDashboard className="w-6 h-6 text-purple-500" />
          Dashboard
        </h1>
        <p className="text-white/40 text-sm mt-1">
          Overview of your tasks, projects, and productivity
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center justify-between mb-2">
            <CheckCircle2 className="w-5 h-5 text-green-500" />
            <span className="text-xs text-green-400 bg-green-500/10 px-2 py-1 rounded-full">
              {completionRate}% done
            </span>
          </div>
          <div className="text-3xl font-semibold text-white/90">{stats.completedTasks}</div>
          <div className="text-sm text-white/40">Completed Tasks</div>
        </div>

        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center justify-between mb-2">
            <Clock className="w-5 h-5 text-blue-500" />
          </div>
          <div className="text-3xl font-semibold text-white/90">{stats.inProgressTasks}</div>
          <div className="text-sm text-white/40">In Progress</div>
        </div>

        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center justify-between mb-2">
            <AlertCircle className="w-5 h-5 text-red-500" />
          </div>
          <div className="text-3xl font-semibold text-white/90">{stats.overdueTasks}</div>
          <div className="text-sm text-white/40">Overdue Tasks</div>
        </div>

        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center justify-between mb-2">
            <FolderKanban className="w-5 h-5 text-purple-500" />
          </div>
          <div className="text-3xl font-semibold text-white/90">{stats.activeProjects}</div>
          <div className="text-sm text-white/40">Active Projects</div>
        </div>
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Activity Over Time */}
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5">
          <h3 className="text-lg font-semibold text-white/90 mb-4 flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-purple-500" />
            Activity (Last 7 Days)
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={activityData}>
                <defs>
                  <linearGradient id="colorCreated" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0}/>
                  </linearGradient>
                  <linearGradient id="colorCompleted" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                <XAxis dataKey="date" stroke="rgba(255,255,255,0.3)" fontSize={12} />
                <YAxis stroke="rgba(255,255,255,0.3)" fontSize={12} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#1a1a1a',
                    border: '1px solid rgba(255,255,255,0.1)',
                    borderRadius: '8px',
                  }}
                  itemStyle={{ color: '#fff' }}
                />
                <Area
                  type="monotone"
                  dataKey="created"
                  name="Created"
                  stroke="#8b5cf6"
                  fillOpacity={1}
                  fill="url(#colorCreated)"
                />
                <Area
                  type="monotone"
                  dataKey="completed"
                  name="Completed"
                  stroke="#10b981"
                  fillOpacity={1}
                  fill="url(#colorCompleted)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Task Status Distribution */}
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5">
          <h3 className="text-lg font-semibold text-white/90 mb-4 flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5 text-green-500" />
            Task Status
          </h3>
          <div className="h-64">
            {statusData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={statusData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={80}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {statusData.map((entry, index) => (
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
            ) : (
              <div className="flex items-center justify-center h-full text-white/40">
                No tasks yet
              </div>
            )}
          </div>
          <div className="flex flex-wrap gap-3 justify-center mt-2">
            {statusData.map((item) => (
              <div key={item.name} className="flex items-center gap-2 text-sm">
                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }} />
                <span className="text-white/60">{item.name}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Priority Distribution */}
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5">
          <h3 className="text-lg font-semibold text-white/90 mb-4 flex items-center gap-2">
            <AlertCircle className="w-5 h-5 text-yellow-500" />
            Task Priority
          </h3>
          <div className="h-64">
            {priorityData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={priorityData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis dataKey="name" stroke="rgba(255,255,255,0.3)" fontSize={12} />
                  <YAxis stroke="rgba(255,255,255,0.3)" fontSize={12} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#1a1a1a',
                      border: '1px solid rgba(255,255,255,0.1)',
                      borderRadius: '8px',
                    }}
                    itemStyle={{ color: '#fff' }}
                  />
                  <Bar dataKey="value" name="Tasks" radius={[4, 4, 0, 0]}>
                    {priorityData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex items-center justify-center h-full text-white/40">
                No tasks yet
              </div>
            )}
          </div>
        </div>

        {/* Tasks by Project */}
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5">
          <h3 className="text-lg font-semibold text-white/90 mb-4 flex items-center gap-2">
            <FolderKanban className="w-5 h-5 text-blue-500" />
            Tasks by Project
          </h3>
          <div className="h-64">
            {projectTaskData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={projectTaskData} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis type="number" stroke="rgba(255,255,255,0.3)" fontSize={12} />
                  <YAxis dataKey="name" type="category" stroke="rgba(255,255,255,0.3)" fontSize={12} width={100} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#1a1a1a',
                      border: '1px solid rgba(255,255,255,0.1)',
                      borderRadius: '8px',
                    }}
                    itemStyle={{ color: '#fff' }}
                  />
                  <Bar dataKey="total" name="Total Tasks" fill="#8b5cf6" radius={[0, 4, 4, 0]} />
                  <Bar dataKey="completed" name="Completed" fill="#10b981" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex items-center justify-center h-full text-white/40">
                No projects yet
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
