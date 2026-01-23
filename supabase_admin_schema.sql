-- ============================================
-- HallPass Admin Schema - Districts & Schools
-- Run this in your Supabase SQL Editor
-- ============================================

-- ============================================
-- DISTRICTS TABLE
-- Top-level organization (e.g., "Springfield School District")
-- ============================================

CREATE TABLE IF NOT EXISTS districts (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,  -- Unique district code (e.g., "SPRINGFIELD-USD")
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    phone TEXT,
    website TEXT,
    logo_url TEXT,
    admin_ids TEXT[] DEFAULT '{}',  -- District admin user IDs
    settings JSONB DEFAULT '{}',    -- District-wide settings
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SCHOOLS TABLE
-- Belongs to a district (e.g., "Springfield Elementary")
-- ============================================

CREATE TABLE IF NOT EXISTS schools (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::TEXT,
    district_id TEXT NOT NULL REFERENCES districts(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    code TEXT NOT NULL,  -- School code within district (e.g., "ELEM-01")
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT,
    phone TEXT,
    website TEXT,
    logo_url TEXT,
    principal_id TEXT,  -- Principal user ID
    admin_ids TEXT[] DEFAULT '{}',  -- School admin user IDs (assistant principals, etc.)
    grade_levels TEXT[] DEFAULT '{}',  -- e.g., ['K', '1', '2', '3', '4', '5']
    settings JSONB DEFAULT '{}',  -- School-specific settings
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(district_id, code)  -- Code must be unique within district
);

-- ============================================
-- ADD school_id TO CLASSROOMS
-- Link classrooms to schools
-- ============================================

ALTER TABLE classrooms
ADD COLUMN IF NOT EXISTS school_id TEXT REFERENCES schools(id) ON DELETE SET NULL;

-- ============================================
-- ADD admin fields TO USERS
-- For tracking admin level and assignments
-- ============================================

ALTER TABLE users
ADD COLUMN IF NOT EXISTS admin_level TEXT CHECK (admin_level IN ('super_admin', 'district_admin', 'principal', 'school_admin', 'none')) DEFAULT 'none';

ALTER TABLE users
ADD COLUMN IF NOT EXISTS district_id TEXT REFERENCES districts(id) ON DELETE SET NULL;

ALTER TABLE users
ADD COLUMN IF NOT EXISTS school_id TEXT REFERENCES schools(id) ON DELETE SET NULL;

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_districts_code ON districts(code);
CREATE INDEX IF NOT EXISTS idx_districts_name ON districts(name);

CREATE INDEX IF NOT EXISTS idx_schools_district ON schools(district_id);
CREATE INDEX IF NOT EXISTS idx_schools_code ON schools(district_id, code);
CREATE INDEX IF NOT EXISTS idx_schools_principal ON schools(principal_id);
CREATE INDEX IF NOT EXISTS idx_schools_name ON schools(name);

CREATE INDEX IF NOT EXISTS idx_classrooms_school ON classrooms(school_id);

CREATE INDEX IF NOT EXISTS idx_users_admin_level ON users(admin_level);
CREATE INDEX IF NOT EXISTS idx_users_district ON users(district_id);
CREATE INDEX IF NOT EXISTS idx_users_school ON users(school_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;

-- Districts policies
CREATE POLICY "Authenticated can read districts" ON districts
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "District admins can update their district" ON districts
    FOR UPDATE USING (auth.uid()::TEXT = ANY(admin_ids));

CREATE POLICY "Super admins can manage districts" ON districts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::TEXT
            AND users.admin_level = 'super_admin'
        )
    );

-- Schools policies
CREATE POLICY "Authenticated can read schools" ON schools
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "School admins can update their school" ON schools
    FOR UPDATE USING (
        auth.uid()::TEXT = principal_id
        OR auth.uid()::TEXT = ANY(admin_ids)
    );

CREATE POLICY "District admins can manage schools in their district" ON schools
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM districts
            WHERE districts.id = schools.district_id
            AND auth.uid()::TEXT = ANY(districts.admin_ids)
        )
    );

CREATE POLICY "Super admins can manage schools" ON schools
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = auth.uid()::TEXT
            AND users.admin_level = 'super_admin'
        )
    );

-- ============================================
-- REALTIME SUBSCRIPTIONS
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE districts;
ALTER PUBLICATION supabase_realtime ADD TABLE schools;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to check if user is admin of a school
CREATE OR REPLACE FUNCTION is_school_admin(user_id TEXT, school_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    school_record RECORD;
BEGIN
    SELECT * INTO school_record FROM schools WHERE id = school_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Check if user is principal or in admin_ids
    RETURN (school_record.principal_id = user_id)
        OR (user_id = ANY(school_record.admin_ids));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is admin of a district
CREATE OR REPLACE FUNCTION is_district_admin(user_id TEXT, district_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    district_record RECORD;
BEGIN
    SELECT * INTO district_record FROM districts WHERE id = district_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    RETURN user_id = ANY(district_record.admin_ids);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's admin scope
CREATE OR REPLACE FUNCTION get_user_admin_scope(user_id TEXT)
RETURNS TABLE (
    admin_level TEXT,
    district_id TEXT,
    school_id TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        u.admin_level,
        u.district_id,
        u.school_id
    FROM users u
    WHERE u.id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Uncomment to insert sample data for testing:

/*
-- Sample District
INSERT INTO districts (id, name, code, city, state) VALUES
('district-1', 'Springfield Unified School District', 'SPRINGFIELD-USD', 'Springfield', 'IL');

-- Sample Schools
INSERT INTO schools (id, district_id, name, code, city, state, grade_levels) VALUES
('school-1', 'district-1', 'Springfield Elementary', 'ELEM-01', 'Springfield', 'IL', ARRAY['K', '1', '2', '3', '4', '5']),
('school-2', 'district-1', 'Springfield Middle School', 'MID-01', 'Springfield', 'IL', ARRAY['6', '7', '8']),
('school-3', 'district-1', 'Springfield High School', 'HIGH-01', 'Springfield', 'IL', ARRAY['9', '10', '11', '12']);

-- Link existing classrooms to a school (update with actual classroom IDs)
-- UPDATE classrooms SET school_id = 'school-1' WHERE id IN ('your-classroom-ids');
*/

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT ALL ON districts TO authenticated;
GRANT ALL ON schools TO authenticated;
GRANT EXECUTE ON FUNCTION is_school_admin TO authenticated;
GRANT EXECUTE ON FUNCTION is_district_admin TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_admin_scope TO authenticated;
