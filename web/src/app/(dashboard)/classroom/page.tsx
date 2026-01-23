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
  UserCheck,
  Link as LinkIcon,
} from 'lucide-react'
import type { Student, Classroom, AppUser } from '@/types'
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
  const [copiedStudentCode, setCopiedStudentCode] = useState<string | null>(null)
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

  // Parent management
  const [showParentManager, setShowParentManager] = useState(false)
  const [parentsWithStudents, setParentsWithStudents] = useState<Array<{ parent: AppUser; students: Student[] }>>([])
  const [unassignedParents, setUnassignedParents] = useState<AppUser[]>([])
  const [loadingParents, setLoadingParents] = useState(false)
  const [assigningParent, setAssigningParent] = useState<AppUser | null>(null)
  const [selectedStudentForAssign, setSelectedStudentForAssign] = useState<string>('')

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

  const handleCopyStudentCode = (code: string) => {
    navigator.clipboard.writeText(code)
    setCopiedStudentCode(code)
    setTimeout(() => setCopiedStudentCode(null), 2000)
  }

  // Load parents when opening parent manager
  const openParentManager = async () => {
    if (!selectedClassroom) return
    setShowParentManager(true)
    setLoadingParents(true)
    try {
      const [pwsResult, unassignedResult] = await Promise.all([
        classroomService.getParentsWithStudents(selectedClassroom.id),
        classroomService.getUnassignedParentsInClassroom(selectedClassroom.id),
      ])
      setParentsWithStudents(pwsResult)
      setUnassignedParents(unassignedResult)
    } catch (err) {
      console.error('Failed to load parents:', err)
    } finally {
      setLoadingParents(false)
    }
  }

  const handleAssignParent = async () => {
    if (!assigningParent || !selectedStudentForAssign) return
    setLoading(true)
    try {
      await classroomService.linkParentToStudent(selectedStudentForAssign, assigningParent.id)
      // Refresh data
      await refreshStudents()
      const [pwsResult, unassignedResult] = await Promise.all([
        classroomService.getParentsWithStudents(selectedClassroom!.id),
        classroomService.getUnassignedParentsInClassroom(selectedClassroom!.id),
      ])
      setParentsWithStudents(pwsResult)
      setUnassignedParents(unassignedResult)
      setAssigningParent(null)
      setSelectedStudentForAssign('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to assign parent')
    } finally {
      setLoading(false)
    }
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

                {/* Manage Parents Button */}
                {selectedClassroom && (
                  <Button
                    variant="outline"
                    className="w-full"
                    onClick={openParentManager}
                  >
                    <UserCheck className="h-4 w-4 mr-2" />
                    Manage Parents ({selectedClassroom.parent_ids.length})
                  </Button>
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
                        className="p-3 rounded-lg border border-gray-200 hover:border-gray-300 transition-colors"
                      >
                        <div className="flex items-center gap-3">
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
                        {/* Parent Invite Code */}
                        {student.invite_code && (
                          <div className="mt-2 pt-2 border-t border-gray-100">
                            <div className="flex items-center justify-between">
                              <span className="text-xs text-gray-500">Parent Code:</span>
                              <div className="flex items-center gap-1">
                                <code className="px-2 py-0.5 bg-blue-50 text-blue-700 rounded text-xs font-mono">
                                  {student.invite_code}
                                </code>
                                <button
                                  onClick={() => handleCopyStudentCode(student.invite_code)}
                                  className="p-1 rounded hover:bg-gray-100 transition-colors"
                                  title="Copy parent invite code"
                                >
                                  {copiedStudentCode === student.invite_code ? (
                                    <Check className="h-3 w-3 text-green-500" />
                                  ) : (
                                    <Copy className="h-3 w-3 text-gray-400" />
                                  )}
                                </button>
                              </div>
                            </div>
                          </div>
                        )}
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

        {/* Parent Manager Modal */}
        {showParentManager && selectedClassroom && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-2xl mx-4 max-h-[80vh] overflow-hidden flex flex-col">
              <CardHeader className="flex flex-row items-center justify-between flex-shrink-0">
                <div>
                  <CardTitle>Manage Parents</CardTitle>
                  <p className="text-sm text-gray-500 mt-1">
                    {selectedClassroom.name} - {selectedClassroom.parent_ids.length} parent{selectedClassroom.parent_ids.length !== 1 ? 's' : ''} joined
                  </p>
                </div>
                <button
                  onClick={() => setShowParentManager(false)}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <CardContent className="overflow-y-auto flex-1">
                {loadingParents ? (
                  <div className="text-center py-8 text-gray-500">Loading parents...</div>
                ) : parentsWithStudents.length === 0 && unassignedParents.length === 0 ? (
                  <div className="text-center py-8">
                    <div className="mx-auto h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center mb-4">
                      <Users className="h-6 w-6 text-gray-400" />
                    </div>
                    <p className="text-gray-500 mb-2">No parents have joined yet</p>
                    <p className="text-sm text-gray-400">
                      Share your class code or QR code with parents to invite them
                    </p>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Unassigned Parents */}
                    {unassignedParents.length > 0 && (
                      <div>
                        <h3 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                          <span className="h-2 w-2 rounded-full bg-yellow-500"></span>
                          Unassigned Parents ({unassignedParents.length})
                        </h3>
                        <p className="text-sm text-gray-500 mb-3">
                          These parents have joined but haven&apos;t been linked to a student yet.
                        </p>
                        <div className="space-y-2">
                          {unassignedParents.map((parent) => (
                            <div
                              key={parent.id}
                              className="flex items-center justify-between p-3 rounded-lg bg-yellow-50 border border-yellow-200"
                            >
                              <div className="flex items-center gap-3">
                                <div className="h-10 w-10 rounded-full bg-yellow-100 flex items-center justify-center">
                                  <span className="text-sm font-medium text-yellow-700">
                                    {parent.name.charAt(0).toUpperCase()}
                                  </span>
                                </div>
                                <div>
                                  <p className="font-medium text-gray-900">{parent.name}</p>
                                  <p className="text-sm text-gray-500">{parent.email}</p>
                                </div>
                              </div>
                              <Button
                                size="sm"
                                onClick={() => setAssigningParent(parent)}
                              >
                                <LinkIcon className="h-4 w-4 mr-2" />
                                Assign
                              </Button>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Assigned Parents */}
                    {parentsWithStudents.filter(p => p.students.length > 0).length > 0 && (
                      <div>
                        <h3 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                          <span className="h-2 w-2 rounded-full bg-green-500"></span>
                          Assigned Parents ({parentsWithStudents.filter(p => p.students.length > 0).length})
                        </h3>
                        <div className="space-y-2">
                          {parentsWithStudents
                            .filter(p => p.students.length > 0)
                            .map(({ parent, students: linkedStudents }) => (
                              <div
                                key={parent.id}
                                className="flex items-center justify-between p-3 rounded-lg bg-green-50 border border-green-200"
                              >
                                <div className="flex items-center gap-3">
                                  <div className="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center">
                                    <span className="text-sm font-medium text-green-700">
                                      {parent.name.charAt(0).toUpperCase()}
                                    </span>
                                  </div>
                                  <div>
                                    <p className="font-medium text-gray-900">{parent.name}</p>
                                    <p className="text-sm text-gray-500">{parent.email}</p>
                                  </div>
                                </div>
                                <div className="flex items-center gap-2">
                                  {linkedStudents.map((s) => (
                                    <span
                                      key={s.id}
                                      className="px-2 py-1 rounded-full bg-white text-xs font-medium text-green-700 border border-green-200"
                                    >
                                      {getStudentFullName(s)}
                                    </span>
                                  ))}
                                  <Button
                                    size="sm"
                                    variant="outline"
                                    onClick={() => setAssigningParent(parent)}
                                  >
                                    <Plus className="h-4 w-4" />
                                  </Button>
                                </div>
                              </div>
                            ))}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        )}

        {/* Assign Parent to Student Modal */}
        {assigningParent && (
          <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/50">
            <Card className="w-full max-w-md mx-4">
              <CardHeader className="flex flex-row items-center justify-between">
                <div>
                  <CardTitle>Assign Parent to Student</CardTitle>
                  <p className="text-sm text-gray-500 mt-1">
                    Linking {assigningParent.name}
                  </p>
                </div>
                <button
                  onClick={() => {
                    setAssigningParent(null)
                    setSelectedStudentForAssign('')
                  }}
                  className="p-2 rounded-lg hover:bg-gray-100"
                >
                  <X className="h-4 w-4" />
                </button>
              </CardHeader>
              <CardContent>
                <p className="text-sm text-gray-600 mb-4">
                  Select which student {assigningParent.name} is the parent of:
                </p>
                <div className="space-y-2 max-h-60 overflow-y-auto">
                  {students.map((student) => {
                    const isAlreadyLinked = student.parent_ids.includes(assigningParent.id)
                    return (
                      <label
                        key={student.id}
                        className={cn(
                          'flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors',
                          isAlreadyLinked
                            ? 'bg-gray-100 border-gray-200 cursor-not-allowed'
                            : selectedStudentForAssign === student.id
                              ? 'bg-blue-50 border-blue-300'
                              : 'hover:bg-gray-50 border-gray-200'
                        )}
                      >
                        <input
                          type="radio"
                          name="student"
                          value={student.id}
                          checked={selectedStudentForAssign === student.id}
                          onChange={(e) => setSelectedStudentForAssign(e.target.value)}
                          disabled={isAlreadyLinked}
                          className="h-4 w-4 text-blue-600"
                        />
                        <Avatar initials={getStudentInitials(student)} size="sm" />
                        <div className="flex-1">
                          <p className="font-medium text-gray-900">
                            {getStudentFullName(student)}
                          </p>
                          {isAlreadyLinked && (
                            <p className="text-xs text-gray-500">Already linked</p>
                          )}
                        </div>
                      </label>
                    )
                  })}
                </div>
              </CardContent>
              <div className="px-6 py-4 border-t border-gray-100 flex justify-end gap-3">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setAssigningParent(null)
                    setSelectedStudentForAssign('')
                  }}
                >
                  Cancel
                </Button>
                <Button
                  onClick={handleAssignParent}
                  disabled={!selectedStudentForAssign}
                  loading={loading}
                >
                  <LinkIcon className="h-4 w-4 mr-2" />
                  Link Parent
                </Button>
              </div>
            </Card>
          </div>
        )}
      </main>
    </>
  )
}
