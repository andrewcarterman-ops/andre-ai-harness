"use client"

import { Suspense } from "react"
import { CreateToolForm } from "./create-tool-form"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ArrowLeft, Rocket } from "lucide-react"
import Link from "next/link"

function CreateToolSkeleton() {
  return (
    <div className="max-w-2xl mx-auto animate-pulse">
      <div className="mb-6">
        <div className="h-10 w-32 bg-white/5 rounded" />
      </div>
      <div className="h-[500px] bg-white/5 rounded-lg" />
    </div>
  )
}

export default function CreateToolPage() {
  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-6">
        <Link href="/">
          <Button variant="ghost" className="pl-0">
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Dashboard
          </Button>
        </Link>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-primary/10 rounded-lg">
              <Rocket className="w-6 h-6 text-primary" />
            </div>
            <div>
              <CardTitle className="text-2xl">Create New Tool</CardTitle>
              <CardDescription>
                Build a custom tool using one of our templates
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <Suspense fallback={<CreateToolSkeleton />}>
            <CreateToolForm />
          </Suspense>
        </CardContent>
      </Card>
    </div>
  )
}
