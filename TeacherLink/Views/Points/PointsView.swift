//
//  PointsView.swift
//  TeacherLink
//
//  Main points/behavior tracking view for teachers
//

import SwiftUI

struct PointsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @StateObject private var pointsViewModel = PointsViewModel()

    @State private var selectedStudents: Set<String> = []
    @State private var showAwardSheet = false
    @State private var isSelectionMode = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Class Points Header
                if classroomViewModel.selectedClassroom != nil {
                    ClassPointsHeader(
                        summaries: pointsViewModel.classSummaries,
                        studentCount: classroomViewModel.students.count
                    )
                }

                // Student Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(classroomViewModel.students) { student in
                            StudentPointsCard(
                                student: student,
                                points: pointsViewModel.getPoints(for: student.id ?? ""),
                                isSelected: selectedStudents.contains(student.id ?? ""),
                                isSelectionMode: isSelectionMode
                            ) {
                                if isSelectionMode {
                                    toggleSelection(student)
                                } else {
                                    // Single student award
                                    selectedStudents = [student.id ?? ""]
                                    showAwardSheet = true
                                }
                            }
                        }
                    }
                    .padding()
                }

                // Bottom Action Bar (when in selection mode)
                if isSelectionMode && !selectedStudents.isEmpty {
                    SelectionActionBar(
                        selectedCount: selectedStudents.count,
                        onAward: { showAwardSheet = true },
                        onCancel: {
                            isSelectionMode = false
                            selectedStudents.removeAll()
                        }
                    )
                }
            }
            .navigationTitle("Points")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedStudents.removeAll()
                        }
                    } label: {
                        Text(isSelectionMode ? "Done" : "Select")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if isSelectionMode {
                        Button("Select All") {
                            selectedStudents = Set(classroomViewModel.students.compactMap { $0.id })
                        }
                    }
                }
            }
            .sheet(isPresented: $showAwardSheet) {
                AwardPointsSheet(
                    students: classroomViewModel.students.filter { selectedStudents.contains($0.id ?? "") },
                    pointsViewModel: pointsViewModel
                )
            }
            .onAppear {
                if let classId = classroomViewModel.selectedClassroom?.id {
                    pointsViewModel.listenToClass(classId: classId)
                }
            }
            .onChange(of: classroomViewModel.selectedClassroom?.id) { _, newValue in
                if let classId = newValue {
                    pointsViewModel.listenToClass(classId: classId)
                }
            }
        }
    }

    private func toggleSelection(_ student: Student) {
        guard let id = student.id else { return }
        if selectedStudents.contains(id) {
            selectedStudents.remove(id)
        } else {
            selectedStudents.insert(id)
        }
    }
}

struct ClassPointsHeader: View {
    let summaries: [StudentPointsSummary]
    let studentCount: Int

    var totalPoints: Int {
        summaries.reduce(0) { $0 + $1.totalPoints }
    }

    var averagePoints: Double {
        guard studentCount > 0 else { return 0 }
        return Double(totalPoints) / Double(studentCount)
    }

    var body: some View {
        HStack(spacing: 24) {
            VStack {
                Text("\(totalPoints)")
                    .font(.title.bold())
                    .foregroundColor(.blue)
                Text("Total Points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 40)

            VStack {
                Text(String(format: "%.1f", averagePoints))
                    .font(.title.bold())
                    .foregroundColor(.green)
                Text("Average")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 40)

            VStack {
                Text("\(studentCount)")
                    .font(.title.bold())
                    .foregroundColor(.purple)
                Text("Students")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct StudentPointsCard: View {
    let student: Student
    let points: Int
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    StudentAvatar(student: student, size: 60)

                    if isSelectionMode {
                        Circle()
                            .fill(isSelected ? Color.blue : Color.black.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: isSelected ? "checkmark" : "")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            )
                            .offset(x: 22, y: -22)
                    }
                }

                Text(student.firstName)
                    .font(.caption.bold())
                    .lineLimit(1)

                // Points Badge
                HStack(spacing: 2) {
                    Image(systemName: points >= 0 ? "star.fill" : "star")
                        .font(.caption2)
                    Text("\(points)")
                        .font(.caption.bold())
                }
                .foregroundColor(pointsColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(pointsColor.opacity(0.15))
                .cornerRadius(12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var pointsColor: Color {
        if points > 0 { return .green }
        if points < 0 { return .red }
        return .gray
    }
}

struct SelectionActionBar: View {
    let selectedCount: Int
    let onAward: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(selectedCount) selected")
                .font(.subheadline.bold())

            Spacer()

            Button(action: onAward) {
                Label("Award Points", systemImage: "star.fill")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(alignment: .top) { Divider() }
    }
}

#Preview {
    PointsView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
}
