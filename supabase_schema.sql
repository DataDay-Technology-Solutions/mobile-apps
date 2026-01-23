-- ============================================
-- HallPass (formerly TeacherLink) - Supabase Schema
-- Run this in your Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- CORE TABLES
-- ============================================

-- Users table (main user profiles)
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    display_name TEXT,
    role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'parent', 'student')),
    classroom_id TEXT,
    class_ids TEXT[] DEFAULT '{}',
    student_ids TEXT[] DEFAULT '{}',
    parent_id TEXT,
    fcm_token TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teachers table
CREATE TABLE IF NOT EXISTS teachers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    classroom_id TEXT
);

-- Parents table
CREATE TABLE IF NOT EXISTS parents (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    student_ids TEXT[] DEFAULT '{}'
);

-- Students table
CREATE TABLE IF NOT EXISTS students (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    first_name TEXT,
    last_name TEXT,
    name TEXT NOT NULL,
    class_id TEXT NOT NULL,
    classroom_id TEXT,
    parent_id TEXT,
    parent_ids TEXT[] DEFAULT '{}',
    parent_email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Classrooms table
CREATE TABLE IF NOT EXISTS classrooms (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    name TEXT NOT NULL,
    teacher_id TEXT NOT NULL,
    teacher_name TEXT,
    class_code TEXT UNIQUE,
    grade_level TEXT,
    student_ids TEXT[] DEFAULT '{}',
    parent_ids TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- HALL PASS TABLES
-- ============================================

-- Hall Passes table
CREATE TABLE IF NOT EXISTS hall_passes (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    student_id TEXT NOT NULL,
    student_name TEXT NOT NULL,
    teacher_id TEXT NOT NULL,
    teacher_name TEXT NOT NULL,
    destination TEXT NOT NULL,
    reason TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'returned', 'expired')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    returned_at TIMESTAMPTZ,
    classroom_id TEXT NOT NULL
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('hall_pass_created', 'hall_pass_returned', 'hall_pass_expired', 'general')),
    hall_pass_id TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- POINTS/BEHAVIOR TABLES
-- ============================================

-- Point Records table
CREATE TABLE IF NOT EXISTS point_records (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    student_id TEXT NOT NULL,
    class_id TEXT NOT NULL,
    behavior_id TEXT,
    behavior_name TEXT NOT NULL,
    points INTEGER NOT NULL,
    note TEXT,
    awarded_by TEXT NOT NULL,
    awarded_by_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Student Points Summaries table
CREATE TABLE IF NOT EXISTS student_points_summaries (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    student_id TEXT NOT NULL,
    class_id TEXT NOT NULL,
    total_points INTEGER DEFAULT 0,
    positive_count INTEGER DEFAULT 0,
    negative_count INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, class_id)
);

-- ============================================
-- STORIES/FEED TABLES
-- ============================================

-- Stories table
CREATE TABLE IF NOT EXISTS stories (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    class_id TEXT NOT NULL,
    author_id TEXT NOT NULL,
    author_name TEXT NOT NULL,
    content TEXT,
    media_urls TEXT[] DEFAULT '{}',
    media_type TEXT CHECK (media_type IN ('image', 'video', 'text')),
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    liked_by_ids TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Story Comments table
CREATE TABLE IF NOT EXISTS story_comments (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    story_id TEXT NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    author_id TEXT NOT NULL,
    author_name TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MESSAGING TABLES
-- ============================================

-- Conversations table
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    participant_ids TEXT[] NOT NULL,
    participant_names JSONB DEFAULT '{}',
    class_id TEXT NOT NULL,
    student_id TEXT,
    student_name TEXT,
    last_message TEXT,
    last_message_date TIMESTAMPTZ DEFAULT NOW(),
    last_message_sender_id TEXT,
    unread_counts JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_students_class ON students(class_id);
CREATE INDEX IF NOT EXISTS idx_students_classroom ON students(classroom_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_teacher ON classrooms(teacher_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_code ON classrooms(class_code);
CREATE INDEX IF NOT EXISTS idx_hall_passes_classroom ON hall_passes(classroom_id);
CREATE INDEX IF NOT EXISTS idx_hall_passes_student ON hall_passes(student_id);
CREATE INDEX IF NOT EXISTS idx_hall_passes_status ON hall_passes(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_point_records_student ON point_records(student_id);
CREATE INDEX IF NOT EXISTS idx_point_records_class ON point_records(class_id);
CREATE INDEX IF NOT EXISTS idx_summaries_student_class ON student_points_summaries(student_id, class_id);
CREATE INDEX IF NOT EXISTS idx_stories_class ON stories(class_id);
CREATE INDEX IF NOT EXISTS idx_story_comments_story ON story_comments(story_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to increment comment count
CREATE OR REPLACE FUNCTION increment_comment_count(story_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE stories SET comment_count = comment_count + 1 WHERE id = story_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement comment count
CREATE OR REPLACE FUNCTION decrement_comment_count(story_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE stories SET comment_count = GREATEST(0, comment_count - 1) WHERE id = story_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE parents ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE classrooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE hall_passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE point_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_points_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own profile" ON users FOR SELECT USING (auth.uid()::TEXT = id);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid()::TEXT = id);
CREATE POLICY "Users can insert their own profile" ON users FOR INSERT WITH CHECK (auth.uid()::TEXT = id);

-- Allow authenticated users to read other users (for participant names, etc.)
CREATE POLICY "Authenticated can read users" ON users FOR SELECT USING (auth.role() = 'authenticated');

-- Students policies
CREATE POLICY "Teachers can view students" ON students FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Teachers can manage students" ON students FOR ALL USING (auth.role() = 'authenticated');

-- Classrooms policies
CREATE POLICY "Authenticated can read classrooms" ON classrooms FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Teachers can manage classrooms" ON classrooms FOR ALL USING (auth.role() = 'authenticated');

-- Hall passes policies
CREATE POLICY "Authenticated can read hall_passes" ON hall_passes FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated can manage hall_passes" ON hall_passes FOR ALL USING (auth.role() = 'authenticated');

-- Notifications policies
CREATE POLICY "Users can view their notifications" ON notifications FOR SELECT USING (user_id = auth.uid()::TEXT);
CREATE POLICY "Users can update their notifications" ON notifications FOR UPDATE USING (user_id = auth.uid()::TEXT);
CREATE POLICY "Authenticated can create notifications" ON notifications FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Points policies
CREATE POLICY "Authenticated can read point_records" ON point_records FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated can manage point_records" ON point_records FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated can read summaries" ON student_points_summaries FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated can manage summaries" ON student_points_summaries FOR ALL USING (auth.role() = 'authenticated');

-- Stories policies
CREATE POLICY "Authenticated can read stories" ON stories FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated can manage stories" ON stories FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated can read comments" ON story_comments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated can manage comments" ON story_comments FOR ALL USING (auth.role() = 'authenticated');

-- Messaging policies
CREATE POLICY "Participants can read conversations" ON conversations FOR SELECT
    USING (auth.uid()::TEXT = ANY(participant_ids));
CREATE POLICY "Authenticated can create conversations" ON conversations FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Participants can update conversations" ON conversations FOR UPDATE
    USING (auth.uid()::TEXT = ANY(participant_ids));

CREATE POLICY "Participants can read messages" ON messages FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM conversations
        WHERE conversations.id = messages.conversation_id
        AND auth.uid()::TEXT = ANY(conversations.participant_ids)
    ));
CREATE POLICY "Participants can send messages" ON messages FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM conversations
        WHERE conversations.id = conversation_id
        AND auth.uid()::TEXT = ANY(conversations.participant_ids)
    ));
CREATE POLICY "Participants can update messages" ON messages FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM conversations
        WHERE conversations.id = messages.conversation_id
        AND auth.uid()::TEXT = ANY(conversations.participant_ids)
    ));

-- Teachers/Parents tables policies
CREATE POLICY "Authenticated can read teachers" ON teachers FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated can manage teachers" ON teachers FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated can read parents" ON parents FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Authenticated can manage parents" ON parents FOR ALL USING (auth.role() = 'authenticated');

-- ============================================
-- REALTIME SUBSCRIPTIONS
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE hall_passes;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE students;
ALTER PUBLICATION supabase_realtime ADD TABLE classrooms;
ALTER PUBLICATION supabase_realtime ADD TABLE point_records;
ALTER PUBLICATION supabase_realtime ADD TABLE student_points_summaries;
ALTER PUBLICATION supabase_realtime ADD TABLE stories;
ALTER PUBLICATION supabase_realtime ADD TABLE story_comments;
ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- ============================================
-- STORAGE BUCKET (create in Supabase Dashboard)
-- ============================================
-- Create a bucket called "media" with public access for storing story images/videos

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ============================================
-- ADMIN HIERARCHY TABLES
-- ============================================

-- Districts table (top-level organization)
CREATE TABLE IF NOT EXISTS districts (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    phone TEXT,
    website TEXT,
    logo_url TEXT,
    admin_ids TEXT[] DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Schools table (belongs to a district)
CREATE TABLE IF NOT EXISTS schools (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    district_id TEXT NOT NULL REFERENCES districts(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    phone TEXT,
    website TEXT,
    logo_url TEXT,
    principal_id TEXT,
    admin_ids TEXT[] DEFAULT '{}',
    grade_levels TEXT[] DEFAULT '{}',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(district_id, code)
);

-- Add school_id to classrooms
ALTER TABLE classrooms
ADD COLUMN IF NOT EXISTS school_id TEXT REFERENCES schools(id) ON DELETE SET NULL;

-- Add admin fields to users
ALTER TABLE users
ADD COLUMN IF NOT EXISTS admin_level TEXT CHECK (admin_level IN ('super_admin', 'district_admin', 'principal', 'school_admin', 'none')) DEFAULT 'none';

ALTER TABLE users
ADD COLUMN IF NOT EXISTS district_id TEXT REFERENCES districts(id) ON DELETE SET NULL;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS school_id TEXT REFERENCES schools(id) ON DELETE SET NULL;

-- Indexes for admin tables
CREATE INDEX IF NOT EXISTS idx_districts_code ON districts(code);
CREATE INDEX IF NOT EXISTS idx_schools_district ON schools(district_id);
CREATE INDEX IF NOT EXISTS idx_schools_principal ON schools(principal_id);
CREATE INDEX IF NOT EXISTS idx_classrooms_school ON classrooms(school_id);
CREATE INDEX IF NOT EXISTS idx_users_admin_level ON users(admin_level);

-- Enable RLS on admin tables
ALTER TABLE districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;

-- Districts policies
CREATE POLICY "Authenticated can read districts" ON districts FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins can manage districts" ON districts FOR ALL USING (auth.role() = 'authenticated');

-- Schools policies
CREATE POLICY "Authenticated can read schools" ON schools FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins can manage schools" ON schools FOR ALL USING (auth.role() = 'authenticated');

-- Realtime for admin tables
ALTER PUBLICATION supabase_realtime ADD TABLE districts;
ALTER PUBLICATION supabase_realtime ADD TABLE schools;

-- Grant permissions on admin tables
GRANT ALL ON districts TO authenticated;
GRANT ALL ON schools TO authenticated;
