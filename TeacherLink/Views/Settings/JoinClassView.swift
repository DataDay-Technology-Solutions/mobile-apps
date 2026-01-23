//
//  JoinClassView.swift
//  TeacherLink
//

import SwiftUI

enum JoinCodeType: String, CaseIterable {
    case classroom = "Class Code"
    case student = "Student Code"
}

struct JoinClassView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var codeType: JoinCodeType = .classroom
    @State private var code = ""
    @State private var isJoining = false
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: codeType == .classroom ? "person.badge.plus" : "figure.and.child.holdinghands")
                    .font(.system(size: 60))
                    .foregroundColor(codeType == .classroom ? .blue : .green)

                // Code Type Picker
                Picker("Code Type", selection: $codeType) {
                    ForEach(JoinCodeType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                // Instructions
                VStack(spacing: 8) {
                    Text(codeType == .classroom ? "Join a Class" : "Link Your Child")
                        .font(.title.bold())

                    Text(codeType == .classroom
                         ? "Enter the class code provided by your child's teacher"
                         : "Enter your child's student code to link them to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Code Input
                TextField(codeType == .classroom ? "Enter Class Code" : "Enter Student Code", text: $code)
                    .font(.title2.monospaced())
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.allCharacters)
                    .padding(.horizontal, 40)
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.uppercased().prefix(codeType == .student ? 7 : 6))
                    }
                    .onChange(of: codeType) { _, _ in
                        code = ""
                        errorMessage = nil
                    }

                // Code Format Hint
                Text(codeType == .classroom ? "Format: ABC123" : "Format: SABC12")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Error Message
                if let error = errorMessage ?? classroomViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Join Button
                Button {
                    if codeType == .classroom {
                        joinClass()
                    } else {
                        linkStudent()
                    }
                } label: {
                    if isJoining {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(codeType == .classroom ? "Join Class" : "Link Child")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidCode ? Color.blue : Color.gray)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .disabled(!isValidCode || isJoining)

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
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
    }

    private var isValidCode: Bool {
        if codeType == .classroom {
            return code.count == 6
        } else {
            return code.count >= 6 && code.hasPrefix("S")
        }
    }

    private func joinClass() {
        guard let userId = authViewModel.currentUser?.id ?? authService.appUser?.id else { return }

        isJoining = true
        errorMessage = nil

        Task {
            await classroomViewModel.joinClassWithCode(code, parentId: userId)

            if classroomViewModel.errorMessage == nil {
                if let classroom = classroomViewModel.selectedClassroom {
                    successMessage = "You've joined \(classroom.teacherName)'s class: \(classroom.name)"
                    showSuccess = true
                }
            }

            isJoining = false
        }
    }

    private func linkStudent() {
        guard let userId = authViewModel.currentUser?.id ?? authService.appUser?.id else { return }

        isJoining = true
        errorMessage = nil

        Task {
            do {
                let student = try await classroomViewModel.linkParentToStudentWithCode(code, parentId: userId)
                successMessage = "You've linked \(student.fullName) to your account!"
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
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
