//
//  PrincipalDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Dashboard for school principals to manage their school
//

import SwiftUI

struct PrincipalDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel = PrincipalViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            SchoolOverviewView()
                .environmentObject(authService)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Overview", systemImage: "chart.bar.fill")
                }
                .tag(0)

            // Classrooms Tab
            SchoolClassroomsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Classes", systemImage: "book.fill")
                }
                .tag(1)

            // Teachers Tab
            SchoolTeachersView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Teachers", systemImage: "person.3.fill")
                }
                .tag(2)

            // Settings Tab
            SchoolSettingsView()
                .environmentObject(authService)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            if let schoolId = authService.appUser?.schoolId {
                Task {
                    await viewModel.loadSchoolData(schoolId: schoolId)
                }
            }
        }
    }
}

// MARK: - School Overview View
struct SchoolOverviewView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var viewModel: PrincipalViewModel
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // School Header
                    if let school = viewModel.school {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "building.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(school.name)
                                    .font(.title2.bold())
                                Text("\(school.city), \(school.state ?? "")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 8)
                        .padding(.horizontal)
                    }

                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Classrooms",
                            value: "\(viewModel.stats?.classroomCount ?? 0)",
                            icon: "book.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Teachers",
                            value: "\(viewModel.stats?.teacherCount ?? 0)",
                            icon: "graduationcap.fill",
                            color: .orange
                        )

                        StatCard(
                            title: "Students",
                            value: "\(viewModel.stats?.studentCount ?? 0)",
                            icon: "person.3.fill",
                            color: .pink
                        )

                        StatCard(
                            title: "Parents",
                            value: "\(viewModel.stats?.parentCount ?? 0)",
                            icon: "figure.2.and.child.holdinghands",
                            color: .teal
                        )

                        StatCard(
                            title: "Total Points",
                            value: "\(viewModel.stats?.totalPoints ?? 0)",
                            icon: "star.fill",
                            color: .yellow
                        )

                        StatCard(
                            title: "Stories",
                            value: "\(viewModel.stats?.storyCount ?? 0)",
                            icon: "text.bubble.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)

                    // Top Performing Classrooms
                    if !viewModel.classrooms.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Classrooms")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.classrooms.prefix(5), id: \.uniqueId) { classroom in
                                ClassroomQuickRow(classroom: classroom)
                            }
                        }
                        .padding(.top)
                    }

                    // Recent Activity placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.recentStories.isEmpty {
                            Text("No recent activity")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(viewModel.recentStories.prefix(5), id: \.id) { story in
                                StoryQuickRow(story: story)
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("Principal Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.blue)
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
            .refreshable {
                if let schoolId = authService.appUser?.schoolId {
                    await viewModel.loadSchoolData(schoolId: schoolId)
                }
            }
        }
    }
}

// MARK: - School Classrooms View
struct SchoolClassroomsView: View {
    @EnvironmentObject var viewModel: PrincipalViewModel
    @State private var searchText = ""

    var filteredClassrooms: [Classroom] {
        if searchText.isEmpty {
            return viewModel.classrooms
        }
        return viewModel.classrooms.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.teacherName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredClassrooms, id: \.uniqueId) { classroom in
                    NavigationLink {
                        ClassroomDetailView(classroom: classroom)
                    } label: {
                        ClassroomListRow(classroom: classroom)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search classrooms...")
            .navigationTitle("Classrooms")
            .overlay {
                if viewModel.classrooms.isEmpty {
                    ContentUnavailableView(
                        "No Classrooms",
                        systemImage: "book",
                        description: Text("No classrooms have been created in this school yet.")
                    )
                }
            }
        }
    }
}

// MARK: - School Teachers View
struct SchoolTeachersView: View {
    @EnvironmentObject var viewModel: PrincipalViewModel
    @State private var searchText = ""

    var filteredTeachers: [AppUser] {
        if searchText.isEmpty {
            return viewModel.teachers
        }
        return viewModel.teachers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredTeachers, id: \.id) { teacher in
                    NavigationLink {
                        TeacherDetailView(teacher: teacher)
                            .environmentObject(viewModel)
                    } label: {
                        SchoolTeacherRow(teacher: teacher)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search teachers...")
            .navigationTitle("Teachers")
            .overlay {
                if viewModel.teachers.isEmpty {
                    ContentUnavailableView(
                        "No Teachers",
                        systemImage: "person.3",
                        description: Text("No teachers have joined this school yet.")
                    )
                }
            }
        }
    }
}

// MARK: - School Settings View
struct SchoolSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService

    private var schoolId: String? {
        authService.appUser?.schoolId
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "building.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)

                        VStack(alignment: .leading) {
                            Text(authService.currentUserName)
                                .font(.headline)
                            Text("School Principal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("School") {
                    if let schoolId = schoolId {
                        NavigationLink {
                            SchoolProfileView(schoolId: schoolId)
                        } label: {
                            Label("School Profile", systemImage: "building")
                        }

                        NavigationLink {
                            GradeLevelsView(schoolId: schoolId)
                        } label: {
                            Label("Grade Levels", systemImage: "list.number")
                        }
                    }
                }

                Section("Reports") {
                    if let schoolId = schoolId {
                        NavigationLink {
                            SchoolReportsView(schoolId: schoolId)
                        } label: {
                            Label("View Reports", systemImage: "chart.bar")
                        }

                        NavigationLink {
                            ExportDataView(
                                exportType: .school,
                                schoolId: schoolId,
                                schoolName: authService.appUser?.name
                            )
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }
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
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Supporting Views

struct ClassroomQuickRow: View {
    let classroom: Classroom

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(classroom.name)
                    .font(.headline)
                HStack {
                    Text(classroom.teacherName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(classroom.gradeLevel)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(classroom.studentIds.count)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("students")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ClassroomListRow: View {
    let classroom: Classroom

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(classroom.name)
                    .font(.headline)
                Text(classroom.teacherName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                    Text("\(classroom.studentIds.count)")
                }
                .foregroundColor(.secondary)

                Text(classroom.gradeLevel)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SchoolTeacherRow: View {
    let teacher: AppUser

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(teacher.name.prefix(1)).uppercased())
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(teacher.name)
                    .font(.headline)
                Text(teacher.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct StoryQuickRow: View {
    let story: Story

    var storyPreview: String {
        let text = story.content ?? "Shared a photo"
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }

    var body: some View {
        HStack {
            Circle()
                .fill(Color.green.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "text.bubble.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(story.authorName)
                    .font(.subheadline.bold())
                Text(storyPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(story.createdAt, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ClassroomDetailView: View {
    let classroom: Classroom

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(classroom.name)
                            .font(.title3.bold())
                        Text(classroom.teacherName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Details") {
                LabeledContent("Grade Level", value: classroom.gradeLevel)
                LabeledContent("Class Code", value: classroom.classCode)
                LabeledContent("Students", value: "\(classroom.studentIds.count)")
                LabeledContent("Parents", value: "\(classroom.parentIds.count)")
            }
        }
        .navigationTitle(classroom.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TeacherDetailView: View {
    let teacher: AppUser
    @EnvironmentObject var viewModel: PrincipalViewModel

    var teacherClassrooms: [Classroom] {
        viewModel.classrooms.filter { $0.teacherId == teacher.id }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.orange.gradient)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(teacher.name.prefix(1)).uppercased())
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(teacher.name)
                            .font(.title3.bold())
                        Text(teacher.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Classrooms (\(teacherClassrooms.count))") {
                if teacherClassrooms.isEmpty {
                    Text("No classrooms yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(teacherClassrooms, id: \.uniqueId) { classroom in
                        HStack {
                            Text(classroom.name)
                            Spacer()
                            Text("\(classroom.studentIds.count) students")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(teacher.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Principal View Model

@MainActor
class PrincipalViewModel: ObservableObject {
    @Published var school: School?
    @Published var classrooms: [Classroom] = []
    @Published var teachers: [AppUser] = []
    @Published var recentStories: [Story] = []
    @Published var stats: SchoolStats?
    @Published var isLoading = false

    func loadSchoolData(schoolId: String) async {
        isLoading = true
        defer { isLoading = false }

        // Load school info
        do {
            school = try await SupabaseConfig.client
                .from("schools")
                .select()
                .eq("id", value: schoolId)
                .single()
                .execute()
                .value
        } catch {
            print("Error loading school: \(error)")
        }

        // Load classrooms in school
        do {
            classrooms = try await SupabaseConfig.client
                .from("classrooms")
                .select()
                .eq("school_id", value: schoolId)
                .order("name")
                .execute()
                .value
        } catch {
            print("Error loading classrooms: \(error)")
        }

        // Load teachers in school
        do {
            let dbUsers: [DatabaseUser] = try await SupabaseConfig.client
                .from("users")
                .select()
                .eq("school_id", value: schoolId)
                .eq("role", value: "teacher")
                .order("name")
                .execute()
                .value
            teachers = dbUsers.map { $0.toAppUser() }
        } catch {
            print("Error loading teachers: \(error)")
        }

        // Load recent stories from school's classrooms
        if !classrooms.isEmpty {
            let classIds = classrooms.compactMap { $0.id }
            do {
                recentStories = try await SupabaseConfig.client
                    .from("stories")
                    .select()
                    .in("class_id", values: classIds)
                    .order("created_at", ascending: false)
                    .limit(10)
                    .execute()
                    .value
            } catch {
                print("Error loading stories: \(error)")
            }
        }

        // Calculate stats
        let studentCount = classrooms.reduce(0) { $0 + $1.studentIds.count }
        let parentCount = classrooms.reduce(0) { $0 + $1.parentIds.count }

        // Load total points from student_points_summary
        var totalPoints = 0
        let classIds = classrooms.compactMap { $0.id }
        if !classIds.isEmpty {
            do {
                let summaries: [StudentPointsSummary] = try await SupabaseConfig.client
                    .from("student_points_summary")
                    .select()
                    .in("class_id", values: classIds)
                    .execute()
                    .value
                totalPoints = summaries.reduce(0) { $0 + $1.totalPoints }
            } catch {
                print("Error loading points: \(error)")
            }
        }

        stats = SchoolStats(
            classroomCount: classrooms.count,
            teacherCount: teachers.count,
            studentCount: studentCount,
            parentCount: parentCount,
            totalPoints: totalPoints,
            storyCount: recentStories.count
        )
    }
}

// MARK: - Supporting Models

struct SchoolStats {
    let classroomCount: Int
    let teacherCount: Int
    let studentCount: Int
    let parentCount: Int
    let totalPoints: Int
    let storyCount: Int
}

#Preview {
    PrincipalDashboardView()
        .environmentObject(AuthenticationService())
}
