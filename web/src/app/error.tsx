"use client"

import * as Sentry from "@sentry/nextjs"
import { useEffect } from "react"
import { AlertCircle, RefreshCw, ArrowLeft } from "lucide-react"
import Link from "next/link"

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Log to Sentry
    Sentry.captureException(error)

    // Log to console
    console.error("[Page Error]", error)
  }, [error])

  return (
    <div className="min-h-[60vh] flex items-center justify-center p-4">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-lg border border-gray-100 p-8 text-center">
        <div className="mx-auto mb-6 h-14 w-14 rounded-full bg-orange-100 flex items-center justify-center">
          <AlertCircle className="h-7 w-7 text-orange-600" />
        </div>

        <h2 className="text-xl font-bold text-gray-900 mb-2">
          Oops! Something went wrong
        </h2>

        <p className="text-gray-600 mb-6">
          We hit a snag loading this page. Please try again or go back.
        </p>

        {process.env.NODE_ENV === "development" && (
          <div className="mb-6 p-3 bg-gray-50 rounded-lg text-left">
            <p className="text-xs font-mono text-red-600 break-all">
              {error.message}
            </p>
          </div>
        )}

        {error.digest && (
          <p className="text-xs text-gray-400 mb-6 font-mono">
            Reference: {error.digest}
          </p>
        )}

        <div className="flex gap-3 justify-center">
          <button
            onClick={reset}
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors font-medium shadow-sm"
          >
            <RefreshCw className="h-4 w-4" />
            Try again
          </button>

          <Link
            href="/dashboard"
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200 transition-colors font-medium"
          >
            <ArrowLeft className="h-4 w-4" />
            Dashboard
          </Link>
        </div>
      </div>
    </div>
  )
}
