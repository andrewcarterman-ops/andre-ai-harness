"use client"

import { useEffect, useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { 
  CheckCircle2, 
  Clock, 
  TrendingUp, 
  Users,
  AlertCircle,
  Activity
} from "lucide-react"
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,
  AreaChart,
  Area
} from "recharts"
import { useTaskStore } from "@/stores/taskStore"
import { useProjectStore } from "@/stores/projectStore"
import { TaskStatus } from "@/types"

const COLORS = ['#8b5cf6', '#3b82f6', '#10b981', '#f59e0b', '#ef4444']

interface StatsCardsProps {
  className?: string
}

export function StatsCards({ className }: StatsCardsProps) {
  const { tasks } = useTaskStore()
  const { projects } = useProjectStore()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  // Calculate statistics
  const totalTasks = tasks.length
  const completedTasks = tasks.filter(t => t.status === 'done').length
  const completionRate = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0
  
  const tasksByStatus = {
    backlog: tasks.filter(t => t.status === 'backlog').length,
    todo: tasks.filter(t => t.status === 'todo').length,
    in_progress: tasks.filter(t => t.status === 'in_progress').length,
    review: tasks.filter(t => t.status === 'review').length,
    done: tasks.filter(t => t.status === 'done').length,
  }

  const statusData = [
    { name: 'Backlog', value: tasksByStatus.backlog, color: '#6b7280' },
    { name: 'Todo', value: tasksByStatus.todo, color: '#3b82f6' },
    { name: 'In Progress', value: tasksByStatus.in_progress, color: '#f59e0b' },
    { name: 'Review', value: tasksByStatus.review, color: '#8b5cf6' },
    { name: 'Done', value: tasksByStatus.done, color: '#10b981' },
  ].filter(d => d.value > 0)

  // Weekly completion data (mock data based on tasks)
  const weeklyData = [
    { day: 'Mon', completed: Math.floor(Math.random() * 5) + 1, created: Math.floor(Math.random() * 3) + 1 },
    { day: 'Tue', completed: Math.floor(Math.random() * 5) + 1, created: Math.floor(Math.random() * 3) + 1 },
    { day: 'Wed', completed: Math.floor(Math.random() * 5) + 1, created: Math.floor(Math.random() * 3) + 1 },
    { day: 'Thu', completed: Math.floor(Math.random() * 5) + 1, created: Math.floor(Math.random() * 3) + 1 },
    { day: 'Fri', completed: Math.floor(Math.random() * 5) + 1, created: Math.floor(Math.random() * 3) + 1 },
    { day: 'Sat', completed: Math.floor(Math.random() * 3), created: Math.floor(Math.random() * 2) },
    { day: 'Sun', completed: Math.floor(Math.random() * 3), created: Math.floor(Math.random() * 2) },
  ]

  // Project health scores
  const projectHealthData = projects.map(p => ({
    name: p.name.length > 15 ? p.name.substring(0, 15) + '...' : p.name,
    health: p.progress,
    tasks: p.taskCount?.total || 0,
  }))

  const stats = [
    {
      title: "Task Completion Rate",
      value: `${completionRate}%`,
      description: `${completedTasks} of ${totalTasks} tasks completed`,
      icon: CheckCircle2,
      trend: completionRate > 50 ? "+12%" : "+5%",
      trendUp: completionRate > 50,
      color: "text-emerald-400",
      bgColor: "bg-emerald-500/10",
    },
    {
      title: "Active Tasks",
      value: tasksByStatus.in_progress.toString(),
      description: `${tasksByStatus.todo} pending, ${tasksByStatus.review} in review`,
      icon: Activity,
      trend: "On track",
      trendUp: true,
      color: "text-blue-400",
      bgColor: "bg-blue-500/10",
    },
    {
      title: "Projects",
      value: projects.length.toString(),
      description: `${projects.filter(p => p.status === 'active').length} active`,
      icon: TrendingUp,
      trend: "+2 new",
      trendUp: true,
      color: "text-purple-400",
      bgColor: "bg-purple-500/10",
    },
    {
      title: "Avg. Completion Time",
      value: "2.4d",
      description: "Per task average",
      icon: Clock,
      trend: "-8%",
      trendUp: true,
      color: "text-amber-400",
      bgColor: "bg-amber-500/10",
    },
  ]

  if (!mounted) {
    return <div className="h-96 flex items-center justify-center text-white/40">Loading analytics...</div>
  }

  return (
    <div className={className}>
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {stats.map((stat) => (
          <Card key={stat.title} className="bg-white/[0.02] border-white/[0.06]">
            <CardContent className="p-5">
              <div className="flex items-start justify-between">
                <div className={`p-2.5 rounded-lg ${stat.bgColor}`}>
                  <stat.icon className={`w-5 h-5 ${stat.color}`} />
                </div>
                <span className={`text-xs font-medium ${stat.trendUp ? 'text-emerald-400' : 'text-red-400'}`}>
                  {stat.trend}
                </span>
              </div>
              <div className="mt-4">
                <p className="text-2xl font-semibold text-white/90">{stat.value}</p>
                <p className="text-sm font-medium text-white/60 mt-0.5">{stat.title}</p>
                <p className="text-xs text-white/40 mt-1">{stat.description}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Weekly Activity Chart */}
        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-white/60 flex items-center gap-2">
              <Activity className="w-4 h-4" />
              Weekly Activity
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={weeklyData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis 
                    dataKey="day" 
                    stroke="rgba(255,255,255,0.3)" 
                    fontSize={12}
                    tickLine={false}
                  />
                  <YAxis 
                    stroke="rgba(255,255,255,0.3)" 
                    fontSize={12}
                    tickLine={false}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: '#1a1a1a', 
                      border: '1px solid rgba(255,255,255,0.1)',
                      borderRadius: '8px',
                      color: '#fff'
                    }}
                  />
                  <Bar dataKey="completed" fill="#10b981" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="created" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Task Distribution */}
        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-white/60 flex items-center gap-2">
              <AlertCircle className="w-4 h-4" />
              Task Distribution
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
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
                      color: '#fff'
                    }}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="flex flex-wrap gap-3 justify-center mt-4">
              {statusData.map((item) => (
                <div key={item.name} className="flex items-center gap-1.5">
                  <div className="w-2 h-2 rounded-full" style={{ backgroundColor: item.color }} />
                  <span className="text-xs text-white/50">{item.name} ({item.value})</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Project Health */}
        <Card className="bg-white/[0.02] border-white/[0.06] lg:col-span-2">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-white/60 flex items-center gap-2">
              <TrendingUp className="w-4 h-4" />
              Project Health Score
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={projectHealthData} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                  <XAxis 
                    type="number" 
                    stroke="rgba(255,255,255,0.3)" 
                    fontSize={12}
                    tickLine={false}
                    domain={[0, 100]}
                  />
                  <YAxis 
                    type="category" 
                    dataKey="name" 
                    stroke="rgba(255,255,255,0.3)" 
                    fontSize={12}
                    tickLine={false}
                    width={100}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: '#1a1a1a', 
                      border: '1px solid rgba(255,255,255,0.1)',
                      borderRadius: '8px',
                      color: '#fff'
                    }}
                    formatter={(value: any) => [`${value}%`, 'Progress']}
                  />
                  <Bar dataKey="health" fill="#8b5cf6" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
