'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { AppUser } from '@/types'
import { authService } from '@/services/auth'

interface AuthContextType {
  user: AppUser | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string, name: string, role: 'teacher' | 'parent') => Promise<void>
  signOut: () => Promise<void>
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

// Module-level flag to prevent double initialization
let authInitialized = false

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AppUser | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Prevent double initialization
    if (authInitialized) {
      console.log('Auth already initialized, skipping')
      return
    }
    authInitialized = true

    const supabase = createClient()
    let mounted = true
    let timeoutId: NodeJS.Timeout | null = null

    console.log('Setting up auth listener')

    // Set up auth state listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event, session) => {
        console.log('Auth event:', event, 'Has session:', !!session)

        if (!mounted) {
          console.log('Component unmounted, ignoring event')
          return
        }

        // Clear timeout since we got an auth event
        if (timeoutId) {
          clearTimeout(timeoutId)
          timeoutId = null
        }

        if (session?.user) {
          // Fetch user profile asynchronously
          authService.getUser(session.user.id)
            .then(appUser => {
              if (mounted) {
                console.log('Got user profile:', appUser?.name)
                setUser(appUser)
                setLoading(false)
              }
            })
            .catch(err => {
              console.error('Error fetching user profile:', err)
              if (mounted) {
                setUser(null)
                setLoading(false)
              }
            })
        } else {
          console.log('No session, setting user to null')
          setUser(null)
          setLoading(false)
        }
      }
    )

    // Fallback timeout
    timeoutId = setTimeout(() => {
      if (mounted && loading) {
        console.log('Auth initialization timeout')
        setLoading(false)
      }
    }, 3000)

    return () => {
      console.log('Auth cleanup')
      mounted = false
      if (timeoutId) clearTimeout(timeoutId)
      subscription.unsubscribe()
      // Reset on cleanup so it can re-initialize if remounted
      authInitialized = false
    }
  }, [])

  const signIn = async (email: string, password: string) => {
    setLoading(true)
    try {
      const appUser = await authService.signIn(email, password)
      setUser(appUser)
    } finally {
      setLoading(false)
    }
  }

  const signUp = async (email: string, password: string, name: string, role: 'teacher' | 'parent') => {
    setLoading(true)
    try {
      const appUser = await authService.signUp(email, password, name, role)
      setUser(appUser)
    } finally {
      setLoading(false)
    }
  }

  const signOut = async () => {
    try {
      const response = await fetch('/api/auth/signout', {
        method: 'POST',
        credentials: 'include'
      })
      await response.json()
    } catch (e) {
      console.error('Signout error:', e)
    }
    setUser(null)
    if (typeof window !== 'undefined') {
      localStorage.clear()
      sessionStorage.clear()
    }
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
