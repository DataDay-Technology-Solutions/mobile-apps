import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingPasswordReset = false
    @State private var showingTestDataAlert = false
    @State private var testDataMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo/Header
                VStack(spacing: 8) {
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Hall Pass")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sign in to continue")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                    
                    if let error = authService.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button(action: signIn) {
                        if authService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                    
                    Button("Forgot Password?") {
                        showingPasswordReset = true
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.secondary)
                    Button("Sign Up") {
                        showingSignUp = true
                    }
                }
                .padding(.bottom, 32)
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetView()
            }
            .alert("Test Data", isPresented: $showingTestDataAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(testDataMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Hidden dev button - triple tap to show
                    Button("") {
                        populateTestData()
                    }
                    .frame(width: 44, height: 44)
                }
            }
        }
    }

    private func populateTestData() {
        Task {
            do {
                try await authService.populateTestData()
                testDataMessage = "Test data created successfully!\n\nTeacher: kkoelpin@pasco.k12.fl.us\nPassword: Create via Firebase Console\n\nClassroom Code: KOELPIN2024"
                showingTestDataAlert = true
            } catch {
                testDataMessage = "Error: \(error.localizedDescription)"
                showingTestDataAlert = true
            }
        }
    }

    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                // Error is handled by authService
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var selectedRole: UserRole = .parent
    @State private var classroomCode = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Information") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                Section("Role") {
                    Picker("I am a", selection: $selectedRole) {
                        Text("Parent").tag(UserRole.parent)
                        Text("Teacher").tag(UserRole.teacher)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedRole == .parent {
                        TextField("Classroom Code (optional)", text: $classroomCode)
                            .autocapitalization(.none)
                    }
                }
                
                if let error = authService.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: signUp) {
                        if authService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Create Account")
                                Spacer()
                            }
                        }
                    }
                    .disabled(!isFormValid || authService.isLoading)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() {
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    name: name,
                    role: selectedRole,
                    classroomId: classroomCode.isEmpty ? nil : classroomCode
                )
                dismiss()
            } catch {
                // Error is handled by authService
            }
        }
    }
}

// MARK: - Password Reset View
struct PasswordResetView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "envelope.badge")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Reset Password")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 32)
                
                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: resetPassword) {
                    if authService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Send Reset Link")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 32)
                .disabled(email.isEmpty || authService.isLoading)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Email Sent", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Check your email for a password reset link.")
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                try await authService.resetPassword(email: email)
                showingSuccess = true
            } catch {
                // Error is handled by authService
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AuthenticationService())
}
