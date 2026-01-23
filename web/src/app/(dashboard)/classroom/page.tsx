'use client'

import { useState } from 'react'
import { useAuth } from '@/contexts/auth-context'
import { useClassroom } from '@/contexts/classroom-context'
import { classroomService } from '@/services/classroom'
import { Header } from '@/components/layout/header'
import { Card, CardContent, CardHeader, CardTitle, Button, Input, Avatar } from '@/components/ui'
import { cn } from '@/lib/utils'
import {
  Plus,
  Users,
  QrCode,
  Copy,
  Check,
  Trash2,
  Edit2,
  X,
  UserPlus,
} from 'lucide-react'
import type { Student, Classroom } from '@/types'
import { getStudentFullName, getStudentInitials } from '@/types'
import QRCode from 'qrcode'
import { useEffect } from 'react'

export default function ClassroomPage() {
  const { user } = useAuth()
  const { classrooms, selectedClassroom, students, refreshClassrooms, refreshStudents, selectClassroom } = useClassroom()
  const [showCreateClass, setShowCreateClass] = useState(false)
  const [showAddStudent, setShowAddStudent] = useState(false)
  const [showQRCode, setShowQRCode] = useState(false)
  const [qrCodeUrl, setQrCodeUrl] = useState('')
  const [copied, setCopied] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // New class form
  const [className, setClassName] = useState('')
  const [gradeLevel, setGradeLevel] = useState('')

  // New student form
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')

  // Edit student
  const [editingStudent, setEditingStudent] = useState<Student | null>(null)
  const [editFirstName, setEditFirstName] = useState('')
  const [editLastName, setEditLastName] = useState('')

  const isTeacher = user?.role === 'teacher'

  // Generate QR code when showing
  useEffect(() => {
    if (showQRCode && selectedClassroom) {
      const joinUrl = `${window.location.origin}/join/${selectedClassroom.class_code}`
      QRCode.toDataURL(joinUrl, { width: 256, margin: 2 })
        .then(url => setQrCodeUrl(url))
        .catch(err => console.error('Failed to generate QR code:', err))
    }
  }, [showQRCode, selectedClassroom])

  const handleCreateClass = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return

    setLoading(true)
    setError('')

    try {
      const newClassroom = await classroomService.createClassroom({
        name: className,
        grade_level: gradeLevel || undefined,
        teacher_id: user.id,
        teacher_name: user.name,
      })
      await refreshClassrooms()
      selectClassroom(newClassroom)
      setShowCreateClass(false)
      setClassName('')
      setGradeLevel('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create classroom')
    } finally {
      setLoading(false)
    }
  }

  const handleAddStudent = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedClassroom) return

    setLoading(true)
    setError('')

    try {
      await classroomService.addStudent({
        first_name: firstName,
        last_name: lastName,
        class_id: selectedClassroom.id,
        parent_ids: [],
      })
      await refreshStudents()
      setShowAddStudent(false)
      setFirstName('')
      setLastName('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add student')
    } finally {
      setLoading(false)
    }
  }

  const handleUpdateStudent = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editingStudent) return

    setLoading(true)
    setError('')

    try {
      await classroomService.updateStudent({
        id: editingStudent.id,
        first_name: editFirstName,
        last_name: editLastName,
      })
      await refreshStudents()
      setEditingStudent(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update student')
    } finally {
      setLoading(false)
    }
  }

  const handleDeleteStudent = async (student: Student) => {
    if (!confirm(`Are you sure you want to remove ${getStudentFullName(student)}?`)) return

    try {
      await classroomService.deleteStudent(student.id)
      await refreshStudents()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete student')
    }
  }

  const handleCopyCode = () => {
    if (selectedClassroom) {
      navigator.clipboard.writeText(selectedClassroom.class_code)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  const handleCopyLink = () => {
    if (selectedClassroom) {
      const joinUrl = `${window.location.origin}/join/${selectedClassroom.class_code}`
      navigator.clipboard.writeText(joinUrl)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  const startEditStudent = (student: Student) => {
    setEditingStudent(student)
    setEditFirstName(student.first_name)
    setEditLastName(student.last_name)
  }

  if (!isTeacher) {
    return (
      <>
        <Header title="Classroom" />
        <main className="flex-1 p-6">
          <Card>
            <CardContent className="py-12 text-center">
              <p className="text-gray-500">Classroom management is only available for teachers.</p>
            </CardContent>
          </Card>
        </main>
      </>
    )
  }

  return (
    <>
      <Header title="Classroom" />
      <main className="flex-1 p-6 overflow-y-auto">
        {/* Error display */}
        {error && (
          <div className="mb-4 p-3 rounded-lg bg-red-50 text-red-600 text-sm">
            {error}
            <button onClick={() => setError('')} className="ml-2 font-medium">Dismiss</button>
          </div>
        )}

        <div className="grid lg:grid-cols-3 gap-6">
          {/* Class Info & Actions */}
          <div className="lg:col-span-1 space-y-4">
            {/* Create Class Button */}
            {classrooms.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <div className="mx-auto h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center mb-4">
                    <Users className="h-6 w-6 text-blue-600" />
                  </div>
                  <h3 className="font-semibold text-gray-900 mb-2">No Classrooms Yet</h3>
                  <p className="text-sm text-gray-500 mb-4">Create your first classroom to get started</p>
                  <Button onClick={() => setShowCreateClass(true)}>
                    <Plus className="h-4 w-4 mr-2" />
                    Create Classroom
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <>
                {/* Selected Class Info */}
                {selectedClassroom && (
                  <Card>
                    <CardHeader>
                      <CardTitle className="text-base">Class Info</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                      <div>
                        <p className="text-sm text-gray-500">Class Name</p>
                        <p className="font-medium text-gray-900">{selectedClassroom.name}</p>
                      </div>
                      {selectedClassroom.grade_level && (
                        <div>
                          <p className="text-sm text-gray-500">Grade Level</p>
                          <p className="font-medium text-gray-900">{selectedClassroom.grade_level}</p>
                        </div>
                      )}
                      <div>
                        <p className="text-sm text-gray-500">Class Code</p>
                        <div className="flex items-center gap-2">
                          <code className="px-2 py-1 bg-gray-100 rounded text-lg font-mono">
                            {selectedClassroom.class_code}
                          </code>
                          <button
                            onClick={handleCopyCode}
                            className="p-2 rounded-lg hover:bg-gray-100 transition-colors"
                          >
                            {copied ? (
                              <Check className="h-4 w-4 text-green-500" />
                            ) : (
                              <Copy className="h-4 w-4 text-gray-400" />
                            )}
                          </button>
                        </div>
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 mb-2">Share</p>
                        <div className="flex gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setShowQRCode(true)}
                          >
                            <QrCode className="h-4 w-4 mr-2" />
                            QR Code
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={handleCopyLink}
                          >
                            <Copy className="h-4 w-4 mr-2" />
                            Copy Link
                          </Button>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                )}

                {/* Create Another Class */}
                <Button
                  variant="outline"
                  className="w-full"
                  onClick={() => setShowCreateClass(true)}
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Create Another Class
                </Button>
              </>
            )}
          </div>

          {/* Students List */}
          <div className="lg:col-span-2">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle className="text-base">
                  Students ({students.length})
                </CardTitle>
                {selectedClassroom && (
                  <Button size="sm" onClick={() => setShowAddStudent(true)}>
                    <UserPlus className="h-4 w-4 mr-2" />
                    Add Student
                  </Button>
                )}
              </CardHeader>
              <CardContent>
                {!selectedClassroom ? (
                  <p className="text-sm text-gray-500 text-center py-6">
                    Select or create a classroom to view students
                  </p>
                ) : students.length === 0 ? (
                  <div className="text-center py-8">
                    <div className="mx-auto h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center mb-4">
                      <Users className="h-6 w-6 text-gray-400" />
                    </div>
                    <p className="text-gray-500 mb-4">No students yet</p>
                    <Button size="sm" onClick={() => setShowAddStudent(true)}>
                      <UserPlus className="h-4 w-4 mr-2" />
                      Add First Student
                    </Button>
                  </div>
                ) : (
                  <div className="grid sm:grid-cols-2 gap-3">
                    {students.map((student) => (
                      <div
                        key={student.id}
                        className="flex items-center gap-3 p-3 rounded-lg border border-gray-200 hover:border-gray-300 transition-colors"
                      >
                        <Avatar initials={getStudentInitials(student)} size="md" />
                        <div className="flex-1 min-w-0">
                          <p className="font-medium text-gray-900 truncate">
                            {getStudentFullName(student)}
                          </p>
                          <p className="text-sm text-gray-500">
                            {student.parent_ids.length} parent{student.parent_ids.length !== 1 ? 's' : ''} connected
                          </p>
                        </div>
                        <div className="flex gap-1">
                          <button
                            onClick={() => startEditStudent(student)}
                            className="p-2 rounded-lg hover:bg-gray-100 text-gray-400 hover:text-gray-600 transition-colors"
                          >
                            <Edit2 className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => handleDeleteStudent(student)}
                            className="p-2 rounded-lg hover:bg-red-50 text-gray-400 hover:text-red-600 transition-colors"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Create Class Modal */}
        {showCreateClass && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-md mx-4">
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle>Create Classroom</CardTitle>
                <button
                  onClick={() => setShowCreateClass(false)}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <form onSubmit={handleCreateClass}>
                <CardContent className="space-y-4">
                  <Input
                    label="Class Name"
                    placeholder="e.g., Mrs. Smith's Class"
                    value={className}
                    onChange={(e) => setClassName(e.target.value)}
                    required
                  />
                  <Input
                    label="Grade Level (optional)"
                    placeholder="e.g., 3rd Grade"
                    value={gradeLevel}
                    onChange={(e) => setGradeLevel(e.target.value)}
                  />
                </CardContent>
                <div className="px-6 py-4 border-t border-gray-100 flex justify-end gap-3">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setShowCreateClass(false)}
                  >
                    Cancel
                  </Button>
                  <Button type="submit" loading={loading}>
                    Create Class
                  </Button>
                </div>
              </form>
            </Card>
          </div>
        )}

        {/* Add Student Modal */}
        {showAddStudent && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-md mx-4">
              <CardHeader className="flex flex-row items-center justify-between">
                <div>
                  <CardTitle>Add Student</CardTitle>
                  <p className="text-sm text-gray-500 mt-1">
                    to {selectedClassroom?.name}
                  </p>
                </div>
                <button
                  onClick={() => setShowAddStudent(false)}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <form onSubmit={handleAddStudent}>
                <CardContent className="space-y-4">
                  <Input
                    label="First Name"
                    placeholder="Student's first name"
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    required
                  />
                  <Input
                    label="Last Name"
                    placeholder="Student's last name"
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    required
                  />
                </CardContent>
                <div className="px-6 py-4 border-t border-gray-100 flex justify-end gap-3">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setShowAddStudent(false)}
                  >
                    Cancel
                  </Button>
                  <Button type="submit" loading={loading}>
                    Add Student
                  </Button>
                </div>
              </form>
            </Card>
          </div>
        )}

        {/* Edit Student Modal */}
        {editingStudent && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-md mx-4">
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle>Edit Student</CardTitle>
                <button
                  onClick={() => setEditingStudent(null)}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <form onSubmit={handleUpdateStudent}>
                <CardContent className="space-y-4">
                  <Input
                    label="First Name"
                    value={editFirstName}
                    onChange={(e) => setEditFirstName(e.target.value)}
                    required
                  />
                  <Input
                    label="Last Name"
                    value={editLastName}
                    onChange={(e) => setEditLastName(e.target.value)}
                    required
                  />
                </CardContent>
                <div className="px-6 py-4 border-t border-gray-100 flex justify-end gap-3">
                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => setEditingStudent(null)}
                  >
                    Cancel
                  </Button>
                  <Button type="submit" loading={loading}>
                    Save Changes
                  </Button>
                </div>
              </form>
            </Card>
          </div>
        )}

        {/* QR Code Modal */}
        {showQRCode && selectedClassroom && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-sm mx-4 text-center">
              <CardHeader className="flex flex-row items-center justify-between">
                <CardTitle>Class QR Code</CardTitle>
                <button
                  onClick={() => setShowQRCode(false)}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-gray-500 mb-4">
                  Parents can scan this code to join {selectedClassroom.name}
                </p>
                {qrCodeUrl && (
                  <img
                    src={qrCodeUrl}
                    alt="Class QR Code"
                    className="mx-auto mb-4 rounded-lg"
                  />
                )}
                <code className="block px-4 py-2 bg-gray-100 rounded-lg text-lg font-mono mb-4">
                  {selectedClassroom.class_code}
                </code>
                <Button variant="outline" className="w-full" onClick={handleCopyLink}>
                  <Copy className="h-4 w-4 mr-2" />
                  Copy Invite Link
                </Button>
              </CardContent>
            </Card>
          </div>
        )}
      </main>
    </>
  )
}
