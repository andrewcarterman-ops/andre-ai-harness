'use client'

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { FileQuestion, Home, ArrowLeft } from 'lucide-react'

export default function NotFound() {
  return (
    <div className="min-h-screen bg-[#0a0a0a] text-white flex items-center justify-center p-4">
      <div className="glass rounded-xl p-8 max-w-md w-full text-center space-y-6">
        <div className="flex justify-center">
          <div className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center">
            <FileQuestion className="w-8 h-8 text-white/60" />
          </div>
        </div>
        
        <div className="space-y-2">
          <h1 className="text-2xl font-semibold tracking-tight">
            Page Not Found
          </h1>
          <p className="text-sm text-white/60">
            The page you&apos;re looking for doesn&apos;t exist or has been moved.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link href="/" passHref>
            <Button
              variant="default"
              className="bg-white/10 hover:bg-white/20 text-white border-0"
            >
              <Home className="w-4 h-4 mr-2" />
              Go Home
            </Button>
          </Link>
          <Button
            variant="outline"
            className="border-white/10 hover:bg-white/5 text-white"
            onClick={() => window.history.back()}
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Go Back
          </Button>
        </div>
      </div>
    </div>
  )
}
