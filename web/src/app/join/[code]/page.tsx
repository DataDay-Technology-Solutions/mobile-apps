'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/auth-context'
import { classroomService } from '@/services/classroom'
import { Card, CardContent, CardHeader, CardTitle, Button } from '@/components/ui'
import { GraduationCap, Users, Check, AlertCircle } from 'lucide-react'
import Link from 'next/link'
import type { Classroom } from '@/types'

export default function JoinClassPage() {
  const params = useParams()
  const router = useRouter()
  const { user, loading: authLoading } = useAuth()
  const [classroom, setClassroom] = useState<Classroom | null>(null)
  const [loading, setLoading] = useState(true)
  const [joining, setJoining] = useState(false)
  const [error, setError] = useState('')
  const [joined, setJoined] = useState(false)

  const code = (params.code as string)?.toUpperCase()

  useEffect(() => {
    const fetchClassroom = async () => {
      if (!code) return

      setLoading(true)
      try {
        const fetchedClassroom = await classroomService.getClassroomByCode(code)
        setClassroom(fetchedClassroom)

        // Check if user is already a member
        if (user && fetchedClassroom?.parent_ids.includes(user.id)) {
          setJoined(true)
        }
      } catch (err) {
        setError('Failed to find classroom')
      } finally {
        setLoading(false)
      }
    }

    fetchClassroom()
  }, [code, user])

  const handleJoin = async () => {
    if (!user || !classroom) return

    // Parents only
    if (user.role !== 'parent') {
      setError('Only parents can join classrooms via invite link')
      return
    }

    setJoining(true)
    setError('')

    try {
      await classroomService.joinClassWithCode(code, user.id)
      setJoined(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to join classroom')
    } finally {
      setJoining(false)
    }
  }

  // Show loading state
  if (loading || authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
        <Card className="w-full max-w-md text-center">
          <CardContent className="py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto" />
            <p className="mt-4 text-gray-500">Loading...</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  // Classroom not found
  if (!classroom) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
        <Card className="w-full max-w-md text-center">
          <CardContent className="py-12">
            <div className="mx-auto h-16 w-16 rounded-full bg-red-100 flex items-center justify-center mb-6">
              <AlertCircle className="h-8 w-8 text-red-600" />
            </div>
            <h2 className="text-xl font-semibold text-gray-900 mb-2">
              Classroom Not Found
            </h2>
            <p className="text-gray-500 mb-6">
              The class code &quot;{code}&quot; doesn&apos;t match any classroom. Please check the code and try again.
            </p>
            <Link href="/login">
              <Button variant="outline">Go to Login</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    )
  }

  // Successfully joined
  if (joined) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-50 to-emerald-100 p-4">
        <Card className="w-full max-w-md text-center">
          <CardContent className="py-12">
            <div className="mx-auto h-16 w-16 rounded-full bg-green-100 flex items-center justify-center mb-6">
              <Check className="h-8 w-8 text-green-600" />
            </div>
            <h2 className="text-xl font-semibold text-gray-900 mb-2">
              Welcome to {classroom.name}!
            </h2>
            <p className="text-gray-500 mb-6">
              You&apos;re now connected with {classroom.teacher_name || 'the teacher'}&apos;s classroom.
            </p>
            <Link href="/dashboard">
              <Button>Go to Dashboard</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    )
  }

  // Not logged in
  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
        <Card className="w-full max-w-md">
          <CardHeader className="text-center">
            <div className="mx-auto mb-4 h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
              <GraduationCap className="h-6 w-6 text-blue-600" />
            </div>
            <CardTitle className="text-2xl">Join Classroom</CardTitle>
          </CardHeader>
          <CardContent className="text-center">
            <div className="p-4 rounded-lg bg-gray-50 mb-6">
              <div className="flex items-center justify-center gap-3 mb-2">
                <Users className="h-5 w-5 text-blue-600" />
                <span className="font-semibold text-gray-900">{classroom.name}</span>
              </div>
              {classroom.grade_level && (
                <p className="text-sm text-gray-500">{classroom.grade_level}</p>
              )}
              {classroom.teacher_name && (
                <p className="text-sm text-gray-500">Teacher: {classroom.teacher_name}</p>
              )}
            </div>

            <p className="text-gray-500 mb-6">
              Sign in or create an account to join this classroom.
            </p>

            <div className="space-y-3">
              <Link href={`/login?redirect=/join/${code}`} className="block">
                <Button className="w-full">Sign In</Button>
              </Link>
              <Link href={`/signup?redirect=/join/${code}`} className="block">
                <Button variant="outline" className="w-full">Create Account</Button>
              </Link>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  // User is logged in but not a parent
  if (user.role !== 'parent') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
        <Card className="w-full max-w-md text-center">
          <CardContent className="py-12">
            <div className="mx-auto h-16 w-16 rounded-full bg-yellow-100 flex items-center justify-center mb-6">
              <AlertCircle className="h-8 w-8 text-yellow-600" />
            </div>
            <h2 className="text-xl font-semibold text-gray-900 mb-2">
              Teachers Can&apos;t Join Classes
            </h2>
            <p className="text-gray-500 mb-6">
              This invite link is for parents. Teachers can create their own classrooms.
            </p>
            <Link href="/dashboard">
              <Button variant="outline">Go to Dashboard</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    )
  }

  // Ready to join
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="mx-auto mb-4 h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
            <GraduationCap className="h-6 w-6 text-blue-600" />
          </div>
          <CardTitle className="text-2xl">Join Classroom</CardTitle>
        </CardHeader>
        <CardContent className="text-center">
          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-50 text-red-600 text-sm">
              {error}
            </div>
          )}

          <div className="p-4 rounded-lg bg-gray-50 mb-6">
            <div className="flex items-center justify-center gap-3 mb-2">
              <Users className="h-5 w-5 text-blue-600" />
              <span className="font-semibold text-gray-900">{classroom.name}</span>
            </div>
            {classroom.grade_level && (
              <p className="text-sm text-gray-500">{classroom.grade_level}</p>
            )}
            {classroom.teacher_name && (
              <p className="text-sm text-gray-500">Teacher: {classroom.teacher_name}</p>
            )}
          </div>

          <p className="text-gray-500 mb-6">
            Hi {user.name}! Would you like to join this classroom?
          </p>

          <Button onClick={handleJoin} loading={joining} className="w-full">
            Join Classroom
          </Button>

          <Link href="/dashboard" className="block mt-4">
            <Button variant="ghost" className="w-full">Cancel</Button>
          </Link>
        </CardContent>
      </Card>
    </div>
  )
}
