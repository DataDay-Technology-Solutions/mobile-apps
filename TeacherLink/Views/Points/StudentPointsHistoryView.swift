//
//  StudentPointsHistoryView.swift
//  TeacherLink
//
//  View showing a student's points history
//

import SwiftUI

struct StudentPointsHistoryView: View {
    let student: Student
    @StateObject private var pointsViewModel = PointsViewModel()
    @State private var showResetConfirm = false

    var body: some View {
        List {
            // Summary Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        StudentAvatar(student: student, size: 80)

                        Text(student.fullName)
                            .font(.title2.bold())

                        // Points Display
                        HStack(spacing: 24) {
                            PointsStat(
                                value: pointsViewModel.selectedStudentSummary?.totalPoints ?? 0,
                                label: "Total",
                                color: totalColor
                            )

                            PointsStat(
                                value: pointsViewModel.selectedStudentSummary?.positiveCount ?? 0,
                                label: "Positive",
                                color: .green
                            )

                            PointsStat(
                                value: pointsViewModel.selectedStudentSummary?.negativeCount ?? 0,
                                label: "Needs Work",
                                color: .red
                            )
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // History Section
            Section {
                if pointsViewModel.studentHistory.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "star")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No points yet")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 32)
                        Spacer()
                    }
                } else {
                    ForEach(pointsViewModel.studentHistory) { record in
                        PointRecordRow(record: record)
                    }
                }
            } header: {
                Text("History")
            }

            // Reset Section
            Section {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset All Points")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Points")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let studentId = student.id {
                Task {
                    await pointsViewModel.loadStudentHistory(studentId: studentId, classId: student.classId)
                }
                pointsViewModel.listenToStudent(studentId: studentId, classId: student.classId)
            }
        }
        .confirmationDialog("Reset Points", isPresented: $showResetConfirm) {
            Button("Reset All Points", role: .destructive) {
                if let studentId = student.id {
                    Task {
                        await pointsViewModel.resetStudentPoints(studentId: studentId, classId: student.classId)
                    }
                }
            }
        } message: {
            Text("This will delete all point history for \(student.firstName). This action cannot be undone.")
        }
    }

    private var totalColor: Color {
        let total = pointsViewModel.selectedStudentSummary?.totalPoints ?? 0
        if total > 0 { return .green }
        if total < 0 { return .red }
        return .gray
    }
}

struct PointsStat: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PointRecordRow: View {
    let record: PointRecord

    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(record.isPositive ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: record.isPositive ? "plus" : "minus")
                    .font(.headline)
                    .foregroundColor(record.isPositive ? .green : .red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(record.behaviorName)
                    .font(.subheadline.bold())

                Text(record.timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(record.points > 0 ? "+\(record.points)" : "\(record.points)")
                .font(.headline)
                .foregroundColor(record.isPositive ? .green : .red)
        }
    }
}

#Preview {
    NavigationStack {
        StudentPointsHistoryView(
            student: Student(id: "1", firstName: "Emma", lastName: "Smith", classId: "class1")
        )
    }
}
