'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import {
  Building2,
  School,
  Users,
  GraduationCap,
  UserCheck,
  BookOpen,
  Star,
  ArrowLeft,
  TrendingUp,
  ChevronRight,
  Settings,
  Download,
  Plus,
  MapPin,
  BarChart3
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { getDistrictStats, getDistrictById, getSchoolsInDistrict } from '@/services/admin'
import type { District, School as SchoolType, DistrictStats, SchoolStats } from '@/types'

export default function DistrictAdminDashboard() {
  const params = useParams()
  const districtId = params.id as string

  const [district, setDistrict] = useState<District | null>(null)
  const [schools, setSchools] = useState<SchoolType[]>([])
  const [stats, setStats] = useState<DistrictStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (districtId) {
      loadData()
    }
  }, [districtId])

  async function loadData() {
    try {
      setLoading(true)
      const [districtData, schoolsData, statsData] = await Promise.all([
        getDistrictById(districtId),
        getSchoolsInDistrict(districtId),
        getDistrictStats(districtId)
      ])
      setDistrict(districtData)
      setSchools(schoolsData)
      setStats(statsData)
    } catch (err) {
      console.error('Error loading district data:', err)
      setError('Failed to load district data')
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    )
  }

  if (error || !district) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600 mb-4">{error || 'District not found'}</p>
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
          <div className="w-14 h-14 rounded-xl bg-purple-100 flex items-center justify-center">
            <Building2 className="w-7 h-7 text-purple-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{district.name}</h1>
            <p className="text-gray-500 flex items-center gap-1">
              <MapPin className="w-4 h-4" />
              {district.city}{district.state ? `, ${district.state}` : ''} &middot; Code: {district.code}
            </p>
          </div>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" size="sm">
            <Download className="w-4 h-4 mr-2" />
            Export Report
          </Button>
          <Button variant="outline" size="sm">
            <Settings className="w-4 h-4 mr-2" />
            Settings
          </Button>
          <Button size="sm">
            <Plus className="w-4 h-4 mr-2" />
            Add School
          </Button>
        </div>
      </div>

      {/* District-wide Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
        <StatCard
          title="Schools"
          value={stats?.school_count || 0}
          icon={School}
          color="bg-blue-500"
        />
        <StatCard
          title="Classrooms"
          value={stats?.classroom_count || 0}
          icon={BookOpen}
          color="bg-green-500"
        />
        <StatCard
          title="Teachers"
          value={stats?.teacher_count || 0}
          icon={GraduationCap}
          color="bg-orange-500"
        />
        <StatCard
          title="Students"
          value={stats?.student_count || 0}
          icon={Users}
          color="bg-pink-500"
        />
        <StatCard
          title="Parents"
          value={stats?.parent_count || 0}
          icon={UserCheck}
          color="bg-teal-500"
        />
        <StatCard
          title="Total Points"
          value={stats?.total_points || 0}
          icon={Star}
          color="bg-yellow-500"
        />
        <StatCard
          title="Stories"
          value={stats?.story_count || 0}
          icon={BookOpen}
          color="bg-indigo-500"
        />
      </div>

      {/* Schools Grid */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <School className="w-5 h-5 text-blue-600" />
            Schools in District
          </CardTitle>
          <Button size="sm">
            <Plus className="w-4 h-4 mr-1" />
            Add School
          </Button>
        </CardHeader>
        <CardContent>
          {schools.length > 0 ? (
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
              {schools.map((school) => {
                const schoolStats = stats?.schools.find(s => s.school_id === school.id)
                return (
                  <SchoolCard key={school.id} school={school} stats={schoolStats} />
                )
              })}
            </div>
          ) : (
            <div className="text-center py-8">
              <School className="w-12 h-12 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500 mb-4">No schools in this district yet</p>
              <Button>
                <Plus className="w-4 h-4 mr-2" />
                Add First School
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Schools Comparison Table */}
      {stats?.schools && stats.schools.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="w-5 h-5 text-purple-600" />
              Schools Comparison
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 font-semibold text-gray-600">School</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Classrooms</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Teachers</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Students</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Parents</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Total Points</th>
                    <th className="text-center py-3 px-4 font-semibold text-gray-600">Stories</th>
                    <th className="text-right py-3 px-4"></th>
                  </tr>
                </thead>
                <tbody>
                  {stats.schools.map((schoolStat) => (
                    <tr key={schoolStat.school_id} className="border-b border-gray-100 hover:bg-gray-50">
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded bg-blue-100 flex items-center justify-center">
                            <School className="w-4 h-4 text-blue-600" />
                          </div>
                          <span className="font-medium text-gray-900">{schoolStat.school_name}</span>
                        </div>
                      </td>
                      <td className="py-3 px-4 text-center text-gray-600">{schoolStat.classroom_count}</td>
                      <td className="py-3 px-4 text-center text-gray-600">{schoolStat.teacher_count}</td>
                      <td className="py-3 px-4 text-center text-gray-600">{schoolStat.student_count}</td>
                      <td className="py-3 px-4 text-center text-gray-600">{schoolStat.parent_count}</td>
                      <td className="py-3 px-4 text-center">
                        <span className={`font-medium ${schoolStat.total_points >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                          {schoolStat.total_points >= 0 ? '+' : ''}{schoolStat.total_points.toLocaleString()}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-center text-gray-600">{schoolStat.story_count}</td>
                      <td className="py-3 px-4 text-right">
                        <Link href={`/admin/school/${schoolStat.school_id}`}>
                          <Button variant="outline" size="sm">
                            View
                            <ChevronRight className="w-4 h-4 ml-1" />
                          </Button>
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr className="bg-gray-50 font-semibold">
                    <td className="py-3 px-4 text-gray-900">District Total</td>
                    <td className="py-3 px-4 text-center text-gray-900">{stats.classroom_count}</td>
                    <td className="py-3 px-4 text-center text-gray-900">{stats.teacher_count}</td>
                    <td className="py-3 px-4 text-center text-gray-900">{stats.student_count}</td>
                    <td className="py-3 px-4 text-center text-gray-900">{stats.parent_count}</td>
                    <td className="py-3 px-4 text-center text-green-600">{stats.total_points.toLocaleString()}</td>
                    <td className="py-3 px-4 text-center text-gray-900">{stats.story_count}</td>
                    <td></td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Top Performing Schools */}
      {stats?.schools && stats.schools.length > 1 && (
        <div className="grid md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-green-600" />
                Top Schools by Engagement
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {[...stats.schools]
                  .sort((a, b) => b.story_count - a.story_count)
                  .slice(0, 5)
                  .map((school, index) => (
                    <div key={school.school_id} className="flex items-center gap-3">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${
                        index === 0 ? 'bg-yellow-100 text-yellow-700' :
                        index === 1 ? 'bg-gray-100 text-gray-700' :
                        index === 2 ? 'bg-orange-100 text-orange-700' :
                        'bg-gray-50 text-gray-500'
                      }`}>
                        {index + 1}
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-gray-900">{school.school_name}</p>
                        <p className="text-sm text-gray-500">
                          {school.classroom_count} classrooms, {school.student_count} students
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-gray-900">{school.story_count}</p>
                        <p className="text-xs text-gray-500">stories</p>
                      </div>
                    </div>
                  ))}
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Star className="w-5 h-5 text-yellow-600" />
                Top Schools by Points
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {[...stats.schools]
                  .sort((a, b) => b.total_points - a.total_points)
                  .slice(0, 5)
                  .map((school, index) => (
                    <div key={school.school_id} className="flex items-center gap-3">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${
                        index === 0 ? 'bg-yellow-100 text-yellow-700' :
                        index === 1 ? 'bg-gray-100 text-gray-700' :
                        index === 2 ? 'bg-orange-100 text-orange-700' :
                        'bg-gray-50 text-gray-500'
                      }`}>
                        {index + 1}
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-gray-900">{school.school_name}</p>
                        <p className="text-sm text-gray-500">
                          {school.student_count} students
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="font-bold text-green-600">+{school.total_points.toLocaleString()}</p>
                        <p className="text-xs text-gray-500">total points</p>
                      </div>
                    </div>
                  ))}
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}

function StatCard({
  title,
  value,
  icon: Icon,
  color
}: {
  title: string
  value: number
  icon: React.ElementType
  color: string
}) {
  return (
    <Card>
      <CardContent className="pt-4 pb-4">
        <div className="flex items-center gap-3">
          <div className={`w-10 h-10 rounded-lg ${color} flex items-center justify-center`}>
            <Icon className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="text-xl font-bold text-gray-900">{value.toLocaleString()}</p>
            <p className="text-xs text-gray-500">{title}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

function SchoolCard({ school, stats }: { school: SchoolType; stats?: SchoolStats }) {
  return (
    <Link href={`/admin/school/${school.id}`}>
      <div className="border border-gray-200 rounded-xl p-4 hover:border-blue-300 hover:shadow-md transition-all cursor-pointer">
        <div className="flex items-start justify-between mb-3">
          <div className="w-12 h-12 rounded-lg bg-blue-100 flex items-center justify-center">
            <School className="w-6 h-6 text-blue-600" />
          </div>
          <ChevronRight className="w-5 h-5 text-gray-400" />
        </div>

        <h3 className="font-semibold text-gray-900 mb-1">{school.name}</h3>
        <p className="text-sm text-gray-500 mb-3">
          {school.city}{school.state ? `, ${school.state}` : ''}
        </p>

        {stats && (
          <div className="grid grid-cols-3 gap-2 pt-3 border-t border-gray-100">
            <div className="text-center">
              <p className="font-semibold text-gray-900">{stats.classroom_count}</p>
              <p className="text-xs text-gray-500">Classes</p>
            </div>
            <div className="text-center">
              <p className="font-semibold text-gray-900">{stats.student_count}</p>
              <p className="text-xs text-gray-500">Students</p>
            </div>
            <div className="text-center">
              <p className="font-semibold text-gray-900">{stats.teacher_count}</p>
              <p className="text-xs text-gray-500">Teachers</p>
            </div>
          </div>
        )}

        {school.grade_levels && school.grade_levels.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-3">
            {school.grade_levels.slice(0, 4).map((grade) => (
              <span key={grade} className="px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded">
                {grade}
              </span>
            ))}
            {school.grade_levels.length > 4 && (
              <span className="px-2 py-0.5 bg-gray-100 text-gray-600 text-xs rounded">
                +{school.grade_levels.length - 4}
              </span>
            )}
          </div>
        )}
      </div>
    </Link>
  )
}
