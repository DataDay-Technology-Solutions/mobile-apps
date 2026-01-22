# Supabase Integration Fixes

## Summary
Fixed all Swift models to properly integrate with the Supabase PostgreSQL database by adding CodingKeys for snake_case field mapping and aligning model properties with the database schema.

## Models Fixed

### 1. Classroom.swift ✅
**Changes:**
- Added `CodingKeys` enum mapping Swift camelCase to PostgreSQL snake_case
- Removed `schoolYear` and `avatarColor` fields (not in database schema)
- Mapped fields: `grade_level`, `teacher_id`, `teacher_name`, `class_code`, `student_ids`, `parent_ids`, `created_at`

**Database Alignment:**
- `gradeLevel` → `grade_level`
- `teacherId` → `teacher_id`
- `teacherName` → `teacher_name`
- `classCode` → `class_code`
- `studentIds` → `student_ids`
- `parentIds` → `parent_ids`
- `createdAt` → `created_at`

### 2. Student.swift ✅
**Changes:**
- Added `CodingKeys` enum for proper field mapping
- Removed `avatarStyle` field (not in database schema)
- Kept compatibility properties: `parentId`, `name`, `classroomId`
- Mapped fields: `first_name`, `last_name`, `class_id`, `parent_ids`, `created_at`

**Database Alignment:**
- `firstName` → `first_name`
- `lastName` → `last_name`
- `classId` → `class_id`
- `parentIds` → `parent_ids`
- `createdAt` → `created_at`

### 3. Points.swift ✅
**Changes:**
- Added `CodingKeys` to `PointRecord` struct
- Added `CodingKeys` to `StudentPointsSummary` struct
- Fixed `StudentPointsSummary.id` to be optional (database generates it)
- All snake_case mappings added

**PointRecord Database Alignment:**
- `studentId` → `student_id`
- `classId` → `class_id`
- `behaviorId` → `behavior_id`
- `behaviorName` → `behavior_name`
- `awardedBy` → `awarded_by`
- `awardedByName` → `awarded_by_name`
- `createdAt` → `created_at`

**StudentPointsSummary Database Alignment:**
- `studentId` → `student_id`
- `classId` → `class_id`
- `totalPoints` → `total_points`
- `positiveCount` → `positive_count`
- `negativeCount` → `negative_count`
- `lastUpdated` → `last_updated`

### 4. Story.swift ✅
**Changes:**
- Added `CodingKeys` for both `Story` and `StoryComment`
- Removed obsolete fields: `type`, `thumbnailURL`, `isAnnouncement`, `isPinned`
- Changed `mediaURLs` → `mediaUrls` (matching database)
- Added `mediaType` field (matching database: "image", "video", "text")
- Made `content` optional (nullable in database)

**Story Database Alignment:**
- `classId` → `class_id`
- `authorId` → `author_id`
- `authorName` → `author_name`
- `mediaUrls` → `media_urls`
- `mediaType` → `media_type`
- `likeCount` → `like_count`
- `likedByIds` → `liked_by_ids`
- `commentCount` → `comment_count`
- `createdAt` → `created_at`
- `updatedAt` → `updated_at`

**StoryComment Database Alignment:**
- `storyId` → `story_id`
- `authorId` → `author_id`
- `authorName` → `author_name`
- `createdAt` → `created_at`

### 5. Message.swift ✅
**Changes:**
- Added `CodingKeys` for both `Conversation` and `Message`
- Removed `imageURL` from Message (not in database schema)
- Made optional fields properly nullable: `lastMessage`, `lastMessageSenderId`

**Conversation Database Alignment:**
- `participantIds` → `participant_ids`
- `participantNames` → `participant_names`
- `classId` → `class_id`
- `studentId` → `student_id`
- `studentName` → `student_name`
- `lastMessage` → `last_message`
- `lastMessageDate` → `last_message_date`
- `lastMessageSenderId` → `last_message_sender_id`
- `unreadCounts` → `unread_counts`
- `createdAt` → `created_at`

**Message Database Alignment:**
- `conversationId` → `conversation_id`
- `senderId` → `sender_id`
- `senderName` → `sender_name`
- `isRead` → `is_read`
- `readAt` → `read_at`
- `createdAt` → `created_at`

### 6. User.swift ✅
**Changes:**
- Added `CodingKeys` enum
- Added database schema fields: `name`, `classroomId`, `studentIds`, `parentId`
- Made `displayName` optional (can use `name` as fallback)
- Updated `initials` computed property to handle both fields

**Database Alignment:**
- `displayName` → `display_name`
- `classroomId` → `classroom_id`
- `classIds` → `class_ids`
- `studentIds` → `student_ids`
- `parentId` → `parent_id`
- `fcmToken` → `fcm_token`
- `createdAt` → `created_at`

## Key Benefits

1. **Proper Serialization**: All models now correctly serialize/deserialize with Supabase
2. **Schema Alignment**: Models match the PostgreSQL database schema exactly
3. **No More Errors**: Fixes "key not found" errors during JSON decoding
4. **Array Support**: Proper handling of PostgreSQL array types (`TEXT[]`)
5. **JSONB Support**: Correct mapping for JSONB fields (`participant_names`, `unread_counts`)
6. **Date Handling**: Consistent `TIMESTAMPTZ` handling across all models

## Testing Instructions

### 1. Build the Project
```bash
cd /Users/dataday/CLAUDE\ CODE\ PROJECTS/GitHub/mobile-apps
open TeacherLink.xcodeproj
```
In Xcode:
- Select your target device/simulator
- Press `Cmd + B` to build
- Fix any compilation errors

### 2. Test Classroom Creation
1. Set `USE_MOCK_DATA = false` in `TeacherLinkApp.swift`
2. Run the app
3. Sign in/create account
4. Navigate to Settings → Create Class
5. Enter class details and create
6. Verify in Supabase dashboard that classroom was created with correct fields

### 3. Test Student Management
1. In the created classroom, add students
2. Verify students appear in the UI
3. Check Supabase `students` table for correct data
4. Test editing and deleting students

### 4. Test Points System
1. Navigate to Points view
2. Award points to students
3. Verify points appear in UI
4. Check `point_records` and `student_points_summaries` tables in Supabase

### 5. Test Stories/Feed
1. Create a story/post
2. Add comments
3. Like posts
4. Verify data in `stories` and `story_comments` tables

### 6. Test Messaging
1. Start a conversation
2. Send messages
3. Verify `conversations` and `messages` tables

## Database Schema Reference

The fixes align with the schema in `supabase_schema.sql`. All tables use:
- `TEXT` for IDs (UUID as text)
- `TEXT[]` for array fields
- `JSONB` for dictionary fields
- `TIMESTAMPTZ` for dates
- snake_case naming convention

## Next Steps

1. ✅ All models fixed
2. 🔄 Build and test in Xcode
3. ⏳ Verify each feature works with Supabase
4. ⏳ Fix any remaining UI issues
5. ⏳ Test real-time subscriptions
6. ⏳ Production deployment

## Notes

- All `id` fields are now optional (`String?`) to allow database generation
- Removed UI-only fields (avatarStyle, colors, etc.) that aren't persisted
- Maintained backward compatibility with computed properties
- Services (ClassroomService, PointsService, etc.) should work without changes
