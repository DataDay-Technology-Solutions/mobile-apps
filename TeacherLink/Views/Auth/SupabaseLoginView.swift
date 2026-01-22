//
//  SupabaseLoginView.swift
//  HallPass (formerly TeacherLink)
//
//  Login view for Supabase authentication
//

import SwiftUI

struct SupabaseLoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var name = ""
    @State private var selectedRole: UserRole = .parent
    @State private var showingAlert = false
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8),
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.3, green: 0.7, blue: 0.9)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }

            // Floating shapes for visual interest
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: -50)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: geometry.size.width - 80, y: 100)
            }

            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)

                    // Logo/Header
                    VStack(spacing: 16) {
                        // App icon style logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.3, green: 0.5, blue: 0.9),
                                            Color(red: 0.6, green: 0.3, blue: 0.8),
                                            Color(red: 0.9, green: 0.4, blue: 0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

                            VStack(spacing: 2) {
                                Image(systemName: "graduationcap.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 20, y: -10)
                            }
                        }

                        Text("HallPass")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text(isSignUp ? "Create your account" : "Welcome back!")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.bottom, 20)

                    // Form Card
                    VStack(spacing: 20) {
                        if isSignUp {
                            LoginTextField(
                                icon: "person.fill",
                                placeholder: "Full Name",
                                text: $name
                            )
                            .textContentType(.name)

                            // Role Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("I am a...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                HStack(spacing: 12) {
                                    LoginRoleButton(
                                        title: "Parent",
                                        icon: "figure.2.and.child.holdinghands",
                                        isSelected: selectedRole == .parent
                                    ) {
                                        selectedRole = .parent
                                    }

                                    LoginRoleButton(
                                        title: "Teacher",
                                        icon: "person.fill.viewfinder",
                                        isSelected: selectedRole == .teacher
                                    ) {
                                        selectedRole = .teacher
                                    }
                                }
                            }
                        }

                        LoginTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                        LoginSecureField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password
                        )
                        .textContentType(isSignUp ? .newPassword : .password)

                        // Error Message
                        if let error = authService.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                        }

                        // Action Button
                        Button(action: {
                            Task {
                                if isSignUp {
                                    try? await authService.signUp(
                                        email: email,
                                        password: password,
                                        name: name,
                                        role: selectedRole
                                    )
                                } else {
                                    try? await authService.signIn(
                                        email: email,
                                        password: password
                                    )
                                }
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.3, blue: 0.9),
                                        Color(red: 0.6, green: 0.3, blue: 0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.5), radius: 8, y: 4)
                        }
                        .disabled(authService.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    )
                    .padding(.horizontal, 24)

                    // Toggle Sign Up / Sign In
                    Button(action: {
                        withAnimation(.spring()) {
                            isSignUp.toggle()
                            authService.errorMessage = nil
                        }
                    }) {
                        HStack {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.white.opacity(0.8))
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 8)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
}

// MARK: - Custom Components

struct LoginTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)

            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LoginSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LoginRoleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          LinearGradient(colors: [Color(red: 0.4, green: 0.3, blue: 0.9), Color(red: 0.6, green: 0.3, blue: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                          LinearGradient(colors: [Color(.systemGray5), Color(.systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

#Preview {
    SupabaseLoginView()
        .environmentObject(AuthenticationService())
}
