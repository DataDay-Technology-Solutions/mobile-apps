import { createClient as createSupabaseClient, SupabaseClient } from '@supabase/supabase-js'

// Standalone admin client - bypasses browser client auth issues
let adminClient: SupabaseClient | null = null

function createClient() {
  if (!adminClient) {
    adminClient = createSupabaseClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
          detectSessionInUrl: false
        }
      }
    )
  }
  return adminClient
}

import type {
  District,
  School,
  Classroom,
  Student,
  AppUser,
  SchoolStats,
  DistrictStats,
  ClassroomStats,
  Story,
  PointRecord,
  Conversation
} from '@/types'

// District Management

export async function getDistricts(): Promise<District[]> {
  const supabase = createClient()
  console.log('[getDistricts] Fetching districts...')
  const { data, error } = await supabase
    .from('districts')
    .select('*')
    .order('name')

  console.log('[getDistricts] Result:', { data, error })
  if (error) throw error
  return data || []
}

export async function getDistrictById(districtId: string): Promise<District | null> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('districts')
    .select('*')
    .eq('id', districtId)
    .single()

  if (error) throw error
  return data
}

export async function createDistrict(district: Omit<District, 'id' | 'created_at'>): Promise<District> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('districts')
    .insert(district)
    .select()
    .single()

  if (error) throw error
  return data
}

// School Management

export async function getSchoolsInDistrict(districtId: string): Promise<School[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('schools')
    .select('*')
    .eq('district_id', districtId)
    .order('name')

  if (error) throw error
  return data || []
}

export async function getSchoolById(schoolId: string): Promise<School | null> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('schools')
    .select('*')
    .eq('id', schoolId)
    .single()

  if (error) throw error
  return data
}

export async function createSchool(school: Omit<School, 'id' | 'created_at'>): Promise<School> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('schools')
    .insert(school)
    .select()
    .single()

  if (error) throw error
  return data
}

// Get classrooms for a school
export async function getClassroomsInSchool(schoolId: string): Promise<Classroom[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('classrooms')
    .select('*')
    .eq('school_id', schoolId)
    .order('grade_level', { ascending: true })
    .order('name')

  if (error) throw error
  return data || []
}

// Get all classrooms (for super admin)
export async function getAllClassrooms(): Promise<Classroom[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('classrooms')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) throw error
  return data || []
}

// Get all students in a school
export async function getStudentsInSchool(schoolId: string): Promise<Student[]> {
  const supabase = createClient()
  // First get all classroom IDs in the school
  const { data: classrooms } = await supabase
    .from('classrooms')
    .select('id')
    .eq('school_id', schoolId)

  if (!classrooms || classrooms.length === 0) return []

  const classroomIds = classrooms.map(c => c.id)

  const { data, error } = await supabase
    .from('students')
    .select('*')
    .in('class_id', classroomIds)
    .order('last_name')

  if (error) throw error
  return data || []
}

// Get all students (for super admin)
export async function getAllStudents(): Promise<Student[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('students')
    .select('*')
    .order('last_name')

  if (error) throw error
  return data || []
}

// Get all teachers in a school
export async function getTeachersInSchool(schoolId: string): Promise<AppUser[]> {
  const supabase = createClient()
  // Get classroom teacher IDs for this school
  const { data: classrooms } = await supabase
    .from('classrooms')
    .select('teacher_id')
    .eq('school_id', schoolId)

  if (!classrooms || classrooms.length === 0) return []

  const teacherIds = [...new Set(classrooms.map(c => c.teacher_id))]

  const { data, error } = await supabase
    .from('users')
    .select('*')
    .in('id', teacherIds)

  if (error) throw error
  return data || []
}

// Get all teachers (for super admin)
export async function getAllTeachers(): Promise<AppUser[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('role', 'teacher')
    .order('name')

  if (error) throw error
  return data || []
}

// Get all parents (for super admin)
export async function getAllParents(): Promise<AppUser[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('role', 'parent')
    .order('name')

  if (error) throw error
  return data || []
}

// Get all stories in a school
export async function getStoriesInSchool(schoolId: string, limit = 50): Promise<Story[]> {
  const supabase = createClient()
  const { data: classrooms } = await supabase
    .from('classrooms')
    .select('id')
    .eq('school_id', schoolId)

  if (!classrooms || classrooms.length === 0) return []

  const classroomIds = classrooms.map(c => c.id)

  const { data, error } = await supabase
    .from('stories')
    .select('*')
    .in('class_id', classroomIds)
    .order('created_at', { ascending: false })
    .limit(limit)

  if (error) throw error
  return data || []
}

// Get all stories (for super admin)
export async function getAllStories(limit = 100): Promise<Story[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('stories')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit)

  if (error) throw error
  return data || []
}

// Get all messages (for super admin monitoring)
export async function getAllConversations(limit = 100): Promise<Conversation[]> {
  const supabase = createClient()
  const { data, error } = await supabase
    .from('conversations')
    .select('*')
    .order('last_message_date', { ascending: false })
    .limit(limit)

  if (error) throw error
  return data || []
}

// Get point records in a school
export async function getPointRecordsInSchool(schoolId: string, limit = 100): Promise<PointRecord[]> {
  const supabase = createClient()
  const { data: classrooms } = await supabase
    .from('classrooms')
    .select('id')
    .eq('school_id', schoolId)

  if (!classrooms || classrooms.length === 0) return []

  const classroomIds = classrooms.map(c => c.id)

  const { data, error } = await supabase
    .from('point_records')
    .select('*')
    .in('class_id', classroomIds)
    .order('created_at', { ascending: false })
    .limit(limit)

  if (error) throw error
  return data || []
}

// Statistics for School (Principal View)

export async function getSchoolStats(schoolId: string): Promise<SchoolStats> {
  const [classrooms, students, teachers, stories, points] = await Promise.all([
    getClassroomsInSchool(schoolId),
    getStudentsInSchool(schoolId),
    getTeachersInSchool(schoolId),
    getStoriesInSchool(schoolId, 1000),
    getPointRecordsInSchool(schoolId, 10000)
  ])

  // Get school name
  const school = await getSchoolById(schoolId)

  // Calculate classroom-level stats
  const classroomStats: ClassroomStats[] = classrooms.map(classroom => {
    const classStudents = students.filter(s => s.class_id === classroom.id)
    const classStories = stories.filter(s => s.class_id === classroom.id)
    const classPoints = points.filter(p => p.class_id === classroom.id)
    const totalPoints = classPoints.reduce((sum, p) => sum + p.points, 0)

    return {
      classroom_id: classroom.id,
      classroom_name: classroom.name,
      teacher_name: classroom.teacher_name || 'Unknown',
      student_count: classStudents.length,
      parent_count: classroom.parent_ids?.length || 0,
      total_points: totalPoints,
      story_count: classStories.length,
      message_count: 0, // Would need to join with messages
      avg_points_per_student: classStudents.length > 0 ? Math.round(totalPoints / classStudents.length) : 0
    }
  })

  const totalPoints = points.reduce((sum, p) => sum + p.points, 0)
  const uniqueParentIds = new Set(classrooms.flatMap(c => c.parent_ids || []))

  return {
    school_id: schoolId,
    school_name: school?.name || 'Unknown School',
    classroom_count: classrooms.length,
    teacher_count: teachers.length,
    student_count: students.length,
    parent_count: uniqueParentIds.size,
    total_points: totalPoints,
    story_count: stories.length,
    message_count: 0,
    classrooms: classroomStats
  }
}

// Statistics for District (District Admin View)

export async function getDistrictStats(districtId: string): Promise<DistrictStats> {
  const schools = await getSchoolsInDistrict(districtId)
  const district = await getDistrictById(districtId)

  // Get stats for each school
  const schoolStats: SchoolStats[] = await Promise.all(
    schools.map(school => getSchoolStats(school.id))
  )

  // Aggregate totals
  const totals = schoolStats.reduce(
    (acc, school) => ({
      classroom_count: acc.classroom_count + school.classroom_count,
      teacher_count: acc.teacher_count + school.teacher_count,
      student_count: acc.student_count + school.student_count,
      parent_count: acc.parent_count + school.parent_count,
      total_points: acc.total_points + school.total_points,
      story_count: acc.story_count + school.story_count,
      message_count: acc.message_count + school.message_count
    }),
    {
      classroom_count: 0,
      teacher_count: 0,
      student_count: 0,
      parent_count: 0,
      total_points: 0,
      story_count: 0,
      message_count: 0
    }
  )

  return {
    district_id: districtId,
    district_name: district?.name || 'Unknown District',
    school_count: schools.length,
    ...totals,
    schools: schoolStats
  }
}

// Super Admin - Get everything

export async function getSuperAdminStats(): Promise<{
  districts: District[]
  totalSchools: number
  totalClassrooms: number
  totalTeachers: number
  totalStudents: number
  totalParents: number
  recentStories: Story[]
  recentActivity: PointRecord[]
}> {
  const supabase = createClient()

  const [districts, classrooms, teachers, students, parents, stories, pointsResult] = await Promise.all([
    getDistricts(),
    getAllClassrooms(),
    getAllTeachers(),
    getAllStudents(),
    getAllParents(),
    getAllStories(20),
    supabase
      .from('point_records')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(20)
  ])

  const points = pointsResult.data || []

  // Count schools
  const { count: schoolCount } = await supabase
    .from('schools')
    .select('*', { count: 'exact', head: true })

  return {
    districts,
    totalSchools: schoolCount || 0,
    totalClassrooms: classrooms.length,
    totalTeachers: teachers.length,
    totalStudents: students.length,
    totalParents: parents.length,
    recentStories: stories,
    recentActivity: points
  }
}

// User admin level check
export async function getUserAdminLevel(userId: string): Promise<{
  level: 'super_admin' | 'district_admin' | 'principal' | 'school_admin' | 'none'
  districtId?: string
  schoolId?: string
}> {
  const supabase = createClient()

  // Check user's admin_level field first
  const { data: user } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single()

  if (!user) return { level: 'none' }

  // Check admin_level field
  if (user.admin_level === 'super_admin') {
    return { level: 'super_admin' }
  }

  if (user.admin_level === 'district_admin' && user.district_id) {
    return { level: 'district_admin', districtId: user.district_id }
  }

  if (user.admin_level === 'principal' && user.school_id) {
    return { level: 'principal', schoolId: user.school_id, districtId: user.district_id }
  }

  if (user.admin_level === 'school_admin' && user.school_id) {
    return { level: 'school_admin', schoolId: user.school_id, districtId: user.district_id }
  }

  // Legacy check: Check if district admin via admin_ids array
  const { data: districtAdmin } = await supabase
    .from('districts')
    .select('id')
    .contains('admin_ids', [userId])
    .single()

  if (districtAdmin) {
    return { level: 'district_admin', districtId: districtAdmin.id }
  }

  // Legacy check: Check if principal via principal_id
  const { data: principalSchool } = await supabase
    .from('schools')
    .select('id, district_id')
    .eq('principal_id', userId)
    .single()

  if (principalSchool) {
    return {
      level: 'principal',
      schoolId: principalSchool.id,
      districtId: principalSchool.district_id
    }
  }

  // Legacy check: Check if school admin via admin_ids array
  const { data: schoolAdmin } = await supabase
    .from('schools')
    .select('id, district_id')
    .contains('admin_ids', [userId])
    .single()

  if (schoolAdmin) {
    return {
      level: 'school_admin',
      schoolId: schoolAdmin.id,
      districtId: schoolAdmin.district_id
    }
  }

  return { level: 'none' }
}
