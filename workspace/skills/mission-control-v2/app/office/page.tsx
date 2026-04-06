'use client';

import { useEffect, useState } from 'react';
import { Agent } from '@/types';
import { 
  Building2, 
  Users, 
  Zap,
  Bot,
  Activity
} from 'lucide-react';

export default function OfficePage() {
  const [agents, setAgents] = useState<Agent[]>([]);

  useEffect(() => {
    fetchAgents();
    const interval = setInterval(fetchAgents, 5000);
    return () => clearInterval(interval);
  }, []);

  const fetchAgents = async () => {
    try {
      const res = await fetch('/api/agents');
      if (res.ok) {
        const data = await res.json();
        setAgents(data);
      }
    } catch (error) {
      console.error('Failed to fetch agents:', error);
    }
  };

  const stats = {
    totalAgents: agents.length,
    working: agents.filter((a) => a.status === 'working').length,
    idle: agents.filter((a) => a.status === 'idle').length,
    offline: agents.filter((a) => a.status === 'offline').length,
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'working': return 'text-green-400 bg-green-500/10 border-green-500/20';
      case 'idle': return 'text-gray-400 bg-gray-500/10 border-gray-500/20';
      case 'paused': return 'text-yellow-400 bg-yellow-500/10 border-yellow-500/20';
      case 'offline': return 'text-red-400 bg-red-500/10 border-red-500/20';
      default: return 'text-gray-400 bg-gray-500/10 border-gray-500/20';
    }
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-semibold text-white/90 flex items-center gap-3">
            <Building2 className="w-6 h-6 text-purple-500" />
            Office
          </h1>
          <p className="text-white/40 text-sm mt-1">
            Team overview and agent status
          </p>
        </div>
        
        <div className="flex gap-4">
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-lg px-4 py-2 text-center">
            <div className="text-2xl font-semibold text-white/90">{stats.totalAgents}</div>
            <div className="text-xs text-white/40">Total Agents</div>
          </div>
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-lg px-4 py-2 text-center">
            <div className="text-2xl font-semibold text-green-400">{stats.working}</div>
            <div className="text-xs text-white/40">Working</div>
          </div>
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-lg px-4 py-2 text-center">
            <div className="text-2xl font-semibold text-gray-400">{stats.idle}</div>
            <div className="text-xs text-white/40">Idle</div>
          </div>
        </div>
      </div>

      <div className="flex gap-6 flex-1">
        {/* Agents Grid */}
        <div className="flex-1">
          <h2 className="text-lg font-semibold text-white/90 mb-4 flex items-center gap-2">
            <Users className="w-5 h-5 text-purple-500" />
            Active Agents
          </h2>

          {agents.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {agents.map((agent) => (
                <div
                  key={agent.id}
                  className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-5 hover:border-purple-500/30 transition-colors"
                >
                  <div className="flex items-start gap-4">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center flex-shrink-0">
                      <Bot className="w-6 h-6 text-white" />
                    </div>
                    
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <h3 className="font-semibold text-white/90">{agent.name}</h3>
                        <span className={cn('px-2 py-1 rounded-full text-xs border', getStatusColor(agent.status))}>
                          {agent.status}
                        </span>
                      </div>
                      
                      <p className="text-sm text-white/50 mb-3">{agent.role}</p>
                      
                      <div className="flex flex-wrap gap-2 mb-3">
                        {agent.capabilities.slice(0, 3).map((cap) => (
                          <span
                            key={cap}
                            className="px-2 py-1 bg-white/[0.04] rounded text-xs text-white/60"
                          >
                            {cap}
                          </span>
                        ))}
                      </div>
                      
                      <div className="grid grid-cols-3 gap-3 text-sm">
                        <div className="text-center p-2 bg-white/[0.02] rounded">
                          <div className="text-white/90 font-medium">{agent.performance.tasksCompleted}</div>
                          <div className="text-xs text-white/40">Tasks</div>
                        </div>
                        <div className="text-center p-2 bg-white/[0.02] rounded">
                          <div className="text-green-400 font-medium">{Math.round(agent.performance.successRate * 100)}%</div>
                          <div className="text-xs text-white/40">Success</div>
                        </div>
                        
                        <div className="text-center p-2 bg-white/[0.02] rounded">
                          <div className="text-white/90 font-medium">{Math.round(agent.performance.avgCompletionTime)}m</div>
                          <div className="text-xs text-white/40">Avg Time</div>
                        </div>
                      </div>
                      
                      {agent.currentTask && (
                        <div className="mt-3 pt-3 border-t border-white/[0.06]">
                          <div className="flex items-center gap-2 text-sm">
                            <Zap className="w-4 h-4 text-yellow-400" />
                            <span className="text-white/40">Current:</span>
                            <span className="text-white/80 truncate">{agent.currentTask}</span>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center h-64 text-white/40">
              <Bot className="w-16 h-16 mb-4 opacity-30" />
              <p className="text-lg">No agents registered yet</p>
              <p className="text-sm">Agents will appear here when they connect</p>
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="w-80 space-y-4">
          <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
            <h3 className="text-sm font-medium text-white/60 mb-3 flex items-center gap-2">
              <Activity className="w-4 h-4" />
              Status Overview
            </h3>
            
            <div className="space-y-2">
              {[
                { label: 'Working', value: stats.working, color: 'bg-green-500' },
                { label: 'Idle', value: stats.idle, color: 'bg-gray-500' },
                { label: 'Paused', value: stats.offline, color: 'bg-yellow-500' },
              ].map((item) => (
                <div key={item.label} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className={cn('w-3 h-3 rounded-full', item.color)} />
                    <span className="text-sm text-white/60">{item.label}</span>
                  </div>
                  <span className="text-sm text-white/90">{item.value}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white/[0.02] border border-white/[0.06] rounded-xl p-4">
            <h3 className="text-sm font-medium text-white/60 mb-3">2D Office View</h3>
            <div className="text-center py-8">
              <Building2 className="w-12 h-12 mx-auto mb-3 text-white/20" />
              <p className="text-white/40 text-sm">
                2D visualization coming in a future update
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Helper
function cn(...classes: (string | false | undefined)[]) {
  return classes.filter(Boolean).join(' ');
}
