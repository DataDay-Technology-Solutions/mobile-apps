//
//  AuthService.swift
//  TeacherLink
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    func signUp(
        email: String,
        password: String,
        displayName: String,
        role: UserRole
    ) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)

        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()

        let user = User(
            id: result.user.uid,
            email: email,
            displayName: displayName,
            role: role,
            classIds: [],
            createdAt: Date()
        )

        try await db.collection("users").document(result.user.uid).setData(from: user)
        return user
    }

    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return try await getUser(userId: result.user.uid)
    }

    func signOut() throws {
        try auth.signOut()
    }

    func getUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let user = try? document.data(as: User.self) else {
            throw AuthError.userNotFound
        }
        return user
    }

    func updateUser(_ user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user, merge: true)
    }

    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    func updateFCMToken(_ token: String) async throws {
        guard let userId = currentUser?.uid else { return }
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }
}

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
