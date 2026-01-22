//
//  AuthenticationService.swift
//  HallPass (formerly TeacherLink)
//
//  Observable authentication service for SwiftUI
//

import Foundation
import Supabase
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var appUser: AppUser?
    @Published var errorMessage: String?
    @Published var needsEmailConfirmation = false
    @Published var pendingEmail: String?

    private let supabase = SupabaseConfig.client
    private var authStateTask: Task<Void, Never>?

    init() {
        setupAuthStateListener()
    }

    deinit {
        authStateTask?.cancel()
    }

    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await handleAuthStateChange(event: event, session: session)
            }
        }

        // Check initial auth state
        Task {
            await checkCurrentSession()
        }
    }

    private func checkCurrentSession() async {
        isLoading = true
        do {
            let session = try await supabase.auth.session
            let user = session.user
            // Check if email is confirmed
            if user.emailConfirmedAt != nil {
                await loadUserProfile(userId: user.id)
            } else {
                // Email not confirmed yet
                needsEmailConfirmation = true
                pendingEmail = user.email
                isAuthenticated = false
                appUser = nil
            }
        } catch {
            // No session exists - user needs to login
            isAuthenticated = false
            appUser = nil
            needsEmailConfirmation = false
        }
        isLoading = false
    }

    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) async {
        switch event {
        case .signedIn:
            if let user = session?.user {
                await loadUserProfile(userId: user.id)
            }
        case .signedOut:
            isAuthenticated = false
            appUser = nil
        case .userUpdated:
            if let user = session?.user {
                await loadUserProfile(userId: user.id)
            }
        default:
            break
        }
    }

    private func loadUserProfile(userId: UUID) async {
        do {
            let dbUser: DatabaseUser = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId.uuidString.lowercased())
                .single()
                .execute()
                .value

            appUser = dbUser.toAppUser()
            isAuthenticated = true
        } catch {
            // User might not have a profile yet
            print("Error loading user profile: \(error)")
            isAuthenticated = true
            appUser = nil
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String, role: UserRole) async throws {
        isLoading = true
        errorMessage = nil
        needsEmailConfirmation = false

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": AnyJSON.string(name)]
            )

            let authUser = response.user
            let userId = authUser.id

            // Create user profile in database
            let newUser = AppUser(
                id: userId.uuidString.lowercased(),
                email: email,
                name: name,
                role: role
            )

            let dbUser = DatabaseUser(from: newUser)
            try await supabase
                .from("users")
                .insert(dbUser)
                .execute()

            // Check if email confirmation is required
            if authUser.emailConfirmedAt == nil {
                // Email confirmation required
                needsEmailConfirmation = true
                pendingEmail = email
                isAuthenticated = false
                appUser = nil
            } else {
                // No confirmation needed (e.g., confirmation disabled in Supabase)
                appUser = newUser
                isAuthenticated = true
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signIn(email: email, password: password)

            guard let user = supabase.auth.currentUser else {
                throw AuthError.userNotFound
            }

            await loadUserProfile(userId: user.id)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            do {
                try await supabase.auth.signOut()
                isAuthenticated = false
                appUser = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        isLoading = false
    }

    // MARK: - Helper Properties

    var isAdmin: Bool {
        appUser?.role == .admin
    }

    var isTeacher: Bool {
        appUser?.role == .teacher
    }

    var isParent: Bool {
        appUser?.role == .parent
    }

    var currentUserId: String? {
        appUser?.id
    }

    var currentUserName: String {
        appUser?.name ?? "User"
    }
}
