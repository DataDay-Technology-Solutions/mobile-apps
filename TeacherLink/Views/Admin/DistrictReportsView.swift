//
//  DistrictReportsView.swift
//  HallPass (formerly TeacherLink)
//
//  District-wide reports and statistics view
//

import SwiftUI

struct DistrictReportsView: View {
    @StateObject private var viewModel = DistrictReportsViewModel()

    let districtId: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ReportCard(
                        title: "Total Schools",
                        value: "\(viewModel.schoolCount)",
                        icon: "building.2.fill",
                        color: .blue
                    )

                    ReportCard(
                        title: "Total Classrooms",
                        value: "\(viewModel.classroomCount)",
                        icon: "book.fill",
                        color: .green
                    )

                    ReportCard(
                        title: "Total Teachers",
                        value: "\(viewModel.teacherCount)",
                        icon: "graduationcap.fill",
                        color: .orange
                    )

                    ReportCard(
                        title: "Total Students",
                        value: "\(viewModel.studentCount)",
                        icon: "person.3.fill",
                        color: .pink
                    )

                    ReportCard(
                        title: "Total Parents",
                        value: "\(viewModel.parentCount)",
                        icon: "figure.2.and.child.holdinghands",
                        color: .teal
                    )

                    ReportCard(
                        title: "Total Points",
                        value: formatNumber(viewModel.totalPoints),
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                .padding(.horizontal)

                // Schools Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Schools Breakdown")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.schoolStats.isEmpty {
                        Text("No school data available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.schoolStats, id: \.schoolId) { stat in
                            SchoolStatRow(stat: stat)
                        }
                    }
                }
                .padding(.top)

                // Activity Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity This Week")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 20) {
                        ActivityStat(
                            title: "Stories",
                            value: "\(viewModel.weeklyStories)",
                            icon: "text.bubble.fill",
                            color: .green
                        )

                        ActivityStat(
                            title: "Points Given",
                            value: "\(viewModel.weeklyPoints)",
                            icon: "star.fill",
                            color: .yellow
                        )

                        ActivityStat(
                            title: "New Students",
                            value: "\(viewModel.weeklyNewStudents)",
                            icon: "person.badge.plus",
                            color: .blue
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .padding(.vertical)
        }
        .navigationTitle("District Reports")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadReports(districtId: districtId)
            }
        }
        .refreshable {
            await viewModel.loadReports(districtId: districtId)
        }
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fK", Double(num) / 1000)
        }
        return "\(num)"
    }
}

// MARK: - Supporting Views

struct ReportCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2.bold())

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

struct SchoolStatRow: View {
    let stat: SchoolStatSummary

    var body: some View {
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
                Text(stat.schoolName)
                    .font(.subheadline.bold())
                Text("\(stat.classroomCount) classes • \(stat.studentCount) students")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(stat.totalPoints)")
                    .font(.subheadline.bold())
                    .foregroundColor(.yellow)
                Text("points")
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

struct ActivityStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(value)
                .font(.headline.bold())

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Models

struct SchoolStatSummary {
    let schoolId: String
    let schoolName: String
    let classroomCount: Int
    let teacherCount: Int
    let studentCount: Int
    let totalPoints: Int
}

// MARK: - DistrictReportsViewModel

@MainActor
class DistrictReportsViewModel: ObservableObject {
    @Published var schoolCount = 0
    @Published var classroomCount = 0
    @Published var teacherCount = 0
    @Published var studentCount = 0
    @Published var parentCount = 0
    @Published var totalPoints = 0
    @Published var schoolStats: [SchoolStatSummary] = []
    @Published var weeklyStories = 0
    @Published var weeklyPoints = 0
    @Published var weeklyNewStudents = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadReports(districtId: String) async {
        isLoading = true
        defer { isLoading = false }

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
        var allClassrooms: [Classroom] = []
        if !schoolIds.isEmpty {
            do {
                allClassrooms = try await SupabaseConfig.client
                    .from("classrooms")
                    .select()
                    .in("school_id", values: schoolIds)
                    .execute()
                    .value
                classroomCount = allClassrooms.count
            } catch {
                print("Error loading classrooms: \(error)")
            }
        }

        // Calculate student and parent counts
        studentCount = allClassrooms.reduce(0) { $0 + $1.studentIds.count }
        parentCount = allClassrooms.reduce(0) { $0 + $1.parentIds.count }

        // Load teachers
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
        let classIds = allClassrooms.compactMap { $0.id }
        var allSummaries: [StudentPointsSummary] = []
        if !classIds.isEmpty {
            do {
                allSummaries = try await SupabaseConfig.client
                    .from("student_points_summary")
                    .select()
                    .in("class_id", values: classIds)
                    .execute()
                    .value
                totalPoints = allSummaries.reduce(0) { $0 + $1.totalPoints }
            } catch {
                print("Error loading points: \(error)")
            }
        }

        // Build school stats
        schoolStats = schools.map { school in
            let schoolClassrooms = allClassrooms.filter { $0.schoolId == school.id }
            let schoolClassIds = schoolClassrooms.compactMap { $0.id }
            let schoolPoints = allSummaries
                .filter { schoolClassIds.contains($0.classId) }
                .reduce(0) { $0 + $1.totalPoints }

            return SchoolStatSummary(
                schoolId: school.id,
                schoolName: school.name,
                classroomCount: schoolClassrooms.count,
                teacherCount: 0, // Would need separate query
                studentCount: schoolClassrooms.reduce(0) { $0 + $1.studentIds.count },
                totalPoints: schoolPoints
            )
        }

        // Weekly activity stats
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        // Weekly stories
        if !classIds.isEmpty {
            do {
                let stories: [Story] = try await SupabaseConfig.client
                    .from("stories")
                    .select()
                    .in("class_id", values: classIds)
                    .gte("created_at", value: ISO8601DateFormatter().string(from: oneWeekAgo))
                    .execute()
                    .value
                weeklyStories = stories.count
            } catch {
                print("Error loading weekly stories: \(error)")
            }
        }

        // Weekly points
        if !classIds.isEmpty {
            do {
                let records: [PointRecord] = try await SupabaseConfig.client
                    .from("point_records")
                    .select()
                    .in("class_id", values: classIds)
                    .gte("created_at", value: ISO8601DateFormatter().string(from: oneWeekAgo))
                    .execute()
                    .value
                weeklyPoints = records.reduce(0) { $0 + $1.points }
            } catch {
                print("Error loading weekly points: \(error)")
            }
        }

        // Weekly new students
        if !classIds.isEmpty {
            do {
                let students: [Student] = try await SupabaseConfig.client
                    .from("students")
                    .select()
                    .in("class_id", values: classIds)
                    .gte("created_at", value: ISO8601DateFormatter().string(from: oneWeekAgo))
                    .execute()
                    .value
                weeklyNewStudents = students.count
            } catch {
                print("Error loading weekly students: \(error)")
            }
        }
    }
}

#Preview {
    NavigationView {
        DistrictReportsView(districtId: "test-district-001")
    }
}
