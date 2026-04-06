'use client';

import { useEffect, useState } from 'react';
import { Agent, AgentStatus, Task } from '@/types';
import { 
  Users, 
  Bot, 
  Activity, 
  CheckCircle2, 
  Clock,
  AlertCircle,
  Zap,
  TrendingUp,
  Calendar
} from 'lucide-react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { useTaskStore } from '@/stores/taskStore';
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
} from 'recharts';

const STATUS_CONFIG: Record<AgentStatus, { color: string; icon: any; label: string }> = {
  idle: { color: 'text-gray-400', icon: Clock, label: 'Idle' },
  working: { color: 'text-green-400', icon: Activity, label: 'Working' },
  paused: { color: 'text-yellow-400', icon: AlertCircle, label: 'Paused' },
  offline: { color: 'text-red-400', icon: AlertCircle, label: 'Offline' },
};

export default function TeamPage() {
  const [agents, setAgents] = useState<Agent[]>([]);
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const { tasks } = useTaskStore();

  useEffect(() => {
    fetchAgents();
    const interval = setInterval(fetchAgents, 5000); // Refresh every 5s
    return () => clearInterval(interval);
  }, []);

  const fetchAgents = async () => {
    try {
      const res = await fetch('/api/agents');
      if (res.ok) {
        const data = await res.json();
        setAgents(data);
        if (selectedAgent) {
          const updated = data.find((a: Agent) => a.id === selectedAgent.id);
          if (updated) setSelectedAgent(updated);
        }
      }
    } catch (error) {
      console.error('Failed to fetch agents:', error);
    }
  };

  const getAgentTasks = (agentId: string) => {
    return tasks.filter((t) => t.assignee.id === agentId);
  };

  const getAgentStats = (agentId: string) => {
    const agentTasks = getAgentTasks(agentId);
    const completed = agentTasks.filter((t) => t.status === 'done').length;
    const inProgress = agentTasks.filter((t) => t.status === 'in_progress').length;
    const total = agentTasks.length;
    
    return { completed, inProgress, total };
  };

  const overallStats = {
    totalAgents: agents.length,
    activeAgents: agents.filter((a) => a.status === 'working').length,
    idleAgents: agents.filter((a) => a.status === 'idle').length,
    totalTasksCompleted: agents.reduce((sum, a) => sum + a.performance.tasksCompleted, 0),
  };

  const statusData = [
    { name: 'Working', value: agents.filter((a) => a.status === 'working').length, color: '#10b981' },
    { name: 'Idle', value: agents.filter((a) => a.status === 'idle').length, color: '#6b7280' },
    { name: 'Paused', value: agents.filter((a) => a.status === 'paused').length, color: '#f59e0b' },
    { name: 'Offline', value: agents.filter((a) => a.status === 'offline').length, color: '#ef4444' },
  ].filter((item) => item.value > 0);

  const performanceData = agents.map((agent) => ({
    name: agent.name,
    tasks: agent.performance.tasksCompleted,
    successRate: Math.round(agent.performance.successRate * 100),
  }));

  return (
    <div className="h-full overflow-auto">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-semibold text-white/90 flex items-center gap-3">
          <Users className="w-6 h-6 text-purple-500" />
          Team
        </h1>
        <p className="text-white/40 text-sm mt-1">
          Manage your AI agents and track performance
        </p>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center gap-2 mb-2">
            <Bot className="w-5 h-5 text-purple-500" />
            <span className="text-sm text-white/40">Total Agents</span>
          </div>
          <div className="text-3xl font-semibold text-white/90">{overallStats.totalAgents}</div>
        </div>

        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center gap-2 mb-2">
            <Activity className="w-5 h-5 text-green-500" />
            <span className="text-sm text-white/40">Active</span>
          </div>
          <div className="text-3xl font-semibold text-green-400">{overallStats.activeAgents}</div>
        </div>

        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center gap-2 mb-2">
            <Clock className="w-5 h-5 text-yellow-500" />
            <span className="text-sm text-white/40">Idle</span>
          </div>
          <div className="text-3xl font-semibold text-yellow-400">{overallStats.idleAgents}</div>
        </div>

        <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
          <div className="flex items-center gap-2 mb-2">
            <CheckCircle2 className="w-5 h-5 text-blue-500" />
            <span className="text-sm text-white/40">Tasks Done</span>
          </div>
          <div className="text-3xl font-semibold text-blue-400">{overallStats.totalTasksCompleted}</div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Agent List */}
        <div className="lg:col-span-2 space-y-4">
          <h2 className="text-lg font-semibold text-white/90 mb-4">Agents</h2>
          
          {agents.map((agent) => {
            const stats = getAgentStats(agent.id);
            const statusConfig = STATUS_CONFIG[agent.status];
            const StatusIcon = statusConfig.icon;
            
            return (
              <div
                key={agent.id}
                onClick={() => setSelectedAgent(agent)}
                className={cn(
                  'p-5 rounded-xl border cursor-pointer transition-all',
                  selectedAgent?.id === agent.id
                    ? 'bg-purple-500/10 border-purple-500/30'
                    : 'bg-white/[0.02] border-white/[0.06] hover:border-white/[0.1]'
                )}
              >
                <div className="flex items-start gap-4">
                  {/* Avatar */}
                  <div className="relative">
                    <div className="w-14 h-14 rounded-full bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center">
                      <Bot className="w-7 h-7 text-white" />
                    </div>
                    <div
                      className={cn(
                        'absolute -bottom-1 -right-1 w-5 h-5 rounded-full border-2 border-[#0a0a0a]',
                        agent.status === 'working' ? 'bg-green-500' :
                        agent.status === 'idle' ? 'bg-gray-500' :
                        agent.status === 'paused' ? 'bg-yellow-500' :
                        'bg-red-500'
                      )}
                    />
                  </div>
                  
                  {/* Info */}
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-1">
                      <h3 className="font-semibold text-white/90">{agent.name}</h3>
                      <div className={cn('flex items-center gap-1 text-sm', statusConfig.color)}>
                        <StatusIcon className="w-4 h-4" />
                        <span>{statusConfig.label}</span>
                      </div>
                    </div>
                    
                    <p className="text-sm text-white/50 mb-3">{agent.role}</p>
                    
                    {/* Capabilities */}
                    <div className="flex flex-wrap gap-2 mb-3">
                      {agent.capabilities.slice(0, 4).map((cap) => (
                        <span
                          key={cap}
                          className="px-2 py-1 bg-white/[0.04] rounded text-xs text-white/60"
                        >
                          {cap}
                        </span>
                      ))}
                    </div>
                    
                    {/* Stats */}
                    <div className="grid grid-cols-3 gap-4 text-sm">
                      <div>
                        <div className="text-white/40">Tasks</div>
                        <div className="text-white/90 font-medium">
                          {stats.completed}/{stats.total}
                        </div>
                      </div>
                      
                      <div>
                        <div className="text-white/40">Success Rate</div>
                        <div className="text-green-400 font-medium">
                          {Math.round(agent.performance.successRate * 100)}%
                        </div>
                      </div>
                      
                      <div>
                        <div className="text-white/40">Avg Time</div>
                        <div className="text-white/90 font-medium">
                          {Math.round(agent.performance.avgCompletionTime)}m
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                {/* Current Task */}
                {agent.currentTask && (
                  <div className="mt-4 pt-4 border-t border-white/[0.06]">
                    <div className="flex items-center gap-2 text-sm">
                      <Zap className="w-4 h-4 text-yellow-400" />
                      <span className="text-white/40">Current Task:</span>
                      <span className="text-white/80">{agent.currentTask}</span>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Status Distribution */}
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5">
            <h3 className="text-sm font-semibold text-white/90 mb-4">Agent Status</h3>
            
            <div className="h-48">
              {statusData.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={statusData}
                      cx="50%"
                      cy="50%"
                      innerRadius={40}
                      outerRadius={60}
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
                  No agents
                </div>
              )}
            </div>
            
            <div className="flex flex-wrap gap-2 justify-center">
              {statusData.map((item) => (
                <div key={item.name} className="flex items-center gap-1 text-xs">
                  <div className="w-2 h-2 rounded-full" style={{ backgroundColor: item.color }} />
                  <span className="text-white/60">{item.name}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Performance Chart */}
          {performanceData.length > 0 && (
            <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5">
              <h3 className="text-sm font-semibold text-white/90 mb-4">Tasks Completed</h3>
              
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={performanceData} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                    <XAxis type="number" stroke="rgba(255,255,255,0.3)" fontSize={12} />
                    <YAxis dataKey="name" type="category" stroke="rgba(255,255,255,0.3)" fontSize={11} width={80} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#1a1a1a',
                        border: '1px solid rgba(255,255,255,0.1)',
                        borderRadius: '8px',
                      }}
                      itemStyle={{ color: '#fff' }}
                    />
                    <Bar dataKey="tasks" fill="#8b5cf6" radius={[0, 4, 4, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
