'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useAuth } from '@/contexts/auth-context'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  Users,
  MessageSquare,
  BookOpen,
  Star,
  Settings,
  GraduationCap,
  LogOut,
  ChevronDown,
  Shield,
  Building2,
  School,
} from 'lucide-react'
import { Avatar } from '@/components/ui'
import { useClassroom } from '@/contexts/classroom-context'
import { useState } from 'react'

const teacherNavItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/classroom', label: 'Classroom', icon: Users },
  { href: '/messages', label: 'Messages', icon: MessageSquare },
  { href: '/stories', label: 'Stories', icon: BookOpen },
  { href: '/points', label: 'Points', icon: Star },
  { href: '/settings', label: 'Settings', icon: Settings },
]

const parentNavItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/messages', label: 'Messages', icon: MessageSquare },
  { href: '/stories', label: 'Stories', icon: BookOpen },
  { href: '/points', label: 'Points', icon: Star },
  { href: '/settings', label: 'Settings', icon: Settings },
]

const adminNavItems = [
  { href: '/admin', label: 'Admin Dashboard', icon: Shield },
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/classroom', label: 'Classroom', icon: Users },
  { href: '/messages', label: 'Messages', icon: MessageSquare },
  { href: '/stories', label: 'Stories', icon: BookOpen },
  { href: '/points', label: 'Points', icon: Star },
  { href: '/settings', label: 'Settings', icon: Settings },
]

export function Sidebar() {
  const pathname = usePathname()
  const { user, signOut } = useAuth()
  const { classrooms, selectedClassroom, selectClassroom } = useClassroom()
  const [classDropdownOpen, setClassDropdownOpen] = useState(false)
  const [isSigningOut, setIsSigningOut] = useState(false)

  // Check if user has admin privileges (super_admin, district_admin, principal, or school_admin)
  // Also check if user is on an admin page (fallback for stale user data)
  const isAdmin = (user?.admin_level && user.admin_level !== 'none') || pathname.startsWith('/admin')

  const navItems = isAdmin
    ? adminNavItems
    : user?.role === 'teacher'
      ? teacherNavItems
      : parentNavItems

  const handleSignOut = async () => {
    if (isSigningOut) return
    setIsSigningOut(true)
    try {
      await signOut()
    } catch (error) {
      console.error('Sign out failed:', error)
      // Force redirect even if signOut fails
      window.location.href = '/login'
    }
  }

  const userInitials = user?.name
    ?.split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2) || '?'

  return (
    <div className="flex flex-col h-full w-64 bg-white border-r border-gray-200">
      {/* Logo */}
      <div className="p-4 border-b border-gray-100">
        <Link href="/dashboard" className="flex items-center gap-2">
          <div className="h-8 w-8 rounded-lg bg-blue-600 flex items-center justify-center">
            <GraduationCap className="h-5 w-5 text-white" />
          </div>
          <span className="font-semibold text-gray-900">Hall Pass</span>
        </Link>
      </div>

      {/* Class Selector */}
      {classrooms.length > 0 && (
        <div className="p-3 border-b border-gray-100">
          <div className="relative">
            <button
              type="button"
              onClick={() => setClassDropdownOpen(!classDropdownOpen)}
              className={cn(
                'w-full flex items-center justify-between p-2 rounded-lg',
                'bg-gray-50 hover:bg-gray-100 transition-colors',
                'text-left'
              )}
            >
              <div className="flex items-center gap-2">
                <div className="h-8 w-8 rounded-lg bg-blue-100 flex items-center justify-center">
                  <Users className="h-4 w-4 text-blue-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 truncate">
                    {selectedClassroom?.name || 'Select Class'}
                  </p>
                  {selectedClassroom?.grade_level && (
                    <p className="text-xs text-gray-500 truncate">
                      {selectedClassroom.grade_level}
                    </p>
                  )}
                </div>
              </div>
              <ChevronDown className={cn(
                'h-4 w-4 text-gray-400 transition-transform',
                classDropdownOpen && 'rotate-180'
              )} />
            </button>

            {classDropdownOpen && (
              <div className="absolute top-full left-0 right-0 mt-1 bg-white rounded-lg shadow-lg border border-gray-200 z-50 py-1">
                {classrooms.map((classroom) => (
                  <button
                    key={classroom.id}
                    type="button"
                    onClick={() => {
                      selectClassroom(classroom)
                      setClassDropdownOpen(false)
                    }}
                    className={cn(
                      'w-full flex items-center gap-2 px-3 py-2 text-left',
                      'hover:bg-gray-50 transition-colors',
                      selectedClassroom?.id === classroom.id && 'bg-blue-50'
                    )}
                  >
                    <div className="h-6 w-6 rounded bg-blue-100 flex items-center justify-center">
                      <Users className="h-3 w-3 text-blue-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        {classroom.name}
                      </p>
                      {classroom.grade_level && (
                        <p className="text-xs text-gray-500 truncate">
                          {classroom.grade_level}
                        </p>
                      )}
                    </div>
                    {selectedClassroom?.id === classroom.id && (
                      <div className="h-2 w-2 rounded-full bg-blue-600" />
                    )}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Navigation */}
      <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
        {navItems.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
          const Icon = item.icon

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                isActive
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              )}
            >
              <Icon className="h-5 w-5" />
              {item.label}
            </Link>
          )
        })}
      </nav>

      {/* User Profile */}
      <div className="p-3 border-t border-gray-100">
        <div className="flex items-center gap-3 p-2 rounded-lg">
          <Avatar initials={userInitials} size="sm" />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-gray-900 truncate">
              {user?.name}
            </p>
            <p className="text-xs text-gray-500 truncate capitalize">
              {user?.role}
            </p>
          </div>
          <button
            type="button"
            onClick={handleSignOut}
            disabled={isSigningOut}
            className="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors disabled:opacity-50"
            title="Sign out"
          >
            <LogOut className={cn("h-4 w-4", isSigningOut && "animate-spin")} />
          </button>
        </div>
      </div>
    </div>
  )
}
