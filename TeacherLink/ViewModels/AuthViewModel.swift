//
//  AuthViewModel.swift
//  TeacherLink
//

import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var passwordResetSent = false

    // Registered users (for demo purposes)
    private var registeredUsers: [String: (password: String, user: User)] = [:]

    init() {
        if USE_MOCK_DATA {
            // Don't auto-login - require authentication
            // Pre-populate with mock users for demo
            setupMockUsers()
        }
    }

    private func setupMockUsers() {
        // Add teacher
        let teacher = MockDataService.shared.teacherUser
        registeredUsers[teacher.email.lowercased()] = ("password", teacher)

        // Add admin
        let admin = MockDataService.shared.adminUser
        registeredUsers[admin.email.lowercased()] = ("admin123", admin)

        // Add parents
        for parent in MockDataService.shared.parentUsers {
            registeredUsers[parent.email.lowercased()] = ("parent123", parent)
        }
    }

    func signUp(email: String, password: String, displayName: String, role: UserRole, classCode: String? = nil) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Check if email already exists
            if registeredUsers[email.lowercased()] != nil {
                errorMessage = "An account with this email already exists"
                isLoading = false
                return
            }

            // For parents, validate class code
            if role == .parent {
                guard let code = classCode, !code.isEmpty else {
                    errorMessage = "Please enter your class code to join"
                    isLoading = false
                    return
                }

                // Validate class code
                let validCode = MockDataService.shared.classroom.classCode
                if code.uppercased() != validCode.uppercased() {
                    errorMessage = "Invalid class code. Please check with your teacher."
                    isLoading = false
                    return
                }
            }

            // Create new user
            let newUser = User(
                id: UUID().uuidString,
                email: email,
                displayName: displayName,
                role: role,
                classIds: role == .parent ? ["class1"] : [],
                createdAt: Date()
            )

            registeredUsers[email.lowercased()] = (password, newUser)
            currentUser = newUser
            isAuthenticated = true
        } else {
            errorMessage = "Firebase not configured. Enable USE_MOCK_DATA or add GoogleService-Info.plist"
        }

        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Check credentials
            if let credentials = MockDataService.shared.validateCredentials(email: email, password: password),
               let user = MockDataService.shared.getUserByCredentials(credentials) {
                currentUser = user
                isAuthenticated = true
            } else if let userData = registeredUsers[email.lowercased()], userData.password == password {
                currentUser = userData.user
                isAuthenticated = true
            } else {
                errorMessage = "Invalid email or password"
            }
        } else {
            errorMessage = "Firebase not configured. Enable USE_MOCK_DATA or add GoogleService-Info.plist"
        }

        isLoading = false
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        passwordResetSent = false

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Check if email exists
            if MockDataService.shared.getUserByEmail(email) != nil ||
               registeredUsers[email.lowercased()] != nil {
                passwordResetSent = true
                // In real app, would send email here
            } else {
                errorMessage = "No account found with this email"
            }
        }

        isLoading = false
    }

    func updatePassword(newPassword: String) async -> Bool {
        guard let user = currentUser else { return false }

        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Update password in registered users
            if var userData = registeredUsers[user.email.lowercased()] {
                userData.password = newPassword
                registeredUsers[user.email.lowercased()] = userData
            }

            isLoading = false
            return true
        }

        isLoading = false
        return false
    }

    var isTeacher: Bool {
        currentUser?.role == .teacher
    }

    var isParent: Bool {
        currentUser?.role == .parent
    }

    var isAdmin: Bool {
        currentUser?.id == "admin1"
    }

    // Switch to parent view for testing
    func switchToParentMode() {
        if USE_MOCK_DATA {
            currentUser = MockDataService.shared.parentUser
            isAuthenticated = true
        }
    }

    // Switch to teacher view for testing
    func switchToTeacherMode() {
        if USE_MOCK_DATA {
            currentUser = MockDataService.shared.teacherUser
            isAuthenticated = true
        }
    }

    // Quick login for demo
    func demoLoginAsTeacher() {
        currentUser = MockDataService.shared.teacherUser
        isAuthenticated = true
    }

    func demoLoginAsParent() {
        currentUser = MockDataService.shared.parentUser
        isAuthenticated = true
    }
}
