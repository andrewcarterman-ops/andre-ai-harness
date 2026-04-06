"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { FolderOpen, FileText, Trash2, Play } from "lucide-react"

const tools = [
  {
    id: 1,
    name: "weather-checker",
    description: "Fetch weather data from external APIs",
    type: "api-connector",
    scripts: ["fetch.py"],
    lastModified: "2 hours ago",
  },
  {
    id: 2,
    name: "pdf-processor",
    description: "Process and manipulate PDF files",
    type: "file-processor",
    scripts: ["extract.py", "merge.py"],
    lastModified: "1 day ago",
  },
  {
    id: 3,
    name: "data-cleaner",
    description: "Clean and transform CSV data",
    type: "data-transformer",
    scripts: ["transform.py", "validate.py"],
    lastModified: "3 days ago",
  },
]

const typeColors: Record<string, string> = {
  "api-connector": "bg-blue-100 text-blue-800",
  "file-processor": "bg-green-100 text-green-800",
  "data-transformer": "bg-purple-100 text-purple-800",
  "automation": "bg-orange-100 text-orange-800",
  "integration": "bg-pink-100 text-pink-800",
  "custom": "bg-gray-100 text-gray-800",
}

export default function ToolsPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">My Tools</h1>
          <p className="text-muted-foreground">Manage and organize your custom tools</p>
        </div>
      </div>

      <div className="grid gap-4">
        {tools.map((tool) => (
          <Card key={tool.id}>
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-primary/10 rounded-lg">
                    <FileText className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <CardTitle className="text-lg">{tool.name}</CardTitle>
                    <CardDescription>{tool.description}</CardDescription>
                  </div>
                </div>
                <Badge className={typeColors[tool.type]}>
                  {tool.type}
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <div className="text-sm text-muted-foreground">
                  <p>Scripts: {tool.scripts.join(", ")}</p>
                  <p>Modified: {tool.lastModified}</p>
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="sm">
                    <Play className="w-4 h-4 mr-1" />
                    Run
                  </Button>
                  <Button variant="outline" size="sm">
                    <FolderOpen className="w-4 h-4 mr-1" />
                    Open
                  </Button>
                  <Button variant="outline" size="sm" className="text-red-600">
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
