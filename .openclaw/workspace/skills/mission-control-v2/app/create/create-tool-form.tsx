"use client"

import { useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { useToast } from "@/components/ui/use-toast"
import { Rocket, Loader2 } from "lucide-react"
import Link from "next/link"

const templates = [
  { value: "api-connector", label: "🔗 API Connector", description: "Connect to external APIs" },
  { value: "file-processor", label: "📁 File Processor", description: "Process files and documents" },
  { value: "data-transformer", label: "🔄 Data Transformer", description: "Transform data formats" },
  { value: "automation", label: "⚙️ Automation", description: "Automate repetitive tasks" },
  { value: "integration", label: "🔌 Integration", description: "Integrate with services" },
  { value: "custom", label: "🎨 Custom", description: "Build something unique" },
]

export function CreateToolForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { toast } = useToast()
  
  const [isLoading, setIsLoading] = useState(false)
  const [toolName, setToolName] = useState("")
  const [toolType, setToolType] = useState(searchParams.get("template") || "")
  const [description, setDescription] = useState("")

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!toolName || !toolType) {
      toast({
        title: "Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      })
      return
    }

    setIsLoading(true)

    try {
      const response = await fetch("/api/tools/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: toolName,
          type: toolType,
          description,
        }),
      })

      const data = await response.json()

      if (response.ok) {
        toast({
          title: "Success!",
          description: `Tool "${toolName}" created successfully`,
        })
        router.push("/tools")
      } else {
        toast({
          title: "Error",
          description: data.error || "Failed to create tool",
          variant: "destructive",
        })
      }
    } catch (error) {
      toast({
        title: "Error",
        description: "Something went wrong",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="space-y-2">
        <Label htmlFor="name">Tool Name *</Label>
        <Input
          id="name"
          placeholder="my-awesome-tool"
          value={toolName}
          onChange={(e) => setToolName(e.target.value)}
          required
        />
        <p className="text-sm text-muted-foreground">
          Use lowercase letters, numbers, and hyphens only
        </p>
      </div>

      <div className="space-y-2">
        <Label htmlFor="type">Template Type *</Label>
        <Select value={toolType} onValueChange={setToolType} required>
          <SelectTrigger>
            <SelectValue placeholder="Select a template" />
          </SelectTrigger>
          <SelectContent>
            {templates.map((template) => (
              <SelectItem key={template.value} value={template.value}>
                <div className="flex flex-col">
                  <span>{template.label}</span>
                  <span className="text-xs text-muted-foreground">
                    {template.description}
                  </span>
                </div>
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-2">
        <Label htmlFor="description">Description (Optional)</Label>
        <Textarea
          id="description"
          placeholder="What does this tool do?"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          rows={4}
        />
      </div>

      <div className="flex gap-4 pt-4">
        <Link href="/" className="flex-1">
          <Button type="button" variant="outline" className="w-full">
            Cancel
          </Button>
        </Link>
        <Button 
          type="submit" 
          className="flex-1"
          disabled={isLoading}
        >
          {isLoading ? (
            <>
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              Creating...
            </>
          ) : (
            <>
              <Rocket className="w-4 h-4 mr-2" />
              Create Tool
            </>
          )}
        </Button>
      </div>
    </form>
  )
}
