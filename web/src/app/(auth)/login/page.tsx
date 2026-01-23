'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/contexts/auth-context'
import { Button, Input, Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui'
import { LogIn, Mail, Lock, ArrowRight } from 'lucide-react'

function isAbortError(err: unknown): boolean {
  // Only check for actual AbortError, not just any error with "aborted" in message
  if (err instanceof Error && err.name === 'AbortError') return true
  if (err instanceof DOMException && err.name === 'AbortError') return true
  // Check for AbortError-like objects (some fetch implementations)
  if (typeof err === 'object' && err !== null && 'name' in err) {
    const name = (err as { name: unknown }).name
    if (name === 'AbortError') return true
  }
  return false
}

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { signIn } = useAuth()
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      console.log('Attempting sign in...')
      await signIn(email, password)
      console.log('Sign in successful, redirecting...')
      router.push('/dashboard')
    } catch (err: unknown) {
      console.error('Sign in error:', err)
      console.error('Error type:', typeof err)
      console.error('Error name:', err instanceof Error ? err.name : 'not an Error')
      console.error('Error message:', err instanceof Error ? err.message : String(err))
      console.error('Full error object:', JSON.stringify(err, Object.getOwnPropertyNames(err as object)))

      if (isAbortError(err)) {
        console.error('Detected as AbortError')
        setError('Connection interrupted. Please try again.')
      } else {
        const message = err instanceof Error ? err.message : 'Failed to sign in'
        console.error('Setting error message:', message)
        setError(message)
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm">
      <CardHeader className="text-center pb-2">
        <div className="mx-auto mb-4 h-14 w-14 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-blue-500/30">
          <LogIn className="h-7 w-7 text-white" />
        </div>
        <CardTitle className="text-2xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent">
          Welcome back!
        </CardTitle>
        <CardDescription className="text-gray-500">
          Sign in to continue to Hall Pass
        </CardDescription>
      </CardHeader>

      <form onSubmit={handleSubmit}>
        <CardContent className="space-y-5 pt-4">
          {error && (
            <div className="p-4 rounded-xl bg-red-50 border border-red-100 text-red-600 text-sm flex items-center gap-2">
              <div className="h-5 w-5 rounded-full bg-red-100 flex items-center justify-center shrink-0">
                <span className="text-red-600 text-xs font-bold">!</span>
              </div>
              {error}
            </div>
          )}

          <div className="space-y-1">
            <label className="text-sm font-medium text-gray-700 flex items-center gap-2">
              <Mail className="h-4 w-4 text-gray-400" />
              Email Address
            </label>
            <Input
              type="email"
              placeholder="you@school.edu"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoComplete="email"
              className="h-12 rounded-xl border-gray-200 focus:border-blue-500 focus:ring-blue-500"
            />
          </div>

          <div className="space-y-1">
            <label className="text-sm font-medium text-gray-700 flex items-center gap-2">
              <Lock className="h-4 w-4 text-gray-400" />
              Password
            </label>
            <Input
              type="password"
              placeholder="Enter your password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              autoComplete="current-password"
              className="h-12 rounded-xl border-gray-200 focus:border-blue-500 focus:ring-blue-500"
            />
          </div>

          <div className="flex justify-end">
            <Link
              href="/forgot-password"
              className="text-sm text-blue-600 hover:text-blue-700 font-medium transition-colors"
            >
              Forgot password?
            </Link>
          </div>
        </CardContent>

        <CardFooter className="flex flex-col gap-5 pt-2">
          <Button
            type="submit"
            className="w-full h-12 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 shadow-lg shadow-blue-500/30 font-semibold text-base transition-all duration-200 hover:shadow-xl hover:shadow-blue-500/40 flex items-center justify-center gap-2"
            loading={loading}
          >
            Sign in
            <ArrowRight className="h-4 w-4" />
          </Button>

          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-4 bg-white text-gray-500">New to Hall Pass?</span>
            </div>
          </div>

          <Link
            href="/signup"
            className="w-full h-12 rounded-xl border-2 border-gray-200 hover:border-blue-300 text-gray-700 hover:text-blue-600 font-semibold flex items-center justify-center gap-2 transition-all duration-200"
          >
            Create an account
          </Link>
        </CardFooter>
      </form>
    </Card>
  )
}
