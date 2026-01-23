import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST() {
  const supabase = await createClient()

  // Check if user is authenticated and is super_admin
  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({
      error: 'Not authenticated',
      debug: { authError: authError?.message }
    }, { status: 401 })
  }

  const { data: userData, error: userError } = await supabase
    .from('users')
    .select('id, email, admin_level')
    .eq('id', user.id)
    .single()

  if (userError || userData?.admin_level !== 'super_admin') {
    return NextResponse.json({
      error: 'Not authorized - super_admin required',
      debug: {
        userId: user.id,
        userEmail: user.email,
        userData,
        userError: userError?.message
      }
    }, { status: 403 })
  }

  try {
    // Check if test district already exists
    const { data: existingDistrict } = await supabase
      .from('districts')
      .select('id')
      .eq('code', 'SPRINGFIELD-USD')
      .single()

    let districtId = existingDistrict?.id

    if (!districtId) {
      // Create test district
      const { data: district, error: districtError } = await supabase
        .from('districts')
        .insert({
          name: 'Springfield Unified School District',
          code: 'SPRINGFIELD-USD',
          city: 'Springfield',
          state: 'IL',
          address: '100 Main Street',
          phone: '(555) 123-4567',
          admin_ids: [user.id]
        })
        .select()
        .single()

      if (districtError) {
        console.error('District creation error:', districtError)
        return NextResponse.json({
          error: `Failed to create district: ${districtError.message}`,
          debug: { code: districtError.code, details: districtError.details, hint: districtError.hint }
        }, { status: 500 })
      }

      if (!district) {
        return NextResponse.json({
          error: 'District insert returned no data - likely blocked by RLS policy',
          debug: { userId: user.id, adminLevel: userData?.admin_level }
        }, { status: 500 })
      }

      districtId = district.id
    }

    // Check if test schools already exist
    const { data: existingSchools } = await supabase
      .from('schools')
      .select('id, code')
      .eq('district_id', districtId)

    const existingCodes = existingSchools?.map(s => s.code) || []

    const schoolsToCreate = [
      {
        district_id: districtId,
        name: 'Springfield Elementary',
        code: 'ELEM-01',
        city: 'Springfield',
        state: 'IL',
        address: '200 Oak Avenue',
        grade_levels: ['K', '1', '2', '3', '4', '5'],
        admin_ids: [user.id]
      },
      {
        district_id: districtId,
        name: 'Springfield Middle School',
        code: 'MID-01',
        city: 'Springfield',
        state: 'IL',
        address: '300 Maple Street',
        grade_levels: ['6', '7', '8'],
        admin_ids: [user.id]
      },
      {
        district_id: districtId,
        name: 'Springfield High School',
        code: 'HIGH-01',
        city: 'Springfield',
        state: 'IL',
        address: '400 Pine Road',
        grade_levels: ['9', '10', '11', '12'],
        admin_ids: [user.id]
      }
    ].filter(school => !existingCodes.includes(school.code))

    let createdSchools = []
    if (schoolsToCreate.length > 0) {
      const { data: schools, error: schoolsError } = await supabase
        .from('schools')
        .insert(schoolsToCreate)
        .select()

      if (schoolsError) {
        console.error('Schools creation error:', schoolsError)
        return NextResponse.json({ error: `Failed to create schools: ${schoolsError.message}` }, { status: 500 })
      }

      createdSchools = schools || []
    }

    // Fetch all schools for the district
    const { data: allSchools } = await supabase
      .from('schools')
      .select('*')
      .eq('district_id', districtId)

    return NextResponse.json({
      success: true,
      message: 'Test data created successfully',
      district: {
        id: districtId,
        name: 'Springfield Unified School District',
        code: 'SPRINGFIELD-USD'
      },
      schools: allSchools,
      created: {
        district: !existingDistrict,
        schools: createdSchools.length
      }
    })

  } catch (error) {
    console.error('Seed error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
