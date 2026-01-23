'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/auth-context'
import { useClassroom } from '@/contexts/classroom-context'
import { Header } from '@/components/layout/header'
import { Card, CardContent, CardHeader, CardTitle, Button, Input } from '@/components/ui'
import { messageService } from '@/services/message'
import { storyService } from '@/services/story'
import { pointsService } from '@/services/points'
import { classroomService } from '@/services/classroom'
import type { Conversation, Story, StudentPointsSummary, Student } from '@/types'
import { timeAgo, getStudentFullName } from '@/types'
import Link from 'next/link'
import {
  Users,
  MessageSquare,
  BookOpen,
  Star,
  Plus,
  ArrowRight,
  TrendingUp,
  UserPlus,
  Link as LinkIcon,
  CheckCircle,
} from 'lucide-react'

export default function DashboardPage() {
  const router = useRouter()
  const { user, loading: authLoading, refreshUser } = useAuth()
  const { selectedClassroom, students, classrooms, refreshClassrooms } = useClassroom()
  const [conversations, setConversations] = useState<Conversation[]>([])
  const [stories, setStories] = useState<Story[]>([])
  const [pointsSummaries, setPointsSummaries] = useState<StudentPointsSummary[]>([])
  const [loading, setLoading] = useState(true)

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!authLoading && !user) {
      window.location.href = '/login'
    }
  }, [authLoading, user])

  // Parent linking state
  const [studentCode, setStudentCode] = useState('')
  const [linkingStudent, setLinkingStudent] = useState(false)
  const [linkError, setLinkError] = useState('')
  const [linkSuccess, setLinkSuccess] = useState<Student | null>(null)
  const [linkedStudents, setLinkedStudents] = useState<Student[]>([])

  // Fetch linked students for parent
  useEffect(() => {
    if (!user || user.role !== 'parent' || !user.student_ids?.length) {
      setLinkedStudents([])
      return
    }

    const fetchLinkedStudents = async () => {
      const studentPromises = user.student_ids.map(id => classroomService.getStudent(id))
      const results = await Promise.all(studentPromises)
      setLinkedStudents(results.filter((s): s is Student => s !== null))
    }

    fetchLinkedStudents()
  }, [user])

  useEffect(() => {
    if (!user || !selectedClassroom) {
      setLoading(false)
      return
    }

    const fetchData = async () => {
      setLoading(true)
      try {
        const [convs, strs, summaries] = await Promise.all([
          messageService.getConversationsForUser(user.id),
          storyService.getStoriesForClass(selectedClassroom.id, 5),
          pointsService.getClassSummaries(selectedClassroom.id),
        ])
        setConversations(convs.slice(0, 3))
        setStories(strs)
        setPointsSummaries(summaries.slice(0, 5))
      } catch (error) {
        console.error('Failed to fetch dashboard data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [user, selectedClassroom])

  const isTeacher = user?.role === 'teacher'
  const totalUnread = conversations.reduce((sum, c) => sum + (c.unread_counts[user?.id || ''] || 0), 0)
  const totalPoints = pointsSummaries.reduce((sum, s) => sum + s.total_points, 0)

  const handleLinkStudent = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user || !studentCode.trim()) return

    setLinkingStudent(true)
    setLinkError('')
    setLinkSuccess(null)

    try {
      const { student, classroom } = await classroomService.linkParentToStudentByCode(
        studentCode.trim().toUpperCase(),
        user.id
      )
      setLinkSuccess(student)
      setStudentCode('')
      // Refresh data
      await Promise.all([refreshUser(), refreshClassrooms()])
      // Update linked students list
      setLinkedStudents(prev => [...prev, student])
    } catch (err) {
      setLinkError(err instanceof Error ? err.message : 'Failed to link to student')
    } finally {
      setLinkingStudent(false)
    }
  }

  // Show loading while auth is checking
  if (authLoading) {
    return (
      <>
        <Header title="Dashboard" />
        <main className="flex-1 p-6 flex items-center justify-center">
          <div className="text-gray-500">Loading...</div>
        </main>
      </>
    )
  }

  // Show loading while redirecting to login (no user)
  if (!user) {
    return (
      <>
        <Header title="Dashboard" />
        <main className="flex-1 p-6 flex items-center justify-center">
          <div className="text-gray-500">Redirecting to login...</div>
        </main>
      </>
    )
  }

  // Show onboarding for teachers without classrooms
  if (isTeacher && classrooms.length === 0 && !loading) {
    return (
      <>
        <Header title="Dashboard" />
        <main className="flex-1 p-6 flex items-center justify-center">
          <Card className="max-w-md w-full text-center">
            <CardContent className="py-12">
              <div className="mx-auto h-16 w-16 rounded-full bg-blue-100 flex items-center justify-center mb-6">
                <Users className="h-8 w-8 text-blue-600" />
              </div>
              <h2 className="text-xl font-semibold text-gray-900 mb-2">
                Create Your First Classroom
              </h2>
              <p className="text-gray-500 mb-6">
                Get started by creating a classroom. You can add students and invite parents to connect.
              </p>
              <Link href="/classroom">
                <Button>
                  <Plus className="h-4 w-4 mr-2" />
                  Create Classroom
                </Button>
              </Link>
            </CardContent>
          </Card>
        </main>
      </>
    )
  }

  // Show link to child for parents without linked students
  if (!isTeacher && linkedStudents.length === 0 && !loading) {
    return (
      <>
        <Header title="Dashboard" />
        <main className="flex-1 p-6 flex items-center justify-center">
          <Card className="max-w-md w-full">
            <CardContent className="py-8">
              <div className="text-center mb-6">
                <div className="mx-auto h-16 w-16 rounded-full bg-green-100 flex items-center justify-center mb-4">
                  <LinkIcon className="h-8 w-8 text-green-600" />
                </div>
                <h2 className="text-xl font-semibold text-gray-900 mb-2">
                  Link to Your Child
                </h2>
                <p className="text-gray-500">
                  Enter the student code provided by your child&apos;s teacher to connect with your child&apos;s classroom.
                </p>
              </div>

              {linkSuccess ? (
                <div className="text-center p-4 rounded-lg bg-green-50 border border-green-200">
                  <CheckCircle className="h-8 w-8 text-green-500 mx-auto mb-2" />
                  <p className="font-medium text-green-800">
                    Successfully linked to {getStudentFullName(linkSuccess)}!
                  </p>
                  <p className="text-sm text-green-600 mt-1">
                    You can now view your child&apos;s progress and communicate with their teacher.
                  </p>
                </div>
              ) : (
                <form onSubmit={handleLinkStudent} className="space-y-4">
                  {linkError && (
                    <div className="p-3 rounded-lg bg-red-50 text-red-600 text-sm">
                      {linkError}
                    </div>
                  )}
                  <Input
                    label="Student Code"
                    placeholder="e.g., EMMA-7K3X"
                    value={studentCode}
                    onChange={(e) => setStudentCode(e.target.value.toUpperCase())}
                    className="text-center font-mono text-lg uppercase"
                    required
                  />
                  <Button
                    type="submit"
                    className="w-full bg-green-600 hover:bg-green-700"
                    loading={linkingStudent}
                  >
                    <UserPlus className="h-4 w-4 mr-2" />
                    Link to My Child
                  </Button>
                </form>
              )}

              <div className="mt-6 pt-6 border-t border-gray-200 text-center">
                <p className="text-sm text-gray-500 mb-2">Don&apos;t have a code?</p>
                <p className="text-sm text-gray-600">
                  Ask your child&apos;s teacher for the student invite code.
                </p>
              </div>
            </CardContent>
          </Card>
        </main>
      </>
    )
  }

  return (
    <>
      <Header title="Dashboard" />
      <main className="flex-1 p-6 overflow-y-auto">
        {/* Stats Grid */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-lg bg-blue-100 flex items-center justify-center">
                  <Users className="h-5 w-5 text-blue-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">{students.length}</p>
                  <p className="text-sm text-gray-500">Students</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-lg bg-purple-100 flex items-center justify-center">
                  <MessageSquare className="h-5 w-5 text-purple-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">{totalUnread}</p>
                  <p className="text-sm text-gray-500">Unread</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-lg bg-green-100 flex items-center justify-center">
                  <BookOpen className="h-5 w-5 text-green-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">{stories.length}</p>
                  <p className="text-sm text-gray-500">Stories</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="p-4">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-lg bg-yellow-100 flex items-center justify-center">
                  <Star className="h-5 w-5 text-yellow-600" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">{totalPoints}</p>
                  <p className="text-sm text-gray-500">Total Points</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="grid lg:grid-cols-2 gap-6">
          {/* Recent Messages */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-base">Recent Messages</CardTitle>
              <Link href="/messages">
                <Button variant="ghost" size="sm">
                  View all
                  <ArrowRight className="h-4 w-4 ml-1" />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              {conversations.length === 0 ? (
                <p className="text-sm text-gray-500 text-center py-6">No messages yet</p>
              ) : (
                <div className="space-y-3">
                  {conversations.map((conv) => {
                    const otherName = Object.entries(conv.participant_names)
                      .find(([id]) => id !== user?.id)?.[1] || 'Unknown'
                    const unread = conv.unread_counts[user?.id || ''] || 0

                    return (
                      <Link
                        key={conv.id}
                        href={`/messages/${conv.id}`}
                        className="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 transition-colors"
                      >
                        <div className="h-10 w-10 rounded-full bg-purple-100 flex items-center justify-center">
                          <span className="text-sm font-medium text-purple-600">
                            {otherName.charAt(0).toUpperCase()}
                          </span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between">
                            <p className="text-sm font-medium text-gray-900 truncate">{otherName}</p>
                            {conv.last_message_date && (
                              <span className="text-xs text-gray-400">
                                {timeAgo(conv.last_message_date)}
                              </span>
                            )}
                          </div>
                          <p className="text-sm text-gray-500 truncate">{conv.last_message || 'No messages'}</p>
                        </div>
                        {unread > 0 && (
                          <span className="h-5 w-5 rounded-full bg-blue-500 text-white text-xs flex items-center justify-center">
                            {unread}
                          </span>
                        )}
                      </Link>
                    )
                  })}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Top Students by Points */}
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-base">Top Students</CardTitle>
              <Link href="/points">
                <Button variant="ghost" size="sm">
                  View all
                  <ArrowRight className="h-4 w-4 ml-1" />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              {pointsSummaries.length === 0 ? (
                <p className="text-sm text-gray-500 text-center py-6">No points recorded yet</p>
              ) : (
                <div className="space-y-3">
                  {pointsSummaries.map((summary, index) => {
                    const student = students.find(s => s.id === summary.student_id)
                    if (!student) return null

                    return (
                      <div
                        key={summary.id}
                        className="flex items-center gap-3 p-3 rounded-lg bg-gray-50"
                      >
                        <div className="h-8 w-8 rounded-full bg-yellow-100 flex items-center justify-center">
                          <span className="text-sm font-bold text-yellow-600">
                            #{index + 1}
                          </span>
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {student.first_name} {student.last_name}
                          </p>
                        </div>
                        <div className="flex items-center gap-1 text-green-600">
                          <TrendingUp className="h-4 w-4" />
                          <span className="font-semibold">{summary.total_points}</span>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Recent Stories */}
        {stories.length > 0 && (
          <Card className="mt-6">
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle className="text-base">Recent Stories</CardTitle>
              <Link href="/stories">
                <Button variant="ghost" size="sm">
                  View all
                  <ArrowRight className="h-4 w-4 ml-1" />
                </Button>
              </Link>
            </CardHeader>
            <CardContent>
              <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {stories.slice(0, 3).map((story) => (
                  <Link
                    key={story.id}
                    href={`/stories/${story.id}`}
                    className="block p-4 rounded-lg border border-gray-200 hover:border-gray-300 transition-colors"
                  >
                    <div className="flex items-center gap-2 mb-2">
                      <div className="h-6 w-6 rounded-full bg-green-100 flex items-center justify-center">
                        <span className="text-xs font-medium text-green-600">
                          {story.author_name.charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <span className="text-sm font-medium text-gray-900">{story.author_name}</span>
                      <span className="text-xs text-gray-400 ml-auto">{timeAgo(story.created_at)}</span>
                    </div>
                    <p className="text-sm text-gray-600 line-clamp-2">{story.content || 'Shared media'}</p>
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </main>
    </>
  )
}
