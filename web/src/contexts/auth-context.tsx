'use client'

import { createContext, useContext, useEffect, useState, ReactNode, useRef } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { AuthChangeEvent, Session } from '@supabase/supabase-js'
import type { AppUser } from '@/types'
import { authService } from '@/services/auth'

function isAbortError(err: unknown): boolean {
  return (
    (err instanceof Error && err.name === 'AbortError') ||
    (err instanceof DOMException && err.name === 'AbortError') ||
    (typeof err === 'object' && err !== null && 'message' in err && String((err as {message: unknown}).message).includes('aborted'))
  )
}

interface AuthContextType {
  user: AppUser | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string, name: string, role: 'teacher' | 'parent') => Promise<void>
  signOut: () => Promise<void>
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AppUser | null>(null)
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const mountedRef = useRef(true)

  useEffect(() => {
    mountedRef.current = true
    const supabase = createClient()
    let retryCount = 0
    const maxRetries = 3

    // Get initial session with retry logic
    const getInitialSession = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession()
        if (!mountedRef.current) return
        if (session?.user) {
          const appUser = await authService.getUser(session.user.id)
          if (mountedRef.current) setUser(appUser)
        }
        if (mountedRef.current) setLoading(false)
      } catch (err) {
        if (!mountedRef.current) return
        if (isAbortError(err) && retryCount < maxRetries) {
          retryCount++
          setTimeout(getInitialSession, 100 * retryCount)
          return
        }
        console.error('Error getting session:', err)
        if (mountedRef.current) setLoading(false)
      }
    }

    getInitialSession()

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event: AuthChangeEvent, session: Session | null) => {
      if (!mountedRef.current) return
      if (event === 'SIGNED_IN' && session?.user) {
        const appUser = await authService.getUser(session.user.id)
        if (mountedRef.current) setUser(appUser)
      } else if (event === 'SIGNED_OUT') {
        if (mountedRef.current) setUser(null)
      }
    })

    return () => {
      mountedRef.current = false
      subscription.unsubscribe()
    }
  }, [])

  const signIn = async (email: string, password: string) => {
    const appUser = await authService.signIn(email, password)
    setUser(appUser)
  }

  const signUp = async (email: string, password: string, name: string, role: 'teacher' | 'parent') => {
    const appUser = await authService.signUp(email, password, name, role)
    setUser(appUser)
  }

  const signOut = async () => {
    // Call server-side signout to properly clear cookies
    try {
      const response = await fetch('/api/auth/signout', {
        method: 'POST',
        credentials: 'include'
      })
      // Wait for cookies to be set from response
      await response.json()
    } catch (e) {
      console.error('Signout error:', e)
    }
    setUser(null)
    // Clear any client-side storage
    if (typeof window !== 'undefined') {
      localStorage.clear()
      sessionStorage.clear()
    }
    // Force a hard redirect to clear any cached state
    window.location.href = '/login'
  }

  const refreshUser = async () => {
    if (user) {
      const updatedUser = await authService.getUser(user.id)
      setUser(updatedUser)
    }
  }

  return (
    <AuthContext.Provider value={{ user, loading, signIn, signUp, signOut, refreshUser }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
