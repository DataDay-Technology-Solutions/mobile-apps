'use client'

import { useEffect, useState } from 'react'
import { useAuth } from '@/contexts/auth-context'
import { useClassroom } from '@/contexts/classroom-context'
import { pointsService } from '@/services/points'
import { Header } from '@/components/layout/header'
import { Card, CardContent, CardHeader, CardTitle, Button, Avatar } from '@/components/ui'
import { cn } from '@/lib/utils'
import {
  Star,
  TrendingUp,
  TrendingDown,
  Check,
  X,
  History,
} from 'lucide-react'
import type { StudentPointsSummary, PointRecord, Behavior, Student } from '@/types'
import {
  DEFAULT_POSITIVE_BEHAVIORS,
  DEFAULT_NEGATIVE_BEHAVIORS,
  getStudentFullName,
  getStudentInitials,
  timeAgo,
} from '@/types'

export default function PointsPage() {
  const { user } = useAuth()
  const { selectedClassroom, students } = useClassroom()
  const [summaries, setSummaries] = useState<StudentPointsSummary[]>([])
  const [recentPoints, setRecentPoints] = useState<PointRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedStudents, setSelectedStudents] = useState<Set<string>>(new Set())
  const [showBehaviorModal, setShowBehaviorModal] = useState(false)
  const [showHistoryModal, setShowHistoryModal] = useState<Student | null>(null)
  const [studentHistory, setStudentHistory] = useState<PointRecord[]>([])

  const isTeacher = user?.role === 'teacher'

  useEffect(() => {
    if (!selectedClassroom) {
      setLoading(false)
      return
    }

    const fetchData = async () => {
      setLoading(true)
      try {
        const [sums, recent] = await Promise.all([
          pointsService.getClassSummaries(selectedClassroom.id),
          pointsService.getClassPointsHistory(selectedClassroom.id, 10),
        ])
        setSummaries(sums)
        setRecentPoints(recent)
      } catch (error) {
        console.error('Failed to fetch points data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()

    // Subscribe to updates
    const unsubscribeSummaries = pointsService.subscribeToClassSummaries(
      selectedClassroom.id,
      (updatedSummaries) => setSummaries(updatedSummaries)
    )

    const unsubscribeRecent = pointsService.subscribeToRecentPoints(
      selectedClassroom.id,
      (updatedRecent) => setRecentPoints(updatedRecent)
    )

    return () => {
      unsubscribeSummaries()
      unsubscribeRecent()
    }
  }, [selectedClassroom])

  const toggleStudentSelection = (studentId: string) => {
    setSelectedStudents(prev => {
      const newSet = new Set(prev)
      if (newSet.has(studentId)) {
        newSet.delete(studentId)
      } else {
        newSet.add(studentId)
      }
      return newSet
    })
  }

  const selectAll = () => {
    setSelectedStudents(new Set(students.map(s => s.id)))
  }

  const clearSelection = () => {
    setSelectedStudents(new Set())
  }

  const handleAwardPoints = async (behavior: Behavior) => {
    if (!user || selectedStudents.size === 0 || !selectedClassroom) return

    try {
      await pointsService.awardPointsToMultipleStudents(
        Array.from(selectedStudents),
        selectedClassroom.id,
        behavior,
        user.id,
        user.name
      )
      clearSelection()
      setShowBehaviorModal(false)
    } catch (error) {
      console.error('Failed to award points:', error)
    }
  }

  const openStudentHistory = async (student: Student) => {
    if (!selectedClassroom) return
    setShowHistoryModal(student)
    try {
      const history = await pointsService.getPointsHistory(student.id, 50)
      setStudentHistory(history)
    } catch (error) {
      console.error('Failed to fetch student history:', error)
    }
  }

  const getStudentSummary = (studentId: string): StudentPointsSummary | undefined => {
    return summaries.find(s => s.student_id === studentId)
  }

  return (
    <>
      <Header title="Points" />
      <main className="flex-1 p-6 overflow-y-auto">
        {!selectedClassroom ? (
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-gray-500">Select a classroom to manage points</p>
            </CardContent>
          </Card>
        ) : (
          <div className="grid lg:grid-cols-3 gap-6">
            {/* Students Grid */}
            <div className="lg:col-span-2">
              <Card>
                <CardHeader className="flex flex-row items-center justify-between">
                  <CardTitle className="text-base">Students</CardTitle>
                  {isTeacher && students.length > 0 && (
                    <div className="flex items-center gap-2">
                      {selectedStudents.size > 0 ? (
                        <>
                          <span className="text-sm text-gray-500">
                            {selectedStudents.size} selected
                          </span>
                          <Button size="sm" variant="ghost" onClick={clearSelection}>
                            Clear
                          </Button>
                          <Button size="sm" onClick={() => setShowBehaviorModal(true)}>
                            <Star className="h-4 w-4 mr-1" />
                            Award
                          </Button>
                        </>
                      ) : (
                        <Button size="sm" variant="outline" onClick={selectAll}>
                          Select All
                        </Button>
                      )}
                    </div>
                  )}
                </CardHeader>
                <CardContent>
                  {students.length === 0 ? (
                    <div className="text-center py-8">
                      <p className="text-gray-500">No students in this class</p>
                    </div>
                  ) : (
                    <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
                      {students.map((student) => {
                        const summary = getStudentSummary(student.id)
                        const isSelected = selectedStudents.has(student.id)

                        return (
                          <div
                            key={student.id}
                            className={cn(
                              'relative p-4 rounded-lg border-2 transition-all cursor-pointer',
                              isSelected
                                ? 'border-blue-500 bg-blue-50'
                                : 'border-gray-200 hover:border-gray-300'
                            )}
                            onClick={() => isTeacher && toggleStudentSelection(student.id)}
                          >
                            {/* Selection indicator */}
                            {isTeacher && (
                              <div
                                className={cn(
                                  'absolute top-2 right-2 h-5 w-5 rounded-full border-2 flex items-center justify-center',
                                  isSelected
                                    ? 'bg-blue-500 border-blue-500'
                                    : 'border-gray-300'
                                )}
                              >
                                {isSelected && <Check className="h-3 w-3 text-white" />}
                              </div>
                            )}

                            <div className="flex flex-col items-center text-center">
                              <Avatar
                                initials={getStudentInitials(student)}
                                size="lg"
                              />
                              <p className="mt-2 font-medium text-gray-900 text-sm">
                                {getStudentFullName(student)}
                              </p>
                              <div className="mt-2 flex items-center gap-2">
                                <span className={cn(
                                  'text-xl font-bold',
                                  (summary?.total_points || 0) >= 0
                                    ? 'text-green-600'
                                    : 'text-red-600'
                                )}>
                                  {summary?.total_points || 0}
                                </span>
                                <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                              </div>
                              <div className="mt-1 flex items-center gap-3 text-xs text-gray-500">
                                <span className="flex items-center gap-1">
                                  <TrendingUp className="h-3 w-3 text-green-500" />
                                  {summary?.positive_count || 0}
                                </span>
                                <span className="flex items-center gap-1">
                                  <TrendingDown className="h-3 w-3 text-red-500" />
                                  {summary?.negative_count || 0}
                                </span>
                              </div>
                              <button
                                onClick={(e) => {
                                  e.stopPropagation()
                                  openStudentHistory(student)
                                }}
                                className="mt-2 text-xs text-blue-600 hover:text-blue-700"
                              >
                                View History
                              </button>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>

            {/* Recent Activity */}
            <div className="lg:col-span-1">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Recent Activity</CardTitle>
                </CardHeader>
                <CardContent>
                  {recentPoints.length === 0 ? (
                    <p className="text-sm text-gray-500 text-center py-4">
                      No points recorded yet
                    </p>
                  ) : (
                    <div className="space-y-3">
                      {recentPoints.map((record) => {
                        const student = students.find(s => s.id === record.student_id)
                        const isPositive = record.points > 0

                        return (
                          <div
                            key={record.id}
                            className="flex items-center gap-3 p-2 rounded-lg bg-gray-50"
                          >
                            <div className={cn(
                              'h-8 w-8 rounded-full flex items-center justify-center',
                              isPositive ? 'bg-green-100' : 'bg-red-100'
                            )}>
                              {isPositive ? (
                                <TrendingUp className="h-4 w-4 text-green-600" />
                              ) : (
                                <TrendingDown className="h-4 w-4 text-red-600" />
                              )}
                            </div>
                            <div className="flex-1 min-w-0">
                              <p className="text-sm font-medium text-gray-900 truncate">
                                {student ? getStudentFullName(student) : 'Unknown'}
                              </p>
                              <p className="text-xs text-gray-500 truncate">
                                {record.behavior_name}
                              </p>
                            </div>
                            <div className="text-right">
                              <p className={cn(
                                'text-sm font-bold',
                                isPositive ? 'text-green-600' : 'text-red-600'
                              )}>
                                {isPositive ? '+' : ''}{record.points}
                              </p>
                              <p className="text-xs text-gray-400">
                                {timeAgo(record.created_at)}
                              </p>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
        )}

        {/* Behavior Selection Modal */}
        {showBehaviorModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-md mx-4 max-h-[80vh] flex flex-col">
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle>Award Points</CardTitle>
                <button
                  onClick={() => setShowBehaviorModal(false)}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <CardContent className="flex-1 overflow-y-auto">
                <p className="text-sm text-gray-500 mb-4">
                  Select a behavior for {selectedStudents.size} student{selectedStudents.size !== 1 ? 's' : ''}
                </p>

                {/* Positive Behaviors */}
                <h4 className="text-sm font-medium text-gray-700 mb-2">Positive</h4>
                <div className="grid grid-cols-2 gap-2 mb-4">
                  {DEFAULT_POSITIVE_BEHAVIORS.map((behavior) => (
                    <button
                      key={behavior.id}
                      onClick={() => handleAwardPoints(behavior)}
                      className="flex items-center gap-2 p-3 rounded-lg border border-gray-200 hover:border-green-300 hover:bg-green-50 transition-colors text-left"
                    >
                      <div
                        className="h-8 w-8 rounded-full flex items-center justify-center"
                        style={{ backgroundColor: `${behavior.color}20` }}
                      >
                        <span style={{ color: behavior.color }}>+{behavior.points}</span>
                      </div>
                      <span className="text-sm font-medium text-gray-900 truncate">
                        {behavior.name}
                      </span>
                    </button>
                  ))}
                </div>

                {/* Negative Behaviors */}
                <h4 className="text-sm font-medium text-gray-700 mb-2">Needs Work</h4>
                <div className="grid grid-cols-2 gap-2">
                  {DEFAULT_NEGATIVE_BEHAVIORS.map((behavior) => (
                    <button
                      key={behavior.id}
                      onClick={() => handleAwardPoints(behavior)}
                      className="flex items-center gap-2 p-3 rounded-lg border border-gray-200 hover:border-red-300 hover:bg-red-50 transition-colors text-left"
                    >
                      <div
                        className="h-8 w-8 rounded-full flex items-center justify-center"
                        style={{ backgroundColor: `${behavior.color}20` }}
                      >
                        <span style={{ color: behavior.color }}>{behavior.points}</span>
                      </div>
                      <span className="text-sm font-medium text-gray-900 truncate">
                        {behavior.name}
                      </span>
                    </button>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Student History Modal */}
        {showHistoryModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-md mx-4 max-h-[80vh] flex flex-col">
              <CardHeader className="flex flex-row items-center justify-between">
                <div>
                  <CardTitle>{getStudentFullName(showHistoryModal)}</CardTitle>
                  <p className="text-sm text-gray-500">Points History</p>
                </div>
                <button
                  onClick={() => setShowHistoryModal(null)}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <CardContent className="flex-1 overflow-y-auto">
                {studentHistory.length === 0 ? (
                  <p className="text-sm text-gray-500 text-center py-8">
                    No points history
                  </p>
                ) : (
                  <div className="space-y-2">
                    {studentHistory.map((record) => {
                      const isPositive = record.points > 0

                      return (
                        <div
                          key={record.id}
                          className={cn(
                            'flex items-center gap-3 p-3 rounded-lg',
                            isPositive ? 'bg-green-50' : 'bg-red-50'
                          )}
                        >
                          <div className={cn(
                            'h-8 w-8 rounded-full flex items-center justify-center font-bold text-sm',
                            isPositive ? 'bg-green-100 text-green-600' : 'bg-red-100 text-red-600'
                          )}>
                            {isPositive ? '+' : ''}{record.points}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium text-gray-900">
                              {record.behavior_name}
                            </p>
                            <p className="text-xs text-gray-500">
                              {record.awarded_by_name} · {timeAgo(record.created_at)}
                            </p>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        )}
      </main>
    </>
  )
}
