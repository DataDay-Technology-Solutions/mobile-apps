// User types matching iOS AppUser.swift and User.swift

export type UserRole = 'admin' | 'teacher' | 'parent' | 'student'

// Admin levels for hierarchical access
export type AdminLevel = 'super_admin' | 'district_admin' | 'principal' | 'school_admin' | 'none'

// District - top level organization
export interface District {
  id: string
  name: string
  code: string  // Unique district code
  address?: string
  city?: string
  state?: string
  zip?: string
  phone?: string
  admin_ids: string[]  // District admin user IDs
  created_at: string
}

// School - belongs to a district
export interface School {
  id: string
  district_id: string
  name: string
  code: string  // Unique school code within district
  address?: string
  city?: string
  state?: string
  zip?: string
  phone?: string
  principal_id?: string  // Principal user ID
  admin_ids: string[]  // School admin user IDs
  grade_levels: string[]  // e.g., ['K', '1', '2', '3', '4', '5']
  created_at: string
}

// Extended user with admin capabilities
export interface AdminUser extends AppUser {
  admin_level: AdminLevel
  district_id?: string
  school_id?: string
}

export interface AppUser {
  id: string
  email: string
  name: string
  display_name?: string
  role: UserRole
  admin_level?: AdminLevel
  district_id?: string
  school_id?: string
  classroom_id?: string
  class_ids: string[]
  student_ids: string[]
  parent_id?: string
  fcm_token?: string
  created_at: string
}

// Classroom types matching iOS Classroom.swift

export interface Classroom {
  id: string
  name: string
  grade_level?: string
  teacher_id: string
  teacher_name?: string
  class_code: string
  student_ids: string[]
  parent_ids: string[]
  school_id?: string  // Optional - links to school
  created_at: string
}

// Student types matching iOS Student.swift

export interface Student {
  id: string
  first_name: string
  last_name: string
  class_id: string
  parent_ids: string[]
  created_at: string
}

// Helper to get student full name
export function getStudentFullName(student: Student): string {
  return `${student.first_name} ${student.last_name}`
}

// Helper to get student initials
export function getStudentInitials(student: Student): string {
  const firstInitial = student.first_name.charAt(0).toUpperCase()
  const lastInitial = student.last_name.charAt(0).toUpperCase()
  return `${firstInitial}${lastInitial}`
}

// Message types matching iOS Message.swift

export interface Conversation {
  id: string
  participant_ids: string[]
  participant_names: Record<string, string>
  class_id?: string
  student_id?: string
  student_name?: string
  last_message?: string
  last_message_date?: string
  last_message_sender_id?: string
  unread_counts: Record<string, number>
  created_at: string
}

export interface Message {
  id: string
  conversation_id: string
  sender_id: string
  sender_name: string
  content: string
  is_read: boolean
  read_at?: string
  created_at: string
}

// Story types matching iOS Story.swift

export type MediaType = 'image' | 'video' | 'text'

export interface Story {
  id: string
  class_id: string
  author_id: string
  author_name: string
  content?: string
  media_urls: string[]
  media_type: MediaType
  like_count: number
  liked_by_ids: string[]
  comment_count: number
  created_at: string
  updated_at: string
}

export interface StoryComment {
  id: string
  story_id: string
  author_id: string
  author_name: string
  content: string
  created_at: string
}

// Points/Behavior types matching iOS Points.swift

export interface Behavior {
  id: string
  name: string
  points: number
  icon: string
  color: string
}

export interface PointRecord {
  id: string
  student_id: string
  class_id: string
  behavior_id?: string
  behavior_name: string
  points: number
  note?: string
  awarded_by: string
  awarded_by_name: string
  created_at: string
}

export interface StudentPointsSummary {
  id: string
  student_id: string
  class_id: string
  total_points: number
  positive_count: number
  negative_count: number
  last_updated: string
}

// Default behaviors (matching iOS)
export const DEFAULT_POSITIVE_BEHAVIORS: Behavior[] = [
  { id: 'helping', name: 'Helping Others', points: 5, icon: 'heart-handshake', color: '#22C55E' },
  { id: 'teamwork', name: 'Teamwork', points: 5, icon: 'users', color: '#3B82F6' },
  { id: 'hardwork', name: 'Hard Work', points: 5, icon: 'briefcase', color: '#8B5CF6' },
  { id: 'participation', name: 'Participation', points: 3, icon: 'hand', color: '#F59E0B' },
  { id: 'kindness', name: 'Kindness', points: 5, icon: 'heart', color: '#EC4899' },
  { id: 'ontask', name: 'On Task', points: 3, icon: 'check-circle', color: '#10B981' },
  { id: 'listening', name: 'Good Listening', points: 3, icon: 'ear', color: '#06B6D4' },
  { id: 'creativity', name: 'Creativity', points: 5, icon: 'lightbulb', color: '#F97316' },
]

export const DEFAULT_NEGATIVE_BEHAVIORS: Behavior[] = [
  { id: 'offtask', name: 'Off Task', points: -2, icon: 'x-circle', color: '#EF4444' },
  { id: 'talkingout', name: 'Talking Out', points: -2, icon: 'message-circle-x', color: '#F87171' },
  { id: 'notlistening', name: 'Not Listening', points: -2, icon: 'ear-off', color: '#FB923C' },
  { id: 'unkind', name: 'Unkind', points: -3, icon: 'frown', color: '#DC2626' },
  { id: 'unprepared', name: 'Unprepared', points: -2, icon: 'alert-circle', color: '#F59E0B' },
  { id: 'missinghomework', name: 'Missing Homework', points: -3, icon: 'file-x', color: '#B91C1C' },
]

// Hall Pass types matching iOS schema

export type HallPassStatus = 'active' | 'returned' | 'expired'

export interface HallPass {
  id: string
  student_id: string
  student_name: string
  teacher_id: string
  teacher_name: string
  destination: string
  reason?: string
  status: HallPassStatus
  created_at: string
  returned_at?: string
  classroom_id: string
}

// Notification types

export interface Notification {
  id: string
  user_id: string
  title: string
  message: string
  type: string
  hall_pass_id?: string
  is_read: boolean
  created_at: string
}

// Utility types for database operations

export type Tables =
  | 'users'
  | 'teachers'
  | 'parents'
  | 'students'
  | 'classrooms'
  | 'hall_passes'
  | 'notifications'
  | 'point_records'
  | 'student_points_summaries'
  | 'stories'
  | 'story_comments'
  | 'conversations'
  | 'messages'

// Time formatting utilities

export function timeAgo(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const seconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (seconds < 60) return 'Just now'
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`
  if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`

  return date.toLocaleDateString()
}

export function formatTime(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
}

export function formatDate(dateString: string): string {
  const date = new Date(dateString)
  return date.toLocaleDateString()
}

// Class code generation (matching iOS)
export function generateClassCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  let code = ''
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return code
}

// Admin Dashboard Statistics

export interface ClassroomStats {
  classroom_id: string
  classroom_name: string
  teacher_name: string
  student_count: number
  parent_count: number
  total_points: number
  story_count: number
  message_count: number
  avg_points_per_student: number
}

export interface SchoolStats {
  school_id: string
  school_name: string
  classroom_count: number
  teacher_count: number
  student_count: number
  parent_count: number
  total_points: number
  story_count: number
  message_count: number
  classrooms: ClassroomStats[]
}

export interface DistrictStats {
  district_id: string
  district_name: string
  school_count: number
  classroom_count: number
  teacher_count: number
  student_count: number
  parent_count: number
  total_points: number
  story_count: number
  message_count: number
  schools: SchoolStats[]
}
