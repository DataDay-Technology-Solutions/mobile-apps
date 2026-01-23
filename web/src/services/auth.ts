import { createClient } from '@/lib/supabase/client'
import type { AppUser, UserRole } from '@/types'

export class AuthError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'AuthError'
  }
}

function isAbortError(err: unknown): boolean {
  return (
    (err instanceof Error && err.name === 'AbortError') ||
    (err instanceof DOMException && err.name === 'AbortError') ||
    (typeof err === 'object' && err !== null && 'name' in err && (err as {name: string}).name === 'AbortError') ||
    (typeof err === 'object' && err !== null && 'message' in err && String((err as {message: unknown}).message).includes('aborted'))
  )
}

async function withRetry<T>(fn: () => Promise<T>, maxRetries = 3): Promise<T> {
  let lastError: unknown
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn()
    } catch (err) {
      lastError = err
      if (isAbortError(err) && i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, 100 * (i + 1)))
        continue
      }
      throw err
    }
  }
  throw lastError
}

export const authService = {
  async signUp(email: string, password: string, name: string, role: UserRole): Promise<AppUser> {
    const supabase = createClient()

    // Create auth user
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
    })

    if (authError) throw new AuthError(authError.message)
    if (!authData.user) throw new AuthError('Failed to create user')

    // Create user profile in database
    const newUser: Partial<AppUser> = {
      id: authData.user.id,
      email,
      name,
      role,
      class_ids: [],
      student_ids: [],
      created_at: new Date().toISOString(),
    }

    const { data: userData, error: userError } = await supabase
      .from('users')
      .insert(newUser)
      .select()
      .single()

    if (userError) throw new AuthError(userError.message)

    return userData as AppUser
  },

  async signIn(email: string, password: string): Promise<AppUser> {
    return withRetry(async () => {
      const supabase = createClient()

      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (authError) throw new AuthError(authError.message)
      if (!authData.user) throw new AuthError('Failed to sign in')

      // Get user profile
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select()
        .eq('id', authData.user.id)
        .single()

      if (userError) throw new AuthError(userError.message)

      return userData as AppUser
    })
  },

  async signOut(): Promise<void> {
    const supabase = createClient()
    // Sign out from all sessions (global scope clears all browser sessions)
    const { error } = await supabase.auth.signOut({ scope: 'global' })
    if (error) {
      console.error('Sign out error:', error)
      // Even if there's an error, we should still try to redirect
    }
  },

  async getUser(userId: string): Promise<AppUser | null> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('users')
      .select()
      .eq('id', userId)
      .single()

    if (error) return null
    return data as AppUser
  },

  async getCurrentUser(): Promise<AppUser | null> {
    const supabase = createClient()

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return null

    return this.getUser(user.id)
  },

  async updateUser(user: Partial<AppUser> & { id: string }): Promise<AppUser> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('users')
      .update(user)
      .eq('id', user.id)
      .select()
      .single()

    if (error) throw new AuthError(error.message)
    return data as AppUser
  },

  async resetPassword(email: string): Promise<void> {
    const supabase = createClient()

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`,
    })

    if (error) throw new AuthError(error.message)
  },
}
