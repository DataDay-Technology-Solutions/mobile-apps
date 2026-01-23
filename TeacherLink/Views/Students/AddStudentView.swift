//
//  AddStudentView.swift
//  TeacherLink
//

import SwiftUI

struct AddStudentView: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isAdding = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                // Show which class the student is being added to
                if let classroom = classroomViewModel.selectedClassroom {
                    Section {
                        HStack {
                            Image(systemName: "building.2")
                                .foregroundColor(.blue)
                            Text(classroom.name)
                                .fontWeight(.medium)
                            if !classroom.gradeLevel.isEmpty {
                                Text("(\(classroom.gradeLevel))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Adding to Class")
                    }
                }

                Section {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)

                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                } header: {
                    Text("Student Information")
                }

                // Show error if any
                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                        }
                    }
                }

                Section {
                    Text("After adding a student, you can share the class code with their parents so they can connect and receive updates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Note")
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isAdding)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isAdding {
                        ProgressView()
                    } else {
                        Button("Add") {
                            addStudent()
                        }
                        .disabled(!isValid)
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        classroomViewModel.selectedClassroom != nil
    }

    private func addStudent() {
        guard classroomViewModel.selectedClassroom != nil else {
            errorMessage = "No classroom selected. Please select a class first."
            return
        }

        isAdding = true
        errorMessage = nil

        Task {
            await classroomViewModel.addStudent(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces)
            )

            // Check if there was an error
            if let error = classroomViewModel.errorMessage {
                errorMessage = error
                isAdding = false
            } else {
                // Success - dismiss the view
                dismiss()
            }
        }
    }
}

#Preview {
    AddStudentView()
        .environmentObject(ClassroomViewModel())
}
