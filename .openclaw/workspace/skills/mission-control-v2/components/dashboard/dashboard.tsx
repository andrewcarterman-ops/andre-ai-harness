"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { 
  Plus, 
  ArrowRight,
  Zap,
  Wrench,
  Layers,
  Sparkles,
  ChevronRight
} from "lucide-react"
import Link from "next/link"

const templates = [
  { name: "API Connector", description: "Connect to external APIs", icon: "🔗" },
  { name: "File Processor", description: "Process files and documents", icon: "📁" },
  { name: "Data Transformer", description: "Transform data formats", icon: "🔄" },
  { name: "Automation", description: "Automate repetitive tasks", icon: "⚙️" },
  { name: "Integration", description: "Integrate with services", icon: "🔌" },
  { name: "Custom", description: "Build something unique", icon: "🎨" },
]

const recentTools = [
  { name: "weather-checker", type: "api-connector", updated: "2h ago" },
  { name: "pdf-processor", type: "file-processor", updated: "1d ago" },
  { name: "data-cleaner", type: "data-transformer", updated: "3d ago" },
]

export function Dashboard() {
  return (
    <div className="space-y-8 animate-fade-in">
      {/* Welcome Section */}
      <div className="space-y-2">
        <h1 className="text-2xl font-semibold text-white/90">Welcome back, Parzival</h1>
        <p className="text-white/40">Here's what's happening in your workspace</p>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Link href="/create">
          <Card className="group bg-white/[0.02] border-white/[0.06] hover:bg-white/[0.04] hover:border-white/[0.1] transition-all duration-200 cursor-pointer">
            <CardContent className="p-5">
              <div className="flex items-start justify-between">
                <div className="p-2.5 rounded-lg bg-purple-500/10">
                  <Plus className="w-5 h-5 text-purple-400" />
                </div>
                <ArrowRight className="w-4 h-4 text-white/20 group-hover:text-white/40 group-hover:translate-x-0.5 transition-all" />
              </div>
              <div className="mt-4">
                <h3 className="font-medium text-white/90">Create Tool</h3>
                <p className="text-sm text-white/40 mt-1">Build a new tool from templates</p>
              </div>
            </CardContent>
          </Card>
        </Link>

        <Link href="/tools">
          <Card className="group bg-white/[0.02] border-white/[0.06] hover:bg-white/[0.04] hover:border-white/[0.1] transition-all duration-200 cursor-pointer">
            <CardContent className="p-5">
              <div className="flex items-start justify-between">
                <div className="p-2.5 rounded-lg bg-blue-500/10">
                  <Wrench className="w-5 h-5 text-blue-400" />
                </div>
                <ArrowRight className="w-4 h-4 text-white/20 group-hover:text-white/40 group-hover:translate-x-0.5 transition-all" />
              </div>
              <div className="mt-4">
                <h3 className="font-medium text-white/90">My Tools</h3>
                <p className="text-sm text-white/40 mt-1">View and manage 12 tools</p>
              </div>
            </CardContent>
          </Card>
        </Link>

        <Link href="/templates">
          <Card className="group bg-white/[0.02] border-white/[0.06] hover:bg-white/[0.04] hover:border-white/[0.1] transition-all duration-200 cursor-pointer">
            <CardContent className="p-5">
              <div className="flex items-start justify-between">
                <div className="p-2.5 rounded-lg bg-green-500/10">
                  <Layers className="w-5 h-5 text-green-400" />
                </div>
                <ArrowRight className="w-4 h-4 text-white/20 group-hover:text-white/40 group-hover:translate-x-0.5 transition-all" />
              </div>
              <div className="mt-4">
                <h3 className="font-medium text-white/90">Templates</h3>
                <p className="text-sm text-white/40 mt-1">Browse 6 available templates</p>
              </div>
            </CardContent>
          </Card>
        </Link>
      </div>

      {/* Templates Grid */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-medium text-white/60 uppercase tracking-wider">Quick Start Templates</h2>
          <Link href="/templates">
            <Button variant="ghost" size="sm" className="text-white/40 hover:text-white">
              View all
              <ChevronRight className="w-4 h-4 ml-1" />
            </Button>
          </Link>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
          {templates.map((template) => (
            <Link key={template.name} href={`/create?template=${template.name.toLowerCase().replace(' ', '-')}`}>
              <Card className="group bg-white/[0.02] border-white/[0.06] hover:bg-white/[0.04] hover:border-white/[0.1] transition-all duration-200 cursor-pointer h-full">
                <CardContent className="p-4">
                  <div className="text-2xl mb-3">{template.icon}</div>
                  <h3 className="font-medium text-white/90 text-sm">{template.name}</h3>
                  <p className="text-xs text-white/40 mt-1">{template.description}</p>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      </div>

      {/* Recent Activity */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-medium text-white/60 uppercase tracking-wider">Recent Tools</h2>
        </div>

        <Card className="bg-white/[0.02] border-white/[0.06]">
          <CardContent className="p-0">
            {recentTools.map((tool, i) => (
              <div 
                key={tool.name}
                className={`flex items-center justify-between px-4 py-3 hover:bg-white/[0.02] transition-colors ${
                  i !== recentTools.length - 1 ? 'border-b border-white/[0.04]' : ''
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-white/[0.04] flex items-center justify-center">
                    <Zap className="w-4 h-4 text-white/40" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-white/90">{tool.name}</p>
                    <Badge variant="secondary" className="text-[10px] bg-white/[0.06] text-white/50 border-0">
                      {tool.type}
                    </Badge>
                  </div>
                </div>
                <span className="text-xs text-white/30">{tool.updated}</span>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      {/* Pro Tip */}
      <div className="flex items-start gap-3 p-4 rounded-lg bg-purple-500/[0.08] border border-purple-500/[0.12]">
        <Sparkles className="w-5 h-5 text-purple-400 mt-0.5" />
        <div>
          <p className="text-sm font-medium text-purple-300">Pro Tip</p>
          <p className="text-sm text-purple-200/70 mt-1">Press ⌘K to open the command palette and quickly navigate between tools and templates.</p>
        </div>
      </div>
    </div>
  )
}
