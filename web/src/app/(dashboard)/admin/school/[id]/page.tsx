'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import {
  School,
  Users,
  GraduationCap,
  UserCheck,
  BookOpen,
  Star,
  MessageSquare,
  ArrowLeft,
  TrendingUp,
  TrendingDown,
  ChevronRight,
  MoreVertical,
  Settings,
  Download
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { getSchoolStats, getSchoolById, getStoriesInSchool } from '@/services/admin'
import type { School as SchoolType, SchoolStats, Story, ClassroomStats } from '@/types'
import { timeAgo } from '@/types'

export default function PrincipalDashboard() {
  const params = useParams()
  const schoolId = params.id as string

  const [school, setSchool] = useState<SchoolType | null>(null)
  const [stats, setStats] = useState<SchoolStats | null>(null)
  const [stories, setStories] = useState<Story[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (schoolId) {
      loadData()
    }
  }, [schoolId])

  async function loadData() {
    try {
      setLoading(true)
      const [schoolData, statsData, storiesData] = await Promise.all([
        getSchoolById(schoolId),
        getSchoolStats(schoolId),
        getStoriesInSchool(schoolId, 10)
      ])
      setSchool(schoolData)
      setStats(statsData)
      setStories(storiesData)
    } catch (err) {
      console.error('Error loading school data:', err)
      setError('Failed to load school data')
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (error || !school) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600 mb-4">{error || 'School not found'}</p>
        <Link href="/admin">
          <Button>Back to Admin</Button>
        </Link>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-4">
          <Link href="/admin" className="text-gray-500 hover:text-gray-700">
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div className="w-14 h-14 rounded-xl bg-blue-100 flex items-center justify-center">
            <School className="w-7 h-7 text-blue-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{school.name}</h1>
            <p className="text-gray-500">
              Principal Dashboard &middot; {school.city}{school.state ? `, ${school.state}` : ''}
            </p>
          </div>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" size="sm">
            <Download className="w-4 h-4 mr-2" />
            Export
          </Button>
          <Button variant="outline" size="sm">
            <Settings className="w-4 h-4 mr-2" />
            Settings
          </Button>
        </div>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-4">
        <StatCard
          title="Classrooms"
          value={stats?.classroom_count || 0}
          icon={BookOpen}
          color="bg-blue-500"
          trend={null}
        />
        <StatCard
          title="Teachers"
          value={stats?.teacher_count || 0}
          icon={GraduationCap}
          color="bg-orange-500"
          trend={null}
        />
        <StatCard
          title="Students"
          value={stats?.student_count || 0}
          icon={Users}
          color="bg-pink-500"
          trend={null}
        />
        <StatCard
          title="Parents"
          value={stats?.parent_count || 0}
          icon={UserCheck}
          color="bg-teal-500"
          trend={null}
        />
        <StatCard
          title="Total Points"
          value={stats?.total_points || 0}
          icon={Star}
          color="bg-yellow-500"
          trend={null}
        />
      </div>

      {/* Classrooms Table */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <BookOpen className="w-5 h-5 text-blue-600" />
            Classrooms Overview
          </CardTitle>
        </CardHeader>
        <CardContent>
          {stats?.classrooms && stats.classrooms.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 font-semibold text-gray-600">Classroom</th>
                    <th className="text-left py-3 px-4 font-semibold text-gray-600">Teacher</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Students</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Parents</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Points</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Avg/Student</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Stories</th>
                    <th className="text-right py-3 px-4"></th>
                  </tr>
                </thead>
                <tbody>
                  {stats.classrooms.map((classroom) => (
                    <ClassroomRow key={classroom.classroom_id} classroom={classroom} />
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-8">
              <BookOpen className="w-12 h-12 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500">No classrooms in this school yet</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Two Column Layout */}
      <div className="grid md:grid-cols-2 gap-6">
        {/* Recent Stories */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BookOpen className="w-5 h-5 text-green-600" />
              Recent Stories
            </CardTitle>
          </CardHeader>
          <CardContent>
            {stories.length > 0 ? (
              <div className="space-y-4">
                {stories.map((story) => (
                  <div key={story.id} className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
                      <BookOpen className="w-5 h-5 text-green-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-gray-900">{story.author_name}</p>
                      <p className="text-sm text-gray-500 truncate">
                        {story.content || 'Shared a photo'}
                      </p>
                      <div className="flex items-center gap-3 mt-1">
                        <span className="text-xs text-gray-400">{timeAgo(story.created_at)}</span>
                        <span className="text-xs text-gray-400">
                          {story.like_count} likes &middot; {story.comment_count} comments
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 text-center py-4">No recent stories</p>
            )}
          </CardContent>
        </Card>

        {/* Top Performing Classrooms */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-blue-600" />
              Top Classrooms by Points
            </CardTitle>
          </CardHeader>
          <CardContent>
            {stats?.classrooms && stats.classrooms.length > 0 ? (
              <div className="space-y-4">
                {[...stats.classrooms]
                  .sort((a, b) => b.avg_points_per_student - a.avg_points_per_student)
                  .slice(0, 5)
                  .map((classroom, index) => (
                    <div key={classroom.classroom_id} className="flex items-center gap-3">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${
                        index === 0 ? 'bg-yellow-100 text-yellow-700' :
                        index === 1 ? 'bg-gray-100 text-gray-700' :
                        index === 2 ? 'bg-orange-100 text-orange-700' :
                        'bg-gray-50 text-gray-500'
                      }`}>
                        {index + 1}
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-gray-900">{classroom.classroom_name}</p>
                        <p className="text-sm text-gray-500">{classroom.teacher_name}</p>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-gray-900">{classroom.avg_points_per_student}</p>
                        <p className="text-xs text-gray-500">avg pts/student</p>
                      </div>
                    </div>
                  ))}
              </div>
            ) : (
              <p className="text-gray-500 text-center py-4">No classroom data</p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Grade Level Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle>Grade Levels</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-3">
            {school.grade_levels?.map((grade) => (
              <div
                key={grade}
                className="px-4 py-2 rounded-lg bg-blue-50 border border-blue-200"
              >
                <span className="font-medium text-blue-700">Grade {grade}</span>
              </div>
            )) || (
              <p className="text-gray-500">No grade levels defined</p>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

function StatCard({
  title,
  value,
  icon: Icon,
  color,
  trend
}: {
  title: string
  value: number
  icon: React.ElementType
  color: string
  trend: number | null
}) {
  return (
    <Card>
      <CardContent className="pt-6">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm text-gray-500 mb-1">{title}</p>
            <p className="text-2xl font-bold text-gray-900">{value.toLocaleString()}</p>
          </div>
          <div className={`w-10 h-10 rounded-lg ${color} flex items-center justify-center`}>
            <Icon className="w-5 h-5 text-white" />
          </div>
        </div>
        {trend !== null && (
          <div className={`flex items-center gap-1 mt-2 text-sm ${
            trend >= 0 ? 'text-green-600' : 'text-red-600'
          }`}>
            {trend >= 0 ? (
              <TrendingUp className="w-4 h-4" />
            ) : (
              <TrendingDown className="w-4 h-4" />
            )}
            <span>{Math.abs(trend)}% from last month</span>
          </div>
        )}
      </CardContent>
    </Card>
  )
}

function ClassroomRow({ classroom }: { classroom: ClassroomStats }) {
  return (
    <tr className="border-b border-gray-100 hover:bg-gray-50">
      <td className="py-3 px-4">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded bg-blue-100 flex items-center justify-center">
            <BookOpen className="w-4 h-4 text-blue-600" />
          </div>
          <span className="font-medium text-gray-900">{classroom.classroom_name}</span>
        </div>
      </td>
      <td className="py-3 px-4 text-gray-600">{classroom.teacher_name}</td>
      <td className="py-3 px-4 text-center">
        <span className="inline-flex items-center gap-1">
          <Users className="w-4 h-4 text-gray-400" />
          {classroom.student_count}
        </span>
      </td>
      <td className="py-3 px-4 text-center">
        <span className="inline-flex items-center gap-1">
          <UserCheck className="w-4 h-4 text-gray-400" />
          {classroom.parent_count}
        </span>
      </td>
      <td className="py-3 px-4 text-center">
        <span className={`font-medium ${classroom.total_points >= 0 ? 'text-green-600' : 'text-red-600'}`}>
          {classroom.total_points >= 0 ? '+' : ''}{classroom.total_points}
        </span>
      </td>
      <td className="py-3 px-4 text-center">
        <span className="font-medium text-gray-700">{classroom.avg_points_per_student}</span>
      </td>
      <td className="py-3 px-4 text-center text-gray-600">{classroom.story_count}</td>
      <td className="py-3 px-4 text-right">
        <button className="p-1 hover:bg-gray-100 rounded">
          <MoreVertical className="w-4 h-4 text-gray-400" />
        </button>
      </td>
    </tr>
  )
}
