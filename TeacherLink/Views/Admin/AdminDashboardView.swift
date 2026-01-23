//
//  AdminDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Super Admin dashboard for managing the entire system
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            AdminOverviewView()
                .environmentObject(authService)
                .tabItem {
                    Label("Overview", systemImage: "chart.bar.fill")
                }
                .tag(0)

            // Users Management Tab
            AdminUsersView()
                .tabItem {
                    Label("Users", systemImage: "person.3.fill")
                }
                .tag(1)

            // Classrooms Tab
            AdminClassroomsView()
                .tabItem {
                    Label("Classes", systemImage: "building.2.fill")
                }
                .tag(2)

            // Settings Tab
            AdminSettingsView()
                .environmentObject(authService)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.red)
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
    @State private var showingViewAs = false
    @State private var selectedPreviewRole: PreviewRole?

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

                Section("View As (Preview Mode)") {
                    Button {
                        selectedPreviewRole = .districtAdmin
                    } label: {
                        Label("District Admin View", systemImage: "building.2.fill")
                            .foregroundColor(.purple)
                    }

                    Button {
                        selectedPreviewRole = .principal
                    } label: {
                        Label("Principal View", systemImage: "building.fill")
                            .foregroundColor(.blue)
                    }

                    Button {
                        selectedPreviewRole = .teacher
                    } label: {
                        Label("Teacher View", systemImage: "person.fill")
                            .foregroundColor(.green)
                    }

                    Button {
                        selectedPreviewRole = .parent
                    } label: {
                        Label("Parent View", systemImage: "figure.2.and.child.holdinghands")
                            .foregroundColor(.orange)
                    }
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
            .fullScreenCover(item: $selectedPreviewRole) { role in
                AdminPreviewView(role: role)
                    .environmentObject(authService)
            }
        }
    }
}

// MARK: - Preview Role
enum PreviewRole: String, Identifiable {
    case districtAdmin = "District Admin"
    case principal = "Principal"
    case teacher = "Teacher"
    case parent = "Parent"

    var id: String { rawValue }
}

// MARK: - Admin Preview View
struct AdminPreviewView: View {
    let role: PreviewRole
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        NavigationStack {
            Group {
                switch role {
                case .districtAdmin:
                    DistrictAdminDashboardView()
                        .environmentObject(authService)
                case .principal:
                    PrincipalDashboardView()
                        .environmentObject(authService)
                case .teacher:
                    TeacherDashboardView()
                        .environmentObject(authService)
                case .parent:
                    ParentDashboardView()
                        .environmentObject(authService)
                }
            }
            .overlay(alignment: .top) {
                PreviewBanner(role: role, dismiss: dismiss)
            }
        }
    }
}

struct PreviewBanner: View {
    let role: PreviewRole
    let dismiss: DismissAction

    var body: some View {
        HStack {
            Image(systemName: "eye.fill")
            Text("Previewing \(role.rawValue) View")
                .font(.caption.bold())
            Spacer()
            Button("Exit Preview") {
                dismiss()
            }
            .font(.caption.bold())
            .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange)
        .foregroundColor(.white)
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
    @StateObject private var viewModel = SystemLogsViewModel()
    @State private var selectedFilter: LogFilter = .all

    enum LogFilter: String, CaseIterable {
        case all = "All"
        case auth = "Auth"
        case data = "Data"
        case error = "Errors"
    }

    var filteredLogs: [SystemLog] {
        switch selectedFilter {
        case .all: return viewModel.logs
        case .auth: return viewModel.logs.filter { $0.category == .auth }
        case .data: return viewModel.logs.filter { $0.category == .data }
        case .error: return viewModel.logs.filter { $0.category == .error }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(LogFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section("Recent Activity") {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if filteredLogs.isEmpty {
                    Text("No logs to display")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredLogs) { log in
                        SystemLogRow(log: log)
                    }
                }
            }
        }
        .navigationTitle("System Logs")
        .onAppear {
            Task {
                await viewModel.loadLogs()
            }
        }
        .refreshable {
            await viewModel.loadLogs()
        }
    }
}

struct SystemLogRow: View {
    let log: SystemLog

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: log.icon)
                .foregroundColor(log.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(log.title)
                    .font(.subheadline.bold())

                if let details = log.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(log.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - System Log Model

struct SystemLog: Identifiable {
    let id = UUID()
    let title: String
    let details: String?
    let category: LogCategory
    let timestamp: Date

    enum LogCategory {
        case auth, data, error, system
    }

    var icon: String {
        switch category {
        case .auth: return "person.badge.key.fill"
        case .data: return "cylinder.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .system: return "gearshape.fill"
        }
    }

    var color: Color {
        switch category {
        case .auth: return .blue
        case .data: return .green
        case .error: return .red
        case .system: return .purple
        }
    }
}

// MARK: - System Logs ViewModel

@MainActor
class SystemLogsViewModel: ObservableObject {
    @Published var logs: [SystemLog] = []
    @Published var isLoading = false

    func loadLogs() async {
        isLoading = true
        defer { isLoading = false }

        // Generate logs from recent activity
        // In a production app, you would query an activity_logs table
        var generatedLogs: [SystemLog] = []

        // Add recent user signups
        do {
            let recentUsers: [DatabaseUser] = try await SupabaseConfig.client
                .from("users")
                .select()
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value

            for user in recentUsers {
                if let createdAt = user.createdAt {
                    generatedLogs.append(SystemLog(
                        title: "New user registered",
                        details: "\(user.name) (\(user.role))",
                        category: .auth,
                        timestamp: createdAt
                    ))
                }
            }
        } catch {
            print("Error loading users: \(error)")
        }

        // Add recent classrooms
        do {
            let recentClassrooms: [Classroom] = try await SupabaseConfig.client
                .from("classrooms")
                .select()
                .order("created_at", ascending: false)
                .limit(10)
                .execute()
                .value

            for classroom in recentClassrooms {
                generatedLogs.append(SystemLog(
                    title: "Classroom created",
                    details: "\(classroom.name) by \(classroom.teacherName)",
                    category: .data,
                    timestamp: classroom.createdAt
                ))
            }
        } catch {
            print("Error loading classrooms: \(error)")
        }

        // Add system startup log
        generatedLogs.append(SystemLog(
            title: "System started",
            details: "Admin dashboard initialized",
            category: .system,
            timestamp: Date()
        ))

        // Sort by timestamp descending
        logs = generatedLogs.sorted { $0.timestamp > $1.timestamp }
    }
}

struct AdminDatabaseView: View {
    @StateObject private var viewModel = DatabaseViewModel()

    var body: some View {
        List {
            Section("Tables") {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.tables) { table in
                        NavigationLink {
                            DatabaseTableView(tableName: table.name)
                        } label: {
                            HStack {
                                Image(systemName: "cylinder.fill")
                                    .foregroundColor(.blue)

                                Text(table.name)
                                    .font(.headline)

                                Spacer()

                                Text("\(table.count) records")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Database Info") {
                LabeledContent("Total Records", value: "\(viewModel.totalRecords)")
                LabeledContent("Last Refreshed", value: viewModel.lastRefreshed)
            }
        }
        .navigationTitle("Database")
        .onAppear {
            Task {
                await viewModel.loadTableCounts()
            }
        }
        .refreshable {
            await viewModel.loadTableCounts()
        }
    }
}

struct DatabaseTableView: View {
    let tableName: String
    @StateObject private var viewModel = TableContentsViewModel()
    @State private var searchText = ""

    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.records.isEmpty {
                Text("No records found")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.records, id: \.id) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.primaryValue)
                            .font(.headline)

                        if let secondary = record.secondaryValue {
                            Text(secondary)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text("ID: \(record.id)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search \(tableName)...")
        .navigationTitle(tableName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadRecords(for: tableName)
            }
        }
    }
}

// MARK: - Database Models

struct DatabaseTable: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct DatabaseRecord: Identifiable {
    let id: String
    let primaryValue: String
    let secondaryValue: String?
}

// MARK: - Database ViewModel

@MainActor
class DatabaseViewModel: ObservableObject {
    @Published var tables: [DatabaseTable] = []
    @Published var totalRecords = 0
    @Published var lastRefreshed = "Never"
    @Published var isLoading = false

    private let tableNames = [
        "users",
        "classrooms",
        "students",
        "stories",
        "messages",
        "point_records",
        "student_points_summary",
        "districts",
        "schools"
    ]

    func loadTableCounts() async {
        isLoading = true
        defer { isLoading = false }

        var loadedTables: [DatabaseTable] = []
        var total = 0

        for tableName in tableNames {
            do {
                // Use a simple count query
                let response: [[String: Int]] = try await SupabaseConfig.client
                    .from(tableName)
                    .select("*", head: true, count: .exact)
                    .execute()
                    .value

                // The count is in the response headers, but we can estimate from the select
                // For now, let's fetch all and count (not ideal for large tables)
                let count = try await getTableCount(tableName: tableName)
                loadedTables.append(DatabaseTable(name: tableName, count: count))
                total += count
            } catch {
                // Table might not exist or have permission issues
                print("Error loading \(tableName): \(error)")
                loadedTables.append(DatabaseTable(name: tableName, count: 0))
            }
        }

        tables = loadedTables.sorted { $0.count > $1.count }
        totalRecords = total

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        lastRefreshed = formatter.string(from: Date())
    }

    private func getTableCount(tableName: String) async throws -> Int {
        // Generic count query - works for most tables
        switch tableName {
        case "users":
            let records: [DatabaseUser] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        case "classrooms":
            let records: [Classroom] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        case "students":
            let records: [Student] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        case "stories":
            let records: [Story] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        case "point_records":
            let records: [PointRecord] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        case "student_points_summary":
            let records: [StudentPointsSummary] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        case "districts":
            let records: [District] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        case "schools":
            let records: [School] = try await SupabaseConfig.client
                .from(tableName).select().execute().value
            return records.count
        default:
            return 0
        }
    }
}

// MARK: - Table Contents ViewModel

@MainActor
class TableContentsViewModel: ObservableObject {
    @Published var records: [DatabaseRecord] = []
    @Published var isLoading = false

    func loadRecords(for tableName: String) async {
        isLoading = true
        defer { isLoading = false }

        switch tableName {
        case "users":
            do {
                let users: [DatabaseUser] = try await SupabaseConfig.client
                    .from(tableName)
                    .select()
                    .order("created_at", ascending: false)
                    .limit(100)
                    .execute()
                    .value

                records = users.map { user in
                    DatabaseRecord(
                        id: user.id,
                        primaryValue: user.name,
                        secondaryValue: "\(user.email) • \(user.role)"
                    )
                }
            } catch {
                print("Error: \(error)")
            }

        case "classrooms":
            do {
                let classrooms: [Classroom] = try await SupabaseConfig.client
                    .from(tableName)
                    .select()
                    .order("created_at", ascending: false)
                    .limit(100)
                    .execute()
                    .value

                records = classrooms.map { classroom in
                    DatabaseRecord(
                        id: classroom.id ?? "",
                        primaryValue: classroom.name,
                        secondaryValue: "\(classroom.teacherName) • \(classroom.gradeLevel)"
                    )
                }
            } catch {
                print("Error: \(error)")
            }

        case "students":
            do {
                let students: [Student] = try await SupabaseConfig.client
                    .from(tableName)
                    .select()
                    .order("last_name", ascending: true)
                    .limit(100)
                    .execute()
                    .value

                records = students.map { student in
                    DatabaseRecord(
                        id: student.id ?? "",
                        primaryValue: student.fullName,
                        secondaryValue: "Class: \(student.classId)"
                    )
                }
            } catch {
                print("Error: \(error)")
            }

        case "stories":
            do {
                let stories: [Story] = try await SupabaseConfig.client
                    .from(tableName)
                    .select()
                    .order("created_at", ascending: false)
                    .limit(100)
                    .execute()
                    .value

                records = stories.map { story in
                    DatabaseRecord(
                        id: story.id ?? "",
                        primaryValue: story.authorName,
                        secondaryValue: story.content ?? "Photo/media post"
                    )
                }
            } catch {
                print("Error: \(error)")
            }

        case "districts":
            do {
                let districts: [District] = try await SupabaseConfig.client
                    .from(tableName)
                    .select()
                    .order("name", ascending: true)
                    .limit(100)
                    .execute()
                    .value

                records = districts.map { district in
                    DatabaseRecord(
                        id: district.id,
                        primaryValue: district.name,
                        secondaryValue: "\(district.city), \(district.state ?? "")"
                    )
                }
            } catch {
                print("Error: \(error)")
            }

        case "schools":
            do {
                let schools: [School] = try await SupabaseConfig.client
                    .from(tableName)
                    .select()
                    .order("name", ascending: true)
                    .limit(100)
                    .execute()
                    .value

                records = schools.map { school in
                    DatabaseRecord(
                        id: school.id,
                        primaryValue: school.name,
                        secondaryValue: "\(school.city), \(school.state ?? "")"
                    )
                }
            } catch {
                print("Error: \(error)")
            }

        default:
            records = []
        }
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
