//
//  AuthService.swift
//  HallPass (formerly TeacherLink)
//

import Foundation
import Supabase

class AuthService {
    static let shared = AuthService()
    private let supabase = SupabaseConfig.client

    private init() {}

    var currentUser: Supabase.User? {
        supabase.auth.currentUser
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    func signUp(
        email: String,
        password: String,
        name: String,
        role: UserRole
    ) async throws -> AppUser {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["name": AnyJSON.string(name)]
        )

        let authUser = response.user
        let userId: UUID = authUser.id

        let user = AppUser(
            id: userId.uuidString,
            email: email,
            name: name,
            role: role,
            classroomId: nil
        )

        // Convert to DatabaseUser for insertion
        let dbUser = DatabaseUser(from: user)
        try await supabase
            .from("users")
            .insert(dbUser)
            .execute()

        return user
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        try await supabase.auth.signIn(email: email, password: password)

        guard let authUser = supabase.auth.currentUser else {
            throw AuthError.userNotFound
        }

        let userId: UUID = authUser.id
        return try await getUser(userId: userId)
    }

    func signOut() throws {
        Task {
            try await supabase.auth.signOut()
        }
    }

    func getUser(userId: UUID) async throws -> AppUser {
        let dbUser: DatabaseUser = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        return dbUser.toAppUser()
    }

    func updateUser(_ user: AppUser) async throws {
        let dbUser = DatabaseUser(from: user)
        try await supabase
            .from("users")
            .update(dbUser)
            .eq("id", value: user.id)
            .execute()
    }

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    func updateFCMToken(_ token: String) async throws {
        guard let user = currentUser else { return }
        let userId: UUID = user.id
        try await supabase
            .from("users")
            .update(["fcm_token": AnyJSON.string(token)])
            .eq("id", value: userId.uuidString)
            .execute()
    }
}

// Note: AppUser is defined in AuthenticationService.swift to avoid duplication

enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case emailAlreadyInUse

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .emailAlreadyInUse:
            return "Email is already in use"
        }
    }
}
