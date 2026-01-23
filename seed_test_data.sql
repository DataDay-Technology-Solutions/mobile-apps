-- ============================================
-- HallPass Test Data Seed
-- Run this in Supabase SQL Editor
-- ============================================

-- Create test district
INSERT INTO districts (id, name, code, city, state, address, phone, admin_ids)
VALUES (
    'district-springfield',
    'Springfield Unified School District',
    'SPRINGFIELD-USD',
    'Springfield',
    'IL',
    '100 Main Street',
    '(555) 123-4567',
    ARRAY['5966af64-c403-43fc-9715-e61c90990b8b', '1efa5d25-a045-428b-a13f-400b7201cf18']
)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    address = EXCLUDED.address,
    phone = EXCLUDED.phone,
    admin_ids = EXCLUDED.admin_ids;

-- Create test schools
INSERT INTO schools (id, district_id, name, code, city, state, address, grade_levels, admin_ids)
VALUES
    (
        'school-elem-01',
        'district-springfield',
        'Springfield Elementary',
        'ELEM-01',
        'Springfield',
        'IL',
        '200 Oak Avenue',
        ARRAY['K', '1', '2', '3', '4', '5'],
        ARRAY['5966af64-c403-43fc-9715-e61c90990b8b']
    ),
    (
        'school-mid-01',
        'district-springfield',
        'Springfield Middle School',
        'MID-01',
        'Springfield',
        'IL',
        '300 Maple Street',
        ARRAY['6', '7', '8'],
        ARRAY['5966af64-c403-43fc-9715-e61c90990b8b']
    ),
    (
        'school-high-01',
        'district-springfield',
        'Springfield High School',
        'HIGH-01',
        'Springfield',
        'IL',
        '400 Pine Road',
        ARRAY['9', '10', '11', '12'],
        ARRAY['5966af64-c403-43fc-9715-e61c90990b8b']
    )
ON CONFLICT (district_id, code) DO UPDATE SET
    name = EXCLUDED.name,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    address = EXCLUDED.address,
    grade_levels = EXCLUDED.grade_levels,
    admin_ids = EXCLUDED.admin_ids;

-- Verify the data
SELECT 'Districts:' as info;
SELECT id, name, code, city, state FROM districts;

SELECT 'Schools:' as info;
SELECT id, district_id, name, code, city FROM schools;
