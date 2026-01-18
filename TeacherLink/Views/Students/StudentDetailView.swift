//
//  StudentDetailView.swift
//  TeacherLink
//

import SwiftUI

struct StudentDetailView: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) private var dismiss

    let student: Student
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            // Avatar Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        StudentAvatar(student: student, size: 100)

                        Text(student.fullName)
                            .font(.title2.bold())
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            // Points Section
            Section {
                NavigationLink {
                    StudentPointsHistoryView(student: student)
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 32)

                        Text("View Points & History")

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Behavior Points")
            }

            // Parent Connections
            Section {
                if student.parentIds.isEmpty {
                    HStack {
                        Image(systemName: "person.fill.questionmark")
                            .foregroundColor(.orange)

                        VStack(alignment: .leading) {
                            Text("No Parents Connected")
                                .font(.subheadline.bold())
                            Text("Share the class code with this student's parents")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    ForEach(student.parentIds, id: \.self) { parentId in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)

                            Text("Parent")
                                .font(.subheadline)

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            } header: {
                Text("Parent Connections")
            }

            // Class Code Section
            Section {
                if let classroom = classroomViewModel.selectedClassroom {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Class Code")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(classroom.classCode)
                                .font(.title.monospaced().bold())

                            Spacer()

                            Button {
                                UIPasteboard.general.string = classroom.classCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }

                            ShareLink(item: "Join my class on TeacherLink!\n\nClass Code: \(classroom.classCode)\n\nDownload the app and enter this code to connect.") {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                }
            } header: {
                Text("Invite Parents")
            } footer: {
                Text("Share this code with \(student.firstName)'s parents so they can connect to your class.")
            }

            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Remove Student")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(student.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Remove Student", isPresented: $showDeleteConfirm) {
            Button("Remove", role: .destructive) {
                Task {
                    await classroomViewModel.deleteStudent(student)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to remove \(student.fullName) from your class? This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        StudentDetailView(student: Student(
            id: "1",
            firstName: "Emma",
            lastName: "Smith",
            classId: "class1"
        ))
        .environmentObject(ClassroomViewModel())
    }
}
