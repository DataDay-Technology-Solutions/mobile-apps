//
//  JoinClassView.swift
//  TeacherLink
//

import SwiftUI

struct JoinClassView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var classCode = ""
    @State private var isJoining = false
    @State private var showSuccess = false
    @State private var joinedClassroom: Classroom?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                // Instructions
                VStack(spacing: 8) {
                    Text("Join a Class")
                        .font(.title.bold())

                    Text("Enter the class code provided by your child's teacher")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Code Input
                TextField("Enter Class Code", text: $classCode)
                    .font(.title2.monospaced())
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .padding(.horizontal, 40)
                    .onChange(of: classCode) { _, newValue in
                        classCode = String(newValue.uppercased().prefix(6))
                    }

                // Error Message
                if let error = classroomViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Join Button
                Button {
                    joinClass()
                } label: {
                    if isJoining {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Join Class")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(classCode.count == 6 ? Color.blue : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .disabled(classCode.count != 6 || isJoining)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Welcome!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if let classroom = joinedClassroom {
                    Text("You've joined \(classroom.teacherName)'s class: \(classroom.name)")
                }
            }
        }
    }

    private func joinClass() {
        guard let userId = authViewModel.currentUser?.id else { return }

        isJoining = true

        Task {
            await classroomViewModel.joinClassWithCode(classCode, parentId: userId)

            if classroomViewModel.errorMessage == nil {
                joinedClassroom = classroomViewModel.selectedClassroom
                showSuccess = true
            }

            isJoining = false
        }
    }
}

#Preview {
    JoinClassView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
}
