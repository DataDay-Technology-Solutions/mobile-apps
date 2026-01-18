//
//  SignUpView.swift
//  TeacherLink
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRole: UserRole = .teacher
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var classCode = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Create Account")
                            .font(.title.bold())

                        Text("Join TeacherLink today")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Role Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I am a...")
                            .font(.headline)

                        HStack(spacing: 12) {
                            RoleButton(
                                role: .teacher,
                                title: "Teacher",
                                icon: "person.fill.viewfinder",
                                isSelected: selectedRole == .teacher
                            ) {
                                selectedRole = .teacher
                            }

                            RoleButton(
                                role: .parent,
                                title: "Parent",
                                icon: "figure.2.and.child.holdinghands",
                                isSelected: selectedRole == .parent
                            ) {
                                selectedRole = .parent
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Form
                    VStack(spacing: 16) {
                        CustomTextField(
                            icon: "person.fill",
                            placeholder: selectedRole == .teacher ? "Full Name" : "Parent Name",
                            text: $displayName
                        )
                        .textContentType(.name)

                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                        // Class code for parents
                        if selectedRole == .parent {
                            VStack(alignment: .leading, spacing: 4) {
                                CustomTextField(
                                    icon: "number.circle.fill",
                                    placeholder: "Class Code",
                                    text: $classCode
                                )
                                .autocapitalization(.allCharacters)

                                Text("Enter the code your teacher provided")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                            }
                        }

                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password
                        )
                        .textContentType(.newPassword)

                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Confirm Password",
                            text: $confirmPassword
                        )
                        .textContentType(.newPassword)

                        if !passwordsMatch && !confirmPassword.isEmpty {
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        if password.count > 0 && password.count < 6 {
                            Text("Password must be at least 6 characters")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }

                    // Sign Up Button
                    Button {
                        Task {
                            await authViewModel.signUp(
                                email: email,
                                password: password,
                                displayName: displayName,
                                role: selectedRole,
                                classCode: selectedRole == .parent ? classCode : nil
                            )
                            if authViewModel.isAuthenticated {
                                dismiss()
                            }
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Create Account")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    .disabled(!isFormValid || authViewModel.isLoading)

                    // Terms
                    Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var passwordsMatch: Bool {
        password == confirmPassword
    }

    private var isFormValid: Bool {
        let baseValid = !displayName.isEmpty &&
            !email.isEmpty &&
            email.contains("@") &&
            password.count >= 6 &&
            passwordsMatch

        // Parents must also provide class code
        if selectedRole == .parent {
            return baseValid && !classCode.isEmpty
        }

        return baseValid
    }
}

struct RoleButton: View {
    let role: UserRole
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.subheadline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
