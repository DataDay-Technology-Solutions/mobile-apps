//
//  ExportDataView.swift
//  HallPass (formerly TeacherLink)
//
//  View for exporting data to CSV format
//

import SwiftUI

struct ExportDataView: View {
    @StateObject private var viewModel = ExportDataViewModel()
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    // Pass in the context for the export
    let exportType: ExportType
    let districtId: String?
    let schoolId: String?
    let districtName: String?
    let schoolName: String?

    enum ExportType {
        case district
        case school
    }

    init(
        exportType: ExportType,
        districtId: String? = nil,
        schoolId: String? = nil,
        districtName: String? = nil,
        schoolName: String? = nil
    ) {
        self.exportType = exportType
        self.districtId = districtId
        self.schoolId = schoolId
        self.districtName = districtName
        self.schoolName = schoolName
    }

    var body: some View {
        List {
            Section {
                Text("Export your data to CSV format for use in spreadsheet applications like Excel or Google Sheets.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Section("Available Exports") {
                ExportOptionRow(
                    title: "Students",
                    description: "Export all students with their points",
                    icon: "person.3.fill",
                    color: .blue,
                    isLoading: viewModel.isExporting && viewModel.currentExport == .students
                ) {
                    exportStudents()
                }

                ExportOptionRow(
                    title: "Classrooms",
                    description: "Export classroom details and counts",
                    icon: "book.fill",
                    color: .green,
                    isLoading: viewModel.isExporting && viewModel.currentExport == .classrooms
                ) {
                    exportClassrooms()
                }

                ExportOptionRow(
                    title: "Points History",
                    description: "Export all point records",
                    icon: "star.fill",
                    color: .yellow,
                    isLoading: viewModel.isExporting && viewModel.currentExport == .points
                ) {
                    exportPoints()
                }

                ExportOptionRow(
                    title: "Teachers",
                    description: "Export teacher information",
                    icon: "graduationcap.fill",
                    color: .orange,
                    isLoading: viewModel.isExporting && viewModel.currentExport == .teachers
                ) {
                    exportTeachers()
                }

                ExportOptionRow(
                    title: "Summary Report",
                    description: "Export a summary of all statistics",
                    icon: "chart.bar.fill",
                    color: .purple,
                    isLoading: viewModel.isExporting && viewModel.currentExport == .summary
                ) {
                    exportSummary()
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadData(
                    exportType: exportType,
                    districtId: districtId,
                    schoolId: schoolId
                )
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Export Functions

    private func exportStudents() {
        Task {
            if let url = await viewModel.exportStudents() {
                exportURL = url
                showingShareSheet = true
            }
        }
    }

    private func exportClassrooms() {
        Task {
            if let url = await viewModel.exportClassrooms() {
                exportURL = url
                showingShareSheet = true
            }
        }
    }

    private func exportPoints() {
        Task {
            if let url = await viewModel.exportPointsHistory() {
                exportURL = url
                showingShareSheet = true
            }
        }
    }

    private func exportTeachers() {
        Task {
            if let url = await viewModel.exportTeachers() {
                exportURL = url
                showingShareSheet = true
            }
        }
    }

    private func exportSummary() {
        Task {
            if let url = await viewModel.exportSummary(
                districtName: districtName,
                schoolName: schoolName
            ) {
                exportURL = url
                showingShareSheet = true
            }
        }
    }
}

// MARK: - Export Option Row

struct ExportOptionRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Export Data View Model

enum ExportItem {
    case students, classrooms, points, teachers, summary
}

@MainActor
class ExportDataViewModel: ObservableObject {
    @Published var classrooms: [Classroom] = []
    @Published var schoolCount = 0
    @Published var classroomCount = 0
    @Published var teacherCount = 0
    @Published var studentCount = 0
    @Published var parentCount = 0
    @Published var totalPoints = 0
    @Published var isLoading = false
    @Published var isExporting = false
    @Published var currentExport: ExportItem?
    @Published var errorMessage: String?

    private var exportType: ExportDataView.ExportType = .district
    private var districtId: String?
    private var schoolId: String?

    func loadData(
        exportType: ExportDataView.ExportType,
        districtId: String?,
        schoolId: String?
    ) async {
        self.exportType = exportType
        self.districtId = districtId
        self.schoolId = schoolId

        isLoading = true
        defer { isLoading = false }

        switch exportType {
        case .district:
            guard let districtId = districtId else { return }
            await loadDistrictData(districtId: districtId)

        case .school:
            guard let schoolId = schoolId else { return }
            await loadSchoolData(schoolId: schoolId)
        }
    }

    private func loadDistrictData(districtId: String) async {
        // Load schools
        var schools: [School] = []
        do {
            schools = try await SupabaseConfig.client
                .from("schools")
                .select()
                .eq("district_id", value: districtId)
                .execute()
                .value
            schoolCount = schools.count
        } catch {
            print("Error loading schools: \(error)")
        }

        // Load classrooms
        let schoolIds = schools.map { $0.id }
        if !schoolIds.isEmpty {
            do {
                classrooms = try await SupabaseConfig.client
                    .from("classrooms")
                    .select()
                    .in("school_id", values: schoolIds)
                    .execute()
                    .value
                classroomCount = classrooms.count
            } catch {
                print("Error loading classrooms: \(error)")
            }
        }

        // Calculate counts
        studentCount = classrooms.reduce(0) { $0 + $1.studentIds.count }
        parentCount = classrooms.reduce(0) { $0 + $1.parentIds.count }

        // Load teacher count
        do {
            let dbUsers: [DatabaseUser] = try await SupabaseConfig.client
                .from("users")
                .select()
                .eq("district_id", value: districtId)
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

    private func loadSchoolData(schoolId: String) async {
        // Load classrooms
        do {
            classrooms = try await SupabaseConfig.client
                .from("classrooms")
                .select()
                .eq("school_id", value: schoolId)
                .execute()
                .value
            classroomCount = classrooms.count
        } catch {
            print("Error loading classrooms: \(error)")
        }

        // Calculate counts
        studentCount = classrooms.reduce(0) { $0 + $1.studentIds.count }
        parentCount = classrooms.reduce(0) { $0 + $1.parentIds.count }

        // Load teacher count
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

    // MARK: - Export Functions

    func exportStudents() async -> URL? {
        isExporting = true
        currentExport = .students
        errorMessage = nil
        defer {
            isExporting = false
            currentExport = nil
        }

        do {
            return try await ExportService.shared.exportStudents(from: classrooms)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func exportClassrooms() async -> URL? {
        isExporting = true
        currentExport = .classrooms
        errorMessage = nil
        defer {
            isExporting = false
            currentExport = nil
        }

        do {
            return try await ExportService.shared.exportClassrooms(classrooms)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func exportPointsHistory() async -> URL? {
        isExporting = true
        currentExport = .points
        errorMessage = nil
        defer {
            isExporting = false
            currentExport = nil
        }

        let classIds = classrooms.compactMap { $0.id }
        guard !classIds.isEmpty else {
            errorMessage = "No classrooms to export"
            return nil
        }

        do {
            return try await ExportService.shared.exportPointsHistory(for: classIds)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func exportTeachers() async -> URL? {
        isExporting = true
        currentExport = .teachers
        errorMessage = nil
        defer {
            isExporting = false
            currentExport = nil
        }

        let id: String
        let isDistrict: Bool

        switch exportType {
        case .district:
            guard let districtId = districtId else { return nil }
            id = districtId
            isDistrict = true
        case .school:
            guard let schoolId = schoolId else { return nil }
            id = schoolId
            isDistrict = false
        }

        do {
            return try await ExportService.shared.exportTeachers(for: id, isDistrict: isDistrict)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func exportSummary(districtName: String?, schoolName: String?) async -> URL? {
        isExporting = true
        currentExport = .summary
        errorMessage = nil
        defer {
            isExporting = false
            currentExport = nil
        }

        do {
            return try ExportService.shared.exportSummaryReport(
                districtName: districtName,
                schoolName: schoolName,
                schoolCount: schoolCount,
                classroomCount: classroomCount,
                teacherCount: teacherCount,
                studentCount: studentCount,
                parentCount: parentCount,
                totalPoints: totalPoints
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

#Preview {
    NavigationView {
        ExportDataView(
            exportType: .district,
            districtId: "test-district-001",
            districtName: "Springfield Unified"
        )
    }
}
