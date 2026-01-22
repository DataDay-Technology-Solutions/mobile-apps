//
//  CreateClassView.swift
//  TeacherLink
//

import SwiftUI

struct CreateClassView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var className = ""
    @State private var gradeLevel = "1st Grade"
    @State private var selectedColor = "blue"
    @State private var isCreating = false
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""

    let gradeLevels = [
        "Pre-K", "Kindergarten",
        "1st Grade", "2nd Grade", "3rd Grade", "4th Grade", "5th Grade",
        "6th Grade", "7th Grade", "8th Grade",
        "9th Grade", "10th Grade", "11th Grade", "12th Grade"
    ]

    let colors = ["blue", "green", "purple", "orange"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Class Name", text: $className)
                        .autocapitalization(.words)

                    Picker("Grade Level", selection: $gradeLevel) {
                        ForEach(gradeLevels, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                } header: {
                    Text("Class Information")
                }

                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(colorFor(color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Class Color")
                }

                Section {
                    Text("After creating your class, you'll get a unique class code that you can share with parents. They can use this code to join your class and receive updates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isCreating {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Creating class...")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Create Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createClass()
                    }
                    .disabled(className.isEmpty || isCreating)
                }
            }
            .alert("Error Creating Class", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorAlertMessage)
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default: return .blue
        }
    }

    private func createClass() {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName ?? authViewModel.currentUser?.name else {
            errorAlertMessage = "User information not found. Please log in again."
            showErrorAlert = true
            return
        }

        print("🟦 [CreateClassView] Starting class creation...")
        print("🟦 [CreateClassView] User ID: \(userId)")
        print("🟦 [CreateClassView] User Name: \(userName)")

        isCreating = true

        Task {
            await classroomViewModel.createClassroom(
                name: className,
                gradeLevel: gradeLevel,
                teacherId: userId,
                teacherName: userName
            )

            isCreating = false

            // Check if there was an error
            if let error = classroomViewModel.errorMessage {
                print("🔴 [CreateClassView] Error: \(error)")
                errorAlertMessage = error
                showErrorAlert = true
            } else if classroomViewModel.successMessage != nil {
                print("🟩 [CreateClassView] Success! Dismissing view")
                dismiss()
            } else {
                print("⚠️ [CreateClassView] Unknown state - no error and no success")
                errorAlertMessage = "Unknown error occurred. Please try again."
                showErrorAlert = true
            }
        }
    }
}

#Preview {
    CreateClassView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
}
