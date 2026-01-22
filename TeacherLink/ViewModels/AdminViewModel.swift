//
//  AdminViewModel.swift
//  HallPass (formerly TeacherLink)
//
//  ViewModel for admin dashboard functionality
//

import Foundation
import Supabase

@MainActor
class AdminViewModel: ObservableObject {
    @Published var users: [AppUser] = []
    @Published var classrooms: [Classroom] = []
    @Published var recentActivity: [AdminActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Stats
    @Published var totalUsers = 0
    @Published var totalTeachers = 0
    @Published var totalParents = 0
    @Published var totalClassrooms = 0

    private let supabase = SupabaseConfig.client

    // MARK: - Load Stats

    func loadStats() async {
        isLoading = true

        do {
            // Load users count by role
            let allUsers: [DatabaseUser] = try await supabase
                .from("users")
                .select()
                .execute()
                .value

            totalUsers = allUsers.count
            totalTeachers = allUsers.filter { $0.role == "teacher" }.count
            totalParents = allUsers.filter { $0.role == "parent" }.count

            // Load classrooms count
            let allClassrooms: [Classroom] = try await supabase
                .from("classrooms")
                .select()
                .execute()
                .value

            totalClassrooms = allClassrooms.count

            // Generate some recent activity
            recentActivity = generateRecentActivity()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load Users

    func loadUsers() async {
        isLoading = true

        do {
            let dbUsers: [DatabaseUser] = try await supabase
                .from("users")
                .select()
                .order("name", ascending: true)
                .execute()
                .value

            users = dbUsers.map { $0.toAppUser() }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Load Classrooms

    func loadClassrooms() async {
        isLoading = true

        do {
            classrooms = try await supabase
                .from("classrooms")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - User Management

    func createUser(email: String, name: String, password: String, role: UserRole) async {
        isLoading = true
        errorMessage = nil

        do {
            // Create auth user
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": AnyJSON.string(name)]
            )

            let authUser = response.user
            let userId = authUser.id

            // Create user profile
            let newUser = AppUser(
                id: userId.uuidString,
                email: email,
                name: name,
                role: role
            )

            let dbUser = DatabaseUser(from: newUser)
            try await supabase
                .from("users")
                .insert(dbUser)
                .execute()

            // Reload users
            await loadUsers()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func updateUserRole(userId: String, newRole: UserRole) async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase
                .from("users")
                .update(["role": AnyJSON.string(newRole.rawValue)])
                .eq("id", value: userId)
                .execute()

            // Update local state
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index] = AppUser(
                    id: users[index].id,
                    email: users[index].email,
                    name: users[index].name,
                    role: newRole,
                    classroomId: users[index].classroomId,
                    classIds: users[index].classIds,
                    studentIds: users[index].studentIds,
                    fcmToken: users[index].fcmToken
                )
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteUser(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Delete user profile
            try await supabase
                .from("users")
                .delete()
                .eq("id", value: userId)
                .execute()

            // Note: To fully delete the auth user, you'd need to use the admin API
            // which requires a service role key (not safe for client-side)

            // Update local state
            users.removeAll { $0.id == userId }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Classroom Management

    func deleteClassroom(classroomId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Delete associated students first
            try await supabase
                .from("students")
                .delete()
                .eq("class_id", value: classroomId)
                .execute()

            // Delete the classroom
            try await supabase
                .from("classrooms")
                .delete()
                .eq("id", value: classroomId)
                .execute()

            // Update local state
            classrooms.removeAll { $0.id == classroomId }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func generateRecentActivity() -> [AdminActivity] {
        // In a real app, you'd fetch this from an activity log table
        return [
            AdminActivity(
                title: "System started",
                icon: "power",
                color: .green,
                timestamp: Date()
            )
        ]
    }
}
