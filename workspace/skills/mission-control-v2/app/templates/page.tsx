import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Check } from "lucide-react"

const templates = [
  {
    id: "api-connector",
    name: "API Connector",
    icon: "🔗",
    description: "Connect to external APIs with authentication, rate limiting, and error handling.",
    includes: ["fetch.py", "post.py", "auth.py"],
    useFor: ["Weather APIs", "REST APIs", "GraphQL", "Webhooks"],
    difficulty: "Intermediate",
  },
  {
    id: "file-processor",
    name: "File Processor",
    icon: "📁",
    description: "Process files: extract, convert, merge, and transform documents.",
    includes: ["extract.py", "convert.py", "batch.py"],
    useFor: ["PDFs", "Images", "Documents", "Archives"],
    difficulty: "Beginner",
  },
  {
    id: "data-transformer",
    name: "Data Transformer",
    icon: "🔄",
    description: "Transform data between formats with validation and mapping.",
    includes: ["transform.py", "validate.py", "map.py"],
    useFor: ["JSON ↔ CSV", "XML parsing", "Data cleaning", "Schema mapping"],
    difficulty: "Intermediate",
  },
  {
    id: "automation",
    name: "Automation",
    icon: "⚙️",
    description: "Automate repetitive tasks with scheduling and notifications.",
    includes: ["schedule.py", "task.py", "notify.py"],
    useFor: ["Scheduled jobs", "Batch processing", "Reminders", "Monitoring"],
    difficulty: "Advanced",
  },
  {
    id: "integration",
    name: "Integration",
    icon: "🔌",
    description: "Integrate with external services and synchronize data.",
    includes: ["connect.py", "sync.py", "webhook.py"],
    useFor: ["Slack/Discord", "GitHub", "Databases", "Cloud storage"],
    difficulty: "Intermediate",
  },
  {
    id: "custom",
    name: "Custom",
    icon: "🎨",
    description: "Start from scratch and build something unique.",
    includes: ["main.py"],
    useFor: ["Anything you can imagine!"],
    difficulty: "Any",
  },
]

const difficultyColors: Record<string, string> = {
  "Beginner": "bg-green-100 text-green-800",
  "Intermediate": "bg-yellow-100 text-yellow-800",
  "Advanced": "bg-red-100 text-red-800",
  "Any": "bg-blue-100 text-blue-800",
}

export default function TemplatesPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Templates</h1>
        <p className="text-muted-foreground">Choose from pre-built templates to jumpstart your tool development</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {templates.map((template) => (
          <Card key={template.id} className="flex flex-col">
            <CardHeader>
              <div className="flex items-center justify-between">
                <span className="text-4xl">{template.icon}</span>
                <Badge className={difficultyColors[template.difficulty]}>
                  {template.difficulty}
                </Badge>
              </div>
              <CardTitle className="mt-4">{template.name}</CardTitle>
              <CardDescription>{template.description}</CardDescription>
            </CardHeader>
            <CardContent className="flex-1">
              <div className="space-y-4">
                <div>
                  <p className="text-sm font-medium mb-2">Includes:</p>
                  <div className="flex flex-wrap gap-2">
                    {template.includes.map((file) => (
                      <code key={file} className="px-2 py-1 bg-muted rounded text-xs">
                        {file}
                      </code>
                    ))}
                  </div>
                </div>
                
                <div>
                  <p className="text-sm font-medium mb-2">Great for:</p>
                  <ul className="space-y-1">
                    {template.useFor.map((use) => (
                      <li key={use} className="text-sm text-muted-foreground flex items-center">
                        <Check className="w-3 h-3 mr-2 text-green-500" />
                        {use}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
