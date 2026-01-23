//
//  SchoolReportsView.swift
//  HallPass (formerly TeacherLink)
//
//  School-wide reports and statistics view
//

import SwiftUI

struct SchoolReportsView: View {
    @StateObject private var viewModel = SchoolReportsViewModel()

    let schoolId: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ReportCard(
                        title: "Classrooms",
                        value: "\(viewModel.classroomCount)",
                        icon: "book.fill",
                        color: .blue
                    )

                    ReportCard(
                        title: "Teachers",
                        value: "\(viewModel.teacherCount)",
                        icon: "graduationcap.fill",
                        color: .orange
                    )

                    ReportCard(
                        title: "Students",
                        value: "\(viewModel.studentCount)",
                        icon: "person.3.fill",
                        color: .pink
                    )

                    ReportCard(
                        title: "Parents",
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

                    ReportCard(
                        title: "Total Stories",
                        value: "\(viewModel.storyCount)",
                        icon: "text.bubble.fill",
                        color: .green
                    )
                }
                .padding(.horizontal)

                // Classrooms Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Classrooms Breakdown")
                        .font(.headline)
                        .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if viewModel.classroomStats.isEmpty {
                        Text("No classroom data available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(viewModel.classroomStats, id: \.classroomId) { stat in
                            ClassroomStatRow(stat: stat)
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

                // Top Performing Classrooms
                if !viewModel.topClassrooms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Top Performing Classrooms")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(Array(viewModel.topClassrooms.enumerated()), id: \.element.classroomId) { index, stat in
                            TopClassroomRow(rank: index + 1, stat: stat)
                        }
                    }
                    .padding(.top)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("School Reports")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadReports(schoolId: schoolId)
            }
        }
        .refreshable {
            await viewModel.loadReports(schoolId: schoolId)
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

struct ClassroomStatRow: View {
    let stat: ClassroomStatSummary

    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "book.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(stat.classroomName)
                    .font(.subheadline.bold())
                Text("\(stat.teacherName) • \(stat.gradeLevel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption2)
                    Text("\(stat.studentCount)")
                        .font(.caption.bold())
                }
                .foregroundColor(.blue)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("\(stat.totalPoints)")
                        .font(.caption.bold())
                }
                .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TopClassroomRow: View {
    let rank: Int
    let stat: ClassroomStatSummary

    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }

    var body: some View {
        HStack {
            Circle()
                .fill(rankColor.gradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("\(rank)")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(stat.classroomName)
                    .font(.subheadline.bold())
                Text(stat.teacherName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(stat.totalPoints)")
                    .font(.headline.bold())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Supporting Models

struct ClassroomStatSummary {
    let classroomId: String
    let classroomName: String
    let teacherName: String
    let gradeLevel: String
    let studentCount: Int
    let parentCount: Int
    let totalPoints: Int
}

// MARK: - SchoolReportsViewModel

@MainActor
class SchoolReportsViewModel: ObservableObject {
    @Published var classroomCount = 0
    @Published var teacherCount = 0
    @Published var studentCount = 0
    @Published var parentCount = 0
    @Published var totalPoints = 0
    @Published var storyCount = 0
    @Published var classroomStats: [ClassroomStatSummary] = []
    @Published var topClassrooms: [ClassroomStatSummary] = []
    @Published var weeklyStories = 0
    @Published var weeklyPoints = 0
    @Published var weeklyNewStudents = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadReports(schoolId: String) async {
        isLoading = true
        defer { isLoading = false }

        // Load classrooms
        var allClassrooms: [Classroom] = []
        do {
            allClassrooms = try await SupabaseConfig.client
                .from("classrooms")
                .select()
                .eq("school_id", value: schoolId)
                .execute()
                .value
            classroomCount = allClassrooms.count
        } catch {
            print("Error loading classrooms: \(error)")
        }

        // Calculate student and parent counts
        studentCount = allClassrooms.reduce(0) { $0 + $1.studentIds.count }
        parentCount = allClassrooms.reduce(0) { $0 + $1.parentIds.count }

        // Load teachers
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

        // Load total points and build classroom stats
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

        // Load stories
        if !classIds.isEmpty {
            do {
                let stories: [Story] = try await SupabaseConfig.client
                    .from("stories")
                    .select()
                    .in("class_id", values: classIds)
                    .execute()
                    .value
                storyCount = stories.count
            } catch {
                print("Error loading stories: \(error)")
            }
        }

        // Build classroom stats
        classroomStats = allClassrooms.map { classroom in
            let classPoints = allSummaries
                .filter { $0.classId == classroom.id }
                .reduce(0) { $0 + $1.totalPoints }

            return ClassroomStatSummary(
                classroomId: classroom.id ?? "",
                classroomName: classroom.name,
                teacherName: classroom.teacherName,
                gradeLevel: classroom.gradeLevel,
                studentCount: classroom.studentIds.count,
                parentCount: classroom.parentIds.count,
                totalPoints: classPoints
            )
        }

        // Top classrooms by points
        topClassrooms = classroomStats
            .sorted { $0.totalPoints > $1.totalPoints }
            .prefix(5)
            .map { $0 }

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
        SchoolReportsView(schoolId: "test-school-001")
    }
}
