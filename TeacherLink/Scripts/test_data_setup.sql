-- Test Data Setup Script for iOS Admin Views
-- Run this in your Supabase SQL Editor

-- =====================================================
-- 1. Create Test District
-- =====================================================
INSERT INTO districts (id, name, code, city, state, admin_ids)
VALUES (
  'test-district-001',
  'Springfield Unified School District',
  'SPRINGFIELD-USD',
  'Springfield',
  'IL',
  '{}'
)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  code = EXCLUDED.code,
  city = EXCLUDED.city,
  state = EXCLUDED.state;

-- =====================================================
-- 2. Create Test Schools
-- =====================================================
INSERT INTO schools (id, district_id, name, code, city, state, grade_levels)
VALUES
  (
    'test-school-elem-001',
    'test-district-001',
    'Springfield Elementary',
    'ELEM-01',
    'Springfield',
    'IL',
    ARRAY['K', '1', '2', '3', '4', '5']
  ),
  (
    'test-school-middle-001',
    'test-district-001',
    'Springfield Middle School',
    'MIDDLE-01',
    'Springfield',
    'IL',
    ARRAY['6', '7', '8']
  )
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  code = EXCLUDED.code,
  grade_levels = EXCLUDED.grade_levels;

-- =====================================================
-- 3. Create Test User Accounts
-- NOTE: You need to create these users in Supabase Auth first
-- using the Authentication > Users section, then run this
-- to update their profiles with admin roles.
-- =====================================================

-- District Admin Account
-- Email: district@test.com (create in Auth first)
-- UPDATE users SET
--   role = 'admin',
--   admin_level = 'district_admin',
--   district_id = 'test-district-001'
-- WHERE email = 'district@test.com';

-- Principal Account
-- Email: principal@test.com (create in Auth first)
-- UPDATE users SET
--   role = 'admin',
--   admin_level = 'principal',
--   district_id = 'test-district-001',
--   school_id = 'test-school-elem-001'
-- WHERE email = 'principal@test.com';

-- =====================================================
-- Verification Queries
-- =====================================================

-- Check district was created
SELECT * FROM districts WHERE id = 'test-district-001';

-- Check schools were created
SELECT * FROM schools WHERE district_id = 'test-district-001';

-- Check admin users
SELECT id, email, name, role, admin_level, district_id, school_id
FROM users
WHERE admin_level IN ('district_admin', 'principal', 'super_admin');
