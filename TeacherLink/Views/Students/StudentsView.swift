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
    @State private var showError = false
    @State private var showSuccess = false

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
            VStack(spacing: 0) {
                // Show selected classroom indicator
                if let classroom = classroomViewModel.selectedClassroom {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .foregroundColor(.blue)
                        Text(classroom.name)
                            .fontWeight(.medium)
                        if !classroom.gradeLevel.isEmpty {
                            Text("(\(classroom.gradeLevel))")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Code: \(classroom.classCode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                }

                Group {
                    if classroomViewModel.selectedClassroom == nil {
                        VStack(spacing: 16) {
                            Image(systemName: "building.2")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No Class Selected")
                                .font(.title2.bold())
                            Text("Select or create a classroom first")
                                .foregroundColor(.secondary)
                        }
                    } else if classroomViewModel.students.isEmpty {
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
            }
            .navigationTitle("Students")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddStudent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(classroomViewModel.selectedClassroom == nil)
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
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    classroomViewModel.errorMessage = nil
                }
            } message: {
                Text(classroomViewModel.errorMessage ?? "An error occurred")
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    classroomViewModel.successMessage = nil
                }
            } message: {
                Text(classroomViewModel.successMessage ?? "")
            }
            .onChange(of: classroomViewModel.errorMessage) { _, newValue in
                showError = newValue != nil
            }
            .onChange(of: classroomViewModel.successMessage) { _, newValue in
                showSuccess = newValue != nil
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
        let hash = abs(student.initials.hashValue)
        let colors: [Color] = [.blue, .green, .purple, .orange, .pink, .teal, .yellow, .red]
        return colors[hash % colors.count]
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
