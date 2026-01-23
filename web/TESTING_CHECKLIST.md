# Hall Pass Testing Checklist

## Quick Links
- **Web App**: https://hallpassedu.com
- **Sentry Dashboard**: https://dataday-technology-solutions.sentry.io
- **Supabase Dashboard**: https://supabase.com/dashboard

---

## 🔐 Authentication Tests

### Sign Up (Web)
- [ ] Teacher signup flow works
- [ ] Parent signup flow works
- [ ] Email validation works (reject invalid emails)
- [ ] Password requirements enforced (min 6 chars)
- [ ] Confirm password match validation
- [ ] Error messages display correctly
- [ ] Redirects to dashboard after signup
- [ ] User created in Supabase `users` table with correct role

### Sign Up (iOS)
- [ ] Teacher signup flow works
- [ ] Parent signup flow works
- [ ] Same validations as web
- [ ] User appears in Supabase

### Login (Web)
- [ ] Login with valid credentials works
- [ ] Login with invalid email shows error
- [ ] Login with wrong password shows error
- [ ] Redirects to dashboard after login
- [ ] Session persists on page refresh
- [ ] Logout works and redirects to login

### Login (iOS)
- [ ] Login with valid credentials works
- [ ] Error handling for invalid credentials
- [ ] Session persists when app reopens

### Password Reset
- [ ] "Forgot password" link works
- [ ] Reset email is received (check spam)
- [ ] Reset link works and allows password change
- [ ] Can login with new password

---

## 👨‍🏫 Teacher Features

### Classroom Management (Web)
- [ ] Create new classroom with name and grade level
- [ ] Class code is auto-generated
- [ ] QR code displays for class code
- [ ] View list of classrooms
- [ ] Switch between classrooms (sidebar dropdown)
- [ ] Edit classroom details
- [ ] Delete classroom (if empty)

### Classroom Management (iOS)
- [ ] Create classroom works
- [ ] Same classroom appears on web
- [ ] Class code generation works
- [ ] QR code scanner works for parent joining

### Student Management (Web)
- [ ] Add student to classroom
- [ ] Student appears in classroom list
- [ ] Edit student details
- [ ] Remove student from classroom
- [ ] Bulk student import (if available)

### Student Management (iOS)
- [ ] Add student works
- [ ] Student syncs to web
- [ ] Edit/remove works

---

## 👪 Parent Features

### Joining Classroom (Web)
- [ ] Join via class code URL (/join/CODE)
- [ ] Select child from student list
- [ ] Confirmation shown after joining
- [ ] Classroom appears in parent dashboard

### Joining Classroom (iOS)
- [ ] Join via class code entry
- [ ] Join via QR code scan
- [ ] Child selection works
- [ ] Classroom syncs

---

## 💬 Messaging

### Conversations (Web)
- [ ] View list of conversations
- [ ] Start new conversation (teacher→parent or parent→teacher)
- [ ] Send text message
- [ ] Messages appear in real-time (no refresh needed)
- [ ] Read receipts work
- [ ] Unread badge shows on sidebar
- [ ] Notification when new message received

### Conversations (iOS)
- [ ] Same conversation list as web
- [ ] Send message from iOS, appears on web
- [ ] Send message from web, appears on iOS
- [ ] Real-time sync works
- [ ] Push notifications work (if configured)

---

## ⭐ Points/Behavior

### Awarding Points (Web)
- [ ] View student point totals
- [ ] Award positive points
- [ ] Deduct points
- [ ] Points reason/behavior selection
- [ ] Points appear in history
- [ ] Total updates in real-time

### Awarding Points (iOS)
- [ ] Award points works
- [ ] Syncs to web immediately
- [ ] Parent can view child's points

### Parent View
- [ ] Parent sees child's point total
- [ ] Parent sees point history
- [ ] Real-time updates when teacher awards points

---

## 📖 Stories/Feed

### Creating Stories (Web)
- [ ] Create text story
- [ ] Create story with image upload
- [ ] Story appears in feed
- [ ] Story has timestamp

### Creating Stories (iOS)
- [ ] Create story from iOS
- [ ] Story appears on web

### Viewing Stories
- [ ] Stories appear in chronological order
- [ ] Parent can view classroom stories
- [ ] Like/comment on stories (if available)
- [ ] Real-time updates

---

## 🛡️ Admin Features

### Super Admin Dashboard
- [ ] View all districts
- [ ] View all schools
- [ ] View all teachers/classrooms/students counts
- [ ] Seed test data button works

### District Admin
- [ ] View schools in district
- [ ] View stats for district

### School Admin/Principal
- [ ] View classrooms in school
- [ ] View teacher and student counts

---

## 🔄 Cross-Platform Sync Tests

### Data Sync
- [ ] Create classroom on web → appears on iOS
- [ ] Create classroom on iOS → appears on web
- [ ] Add student on web → appears on iOS
- [ ] Add student on iOS → appears on web
- [ ] Send message on web → appears on iOS (real-time)
- [ ] Send message on iOS → appears on web (real-time)
- [ ] Award points on web → appears on iOS (real-time)
- [ ] Award points on iOS → appears on web (real-time)
- [ ] Create story on web → appears on iOS
- [ ] Create story on iOS → appears on web

### Session Sync
- [ ] Login on web, user data same as iOS
- [ ] Changes on one platform reflect on other after refresh

---

## 🚨 Error Handling Tests

### Network Errors
- [ ] Offline mode shows appropriate message
- [ ] Reconnection recovery works
- [ ] API timeout shows error toast

### Validation Errors
- [ ] Form validation errors display clearly
- [ ] Backend validation errors display

### Sentry Integration
- [ ] Throw test error → appears in Sentry dashboard
- [ ] Error includes user context
- [ ] Error includes stack trace

---

## 📱 Responsive/UI Tests

### Web Responsive
- [ ] Login page looks good on mobile
- [ ] Dashboard works on mobile
- [ ] Sidebar collapses on mobile
- [ ] All features accessible on mobile

### iOS UI
- [ ] All screens render properly
- [ ] No layout issues
- [ ] Dark mode support (if available)

---

## 🔒 Security Tests

### Authentication
- [ ] Protected routes redirect to login if not authenticated
- [ ] Auth pages redirect to dashboard if authenticated
- [ ] Session timeout works correctly
- [ ] Cannot access other users' data

### Authorization
- [ ] Teachers can only see their classrooms
- [ ] Parents can only see joined classrooms
- [ ] Admins have appropriate access levels

---

## ⚡ Performance Tests

### Load Time
- [ ] Login page loads in < 3 seconds
- [ ] Dashboard loads in < 3 seconds
- [ ] Real-time updates feel instant

### Scalability
- [ ] Works with 50+ students in classroom
- [ ] Works with 100+ messages in conversation
- [ ] Works with 50+ stories in feed

---

## 📋 Test Accounts

Create these test accounts for testing:

| Role | Email | Password | Notes |
|------|-------|----------|-------|
| Teacher | teacher@test.com | test1234 | Has 1 classroom |
| Parent | parent@test.com | test1234 | Joined teacher's class |
| Super Admin | adamlnewell@gmail.com | (existing) | Full admin access |

---

## 🐛 Known Issues to Fix

_Add issues discovered during testing here:_

1.
2.
3.

---

## ✅ Sign-Off

- [ ] All critical features tested
- [ ] No blocking bugs
- [ ] Ready for demo

**Tested by:** ________________
**Date:** ________________
