import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function POST() {
  const cookieStore = await cookies()

  // Clear all Supabase-related cookies with proper options
  const allCookies = cookieStore.getAll()
  const response = NextResponse.json({ success: true })

  for (const cookie of allCookies) {
    if (cookie.name.includes('supabase') || cookie.name.includes('sb-')) {
      // Delete from cookie store
      cookieStore.delete(cookie.name)
      // Also set expired cookie in response to ensure browser clears it
      response.cookies.set(cookie.name, '', {
        expires: new Date(0),
        path: '/',
      })
    }
  }

  return response
}
