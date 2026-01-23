'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/auth-context'
import { useClassroom } from '@/contexts/classroom-context'
import { classroomService } from '@/services/classroom'
import { authService } from '@/services/auth'
import { Header } from '@/components/layout/header'
import { Card, CardContent, CardHeader, CardTitle, Button, Input, Avatar } from '@/components/ui'
import { cn } from '@/lib/utils'
import { User, Mail, Lock, LogOut, Users, Plus, Trash2 } from 'lucide-react'

export default function SettingsPage() {
  const router = useRouter()
  const { user, signOut, refreshUser } = useAuth()
  const { classrooms, refreshClassrooms } = useClassroom()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  // Profile form
  const [name, setName] = useState(user?.name || '')

  // Join class form (for parents)
  const [classCode, setClassCode] = useState('')
  const [joiningClass, setJoiningClass] = useState(false)

  const isTeacher = user?.role === 'teacher'

  const userInitials = user?.name
    ?.split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2) || '?'

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return

    setLoading(true)
    setError('')
    setSuccess('')

    try {
      await authService.updateUser({ id: user.id, name })
      await refreshUser()
      setSuccess('Profile updated successfully')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update profile')
    } finally {
      setLoading(false)
    }
  }

  const handleJoinClass = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user || !classCode.trim()) return

    setJoiningClass(true)
    setError('')
    setSuccess('')

    try {
      await classroomService.joinClassWithCode(classCode.trim().toUpperCase(), user.id)
      await refreshClassrooms()
      setClassCode('')
      setSuccess('Successfully joined the classroom!')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to join classroom')
    } finally {
      setJoiningClass(false)
    }
  }

  const handleSignOut = async () => {
    await signOut()
    router.push('/login')
  }

  return (
    <>
      <Header title="Settings" />
      <main className="flex-1 p-6 overflow-y-auto">
        <div className="max-w-2xl mx-auto space-y-6">
          {/* Error/Success Messages */}
          {error && (
            <div className="p-3 rounded-lg bg-red-50 text-red-600 text-sm">
              {error}
            </div>
          )}
          {success && (
            <div className="p-3 rounded-lg bg-green-50 text-green-600 text-sm">
              {success}
            </div>
          )}

          {/* Profile Card */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Profile</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center gap-4 mb-6">
                <Avatar initials={userInitials} size="xl" />
                <div>
                  <p className="font-semibold text-gray-900">{user?.name}</p>
                  <p className="text-sm text-gray-500">{user?.email}</p>
                  <p className="text-sm text-gray-500 capitalize">{user?.role}</p>
                </div>
              </div>

              <form onSubmit={handleUpdateProfile} className="space-y-4">
                <Input
                  label="Display Name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Your name"
                />
                <Button type="submit" loading={loading}>
                  Update Profile
                </Button>
              </form>
            </CardContent>
          </Card>

          {/* Join Classroom (Parents only) */}
          {!isTeacher && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Join a Classroom</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-gray-500 mb-4">
                  Enter the class code provided by your child&apos;s teacher to connect with their classroom.
                </p>
                <form onSubmit={handleJoinClass} className="flex gap-3">
                  <Input
                    placeholder="Enter class code (e.g., ABC123)"
                    value={classCode}
                    onChange={(e) => setClassCode(e.target.value.toUpperCase())}
                    className="flex-1 uppercase"
                    maxLength={6}
                  />
                  <Button type="submit" loading={joiningClass}>
                    <Plus className="h-4 w-4 mr-2" />
                    Join
                  </Button>
                </form>
              </CardContent>
            </Card>
          )}

          {/* My Classrooms */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">
                {isTeacher ? 'My Classrooms' : 'Connected Classrooms'}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {classrooms.length === 0 ? (
                <p className="text-sm text-gray-500 text-center py-4">
                  {isTeacher
                    ? 'You haven\'t created any classrooms yet'
                    : 'You haven\'t joined any classrooms yet'}
                </p>
              ) : (
                <div className="space-y-3">
                  {classrooms.map((classroom) => (
                    <div
                      key={classroom.id}
                      className="flex items-center gap-3 p-3 rounded-lg bg-gray-50"
                    >
                      <div className="h-10 w-10 rounded-lg bg-blue-100 flex items-center justify-center">
                        <Users className="h-5 w-5 text-blue-600" />
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-gray-900">{classroom.name}</p>
                        {classroom.grade_level && (
                          <p className="text-sm text-gray-500">{classroom.grade_level}</p>
                        )}
                      </div>
                      {isTeacher && (
                        <code className="px-2 py-1 bg-white rounded text-sm font-mono text-gray-600">
                          {classroom.class_code}
                        </code>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* Account Actions */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Account</CardTitle>
            </CardHeader>
            <CardContent>
              <Button
                variant="outline"
                className="w-full text-red-600 hover:bg-red-50 hover:border-red-300"
                onClick={handleSignOut}
              >
                <LogOut className="h-4 w-4 mr-2" />
                Sign Out
              </Button>
            </CardContent>
          </Card>
        </div>
      </main>
    </>
  )
}
