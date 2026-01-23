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
            {selectedClassroom && (
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
                  {selectedClassroom && !searchQuery && (
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
            teacherId={selectedClassroom?.teacher_id}
            userId={user?.id}
            userName={user?.name}
            userRole={user?.role}
            linkedStudents={user?.student_ids || []}
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
  teacherId?: string
  userId?: string
  userName?: string
  userRole?: string
  linkedStudents?: string[]
}

function NewMessageModal({ onClose, students, classroomId, teacherId, userId, userName, userRole, linkedStudents = [] }: NewMessageModalProps) {
  const [loading, setLoading] = useState(false)
  const [teacherName, setTeacherName] = useState<string>('')

  const isTeacher = userRole === 'teacher'
  const studentsWithParents = students.filter(s => s.parent_ids.length > 0)

  // Fetch teacher name for parent view
  useEffect(() => {
    if (!isTeacher && teacherId) {
      // Fetch teacher name
      import('@/services/auth').then(({ authService }) => {
        authService.getUser(teacherId).then(teacher => {
          if (teacher) setTeacherName(teacher.name)
        })
      })
    }
  }, [isTeacher, teacherId])

  // For teachers: message a student's parent
  const handleStartConversationWithParent = async (student: any) => {
    if (!userId || !userName || !classroomId) return

    setLoading(true)
    try {
      const parentId = student.parent_ids[0]
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

      window.location.href = `/messages/${conversation.id}`
    } catch (error) {
      console.error('Failed to create conversation:', error)
    } finally {
      setLoading(false)
    }
  }

  // For parents: message the teacher about their child
  const handleStartConversationWithTeacher = async (studentId?: string, studentName?: string) => {
    if (!userId || !userName || !classroomId || !teacherId) return

    setLoading(true)
    try {
      const participantNames = {
        [userId]: userName,
        [teacherId]: teacherName || 'Teacher',
      }

      const conversation = await messageService.getOrCreateConversation(
        [userId, teacherId],
        participantNames,
        classroomId,
        studentId,
        studentName
      )

      window.location.href = `/messages/${conversation.id}`
    } catch (error) {
      console.error('Failed to create conversation:', error)
    } finally {
      setLoading(false)
    }
  }

  // Get linked students for parent view
  const myLinkedStudents = students.filter(s => linkedStudents.includes(s.id))

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
          {isTeacher ? (
            // Teacher view: select a student to message their parent
            <>
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
                      onClick={() => handleStartConversationWithParent(student)}
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
            </>
          ) : (
            // Parent view: message the teacher
            <>
              <p className="text-sm text-gray-500 mb-4">
                Message your child&apos;s teacher
              </p>
              {myLinkedStudents.length > 1 ? (
                // Multiple children - let parent select which child to discuss
                <div className="space-y-2">
                  <p className="text-xs text-gray-400 mb-2">Select which child this message is about:</p>
                  {myLinkedStudents.map((student) => (
                    <button
                      key={student.id}
                      onClick={() => handleStartConversationWithTeacher(student.id, `${student.first_name} ${student.last_name}`)}
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
                          About {student.first_name} {student.last_name}
                        </p>
                        <p className="text-sm text-gray-500">
                          Message {teacherName || 'the teacher'}
                        </p>
                      </div>
                    </button>
                  ))}
                </div>
              ) : (
                // Single child or general message
                <button
                  onClick={() => {
                    const student = myLinkedStudents[0]
                    handleStartConversationWithTeacher(
                      student?.id,
                      student ? `${student.first_name} ${student.last_name}` : undefined
                    )
                  }}
                  disabled={loading}
                  className={cn(
                    'w-full flex items-center gap-3 p-3 rounded-lg border border-gray-200',
                    'hover:border-blue-300 hover:bg-blue-50 transition-colors text-left',
                    'disabled:opacity-50 disabled:cursor-not-allowed'
                  )}
                >
                  <Avatar
                    initials={teacherName ? teacherName.split(' ').map(n => n[0]).join('').slice(0, 2) : 'T'}
                    size="md"
                    className="bg-blue-100 text-blue-600"
                  />
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">
                      {teacherName || 'Teacher'}
                    </p>
                    <p className="text-sm text-gray-500">
                      {myLinkedStudents[0] ? `About ${myLinkedStudents[0].first_name}` : 'Classroom teacher'}
                    </p>
                  </div>
                </button>
              )}
            </>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
