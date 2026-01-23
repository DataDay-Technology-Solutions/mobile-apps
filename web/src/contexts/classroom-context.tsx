'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'
import { useAuth } from './auth-context'
import { classroomService } from '@/services/classroom'
import type { Classroom, Student } from '@/types'

interface ClassroomContextType {
  classrooms: Classroom[]
  selectedClassroom: Classroom | null
  students: Student[]
  loading: boolean
  selectClassroom: (classroom: Classroom | null) => void
  refreshClassrooms: () => Promise<void>
  refreshStudents: () => Promise<void>
}

const ClassroomContext = createContext<ClassroomContextType | undefined>(undefined)

export function ClassroomProvider({ children }: { children: ReactNode }) {
  const { user } = useAuth()
  const [classrooms, setClassrooms] = useState<Classroom[]>([])
  const [selectedClassroom, setSelectedClassroom] = useState<Classroom | null>(null)
  const [students, setStudents] = useState<Student[]>([])
  const [loading, setLoading] = useState(true)

  // Fetch classrooms when user changes
  useEffect(() => {
    if (user) {
      refreshClassrooms()
    } else {
      setClassrooms([])
      setSelectedClassroom(null)
      setStudents([])
      setLoading(false)
    }
  }, [user])

  // Fetch students when selected classroom changes
  useEffect(() => {
    if (selectedClassroom) {
      refreshStudents()

      // Subscribe to classroom updates
      const unsubscribeClassroom = classroomService.subscribeToClassroom(
        selectedClassroom.id,
        (updatedClassroom) => {
          setSelectedClassroom(updatedClassroom)
          setClassrooms(prev =>
            prev.map(c => c.id === updatedClassroom.id ? updatedClassroom : c)
          )
        }
      )

      // Subscribe to student updates
      const unsubscribeStudents = classroomService.subscribeToStudents(
        selectedClassroom.id,
        (updatedStudents) => {
          setStudents(updatedStudents)
        }
      )

      return () => {
        unsubscribeClassroom()
        unsubscribeStudents()
      }
    } else {
      setStudents([])
    }
  }, [selectedClassroom?.id])

  const refreshClassrooms = async () => {
    if (!user) return
    setLoading(true)

    try {
      let fetchedClassrooms: Classroom[] = []

      if (user.role === 'teacher') {
        fetchedClassrooms = await classroomService.getClassroomsForTeacher(user.id)
      } else if (user.role === 'parent') {
        fetchedClassrooms = await classroomService.getClassroomsForParent(user.id)
      }

      setClassrooms(fetchedClassrooms)

      // Auto-select first classroom if none selected
      if (!selectedClassroom && fetchedClassrooms.length > 0) {
        setSelectedClassroom(fetchedClassrooms[0])
      }
    } catch (error) {
      console.error('Failed to fetch classrooms:', error)
    } finally {
      setLoading(false)
    }
  }

  const refreshStudents = async () => {
    if (!selectedClassroom) return

    try {
      const fetchedStudents = await classroomService.getStudentsForClass(selectedClassroom.id)
      setStudents(fetchedStudents)
    } catch (error) {
      console.error('Failed to fetch students:', error)
    }
  }

  const selectClassroom = (classroom: Classroom | null) => {
    setSelectedClassroom(classroom)
  }

  return (
    <ClassroomContext.Provider
      value={{
        classrooms,
        selectedClassroom,
        students,
        loading,
        selectClassroom,
        refreshClassrooms,
        refreshStudents,
      }}
    >
      {children}
    </ClassroomContext.Provider>
  )
}

export function useClassroom() {
  const context = useContext(ClassroomContext)
  if (context === undefined) {
    throw new Error('useClassroom must be used within a ClassroomProvider')
  }
  return context
}
