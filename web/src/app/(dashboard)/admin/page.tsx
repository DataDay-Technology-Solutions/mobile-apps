'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import {
  Building2,
  School,
  Users,
  GraduationCap,
  UserCheck,
  BookOpen,
  Star,
  MessageSquare,
  TrendingUp,
  Plus,
  ChevronRight,
  Activity,
  BarChart3,
  X
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { getSuperAdminStats, createDistrict, createSchool } from '@/services/admin'
import type { District, Story, PointRecord } from '@/types'
import { timeAgo } from '@/types'

interface SuperAdminStats {
  districts: District[]
  totalSchools: number
  totalClassrooms: number
  totalTeachers: number
  totalStudents: number
  totalParents: number
  recentStories: Story[]
  recentActivity: PointRecord[]
}

export default function SuperAdminDashboard() {
  const [stats, setStats] = useState<SuperAdminStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Modal states
  const [showAddDistrict, setShowAddDistrict] = useState(false)
  const [showAddSchool, setShowAddSchool] = useState(false)
  const [showReports, setShowReports] = useState(false)

  // Form states
  const [districtName, setDistrictName] = useState('')
  const [districtCode, setDistrictCode] = useState('')
  const [districtCity, setDistrictCity] = useState('')
  const [districtState, setDistrictState] = useState('')
  const [schoolName, setSchoolName] = useState('')
  const [schoolCode, setSchoolCode] = useState('')
  const [schoolCity, setSchoolCity] = useState('')
  const [schoolState, setSchoolState] = useState('')
  const [selectedDistrictId, setSelectedDistrictId] = useState('')
  const [formLoading, setFormLoading] = useState(false)
  const [formError, setFormError] = useState('')

  useEffect(() => {
    let cancelled = false
    let retryCount = 0
    const maxRetries = 3

    async function fetchStats() {
      try {
        setLoading(true)
        const data = await getSuperAdminStats()
        if (!cancelled) {
          setStats(data)
          setError(null)
          setLoading(false)
        }
      } catch (err: unknown) {
        if (cancelled) return // Ignore errors from cancelled requests

        // Handle AbortError silently (happens in React StrictMode)
        const isAbortError =
          (err instanceof Error && err.name === 'AbortError') ||
          (err instanceof DOMException && err.name === 'AbortError') ||
          (typeof err === 'object' && err !== null && 'name' in err && (err as {name: string}).name === 'AbortError') ||
          (typeof err === 'object' && err !== null && 'message' in err && String((err as {message: unknown}).message).includes('aborted'))

        if (isAbortError && retryCount < maxRetries) {
          console.log(`Request was aborted, retrying... (attempt ${retryCount + 1}/${maxRetries})`)
          retryCount++
          setTimeout(() => {
            if (!cancelled) fetchStats()
          }, 100 * retryCount) // Exponential backoff
          return
        }

        let errorMessage = 'Unknown error'
        if (err instanceof Error) {
          errorMessage = err.message
        } else if (err && typeof err === 'object' && 'message' in err) {
          errorMessage = String((err as { message: unknown }).message)
        }
        console.error('Error loading admin stats:', errorMessage)
        if (!cancelled) {
          setError(`Failed to load dashboard data: ${errorMessage}`)
          setLoading(false)
        }
      }
    }

    fetchStats()

    return () => {
      cancelled = true
    }
  }, [])

  async function loadStats() {
    try {
      setLoading(true)
      setError(null)
      const data = await getSuperAdminStats()
      setStats(data)
    } catch (err: unknown) {
      // Handle AbortError silently
      const isAbortError =
        (err instanceof Error && err.name === 'AbortError') ||
        (err instanceof DOMException && err.name === 'AbortError') ||
        (typeof err === 'object' && err !== null && 'name' in err && (err as {name: string}).name === 'AbortError') ||
        (typeof err === 'object' && err !== null && 'message' in err && String((err as {message: unknown}).message).includes('aborted'))

      if (isAbortError) {
        console.log('Request was aborted, retrying...')
        // Retry after a short delay
        setTimeout(() => loadStats(), 100)
        return
      }

      let errorMessage = 'Unknown error'
      if (err instanceof Error) {
        errorMessage = err.message
      } else if (err && typeof err === 'object' && 'message' in err) {
        errorMessage = String((err as { message: unknown }).message)
      }
      console.error('Error loading admin stats:', errorMessage)
      setError(`Failed to load dashboard data: ${errorMessage}`)
    } finally {
      setLoading(false)
    }
  }

  async function handleCreateDistrict(e: React.FormEvent) {
    e.preventDefault()
    setFormLoading(true)
    setFormError('')
    try {
      await createDistrict({
        name: districtName,
        code: districtCode.toUpperCase(),
        city: districtCity,
        state: districtState,
        admin_ids: [],
      })
      setShowAddDistrict(false)
      setDistrictName('')
      setDistrictCode('')
      setDistrictCity('')
      setDistrictState('')
      loadStats()
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Failed to create district')
    } finally {
      setFormLoading(false)
    }
  }

  async function handleCreateSchool(e: React.FormEvent) {
    e.preventDefault()
    if (!selectedDistrictId) {
      setFormError('Please select a district')
      return
    }
    setFormLoading(true)
    setFormError('')
    try {
      await createSchool({
        name: schoolName,
        code: schoolCode.toUpperCase(),
        city: schoolCity,
        state: schoolState,
        district_id: selectedDistrictId,
        admin_ids: [],
        grade_levels: [],
      })
      setShowAddSchool(false)
      setSchoolName('')
      setSchoolCode('')
      setSchoolCity('')
      setSchoolState('')
      setSelectedDistrictId('')
      loadStats()
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Failed to create school')
    } finally {
      setFormLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <p className="text-red-600 mb-4">{error}</p>
        <Button onClick={loadStats}>Retry</Button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Super Admin Dashboard</h1>
          <p className="text-gray-600 mt-1">Overview of all districts, schools, and activity</p>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" onClick={() => setShowReports(true)}>
            <BarChart3 className="w-4 h-4 mr-2" />
            Reports
          </Button>
          <Button onClick={() => setShowAddDistrict(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Add District
          </Button>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <StatCard
          title="Districts"
          value={stats?.districts.length || 0}
          icon={Building2}
          color="bg-purple-500"
        />
        <StatCard
          title="Schools"
          value={stats?.totalSchools || 0}
          icon={School}
          color="bg-blue-500"
        />
        <StatCard
          title="Classrooms"
          value={stats?.totalClassrooms || 0}
          icon={BookOpen}
          color="bg-green-500"
        />
        <StatCard
          title="Teachers"
          value={stats?.totalTeachers || 0}
          icon={GraduationCap}
          color="bg-orange-500"
        />
        <StatCard
          title="Students"
          value={stats?.totalStudents || 0}
          icon={Users}
          color="bg-pink-500"
        />
        <StatCard
          title="Parents"
          value={stats?.totalParents || 0}
          icon={UserCheck}
          color="bg-teal-500"
        />
      </div>

      {/* Districts List */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Building2 className="w-5 h-5 text-purple-600" />
            Districts
          </CardTitle>
          <Button size="sm" variant="outline" onClick={() => setShowAddDistrict(true)}>
            <Plus className="w-4 h-4 mr-1" />
            New District
          </Button>
        </CardHeader>
        <CardContent>
          {stats?.districts && stats.districts.length > 0 ? (
            <div className="divide-y">
              {stats.districts.map((district) => (
                <Link
                  key={district.id}
                  href={`/admin/district/${district.id}`}
                  className="flex items-center justify-between py-4 hover:bg-gray-50 -mx-4 px-4 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-lg bg-purple-100 flex items-center justify-center">
                      <Building2 className="w-6 h-6 text-purple-600" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">{district.name}</h3>
                      <p className="text-sm text-gray-500">
                        {district.city}{district.state ? `, ${district.state}` : ''} &middot; Code: {district.code}
                      </p>
                    </div>
                  </div>
                  <ChevronRight className="w-5 h-5 text-gray-400" />
                </Link>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <Building2 className="w-12 h-12 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500 mb-4">No districts yet</p>
              <Button onClick={() => setShowAddDistrict(true)}>
                <Plus className="w-4 h-4 mr-2" />
                Create First District
              </Button>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Two Column Layout for Activity */}
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
            {stats?.recentStories && stats.recentStories.length > 0 ? (
              <div className="space-y-4">
                {stats.recentStories.slice(0, 5).map((story) => (
                  <div key={story.id} className="flex items-start gap-3">
                    <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
                      <BookOpen className="w-5 h-5 text-green-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-gray-900 truncate">
                        {story.author_name}
                      </p>
                      <p className="text-sm text-gray-500 truncate">
                        {story.content || 'Shared a photo'}
                      </p>
                      <p className="text-xs text-gray-400 mt-1">
                        {timeAgo(story.created_at)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 text-center py-4">No recent stories</p>
            )}
          </CardContent>
        </Card>

        {/* Recent Points Activity */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Star className="w-5 h-5 text-yellow-600" />
              Recent Points Activity
            </CardTitle>
          </CardHeader>
          <CardContent>
            {stats?.recentActivity && stats.recentActivity.length > 0 ? (
              <div className="space-y-4">
                {stats.recentActivity.slice(0, 5).map((record) => (
                  <div key={record.id} className="flex items-start gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                      record.points > 0 ? 'bg-green-100' : 'bg-red-100'
                    }`}>
                      <Star className={`w-5 h-5 ${
                        record.points > 0 ? 'text-green-600' : 'text-red-600'
                      }`} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-gray-900">
                        {record.behavior_name}
                      </p>
                      <p className="text-sm text-gray-500">
                        {record.points > 0 ? '+' : ''}{record.points} points by {record.awarded_by_name}
                      </p>
                      <p className="text-xs text-gray-400 mt-1">
                        {timeAgo(record.created_at)}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-500 text-center py-4">No recent activity</p>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="w-5 h-5 text-blue-600" />
            Quick Actions
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <QuickActionButton
              icon={Building2}
              label="Add District"
              color="bg-purple-100 text-purple-600"
              onClick={() => setShowAddDistrict(true)}
            />
            <QuickActionButton
              icon={School}
              label="Add School"
              color="bg-blue-100 text-blue-600"
              onClick={() => setShowAddSchool(true)}
            />
            <QuickActionButton
              icon={GraduationCap}
              label="Manage Teachers"
              color="bg-orange-100 text-orange-600"
              href="/classroom"
            />
            <QuickActionButton
              icon={BarChart3}
              label="View Reports"
              color="bg-green-100 text-green-600"
              onClick={() => setShowReports(true)}
            />
          </div>
        </CardContent>
      </Card>

      {/* Add District Modal */}
      {showAddDistrict && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-gray-900">Add New District</h2>
              <button onClick={() => setShowAddDistrict(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleCreateDistrict} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">District Name *</label>
                <Input
                  value={districtName}
                  onChange={(e) => setDistrictName(e.target.value)}
                  placeholder="e.g., Springfield Unified School District"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">District Code *</label>
                <Input
                  value={districtCode}
                  onChange={(e) => setDistrictCode(e.target.value)}
                  placeholder="e.g., SPRINGFIELD-USD"
                  required
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
                  <Input
                    value={districtCity}
                    onChange={(e) => setDistrictCity(e.target.value)}
                    placeholder="e.g., Springfield"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">State</label>
                  <Input
                    value={districtState}
                    onChange={(e) => setDistrictState(e.target.value)}
                    placeholder="e.g., IL"
                    maxLength={2}
                  />
                </div>
              </div>
              {formError && <p className="text-red-600 text-sm">{formError}</p>}
              <div className="flex gap-3 pt-2">
                <Button type="button" variant="outline" className="flex-1" onClick={() => setShowAddDistrict(false)}>
                  Cancel
                </Button>
                <Button type="submit" className="flex-1" disabled={formLoading}>
                  {formLoading ? 'Creating...' : 'Create District'}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add School Modal */}
      {showAddSchool && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-bold text-gray-900">Add New School</h2>
              <button onClick={() => setShowAddSchool(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleCreateSchool} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">District *</label>
                <select
                  value={selectedDistrictId}
                  onChange={(e) => setSelectedDistrictId(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Select a district...</option>
                  {stats?.districts.map((district) => (
                    <option key={district.id} value={district.id}>{district.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">School Name *</label>
                <Input
                  value={schoolName}
                  onChange={(e) => setSchoolName(e.target.value)}
                  placeholder="e.g., Springfield Elementary"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">School Code *</label>
                <Input
                  value={schoolCode}
                  onChange={(e) => setSchoolCode(e.target.value)}
                  placeholder="e.g., ELEM-01"
                  required
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">City</label>
                  <Input
                    value={schoolCity}
                    onChange={(e) => setSchoolCity(e.target.value)}
                    placeholder="e.g., Springfield"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">State</label>
                  <Input
                    value={schoolState}
                    onChange={(e) => setSchoolState(e.target.value)}
                    placeholder="e.g., IL"
                    maxLength={2}
                  />
                </div>
              </div>
              {formError && <p className="text-red-600 text-sm">{formError}</p>}
              <div className="flex gap-3 pt-2">
                <Button type="button" variant="outline" className="flex-1" onClick={() => setShowAddSchool(false)}>
                  Cancel
                </Button>
                <Button type="submit" className="flex-1" disabled={formLoading}>
                  {formLoading ? 'Creating...' : 'Create School'}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Reports Modal */}
      {showReports && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl p-6 w-full max-w-2xl mx-4 max-h-[80vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold text-gray-900">System Reports</h2>
              <button onClick={() => setShowReports(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-6">
              <div className="grid grid-cols-2 gap-4">
                <div className="p-4 bg-purple-50 rounded-lg">
                  <p className="text-2xl font-bold text-purple-700">{stats?.districts.length || 0}</p>
                  <p className="text-sm text-purple-600">Total Districts</p>
                </div>
                <div className="p-4 bg-blue-50 rounded-lg">
                  <p className="text-2xl font-bold text-blue-700">{stats?.totalSchools || 0}</p>
                  <p className="text-sm text-blue-600">Total Schools</p>
                </div>
                <div className="p-4 bg-green-50 rounded-lg">
                  <p className="text-2xl font-bold text-green-700">{stats?.totalClassrooms || 0}</p>
                  <p className="text-sm text-green-600">Total Classrooms</p>
                </div>
                <div className="p-4 bg-orange-50 rounded-lg">
                  <p className="text-2xl font-bold text-orange-700">{stats?.totalTeachers || 0}</p>
                  <p className="text-sm text-orange-600">Total Teachers</p>
                </div>
                <div className="p-4 bg-pink-50 rounded-lg">
                  <p className="text-2xl font-bold text-pink-700">{stats?.totalStudents || 0}</p>
                  <p className="text-sm text-pink-600">Total Students</p>
                </div>
                <div className="p-4 bg-teal-50 rounded-lg">
                  <p className="text-2xl font-bold text-teal-700">{stats?.totalParents || 0}</p>
                  <p className="text-sm text-teal-600">Total Parents</p>
                </div>
              </div>
              <div>
                <h3 className="font-semibold text-gray-900 mb-3">Districts Overview</h3>
                <div className="space-y-2">
                  {stats?.districts.map((district) => (
                    <div key={district.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div>
                        <p className="font-medium text-gray-900">{district.name}</p>
                        <p className="text-sm text-gray-500">{district.city}, {district.state}</p>
                      </div>
                      <Link href={`/admin/district/${district.id}`}>
                        <Button variant="outline" size="sm">View Details</Button>
                      </Link>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            <div className="mt-6 pt-4 border-t">
              <Button variant="outline" className="w-full" onClick={() => setShowReports(false)}>
                Close
              </Button>
            </div>
          </div>
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
      <CardContent className="pt-6">
        <div className="flex items-center gap-3">
          <div className={`w-10 h-10 rounded-lg ${color} flex items-center justify-center`}>
            <Icon className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="text-2xl font-bold text-gray-900">{value.toLocaleString()}</p>
            <p className="text-sm text-gray-500">{title}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

function QuickActionButton({
  icon: Icon,
  label,
  color,
  onClick,
  href
}: {
  icon: React.ElementType
  label: string
  color: string
  onClick?: () => void
  href?: string
}) {
  const content = (
    <>
      <div className={`w-12 h-12 rounded-full ${color} flex items-center justify-center`}>
        <Icon className="w-6 h-6" />
      </div>
      <span className="text-sm font-medium text-gray-700">{label}</span>
    </>
  )

  if (href) {
    return (
      <Link
        href={href}
        className="flex flex-col items-center gap-2 p-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
      >
        {content}
      </Link>
    )
  }

  return (
    <button
      onClick={onClick}
      className="flex flex-col items-center gap-2 p-4 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
    >
      {content}
    </button>
  )
}
