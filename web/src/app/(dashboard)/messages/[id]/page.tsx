'use client'

import { useEffect, useState, useRef } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/auth-context'
import { messageService } from '@/services/message'
import { Card, Button, Avatar } from '@/components/ui'
import { cn } from '@/lib/utils'
import { ArrowLeft, Send } from 'lucide-react'
import type { Conversation, Message } from '@/types'
import { formatTime, timeAgo } from '@/types'
import Link from 'next/link'

export default function ConversationPage() {
  const params = useParams()
  const router = useRouter()
  const { user } = useAuth()
  const [conversation, setConversation] = useState<Conversation | null>(null)
  const [messages, setMessages] = useState<Message[]>([])
  const [newMessage, setNewMessage] = useState('')
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const conversationId = params.id as string

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  // Fetch conversation and messages
  useEffect(() => {
    if (!conversationId || !user) return

    const fetchData = async () => {
      setLoading(true)
      try {
        const [conv, msgs] = await Promise.all([
          messageService.getConversation(conversationId),
          messageService.getMessages(conversationId),
        ])
        setConversation(conv)
        setMessages(msgs)

        // Mark as read
        if (conv) {
          await messageService.markAsRead(conversationId, user.id)
        }
      } catch (error) {
        console.error('Failed to fetch conversation:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()

    // Subscribe to new messages
    const unsubscribe = messageService.subscribeToMessages(conversationId, (updatedMessages) => {
      setMessages(updatedMessages)
      // Mark new messages as read
      messageService.markAsRead(conversationId, user.id)
    })

    return () => {
      unsubscribe()
    }
  }, [conversationId, user])

  const handleSend = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newMessage.trim() || !user || !conversation) return

    setSending(true)
    try {
      await messageService.sendMessage(
        conversationId,
        user.id,
        user.name,
        newMessage.trim()
      )
      setNewMessage('')
      inputRef.current?.focus()
    } catch (error) {
      console.error('Failed to send message:', error)
    } finally {
      setSending(false)
    }
  }

  if (loading) {
    return (
      <div className="flex flex-col h-full">
        <div className="h-16 border-b border-gray-200 bg-white px-4 flex items-center gap-4">
          <Link href="/messages" className="p-2 rounded-lg hover:bg-gray-100">
            <ArrowLeft className="h-5 w-5 text-gray-600" />
          </Link>
          <div className="animate-pulse flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-gray-200" />
            <div className="h-4 w-32 bg-gray-200 rounded" />
          </div>
        </div>
        <div className="flex-1 p-4">
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className={cn('flex', i % 2 === 0 && 'justify-end')}>
                <div className="animate-pulse h-12 w-48 bg-gray-200 rounded-2xl" />
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  if (!conversation) {
    return (
      <div className="flex flex-col h-full items-center justify-center">
        <p className="text-gray-500">Conversation not found</p>
        <Link href="/messages">
          <Button variant="outline" className="mt-4">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Messages
          </Button>
        </Link>
      </div>
    )
  }

  const otherParticipant = Object.entries(conversation.participant_names)
    .find(([id]) => id !== user?.id)
  const otherName = otherParticipant?.[1] || 'Unknown'
  const otherInitials = otherName
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)

  // Group messages by date
  const groupedMessages = messages.reduce((groups, message) => {
    const date = new Date(message.created_at).toDateString()
    if (!groups[date]) {
      groups[date] = []
    }
    groups[date].push(message)
    return groups
  }, {} as Record<string, Message[]>)

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="h-16 border-b border-gray-200 bg-white px-4 flex items-center gap-4">
        <Link href="/messages" className="p-2 rounded-lg hover:bg-gray-100">
          <ArrowLeft className="h-5 w-5 text-gray-600" />
        </Link>
        <Avatar initials={otherInitials} size="md" />
        <div className="flex-1">
          <p className="font-medium text-gray-900">{otherName}</p>
          {conversation.student_name && (
            <p className="text-sm text-gray-500">Re: {conversation.student_name}</p>
          )}
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 bg-gray-50">
        {messages.length === 0 ? (
          <div className="flex items-center justify-center h-full">
            <div className="text-center">
              <Avatar initials={otherInitials} size="xl" className="mx-auto mb-4" />
              <p className="text-gray-900 font-medium">{otherName}</p>
              <p className="text-sm text-gray-500">Start a conversation</p>
            </div>
          </div>
        ) : (
          <div className="space-y-4 max-w-2xl mx-auto">
            {Object.entries(groupedMessages).map(([date, dateMessages]) => (
              <div key={date}>
                {/* Date separator */}
                <div className="flex items-center justify-center my-4">
                  <span className="px-3 py-1 bg-gray-200 rounded-full text-xs text-gray-600">
                    {new Date(date).toLocaleDateString(undefined, {
                      weekday: 'long',
                      month: 'short',
                      day: 'numeric',
                    })}
                  </span>
                </div>

                {/* Messages for this date */}
                <div className="space-y-2">
                  {dateMessages.map((message, index) => {
                    const isMe = message.sender_id === user?.id
                    const showAvatar = index === 0 ||
                      dateMessages[index - 1].sender_id !== message.sender_id

                    return (
                      <div
                        key={message.id}
                        className={cn('flex items-end gap-2', isMe && 'flex-row-reverse')}
                      >
                        {/* Avatar placeholder for alignment */}
                        <div className="w-8">
                          {!isMe && showAvatar && (
                            <Avatar initials={otherInitials} size="sm" />
                          )}
                        </div>

                        {/* Message bubble */}
                        <div
                          className={cn(
                            'max-w-[70%] px-4 py-2 rounded-2xl',
                            isMe
                              ? 'bg-blue-500 text-white rounded-br-sm'
                              : 'bg-white text-gray-900 rounded-bl-sm shadow-sm'
                          )}
                        >
                          <p className="text-sm whitespace-pre-wrap break-words">
                            {message.content}
                          </p>
                          <p className={cn(
                            'text-xs mt-1',
                            isMe ? 'text-blue-100' : 'text-gray-400'
                          )}>
                            {formatTime(message.created_at)}
                          </p>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            ))}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Message Input */}
      <div className="p-4 bg-white border-t border-gray-200">
        <form onSubmit={handleSend} className="max-w-2xl mx-auto flex gap-2">
          <input
            ref={inputRef}
            type="text"
            placeholder="Type a message..."
            value={newMessage}
            onChange={(e) => setNewMessage(e.target.value)}
            className={cn(
              'flex-1 h-10 px-4 rounded-full border border-gray-300 bg-white',
              'placeholder:text-gray-400',
              'focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent'
            )}
          />
          <Button
            type="submit"
            disabled={!newMessage.trim() || sending}
            className="rounded-full w-10 h-10 p-0"
          >
            <Send className="h-4 w-4" />
          </Button>
        </form>
      </div>
    </div>
  )
}
