//
//  ParentDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Main dashboard for parents using Supabase
//

import SwiftUI

struct ParentDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService

    // Create view models for child views
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var classroomViewModel = ClassroomViewModel()
    @StateObject private var storyViewModel = StoryViewModel()
    @StateObject private var messageViewModel = MessageViewModel()
    @StateObject private var pointsViewModel = PointsViewModel()

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Stories/Feed Tab
            StoriesView()
                .tabItem {
                    Label("Feed", systemImage: "house.fill")
                }
                .tag(0)

            // Messages Tab
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .tag(1)

            // My Child Tab
            ParentChildView()
                .tabItem {
                    Label("My Child", systemImage: "star.fill")
                }
                .tag(2)

            // Settings Tab
            ParentSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .environmentObject(authViewModel)
        .environmentObject(classroomViewModel)
        .environmentObject(storyViewModel)
        .environmentObject(messageViewModel)
        .environmentObject(pointsViewModel)
        .onAppear {
            setupParentData()
        }
    }

    private func setupParentData() {
        guard let appUser = authService.appUser else { return }

        // Sync auth state from AuthenticationService to AuthViewModel
        let user = User(
            id: appUser.id,
            email: appUser.email,
            name: appUser.name,
            displayName: appUser.name,
            role: appUser.role
        )
        authViewModel.currentUser = user
        authViewModel.isAuthenticated = true

        // Load classrooms for this parent
        Task {
            await classroomViewModel.loadClassrooms(for: user)

            // After classrooms load, load stories for the selected classroom
            if let classId = classroomViewModel.selectedClassroom?.id {
                storyViewModel.listenToStories(classId: classId)
            }
        }

        // Load conversations for this parent
        messageViewModel.listenToConversations(userId: appUser.id, role: .parent)
    }
}

// MARK: - Parent Child View (Points & Info)
struct ParentChildView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var pointsViewModel: PointsViewModel
    @State private var showingLinkChild = false

    var body: some View {
        NavigationView {
            content
        }
        .sheet(isPresented: $showingLinkChild) {
            JoinClassView()
                .environmentObject(authViewModel)
                .environmentObject(classroomViewModel)
                .environmentObject(authService)
        }
    }

    @ViewBuilder
    private var content: some View {
        if classroomViewModel.classrooms.isEmpty {
            noClassView
        } else if linkedStudents.isEmpty {
            noChildLinkedView
        } else if linkedStudents.count == 1 {
            // Single child - show details directly
            StudentDetailForParent(student: linkedStudents[0], isRootView: true)
                .environmentObject(classroomViewModel)
        } else {
            // Multiple children - show selector
            childrenListView
        }
    }

    private var noClassView: some View {
        VStack(spacing: 20) {
            Image(systemName: "backpack.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("No Class Joined")
                .font(.title2.bold())

            Text("Join your child's class to see their points and updates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingLinkChild = true
            } label: {
                Label("Join Class or Link Child", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .navigationTitle("My Child")
    }

    private var childrenListView: some View {
        List {
            ForEach(linkedStudents, id: \.id) { student in
                Section {
                    NavigationLink {
                        StudentDetailForParent(student: student)
                            .environmentObject(classroomViewModel)
                    } label: {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(colorForStudent(student).gradient)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(student.firstName.prefix(1))
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(student.fullName)
                                    .font(.headline)

                                if let classroom = classroomForStudent(student) {
                                    Text(classroom.name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("My Children")
    }

    private var noChildLinkedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("No Child Linked")
                .font(.title2.bold())

            Text("Ask your child's teacher for a student invite code to link your account.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingLinkChild = true
            } label: {
                Label("Link My Child", systemImage: "link.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .navigationTitle("My Child")
    }

    private var linkedStudents: [Student] {
        guard let userId = authService.appUser?.id else { return [] }
        return classroomViewModel.students.filter { student in
            student.parentIds.contains(userId)
        }
    }

    private func classroomForStudent(_ student: Student) -> Classroom? {
        classroomViewModel.classrooms.first { $0.id == student.classId }
    }

    private func colorForStudent(_ student: Student) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
        let index = abs(student.firstName.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Student Detail View for Parents
struct StudentDetailForParent: View {
    let student: Student
    var isRootView: Bool = false
    @EnvironmentObject var classroomViewModel: ClassroomViewModel

    var body: some View {
        List {
            // Student Header
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(student.firstName.prefix(1))
                                .font(.title.bold())
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(student.fullName)
                            .font(.title3.bold())

                        if let classroom = classroomForStudent {
                            Text(classroom.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }

            // Points Summary
            Section("Points") {
                HStack {
                    Label("View Points History", systemImage: "star.fill")
                        .foregroundColor(.orange)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Classroom Info
            if let classroom = classroomForStudent {
                Section("Classroom") {
                    HStack {
                        Label("Class", systemImage: "book.fill")
                        Spacer()
                        Text(classroom.name)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Grade", systemImage: "graduationcap.fill")
                        Spacer()
                        Text(classroom.gradeLevel)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Teacher", systemImage: "person.fill")
                        Spacer()
                        Text(classroom.teacherName)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle(isRootView ? "My Child" : student.firstName)
        .navigationBarTitleDisplayMode(isRootView ? .large : .inline)
    }

    private var classroomForStudent: Classroom? {
        classroomViewModel.classrooms.first { $0.id == student.classId }
    }
}

// MARK: - Parent Settings View
struct ParentSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @State private var showingJoinClass = false

    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.green.gradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(authService.currentUserName.prefix(1).uppercased())
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(authService.currentUserName)
                                .font(.headline)
                            Text(authService.appUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Classroom Section
                Section("My Classes") {
                    if classroomViewModel.classrooms.isEmpty {
                        Text("No classes joined yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(classroomViewModel.classrooms, id: \.uniqueId) { classroom in
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Text(classroom.name.prefix(1))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(classroom.name)
                                        .font(.headline)
                                    Text(classroom.gradeLevel)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if classroom.id == classroomViewModel.selectedClassroom?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }

                    Button {
                        showingJoinClass = true
                    } label: {
                        Label("Join a Class", systemImage: "plus.circle.fill")
                    }
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        authService.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingJoinClass) {
                JoinClassView()
                    .environmentObject(authViewModel)
                    .environmentObject(classroomViewModel)
                    .environmentObject(authService)
            }
        }
    }
}

#Preview {
    ParentDashboardView()
        .environmentObject(AuthenticationService())
}
