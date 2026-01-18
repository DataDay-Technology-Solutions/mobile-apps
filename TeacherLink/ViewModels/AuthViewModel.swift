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

    init() {
        if USE_MOCK_DATA {
            // Auto-login as teacher in mock mode
            currentUser = MockDataService.shared.teacherUser
            isAuthenticated = true
        }
    }

    func signUp(email: String, password: String, displayName: String, role: UserRole) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            currentUser = User(
                id: UUID().uuidString,
                email: email,
                displayName: displayName,
                role: role,
                classIds: [],
                createdAt: Date()
            )
            isAuthenticated = true
        } else {
            // Firebase implementation would go here
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

            // In mock mode, log in as teacher
            currentUser = MockDataService.shared.teacherUser
            isAuthenticated = true
        } else {
            errorMessage = "Firebase not configured. Enable USE_MOCK_DATA or add GoogleService-Info.plist"
        }

        isLoading = false
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 500_000_000)
            // Just simulate success in mock mode
        }

        isLoading = false
    }

    var isTeacher: Bool {
        currentUser?.role == .teacher
    }

    var isParent: Bool {
        currentUser?.role == .parent
    }

    // Switch to parent view for testing
    func switchToParentMode() {
        if USE_MOCK_DATA {
            currentUser = MockDataService.shared.parentUser
        }
    }

    // Switch to teacher view for testing
    func switchToTeacherMode() {
        if USE_MOCK_DATA {
            currentUser = MockDataService.shared.teacherUser
        }
    }
}
