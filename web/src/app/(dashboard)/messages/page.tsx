'use client'

import { useEffect, useState } from 'react'
import { useAuth } from '@/contexts/auth-context'
import { useClassroom } from '@/contexts/classroom-context'
import { messageService } from '@/services/message'
import { Header } from '@/components/layout/header'
import { Card, CardContent, CardHeader, CardTitle, Button, Avatar, Input } from '@/components/ui'
import { cn } from '@/lib/utils'
import { Plus, MessageSquare, Search, X, Users } from 'lucide-react'
import type { Conversation } from '@/types'
import { timeAgo } from '@/types'
import Link from 'next/link'

export default function MessagesPage() {
  const { user } = useAuth()
  const { selectedClassroom, students } = useClassroom()
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [loading, setLoading] = useState(true)
  const [showNewMessage, setShowNewMessage] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')

  useEffect(() => {
    if (!user) return

    const fetchConversations = async () => {
      setLoading(true)
      try {
        const convs = await messageService.getConversationsForUser(user.id)
        setConversations(convs)
      } catch (error) {
        console.error('Failed to fetch conversations:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchConversations()

    // Subscribe to conversation updates
    const unsubscribe = messageService.subscribeToConversations(user.id, (updatedConvs) => {
      setConversations(updatedConvs)
    })

    return () => {
      unsubscribe()
    }
  }, [user])

  const filteredConversations = conversations.filter((conv) => {
    if (!searchQuery) return true
    const otherName = Object.entries(conv.participant_names)
      .find(([id]) => id !== user?.id)?.[1] || ''
    return otherName.toLowerCase().includes(searchQuery.toLowerCase())
  })

  const isTeacher = user?.role === 'teacher'

  return (
    <>
      <Header title="Messages" />
      <main className="flex-1 p-6 overflow-y-auto">
        <div className="max-w-3xl mx-auto">
          {/* Header Actions */}
          <div className="flex items-center gap-4 mb-6">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Search conversations..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
            {isTeacher && selectedClassroom && (
              <Button onClick={() => setShowNewMessage(true)}>
                <Plus className="h-4 w-4 mr-2" />
                New Message
              </Button>
            )}
          </div>

          {/* Conversations List */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Conversations</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="space-y-3">
                  {[1, 2, 3].map((i) => (
                    <div key={i} className="animate-pulse flex items-center gap-3 p-3">
                      <div className="h-12 w-12 rounded-full bg-gray-200" />
                      <div className="flex-1">
                        <div className="h-4 bg-gray-200 rounded w-1/3 mb-2" />
                        <div className="h-3 bg-gray-200 rounded w-2/3" />
                      </div>
                    </div>
                  ))}
                </div>
              ) : filteredConversations.length === 0 ? (
                <div className="text-center py-8">
                  <div className="mx-auto h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center mb-4">
                    <MessageSquare className="h-6 w-6 text-gray-400" />
                  </div>
                  <p className="text-gray-500 mb-4">
                    {searchQuery ? 'No conversations match your search' : 'No conversations yet'}
                  </p>
                  {isTeacher && selectedClassroom && !searchQuery && (
                    <Button size="sm" onClick={() => setShowNewMessage(true)}>
                      <Plus className="h-4 w-4 mr-2" />
                      Start a Conversation
                    </Button>
                  )}
                </div>
              ) : (
                <div className="divide-y divide-gray-100">
                  {filteredConversations.map((conv) => {
                    const otherParticipant = Object.entries(conv.participant_names)
                      .find(([id]) => id !== user?.id)
                    const otherName = otherParticipant?.[1] || 'Unknown'
                    const otherInitials = otherName
                      .split(' ')
                      .map(n => n[0])
                      .join('')
                      .toUpperCase()
                      .slice(0, 2)
                    const unread = conv.unread_counts[user?.id || ''] || 0

                    return (
                      <Link
                        key={conv.id}
                        href={`/messages/${conv.id}`}
                        className={cn(
                          'flex items-center gap-3 p-4 hover:bg-gray-50 transition-colors',
                          unread > 0 && 'bg-blue-50/50 hover:bg-blue-50'
                        )}
                      >
                        <Avatar initials={otherInitials} size="lg" />
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between">
                            <p className={cn(
                              'font-medium text-gray-900 truncate',
                              unread > 0 && 'font-semibold'
                            )}>
                              {otherName}
                            </p>
                            {conv.last_message_date && (
                              <span className="text-xs text-gray-400">
                                {timeAgo(conv.last_message_date)}
                              </span>
                            )}
                          </div>
                          {conv.student_name && (
                            <p className="text-xs text-gray-500">
                              Re: {conv.student_name}
                            </p>
                          )}
                          <p className={cn(
                            'text-sm truncate',
                            unread > 0 ? 'text-gray-900 font-medium' : 'text-gray-500'
                          )}>
                            {conv.last_message || 'No messages yet'}
                          </p>
                        </div>
                        {unread > 0 && (
                          <span className="h-6 w-6 rounded-full bg-blue-500 text-white text-xs flex items-center justify-center font-medium">
                            {unread > 9 ? '9+' : unread}
                          </span>
                        )}
                      </Link>
                    )
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* New Message Modal */}
        {showNewMessage && (
          <NewMessageModal
            onClose={() => setShowNewMessage(false)}
            students={students}
            classroomId={selectedClassroom?.id}
            userId={user?.id}
            userName={user?.name}
          />
        )}
      </main>
    </>
  )
}

interface NewMessageModalProps {
  onClose: () => void
  students: any[]
  classroomId?: string
  userId?: string
  userName?: string
}

function NewMessageModal({ onClose, students, classroomId, userId, userName }: NewMessageModalProps) {
  const [selectedStudent, setSelectedStudent] = useState<any>(null)
  const [loading, setLoading] = useState(false)

  const studentsWithParents = students.filter(s => s.parent_ids.length > 0)

  const handleStartConversation = async (student: any) => {
    if (!userId || !userName || !classroomId) return

    setLoading(true)
    try {
      // For now, we'll create a conversation with the first parent
      const parentId = student.parent_ids[0]

      // Get parent name (we'd need to fetch this, but for now use placeholder)
      const participantNames = {
        [userId]: userName,
        [parentId]: `${student.first_name}'s Parent`,
      }

      const conversation = await messageService.getOrCreateConversation(
        [userId, parentId],
        participantNames,
        classroomId,
        student.id,
        `${student.first_name} ${student.last_name}`
      )

      // Navigate to the conversation
      window.location.href = `/messages/${conversation.id}`
    } catch (error) {
      console.error('Failed to create conversation:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <Card className="w-full max-w-md mx-4 max-h-[80vh] flex flex-col">
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>New Message</CardTitle>
          <button
            onClick={onClose}
            className="p-2 rounded-lg hover:bg-gray-100"
          >
            <X className="h-4 w-4" />
          </button>
        </CardHeader>
        <CardContent className="flex-1 overflow-y-auto">
          <p className="text-sm text-gray-500 mb-4">
            Select a student to message their parent
          </p>
          {studentsWithParents.length === 0 ? (
            <div className="text-center py-8">
              <div className="mx-auto h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center mb-4">
                <Users className="h-6 w-6 text-gray-400" />
              </div>
              <p className="text-gray-500">
                No students have connected parents yet
              </p>
            </div>
          ) : (
            <div className="space-y-2">
              {studentsWithParents.map((student) => (
                <button
                  key={student.id}
                  onClick={() => handleStartConversation(student)}
                  disabled={loading}
                  className={cn(
                    'w-full flex items-center gap-3 p-3 rounded-lg border border-gray-200',
                    'hover:border-blue-300 hover:bg-blue-50 transition-colors text-left',
                    'disabled:opacity-50 disabled:cursor-not-allowed'
                  )}
                >
                  <Avatar
                    initials={`${student.first_name[0]}${student.last_name[0]}`}
                    size="md"
                  />
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">
                      {student.first_name} {student.last_name}
                    </p>
                    <p className="text-sm text-gray-500">
                      {student.parent_ids.length} parent{student.parent_ids.length !== 1 ? 's' : ''} connected
                    </p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
