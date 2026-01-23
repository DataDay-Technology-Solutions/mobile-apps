import { createClient } from '@/lib/supabase/client'
import type { Classroom, Student, AppUser } from '@/types'
import { generateClassCode } from '@/types'

export class ClassroomError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'ClassroomError'
  }
}

export const classroomService = {
  // Classroom CRUD operations

  async createClassroom(classroom: Omit<Classroom, 'id' | 'created_at' | 'class_code' | 'student_ids' | 'parent_ids'>): Promise<Classroom> {
    const supabase = createClient()

    const newClassroom = {
      ...classroom,
      class_code: generateClassCode(),
      student_ids: [],
      parent_ids: [],
      created_at: new Date().toISOString(),
    }

    const { data, error } = await supabase
      .from('classrooms')
      .insert(newClassroom)
      .select()
      .single()

    if (error) throw new ClassroomError(error.message)

    // Update teacher's classroom_id
    await supabase
      .from('users')
      .update({ classroom_id: data.id })
      .eq('id', classroom.teacher_id)

    return data as Classroom
  },

  async getClassroom(id: string): Promise<Classroom | null> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('classrooms')
      .select()
      .eq('id', id)
      .single()

    if (error) return null
    return data as Classroom
  },

  async getClassroomsForTeacher(teacherId: string): Promise<Classroom[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('classrooms')
      .select()
      .eq('teacher_id', teacherId)
      .order('created_at', { ascending: false })

    if (error) throw new ClassroomError(error.message)
    return data as Classroom[]
  },

  async getClassroomsForParent(parentId: string): Promise<Classroom[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('classrooms')
      .select()
      .contains('parent_ids', [parentId])
      .order('created_at', { ascending: false })

    if (error) throw new ClassroomError(error.message)
    return data as Classroom[]
  },

  async updateClassroom(classroom: Partial<Classroom> & { id: string }): Promise<Classroom> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('classrooms')
      .update(classroom)
      .eq('id', classroom.id)
      .select()
      .single()

    if (error) throw new ClassroomError(error.message)
    return data as Classroom
  },

  async deleteClassroom(id: string): Promise<void> {
    const supabase = createClient()

    const { error } = await supabase
      .from('classrooms')
      .delete()
      .eq('id', id)

    if (error) throw new ClassroomError(error.message)
  },

  async getClassroomByCode(code: string): Promise<Classroom | null> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('classrooms')
      .select()
      .eq('class_code', code.toUpperCase())
      .single()

    if (error) return null
    return data as Classroom
  },

  async joinClassWithCode(code: string, parentId: string): Promise<Classroom> {
    const supabase = createClient()

    const classroom = await this.getClassroomByCode(code)
    if (!classroom) throw new ClassroomError('Invalid class code')

    // Check if already joined
    if (classroom.parent_ids.includes(parentId)) {
      throw new ClassroomError('Already joined this class')
    }

    // Add parent to classroom
    const updatedParentIds = [...classroom.parent_ids, parentId]
    const { data, error } = await supabase
      .from('classrooms')
      .update({ parent_ids: updatedParentIds })
      .eq('id', classroom.id)
      .select()
      .single()

    if (error) throw new ClassroomError(error.message)

    // Update parent's class_ids
    const { data: parentData } = await supabase
      .from('users')
      .select('class_ids')
      .eq('id', parentId)
      .single()

    const currentClassIds = parentData?.class_ids || []
    if (!currentClassIds.includes(classroom.id)) {
      await supabase
        .from('users')
        .update({ class_ids: [...currentClassIds, classroom.id] })
        .eq('id', parentId)
    }

    return data as Classroom
  },

  // Student CRUD operations

  async addStudent(student: Omit<Student, 'id' | 'created_at'>): Promise<Student> {
    const supabase = createClient()

    const newStudent = {
      ...student,
      name: `${student.first_name} ${student.last_name}`.trim(),
      parent_ids: student.parent_ids || [],
      created_at: new Date().toISOString(),
    }

    const { data, error } = await supabase
      .from('students')
      .insert(newStudent)
      .select()
      .single()

    if (error) throw new ClassroomError(error.message)

    // Update classroom's student_ids
    const classroom = await this.getClassroom(student.class_id)
    if (classroom) {
      const updatedStudentIds = [...classroom.student_ids, data.id]
      await supabase
        .from('classrooms')
        .update({ student_ids: updatedStudentIds })
        .eq('id', student.class_id)
    }

    return data as Student
  },

  async getStudentsForClass(classId: string): Promise<Student[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('students')
      .select()
      .eq('class_id', classId)
      .order('last_name', { ascending: true })

    if (error) throw new ClassroomError(error.message)
    return data as Student[]
  },

  async getStudent(id: string): Promise<Student | null> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('students')
      .select()
      .eq('id', id)
      .single()

    if (error) return null
    return data as Student
  },

  async updateStudent(student: Partial<Student> & { id: string }): Promise<Student> {
    const supabase = createClient()

    // If first_name or last_name is being updated, recompute the name field
    const updateData: Record<string, unknown> = { ...student }
    if (student.first_name !== undefined || student.last_name !== undefined) {
      // Fetch current student to get existing names if not provided
      const current = await this.getStudent(student.id)
      if (current) {
        const firstName = student.first_name ?? current.first_name
        const lastName = student.last_name ?? current.last_name
        updateData.name = `${firstName} ${lastName}`.trim()
      }
    }

    const { data, error } = await supabase
      .from('students')
      .update(updateData)
      .eq('id', student.id)
      .select()
      .single()

    if (error) throw new ClassroomError(error.message)
    return data as Student
  },

  async deleteStudent(id: string): Promise<void> {
    const supabase = createClient()

    // Get student to find their class
    const student = await this.getStudent(id)
    if (!student) throw new ClassroomError('Student not found')

    // Remove from classroom's student_ids
    const classroom = await this.getClassroom(student.class_id)
    if (classroom) {
      const updatedStudentIds = classroom.student_ids.filter(sid => sid !== id)
      await supabase
        .from('classrooms')
        .update({ student_ids: updatedStudentIds })
        .eq('id', student.class_id)
    }

    // Delete student
    const { error } = await supabase
      .from('students')
      .delete()
      .eq('id', id)

    if (error) throw new ClassroomError(error.message)
  },

  async linkParentToStudent(studentId: string, parentId: string): Promise<Student> {
    const supabase = createClient()

    const student = await this.getStudent(studentId)
    if (!student) throw new ClassroomError('Student not found')

    if (student.parent_ids.includes(parentId)) {
      return student // Already linked
    }

    const updatedParentIds = [...student.parent_ids, parentId]
    const { data, error } = await supabase
      .from('students')
      .update({ parent_ids: updatedParentIds })
      .eq('id', studentId)
      .select()
      .single()

    if (error) throw new ClassroomError(error.message)

    // Update parent's student_ids
    const { data: parentData } = await supabase
      .from('users')
      .select('student_ids')
      .eq('id', parentId)
      .single()

    const currentStudentIds = parentData?.student_ids || []
    if (!currentStudentIds.includes(studentId)) {
      await supabase
        .from('users')
        .update({ student_ids: [...currentStudentIds, studentId] })
        .eq('id', parentId)
    }

    return data as Student
  },

  // Real-time subscriptions

  subscribeToClassroom(classroomId: string, callback: (classroom: Classroom) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`classroom_${classroomId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'classrooms', filter: `id=eq.${classroomId}` },
        (payload) => {
          if (payload.new) {
            callback(payload.new as Classroom)
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },

  subscribeToStudents(classId: string, callback: (students: Student[]) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`students_${classId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'students', filter: `class_id=eq.${classId}` },
        async () => {
          // Refetch all students on any change
          const students = await this.getStudentsForClass(classId)
          callback(students)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },
}
