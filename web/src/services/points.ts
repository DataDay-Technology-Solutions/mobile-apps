import { createClient } from '@/lib/supabase/client'
import type { PointRecord, StudentPointsSummary, Behavior } from '@/types'

export class PointsError extends Error {
  constructor(message: string) {
    super(message)
    this.name = 'PointsError'
  }
}

export const pointsService = {
  // Award points to a student

  async awardPoints(
    studentId: string,
    classId: string,
    behavior: Behavior,
    awardedBy: string,
    awardedByName: string,
    note?: string
  ): Promise<PointRecord> {
    const supabase = createClient()

    const newRecord: Omit<PointRecord, 'id'> = {
      student_id: studentId,
      class_id: classId,
      behavior_id: behavior.id,
      behavior_name: behavior.name,
      points: behavior.points,
      note,
      awarded_by: awardedBy,
      awarded_by_name: awardedByName,
      created_at: new Date().toISOString(),
    }

    const { data, error } = await supabase
      .from('point_records')
      .insert(newRecord)
      .select()
      .single()

    if (error) throw new PointsError(error.message)

    // Update student summary
    await this.updateStudentSummary(studentId, classId, behavior.points)

    return data as PointRecord
  },

  // Award points to multiple students

  async awardPointsToMultipleStudents(
    studentIds: string[],
    classId: string,
    behavior: Behavior,
    awardedBy: string,
    awardedByName: string,
    note?: string
  ): Promise<PointRecord[]> {
    const records: PointRecord[] = []
    for (const studentId of studentIds) {
      const record = await this.awardPoints(
        studentId,
        classId,
        behavior,
        awardedBy,
        awardedByName,
        note
      )
      records.push(record)
    }
    return records
  },

  // Get points history for a student

  async getPointsHistory(studentId: string, limit: number = 50): Promise<PointRecord[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('point_records')
      .select()
      .eq('student_id', studentId)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw new PointsError(error.message)
    return data as PointRecord[]
  },

  // Get points history for entire class

  async getClassPointsHistory(classId: string, limit: number = 100): Promise<PointRecord[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('point_records')
      .select()
      .eq('class_id', classId)
      .order('created_at', { ascending: false })
      .limit(limit)

    if (error) throw new PointsError(error.message)
    return data as PointRecord[]
  },

  // Get student summary

  async getStudentSummary(studentId: string, classId: string): Promise<StudentPointsSummary | null> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('student_points_summaries')
      .select()
      .eq('student_id', studentId)
      .eq('class_id', classId)
      .single()

    if (error) return null
    return data as StudentPointsSummary
  },

  // Get all summaries for a class

  async getClassSummaries(classId: string): Promise<StudentPointsSummary[]> {
    const supabase = createClient()

    const { data, error } = await supabase
      .from('student_points_summaries')
      .select()
      .eq('class_id', classId)
      .order('total_points', { ascending: false })

    if (error) throw new PointsError(error.message)
    return data as StudentPointsSummary[]
  },

  // Update student summary (upsert)

  async updateStudentSummary(studentId: string, classId: string, pointsDelta: number): Promise<void> {
    const supabase = createClient()

    const existing = await this.getStudentSummary(studentId, classId)

    if (existing) {
      // Update existing summary
      const newTotal = existing.total_points + pointsDelta
      const positiveCount = pointsDelta > 0 ? existing.positive_count + 1 : existing.positive_count
      const negativeCount = pointsDelta < 0 ? existing.negative_count + 1 : existing.negative_count

      const { error } = await supabase
        .from('student_points_summaries')
        .update({
          total_points: newTotal,
          positive_count: positiveCount,
          negative_count: negativeCount,
          last_updated: new Date().toISOString(),
        })
        .eq('id', existing.id)

      if (error) throw new PointsError(error.message)
    } else {
      // Create new summary
      const { error } = await supabase
        .from('student_points_summaries')
        .insert({
          student_id: studentId,
          class_id: classId,
          total_points: pointsDelta,
          positive_count: pointsDelta > 0 ? 1 : 0,
          negative_count: pointsDelta < 0 ? 1 : 0,
          last_updated: new Date().toISOString(),
        })

      if (error) throw new PointsError(error.message)
    }
  },

  // Delete a point record

  async deletePointRecord(id: string): Promise<void> {
    const supabase = createClient()

    // Get the record first to adjust summary
    const { data: record } = await supabase
      .from('point_records')
      .select()
      .eq('id', id)
      .single()

    if (record) {
      // Reverse the points in summary
      await this.updateStudentSummary(
        record.student_id,
        record.class_id,
        -record.points
      )
    }

    const { error } = await supabase
      .from('point_records')
      .delete()
      .eq('id', id)

    if (error) throw new PointsError(error.message)
  },

  // Reset student points

  async resetStudentPoints(studentId: string, classId: string): Promise<void> {
    const supabase = createClient()

    // Delete all point records
    const { error: recordsError } = await supabase
      .from('point_records')
      .delete()
      .eq('student_id', studentId)
      .eq('class_id', classId)

    if (recordsError) throw new PointsError(recordsError.message)

    // Reset summary
    const { error: summaryError } = await supabase
      .from('student_points_summaries')
      .update({
        total_points: 0,
        positive_count: 0,
        negative_count: 0,
        last_updated: new Date().toISOString(),
      })
      .eq('student_id', studentId)
      .eq('class_id', classId)

    if (summaryError) throw new PointsError(summaryError.message)
  },

  // Real-time subscriptions

  subscribeToStudentPoints(studentId: string, classId: string, callback: (summary: StudentPointsSummary | null) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`points_${studentId}_${classId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'student_points_summaries',
          filter: `student_id=eq.${studentId}`
        },
        async () => {
          const summary = await this.getStudentSummary(studentId, classId)
          callback(summary)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },

  subscribeToClassSummaries(classId: string, callback: (summaries: StudentPointsSummary[]) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`class_summaries_${classId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'student_points_summaries',
          filter: `class_id=eq.${classId}`
        },
        async () => {
          const summaries = await this.getClassSummaries(classId)
          callback(summaries)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },

  subscribeToRecentPoints(classId: string, callback: (records: PointRecord[]) => void) {
    const supabase = createClient()

    const channel = supabase
      .channel(`recent_points_${classId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'point_records',
          filter: `class_id=eq.${classId}`
        },
        async () => {
          const records = await this.getClassPointsHistory(classId, 10)
          callback(records)
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  },
}
