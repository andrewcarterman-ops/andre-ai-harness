"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { FolderOpen, RefreshCw } from "lucide-react"

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Settings</h1>
        <p className="text-muted-foreground">Configure Mission Control and manage your workspace</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Workspace</CardTitle>
          <CardDescription>Manage your tools directory and configuration</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
            <div>
              <p className="font-medium">Skills Directory</p>
              <p className="text-sm text-muted-foreground">~/.openclaw/workspace/skills</p>
            </div>
            <Button variant="outline" size="sm">
              <FolderOpen className="w-4 h-4 mr-2" />
              Open Folder
            </Button>
          </div>

          <div className="flex items-center justify-between p-4 bg-muted rounded-lg">
            <div>
              <p className="font-medium">Python Path</p>
              <p className="text-sm text-muted-foreground">System Python</p>
            </div>
            <code className="px-2 py-1 bg-background rounded text-xs">python</code>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>System</CardTitle>
          <CardDescription>System information and maintenance</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground">Version</p>
              <p className="font-medium">2.0.0</p>
            </div>
            <div className="p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground">Framework</p>
              <p className="font-medium">Next.js 14</p>
            </div>
            <div className="p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground">UI Library</p>
              <p className="font-medium">Tailwind CSS + Radix</p>
            </div>
            <div className="p-4 bg-muted rounded-lg">
              <p className="text-sm text-muted-foreground">Status</p>
              <p className="font-medium text-green-600">Online</p>
            </div>
          </div>

          <Button variant="outline" className="w-full">
            <RefreshCw className="w-4 h-4 mr-2" />
            Reload Configuration
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>About</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-muted-foreground">
            Mission Control is your personal tool factory for OpenClaw. 
            Create custom skills with pre-built templates, automatic structure generation, 
            and integrated documentation.
          </p>
          <p className="text-sm text-muted-foreground mt-4">
            Built with ❤️ by Andrew for Parzival
          </p>
        </CardContent>
      </Card>
    </div>
  )
}
