'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useAuth } from '@/contexts/auth-context'
import { Button, Input, Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui'
import { UserPlus, User, Users, Mail, Lock, ArrowRight, Sparkles, Heart } from 'lucide-react'
import { cn } from '@/lib/utils'

type Role = 'teacher' | 'parent'

function isAbortError(err: unknown): boolean {
  return (
    (err instanceof Error && err.name === 'AbortError') ||
    (err instanceof DOMException && err.name === 'AbortError') ||
    (typeof err === 'object' && err !== null && 'message' in err && String((err as {message: unknown}).message).includes('aborted'))
  )
}

export default function SignupPage() {
  const [step, setStep] = useState<1 | 2>(1)
  const [role, setRole] = useState<Role | null>(null)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { signUp } = useAuth()
  const router = useRouter()

  const handleRoleSelect = (selectedRole: Role) => {
    setRole(selectedRole)
    setStep(2)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    if (password !== confirmPassword) {
      setError('Passwords do not match')
      return
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters')
      return
    }

    if (!role) {
      setError('Please select a role')
      return
    }

    setLoading(true)

    try {
      console.log('Attempting sign up...')
      await signUp(email, password, name, role)
      console.log('Sign up successful, redirecting...')
      router.push('/dashboard')
    } catch (err) {
      console.error('Sign up error:', err)
      if (isAbortError(err)) {
        setError('Connection interrupted. Please try again.')
      } else {
        setError(err instanceof Error ? err.message : 'Failed to create account')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm">
      <CardHeader className="text-center pb-2">
        <div className="mx-auto mb-4 h-14 w-14 rounded-2xl bg-gradient-to-br from-green-500 to-emerald-600 flex items-center justify-center shadow-lg shadow-green-500/30">
          <UserPlus className="h-7 w-7 text-white" />
        </div>
        <CardTitle className="text-2xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent">
          {step === 1 ? 'Join Hall Pass' : 'Almost there!'}
        </CardTitle>
        <CardDescription className="text-gray-500">
          {step === 1 ? 'Select your role to get started' : 'Complete your account setup'}
        </CardDescription>
      </CardHeader>

      {step === 1 ? (
        <CardContent className="space-y-4 pt-4">
          <button
            type="button"
            onClick={() => handleRoleSelect('teacher')}
            className={cn(
              'w-full p-5 rounded-2xl border-2 text-left transition-all duration-200',
              'hover:border-blue-400 hover:bg-blue-50/50 hover:shadow-lg hover:shadow-blue-500/10',
              'focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2',
              'group'
            )}
          >
            <div className="flex items-center gap-4">
              <div className="h-14 w-14 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center shadow-lg shadow-blue-500/30 group-hover:scale-105 transition-transform">
                <User className="h-7 w-7 text-white" />
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="font-bold text-gray-900 text-lg">I&apos;m a Teacher</h3>
                  <Sparkles className="h-4 w-4 text-yellow-500" />
                </div>
                <p className="text-sm text-gray-500">Create classrooms, track progress & connect with parents</p>
              </div>
              <ArrowRight className="h-5 w-5 text-gray-300 group-hover:text-blue-500 group-hover:translate-x-1 transition-all" />
            </div>
          </button>

          <button
            type="button"
            onClick={() => handleRoleSelect('parent')}
            className={cn(
              'w-full p-5 rounded-2xl border-2 text-left transition-all duration-200',
              'hover:border-green-400 hover:bg-green-50/50 hover:shadow-lg hover:shadow-green-500/10',
              'focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2',
              'group'
            )}
          >
            <div className="flex items-center gap-4">
              <div className="h-14 w-14 rounded-2xl bg-gradient-to-br from-green-500 to-emerald-600 flex items-center justify-center shadow-lg shadow-green-500/30 group-hover:scale-105 transition-transform">
                <Users className="h-7 w-7 text-white" />
              </div>
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="font-bold text-gray-900 text-lg">I&apos;m a Parent</h3>
                  <Heart className="h-4 w-4 text-red-500" />
                </div>
                <p className="text-sm text-gray-500">Stay connected with your child&apos;s classroom journey</p>
              </div>
              <ArrowRight className="h-5 w-5 text-gray-300 group-hover:text-green-500 group-hover:translate-x-1 transition-all" />
            </div>
          </button>

          <div className="relative pt-4">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-gray-200"></div>
            </div>
            <div className="relative flex justify-center text-sm">
              <span className="px-4 bg-white text-gray-500">Already have an account?</span>
            </div>
          </div>

          <Link
            href="/login"
            className="w-full h-12 rounded-xl border-2 border-gray-200 hover:border-blue-300 text-gray-700 hover:text-blue-600 font-semibold flex items-center justify-center gap-2 transition-all duration-200"
          >
            Sign in instead
          </Link>
        </CardContent>
      ) : (
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

            <button
              type="button"
              onClick={() => setStep(1)}
              className={cn(
                'w-full flex items-center gap-3 p-3 rounded-xl transition-colors',
                role === 'teacher' ? 'bg-blue-50 hover:bg-blue-100' : 'bg-green-50 hover:bg-green-100'
              )}
            >
              <div className={cn(
                'h-10 w-10 rounded-xl flex items-center justify-center shadow-sm',
                role === 'teacher'
                  ? 'bg-gradient-to-br from-blue-500 to-indigo-600'
                  : 'bg-gradient-to-br from-green-500 to-emerald-600'
              )}>
                {role === 'teacher' ? (
                  <User className="h-5 w-5 text-white" />
                ) : (
                  <Users className="h-5 w-5 text-white" />
                )}
              </div>
              <span className="text-sm text-gray-700">
                Signing up as a <span className="font-semibold capitalize">{role}</span>
              </span>
              <span className={cn(
                'ml-auto text-sm font-medium',
                role === 'teacher' ? 'text-blue-600' : 'text-green-600'
              )}>
                Change
              </span>
            </button>

            <div className="space-y-1">
              <label className="text-sm font-medium text-gray-700 flex items-center gap-2">
                <User className="h-4 w-4 text-gray-400" />
                Full Name
              </label>
              <Input
                type="text"
                placeholder="Your name"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
                autoComplete="name"
                className="h-12 rounded-xl border-gray-200 focus:border-blue-500 focus:ring-blue-500"
              />
            </div>

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
                placeholder="Create a password (6+ characters)"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="new-password"
                className="h-12 rounded-xl border-gray-200 focus:border-blue-500 focus:ring-blue-500"
              />
            </div>

            <div className="space-y-1">
              <label className="text-sm font-medium text-gray-700 flex items-center gap-2">
                <Lock className="h-4 w-4 text-gray-400" />
                Confirm Password
              </label>
              <Input
                type="password"
                placeholder="Confirm your password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
                autoComplete="new-password"
                className="h-12 rounded-xl border-gray-200 focus:border-blue-500 focus:ring-blue-500"
              />
            </div>
          </CardContent>

          <CardFooter className="flex flex-col gap-5 pt-2">
            <Button
              type="submit"
              className={cn(
                'w-full h-12 rounded-xl font-semibold text-base transition-all duration-200 flex items-center justify-center gap-2',
                role === 'teacher'
                  ? 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 shadow-lg shadow-blue-500/30 hover:shadow-xl hover:shadow-blue-500/40'
                  : 'bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 shadow-lg shadow-green-500/30 hover:shadow-xl hover:shadow-green-500/40'
              )}
              loading={loading}
            >
              Create account
              <ArrowRight className="h-4 w-4" />
            </Button>

            <p className="text-center text-sm text-gray-500">
              Already have an account?{' '}
              <Link href="/login" className="text-blue-600 hover:text-blue-700 font-medium">
                Sign in
              </Link>
            </p>
          </CardFooter>
        </form>
      )}
    </Card>
  )
}
