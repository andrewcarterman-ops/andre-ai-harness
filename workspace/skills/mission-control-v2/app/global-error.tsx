'use client'

import { useEffect } from 'react'
import { AlertTriangle, RefreshCw } from 'lucide-react'

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Log the error to an error reporting service
    console.error('Root layout error:', error)
  }, [error])

  return (
    <html lang="en">
      <body className="bg-[#0a0a0a] text-white min-h-screen flex items-center justify-center p-4">
        <div className="glass rounded-xl p-8 max-w-md w-full text-center space-y-6">
          <div className="flex justify-center">
            <div className="w-16 h-16 rounded-full bg-red-500/10 flex items-center justify-center">
              <AlertTriangle className="w-8 h-8 text-red-400" />
            </div>
          </div>
          
          <div className="space-y-2">
            <h1 className="text-2xl font-semibold tracking-tight">
              Critical Error
            </h1>
            <p className="text-sm text-white/60">
              A critical error occurred in the application. Please refresh the page to continue.
            </p>
          </div>

          {error.message && (
            <div className="bg-red-500/10 border border-red-500/20 rounded-lg p-3 text-left">
              <p className="text-xs text-red-400 font-mono break-all">
                {error.message}
              </p>
              {error.digest && (
                <p className="text-xs text-red-400/60 font-mono mt-1">
                  Error ID: {error.digest}
                </p>
              )}
            </div>
          )}

          <button
            onClick={reset}
            className="inline-flex items-center justify-center px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition-colors"
          >
            <RefreshCw className="w-4 h-4 mr-2" />
            Refresh Page
          </button>
        </div>
      </body>
    </html>
  )
}
