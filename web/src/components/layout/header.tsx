'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/auth-context'
import { useClassroom } from '@/contexts/classroom-context'
import { messageService } from '@/services/message'
import { Bell, Menu, X } from 'lucide-react'
import { Avatar, Button } from '@/components/ui'
import Link from 'next/link'

interface HeaderProps {
  title?: string
  onMenuClick?: () => void
  showMenuButton?: boolean
}

export function Header({ title, onMenuClick, showMenuButton = false }: HeaderProps) {
  const { user } = useAuth()
  const { selectedClassroom } = useClassroom()
  const [unreadCount, setUnreadCount] = useState(0)

  useEffect(() => {
    if (!user) return

    const fetchUnreadCount = async () => {
      const count = await messageService.getTotalUnreadCount(user.id)
      setUnreadCount(count)
    }

    fetchUnreadCount()

    // Subscribe to conversation updates
    const unsubscribe = messageService.subscribeToConversations(user.id, async () => {
      const count = await messageService.getTotalUnreadCount(user.id)
      setUnreadCount(count)
    })

    return () => {
      unsubscribe()
    }
  }, [user])

  const userInitials = user?.name
    ?.split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2) || '?'

  return (
    <header className="h-16 border-b border-gray-200 bg-white px-4 flex items-center justify-between">
      <div className="flex items-center gap-4">
        {showMenuButton && (
          <button
            type="button"
            onClick={onMenuClick}
            className="lg:hidden p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100"
          >
            <Menu className="h-5 w-5" />
          </button>
        )}
        <div>
          <h1 className="text-lg font-semibold text-gray-900">
            {title || 'Dashboard'}
          </h1>
          {selectedClassroom && (
            <p className="text-sm text-gray-500">
              {selectedClassroom.name}
            </p>
          )}
        </div>
      </div>

      <div className="flex items-center gap-3">
        {/* Notifications */}
        <Link
          href="/messages"
          className="relative p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors"
        >
          <Bell className="h-5 w-5" />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 h-5 w-5 rounded-full bg-red-500 text-white text-xs flex items-center justify-center font-medium">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </Link>

        {/* User Avatar (mobile) */}
        <Link href="/settings" className="lg:hidden">
          <Avatar initials={userInitials} size="sm" />
        </Link>
      </div>
    </header>
  )
}
