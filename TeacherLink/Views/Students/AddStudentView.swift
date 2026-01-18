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

    var body: some View {
        NavigationStack {
            Form {
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
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addStudent()
                    }
                    .disabled(!isValid || isAdding)
                }
            }
        }
    }

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func addStudent() {
        isAdding = true

        Task {
            await classroomViewModel.addStudent(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces)
            )
            dismiss()
        }
    }
}

#Preview {
    AddStudentView()
        .environmentObject(ClassroomViewModel())
}
