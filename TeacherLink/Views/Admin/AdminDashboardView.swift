//
//  AdminDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Super Admin dashboard for managing the entire system
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        TabView {
            // Overview Tab
            AdminOverviewView()
                .environmentObject(authService)
                .tabItem {
                    Label("Overview", systemImage: "chart.bar")
                }

            // Users Management Tab
            AdminUsersView()
                .tabItem {
                    Label("Users", systemImage: "person.3")
                }

            // Classrooms Tab
            AdminClassroomsView()
                .tabItem {
                    Label("Classes", systemImage: "building.2")
                }

            // Settings Tab
            AdminSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

// MARK: - Admin Overview View
struct AdminOverviewView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel = AdminViewModel()
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Users",
                            value: "\(viewModel.totalUsers)",
                            icon: "person.3.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Teachers",
                            value: "\(viewModel.totalTeachers)",
                            icon: "person.fill",
                            color: .green
                        )

                        StatCard(
                            title: "Parents",
                            value: "\(viewModel.totalParents)",
                            icon: "figure.2.and.child.holdinghands",
                            color: .orange
                        )

                        StatCard(
                            title: "Classrooms",
                            value: "\(viewModel.totalClassrooms)",
                            icon: "building.2.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.recentActivity.isEmpty {
                            Text("No recent activity")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(viewModel.recentActivity, id: \.id) { activity in
                                AdminActivityRow(activity: activity)
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("Admin Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                Task {
                    await viewModel.loadStats()
                }
            }
            .refreshable {
                await viewModel.loadStats()
            }
        }
    }
}

// MARK: - Admin Users View
struct AdminUsersView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var searchText = ""
    @State private var selectedRole: UserRole? = nil
    @State private var showingAddUser = false

    var filteredUsers: [AppUser] {
        var users = viewModel.users

        if let role = selectedRole {
            users = users.filter { $0.role == role }
        }

        if !searchText.isEmpty {
            users = users.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }

        return users
    }

    var body: some View {
        NavigationView {
            List {
                // Filter Section
                Section {
                    Picker("Filter by Role", selection: $selectedRole) {
                        Text("All Users").tag(nil as UserRole?)
                        Text("Admins").tag(UserRole.admin as UserRole?)
                        Text("Teachers").tag(UserRole.teacher as UserRole?)
                        Text("Parents").tag(UserRole.parent as UserRole?)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Users List
                Section {
                    ForEach(filteredUsers, id: \.id) { user in
                        NavigationLink {
                            AdminUserDetailView(user: user, viewModel: viewModel)
                        } label: {
                            UserRow(user: user)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search users...")
            .navigationTitle("Manage Users")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddUser = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddAdminUserView(viewModel: viewModel)
            }
            .onAppear {
                Task {
                    await viewModel.loadUsers()
                }
            }
        }
    }
}

// MARK: - Admin Classrooms View
struct AdminClassroomsView: View {
    @StateObject private var viewModel = AdminViewModel()
    @State private var searchText = ""

    var filteredClassrooms: [Classroom] {
        if searchText.isEmpty {
            return viewModel.classrooms
        }
        return viewModel.classrooms.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.teacherName.localizedCaseInsensitiveContains(searchText) ||
            $0.classCode.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredClassrooms, id: \.id) { classroom in
                    NavigationLink {
                        AdminClassroomDetailView(classroom: classroom, viewModel: viewModel)
                    } label: {
                        AdminClassroomRow(classroom: classroom)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search classrooms...")
            .navigationTitle("Manage Classrooms")
            .onAppear {
                Task {
                    await viewModel.loadClassrooms()
                }
            }
        }
    }
}

// MARK: - Admin Settings View
struct AdminSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "shield.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)

                        VStack(alignment: .leading) {
                            Text(authService.currentUserName)
                                .font(.headline)
                            Text("Super Admin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("System") {
                    NavigationLink {
                        AdminSystemLogsView()
                    } label: {
                        Label("System Logs", systemImage: "doc.text")
                    }

                    NavigationLink {
                        AdminDatabaseView()
                    } label: {
                        Label("Database", systemImage: "cylinder")
                    }
                }

                Section {
                    Button(action: {
                        authService.signOut()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Admin Settings")
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct UserRow: View {
    let user: AppUser

    var roleColor: Color {
        switch user.role {
        case .admin: return .red
        case .teacher: return .blue
        case .parent: return .green
        case .student: return .orange
        }
    }

    var body: some View {
        HStack {
            Circle()
                .fill(roleColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.name.prefix(1)).uppercased())
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )

            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(user.role.rawValue.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(roleColor.opacity(0.2))
                .foregroundColor(roleColor)
                .cornerRadius(8)
        }
    }
}

struct AdminClassroomRow: View {
    let classroom: Classroom

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(classroom.name)
                .font(.headline)

            HStack {
                Text(classroom.teacherName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Code: \(classroom.classCode)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdminActivityRow: View {
    let activity: AdminActivity

    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(activity.color)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(activity.title)
                    .font(.subheadline)
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Detail Views

struct AdminUserDetailView: View {
    let user: AppUser
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingDeleteAlert = false
    @State private var selectedRole: UserRole

    init(user: AppUser, viewModel: AdminViewModel) {
        self.user = user
        self.viewModel = viewModel
        self._selectedRole = State(initialValue: user.role)
    }

    var body: some View {
        List {
            Section("User Information") {
                LabeledContent("Name", value: user.name)
                LabeledContent("Email", value: user.email)
                LabeledContent("ID", value: user.id)
            }

            Section("Role") {
                Picker("Role", selection: $selectedRole) {
                    Text("Admin").tag(UserRole.admin)
                    Text("Teacher").tag(UserRole.teacher)
                    Text("Parent").tag(UserRole.parent)
                    Text("Student").tag(UserRole.student)
                }
                .pickerStyle(SegmentedPickerStyle())

                if selectedRole != user.role {
                    Button("Save Role Change") {
                        Task {
                            await viewModel.updateUserRole(userId: user.id, newRole: selectedRole)
                        }
                    }
                    .foregroundColor(.blue)
                }
            }

            Section {
                Button("Delete User", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle(user.name)
        .alert("Delete User?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUser(userId: user.id)
                }
            }
        } message: {
            Text("This action cannot be undone. All data associated with this user will be deleted.")
        }
    }
}

struct AdminClassroomDetailView: View {
    let classroom: Classroom
    @ObservedObject var viewModel: AdminViewModel
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section("Classroom Information") {
                LabeledContent("Name", value: classroom.name)
                LabeledContent("Grade", value: classroom.gradeLevel)
                LabeledContent("Class Code", value: classroom.classCode)
                LabeledContent("Teacher", value: classroom.teacherName)
            }

            Section("Statistics") {
                LabeledContent("Students", value: "\(classroom.studentIds.count)")
                LabeledContent("Parents", value: "\(classroom.parentIds.count)")
            }

            Section {
                Button("Delete Classroom", role: .destructive) {
                    showingDeleteAlert = true
                }
            }
        }
        .navigationTitle(classroom.name)
        .alert("Delete Classroom?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    if let id = classroom.id {
                        await viewModel.deleteClassroom(classroomId: id)
                    }
                }
            }
        } message: {
            Text("This action cannot be undone. All data associated with this classroom will be deleted.")
        }
    }
}

struct AddAdminUserView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: AdminViewModel

    @State private var email = ""
    @State private var name = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .teacher

    var body: some View {
        NavigationView {
            Form {
                Section("User Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }

                Section("Role") {
                    Picker("Role", selection: $selectedRole) {
                        Text("Admin").tag(UserRole.admin)
                        Text("Teacher").tag(UserRole.teacher)
                        Text("Parent").tag(UserRole.parent)
                    }
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createUser(
                                email: email,
                                name: name,
                                password: password,
                                role: selectedRole
                            )
                            dismiss()
                        }
                    }
                    .disabled(email.isEmpty || name.isEmpty || password.count < 6)
                }
            }
        }
    }
}

struct AdminSystemLogsView: View {
    var body: some View {
        List {
            Text("System logs will be displayed here")
                .foregroundColor(.secondary)
        }
        .navigationTitle("System Logs")
    }
}

struct AdminDatabaseView: View {
    var body: some View {
        List {
            Section("Tables") {
                LabeledContent("users", value: "View")
                LabeledContent("classrooms", value: "View")
                LabeledContent("students", value: "View")
                LabeledContent("hall_passes", value: "View")
                LabeledContent("stories", value: "View")
                LabeledContent("messages", value: "View")
            }
        }
        .navigationTitle("Database")
    }
}

// MARK: - Admin Activity Model

struct AdminActivity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let timestamp: Date
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthenticationService())
}
