//
//  DistrictAdminDashboardView.swift
//  HallPass (formerly TeacherLink)
//
//  Dashboard for district administrators to manage schools
//

import SwiftUI

struct DistrictAdminDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel = DistrictAdminViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            DistrictOverviewView()
                .environmentObject(authService)
                .environmentObject(viewModel)
                .tabItem {
                    Label("Overview", systemImage: "chart.bar.fill")
                }
                .tag(0)

            // Schools Tab
            DistrictSchoolsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Schools", systemImage: "building.2.fill")
                }
                .tag(1)

            // Teachers Tab
            DistrictTeachersView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Teachers", systemImage: "person.3.fill")
                }
                .tag(2)

            // Settings Tab
            DistrictSettingsView()
                .environmentObject(authService)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.purple)
        .onAppear {
            if let districtId = authService.appUser?.districtId {
                Task {
                    await viewModel.loadDistrictData(districtId: districtId)
                }
            }
        }
    }
}

// MARK: - District Overview View
struct DistrictOverviewView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var viewModel: DistrictAdminViewModel
    @State private var showingLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // District Header
                    if let district = viewModel.district {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.purple.gradient)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "building.2.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(district.name)
                                    .font(.title2.bold())
                                Text("\(district.city), \(district.state ?? "")")
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
                            title: "Schools",
                            value: "\(viewModel.stats?.schoolCount ?? 0)",
                            icon: "building.2.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Classrooms",
                            value: "\(viewModel.stats?.classroomCount ?? 0)",
                            icon: "book.fill",
                            color: .green
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
                    }
                    .padding(.horizontal)

                    // Schools Quick List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Schools")
                                .font(.headline)
                            Spacer()
                            Text("\(viewModel.schools.count) total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        if viewModel.schools.isEmpty {
                            Text("No schools in district")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(viewModel.schools.prefix(5), id: \.id) { school in
                                SchoolQuickRow(school: school)
                            }
                        }
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("District Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.purple)
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
                if let districtId = authService.appUser?.districtId {
                    await viewModel.loadDistrictData(districtId: districtId)
                }
            }
        }
    }
}

// MARK: - District Schools View
struct DistrictSchoolsView: View {
    @EnvironmentObject var viewModel: DistrictAdminViewModel
    @State private var searchText = ""

    var filteredSchools: [School] {
        if searchText.isEmpty {
            return viewModel.schools
        }
        return viewModel.schools.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSchools, id: \.id) { school in
                    NavigationLink {
                        SchoolDetailView(school: school)
                            .environmentObject(viewModel)
                    } label: {
                        SchoolRow(school: school)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search schools...")
            .navigationTitle("Schools")
            .overlay {
                if viewModel.schools.isEmpty {
                    ContentUnavailableView(
                        "No Schools",
                        systemImage: "building.2",
                        description: Text("No schools have been added to this district yet.")
                    )
                }
            }
        }
    }
}

// MARK: - District Teachers View
struct DistrictTeachersView: View {
    @EnvironmentObject var viewModel: DistrictAdminViewModel
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
                    TeacherRow(teacher: teacher)
                }
            }
            .searchable(text: $searchText, prompt: "Search teachers...")
            .navigationTitle("Teachers")
            .overlay {
                if viewModel.teachers.isEmpty {
                    ContentUnavailableView(
                        "No Teachers",
                        systemImage: "person.3",
                        description: Text("No teachers have joined schools in this district yet.")
                    )
                }
            }
        }
    }
}

// MARK: - District Settings View
struct DistrictSettingsView: View {
    @EnvironmentObject var authService: AuthenticationService

    private var districtId: String? {
        authService.appUser?.districtId
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.largeTitle)
                            .foregroundColor(.purple)

                        VStack(alignment: .leading) {
                            Text(authService.currentUserName)
                                .font(.headline)
                            Text("District Administrator")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("District") {
                    if let districtId = districtId {
                        NavigationLink {
                            DistrictProfileView(districtId: districtId)
                        } label: {
                            Label("District Profile", systemImage: "building.2")
                        }

                        NavigationLink {
                            ManageSchoolsView(districtId: districtId)
                        } label: {
                            Label("Manage Schools", systemImage: "building")
                        }
                    }
                }

                Section("Reports") {
                    if let districtId = districtId {
                        NavigationLink {
                            DistrictReportsView(districtId: districtId)
                        } label: {
                            Label("View Reports", systemImage: "chart.bar")
                        }

                        NavigationLink {
                            ExportDataView(
                                exportType: .district,
                                districtId: districtId,
                                districtName: authService.appUser?.name
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

struct SchoolQuickRow: View {
    let school: School

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "building.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(school.name)
                    .font(.headline)
                Text("\(school.city), \(school.state ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct SchoolRow: View {
    let school: School

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "building.fill")
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(school.name)
                    .font(.headline)
                Text("\(school.city), \(school.state ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let grades = school.gradeLevels, !grades.isEmpty {
                    Text("Grades: \(grades.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TeacherRow: View {
    let teacher: AppUser

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange)
                .frame(width: 40, height: 40)
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

struct SchoolDetailView: View {
    let school: School
    @EnvironmentObject var viewModel: DistrictAdminViewModel
    @StateObject private var schoolStats = SchoolStatsViewModel()

    var body: some View {
        List {
            Section {
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
                            .font(.title3.bold())
                        Text("\(school.city), \(school.state ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Statistics") {
                if schoolStats.isLoading {
                    ProgressView()
                } else {
                    LabeledContent("Classrooms", value: "\(schoolStats.classroomCount)")
                    LabeledContent("Teachers", value: "\(schoolStats.teacherCount)")
                    LabeledContent("Students", value: "\(schoolStats.studentCount)")
                    LabeledContent("Parents", value: "\(schoolStats.parentCount)")
                    LabeledContent("Total Points", value: "\(schoolStats.totalPoints)")
                }
            }

            if let grades = school.gradeLevels, !grades.isEmpty {
                Section("Grade Levels") {
                    Text(grades.joined(separator: ", "))
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(school.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await schoolStats.loadStats(for: school.id)
            }
        }
    }
}

// MARK: - School Stats ViewModel
@MainActor
class SchoolStatsViewModel: ObservableObject {
    @Published var classroomCount = 0
    @Published var teacherCount = 0
    @Published var studentCount = 0
    @Published var parentCount = 0
    @Published var totalPoints = 0
    @Published var isLoading = false

    func loadStats(for schoolId: String) async {
        isLoading = true
        defer { isLoading = false }

        // Load classrooms in school
        var classrooms: [Classroom] = []
        do {
            classrooms = try await SupabaseConfig.client
                .from("classrooms")
                .select()
                .eq("school_id", value: schoolId)
                .execute()
                .value
        } catch {
            print("Error loading classrooms: \(error)")
        }

        classroomCount = classrooms.count
        studentCount = classrooms.reduce(0) { $0 + $1.studentIds.count }
        parentCount = classrooms.reduce(0) { $0 + $1.parentIds.count }

        // Load teachers in school
        do {
            let dbUsers: [DatabaseUser] = try await SupabaseConfig.client
                .from("users")
                .select()
                .eq("school_id", value: schoolId)
                .eq("role", value: "teacher")
                .execute()
                .value
            teacherCount = dbUsers.count
        } catch {
            print("Error loading teachers: \(error)")
        }

        // Load total points
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
    }
}

// MARK: - Manage Schools View

struct ManageSchoolsView: View {
    let districtId: String
    @StateObject private var viewModel = ManageSchoolsViewModel()
    @State private var showingAddSchool = false
    @State private var newSchoolName = ""
    @State private var newSchoolCode = ""
    @State private var newSchoolCity = ""
    @State private var newSchoolState = ""

    var body: some View {
        List {
            Section {
                ForEach(viewModel.schools, id: \.id) { school in
                    NavigationLink {
                        SchoolDetailView(school: school)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "building.fill")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(school.name)
                                    .font(.headline)
                                Text("\(school.city), \(school.state ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            let school = viewModel.schools[index]
                            await viewModel.deleteSchool(schoolId: school.id)
                        }
                    }
                }
            }

            if viewModel.schools.isEmpty && !viewModel.isLoading {
                Section {
                    Text("No schools in this district yet")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Manage Schools")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSchool = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSchool) {
            NavigationView {
                Form {
                    Section("School Information") {
                        TextField("School Name", text: $newSchoolName)
                        TextField("School Code", text: $newSchoolCode)
                            .textInputAutocapitalization(.characters)
                        TextField("City", text: $newSchoolCity)
                        TextField("State", text: $newSchoolState)
                            .textInputAutocapitalization(.characters)
                    }
                }
                .navigationTitle("Add School")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddSchool = false
                            resetForm()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            Task {
                                await viewModel.addSchool(
                                    districtId: districtId,
                                    name: newSchoolName,
                                    code: newSchoolCode,
                                    city: newSchoolCity,
                                    state: newSchoolState
                                )
                                showingAddSchool = false
                                resetForm()
                            }
                        }
                        .disabled(newSchoolName.isEmpty || newSchoolCode.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSchools(districtId: districtId)
            }
        }
    }

    private func resetForm() {
        newSchoolName = ""
        newSchoolCode = ""
        newSchoolCity = ""
        newSchoolState = ""
    }
}

// MARK: - Manage Schools ViewModel

@MainActor
class ManageSchoolsViewModel: ObservableObject {
    @Published var schools: [School] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadSchools(districtId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            schools = try await SupabaseConfig.client
                .from("schools")
                .select()
                .eq("district_id", value: districtId)
                .order("name")
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSchool(districtId: String, name: String, code: String, city: String, state: String) async {
        isLoading = true
        defer { isLoading = false }

        struct NewSchool: Encodable {
            let districtId: String
            let name: String
            let code: String
            let city: String
            let state: String
            let gradeLevels: [String]

            enum CodingKeys: String, CodingKey {
                case districtId = "district_id"
                case name, code, city, state
                case gradeLevels = "grade_levels"
            }
        }

        let newSchool = NewSchool(
            districtId: districtId,
            name: name,
            code: code,
            city: city,
            state: state,
            gradeLevels: []
        )

        do {
            try await SupabaseConfig.client
                .from("schools")
                .insert(newSchool)
                .execute()

            await loadSchools(districtId: districtId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSchool(schoolId: String) async {
        do {
            try await SupabaseConfig.client
                .from("schools")
                .delete()
                .eq("id", value: schoolId)
                .execute()

            schools.removeAll { $0.id == schoolId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - District Admin View Model

@MainActor
class DistrictAdminViewModel: ObservableObject {
    @Published var district: District?
    @Published var schools: [School] = []
    @Published var teachers: [AppUser] = []
    @Published var stats: DistrictStats?
    @Published var isLoading = false

    func loadDistrictData(districtId: String) async {
        isLoading = true
        defer { isLoading = false }

        // Load district info
        do {
            district = try await SupabaseConfig.client
                .from("districts")
                .select()
                .eq("id", value: districtId)
                .single()
                .execute()
                .value
        } catch {
            print("Error loading district: \(error)")
        }

        // Load schools in district
        do {
            schools = try await SupabaseConfig.client
                .from("schools")
                .select()
                .eq("district_id", value: districtId)
                .order("name")
                .execute()
                .value
        } catch {
            print("Error loading schools: \(error)")
        }

        // Load teachers in district
        do {
            let dbUsers: [DatabaseUser] = try await SupabaseConfig.client
                .from("users")
                .select()
                .eq("district_id", value: districtId)
                .eq("role", value: "teacher")
                .order("name")
                .execute()
                .value
            teachers = dbUsers.map { $0.toAppUser() }
        } catch {
            print("Error loading teachers: \(error)")
        }

        // Load classrooms in district (via school_ids)
        var allClassrooms: [Classroom] = []
        let schoolIds = schools.map { $0.id }
        if !schoolIds.isEmpty {
            do {
                allClassrooms = try await SupabaseConfig.client
                    .from("classrooms")
                    .select()
                    .in("school_id", values: schoolIds)
                    .execute()
                    .value
            } catch {
                print("Error loading classrooms: \(error)")
            }
        }

        // Calculate student and parent counts from classrooms
        let studentCount = allClassrooms.reduce(0) { $0 + $1.studentIds.count }
        let parentCount = allClassrooms.reduce(0) { $0 + $1.parentIds.count }

        // Load total points from student_points_summary
        var totalPoints = 0
        let classIds = allClassrooms.compactMap { $0.id }
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

        // Calculate stats
        stats = DistrictStats(
            schoolCount: schools.count,
            classroomCount: allClassrooms.count,
            teacherCount: teachers.count,
            studentCount: studentCount,
            parentCount: parentCount,
            totalPoints: totalPoints
        )
    }
}

// MARK: - Supporting Models

struct District: Codable, Identifiable {
    let id: String
    let name: String
    let code: String
    let city: String
    let state: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, code, city, state
        case createdAt = "created_at"
    }
}

struct School: Codable, Identifiable {
    let id: String
    let districtId: String
    let name: String
    let code: String
    let city: String
    let state: String?
    let gradeLevels: [String]?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, code, city, state
        case districtId = "district_id"
        case gradeLevels = "grade_levels"
        case createdAt = "created_at"
    }
}

struct DistrictStats {
    let schoolCount: Int
    let classroomCount: Int
    let teacherCount: Int
    let studentCount: Int
    let parentCount: Int
    let totalPoints: Int
}

#Preview {
    DistrictAdminDashboardView()
        .environmentObject(AuthenticationService())
}
