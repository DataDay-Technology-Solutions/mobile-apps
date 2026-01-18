//
//  StudentsView.swift
//  TeacherLink
//

import SwiftUI

struct StudentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel

    @State private var showAddStudent = false
    @State private var searchText = ""

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return classroomViewModel.students
        }
        return classroomViewModel.students.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if classroomViewModel.students.isEmpty {
                    EmptyStudentsView()
                } else {
                    List {
                        ForEach(filteredStudents) { student in
                            NavigationLink {
                                StudentDetailView(student: student)
                                    .environmentObject(classroomViewModel)
                            } label: {
                                StudentRow(student: student)
                            }
                        }
                        .onDelete(perform: deleteStudents)
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search students")
                }
            }
            .navigationTitle("Students")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddStudent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Text("\(classroomViewModel.students.count) students")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showAddStudent) {
                AddStudentView()
                    .environmentObject(classroomViewModel)
            }
        }
    }

    private func deleteStudents(at offsets: IndexSet) {
        for index in offsets {
            let student = filteredStudents[index]
            Task {
                await classroomViewModel.deleteStudent(student)
            }
        }
    }
}

struct StudentRow: View {
    let student: Student

    var body: some View {
        HStack(spacing: 12) {
            StudentAvatar(student: student, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(student.fullName)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(student.parentIds.count) parent(s)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StudentAvatar: View {
    let student: Student
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: size, height: size)

            // Simple monster face
            VStack(spacing: 2) {
                HStack(spacing: size * 0.15) {
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.2, height: size * 0.2)
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.2, height: size * 0.2)
                }

                // Smile
                Capsule()
                    .fill(.white)
                    .frame(width: size * 0.3, height: size * 0.08)
            }
        }
    }

    private var avatarColor: Color {
        switch student.avatarStyle.backgroundColor {
        case "avatarBlue": return .blue
        case "avatarGreen": return .green
        case "avatarPurple": return .purple
        case "avatarOrange": return .orange
        case "avatarPink": return .pink
        case "avatarTeal": return .teal
        case "avatarYellow": return .yellow
        case "avatarRed": return .red
        default: return .blue
        }
    }
}

struct EmptyStudentsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Students Yet")
                .font(.title2.bold())

            Text("Add students to your class to get started")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    StudentsView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
}
