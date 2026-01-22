import Foundation
import Supabase

// MARK: - Hall Pass Model
struct HallPass: Codable, Identifiable {
    var id: String?
    var studentId: String
    var studentName: String
    var teacherId: String
    var teacherName: String
    var destination: String
    var reason: String
    var status: HallPassStatus
    var createdAt: Date
    var returnedAt: Date?
    var classroomId: String

    enum HallPassStatus: String, Codable {
        case active
        case returned
        case expired
    }

    enum CodingKeys: String, CodingKey {
        case id
        case studentId = "student_id"
        case studentName = "student_name"
        case teacherId = "teacher_id"
        case teacherName = "teacher_name"
        case destination
        case reason
        case status
        case createdAt = "created_at"
        case returnedAt = "returned_at"
        case classroomId = "classroom_id"
    }
}

// MARK: - Teacher Model
struct Teacher: Codable, Identifiable {
    var id: String?
    var name: String
    var email: String
    var classroomId: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case classroomId = "classroom_id"
    }
}

// MARK: - Parent Model
struct Parent: Codable, Identifiable {
    var id: String?
    var name: String
    var email: String
    var studentIds: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case studentIds = "student_ids"
    }
}

// MARK: - In-App Notification Model
struct InAppNotification: Codable, Identifiable {
    var id: String?
    var userId: String
    var title: String
    var message: String
    var type: NotificationType
    var hallPassId: String?
    var isRead: Bool
    var createdAt: Date

    enum NotificationType: String, Codable {
        case hallPassCreated = "hall_pass_created"
        case hallPassReturned = "hall_pass_returned"
        case hallPassExpired = "hall_pass_expired"
        case general
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case message
        case type
        case hallPassId = "hall_pass_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// MARK: - Hall Pass Service (Supabase Backend)
@MainActor
class HallPassService: ObservableObject {
    @Published var hallPasses: [HallPass] = []
    @Published var students: [Student] = []
    @Published var notifications: [InAppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseConfig.client
    private var hallPassChannel: RealtimeChannelV2?
    private var notificationChannel: RealtimeChannelV2?

    deinit {
        Task {
            await hallPassChannel?.unsubscribe()
            await notificationChannel?.unsubscribe()
        }
    }

    // MARK: - Hall Pass Methods

    /// Create a new hall pass
    func createHallPass(
        studentId: String,
        studentName: String,
        teacherId: String,
        teacherName: String,
        destination: String,
        reason: String,
        classroomId: String
    ) async throws -> String {
        isLoading = true

        let hallPassData: [String: AnyJSON] = [
            "student_id": .string(studentId),
            "student_name": .string(studentName),
            "teacher_id": .string(teacherId),
            "teacher_name": .string(teacherName),
            "destination": .string(destination),
            "reason": .string(reason),
            "status": .string(HallPass.HallPassStatus.active.rawValue),
            "created_at": .string(ISO8601DateFormatter().string(from: Date())),
            "classroom_id": .string(classroomId)
        ]

        do {
            let response: [HallPass] = try await supabase
                .from("hall_passes")
                .insert(hallPassData)
                .select()
                .execute()
                .value

            guard let newHallPass = response.first, let hallPassId = newHallPass.id else {
                throw NSError(domain: "DatabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create hall pass"])
            }

            // Create notification for parent
            if let student = students.first(where: { $0.id == studentId }),
               let parentId = student.parentId {
                try await createNotification(
                    userId: parentId,
                    title: "Hall Pass Created",
                    message: "\(studentName) has left class for: \(destination)",
                    type: .hallPassCreated,
                    hallPassId: hallPassId
                )
            }

            isLoading = false
            return hallPassId
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Mark hall pass as returned
    func returnHallPass(hallPassId: String) async throws {
        isLoading = true

        do {
            try await supabase
                .from("hall_passes")
                .update([
                    "status": AnyJSON.string(HallPass.HallPassStatus.returned.rawValue),
                    "returned_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
                ])
                .eq("id", value: hallPassId)
                .execute()

            // Get the hall pass to notify parent
            if let hallPass = hallPasses.first(where: { $0.id == hallPassId }),
               let student = students.first(where: { $0.id == hallPass.studentId }),
               let parentId = student.parentId {
                try await createNotification(
                    userId: parentId,
                    title: "Hall Pass Returned",
                    message: "\(hallPass.studentName) has returned to class",
                    type: .hallPassReturned,
                    hallPassId: hallPassId
                )
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Listen to hall passes for a classroom (real-time updates)
    func listenToHallPasses(classroomId: String) {
        // First fetch existing data
        Task {
            await fetchHallPasses(classroomId: classroomId)
        }

        // Set up realtime subscription
        hallPassChannel = supabase.realtimeV2.channel("hall_passes_\(classroomId)")

        let insertions = hallPassChannel?.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "hall_passes",
            filter: "classroom_id=eq.\(classroomId)"
        )

        let updates = hallPassChannel?.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "hall_passes",
            filter: "classroom_id=eq.\(classroomId)"
        )

        let deletions = hallPassChannel?.postgresChange(
            DeleteAction.self,
            schema: "public",
            table: "hall_passes",
            filter: "classroom_id=eq.\(classroomId)"
        )

        Task {
            await hallPassChannel?.subscribe()

            if let insertions = insertions {
                for await insertion in insertions {
                    await MainActor.run {
                        if let newRecord = try? insertion.decodeRecord(as: HallPass.self, decoder: JSONDecoder()) {
                            self.hallPasses.insert(newRecord, at: 0)
                        }
                    }
                }
            }
        }

        Task {
            if let updates = updates {
                for await update in updates {
                    await MainActor.run {
                        if let updatedRecord = try? update.decodeRecord(as: HallPass.self, decoder: JSONDecoder()),
                           let index = self.hallPasses.firstIndex(where: { $0.id == updatedRecord.id }) {
                            self.hallPasses[index] = updatedRecord
                        }
                    }
                }
            }
        }

        Task {
            if let deletions = deletions {
                for await deletion in deletions {
                    await MainActor.run {
                        if let oldRecord = try? deletion.decodeOldRecord(as: HallPass.self, decoder: JSONDecoder()) {
                            self.hallPasses.removeAll { $0.id == oldRecord.id }
                        }
                    }
                }
            }
        }
    }

    /// Fetch hall passes for a classroom
    private func fetchHallPasses(classroomId: String) async {
        do {
            let response: [HallPass] = try await supabase
                .from("hall_passes")
                .select()
                .eq("classroom_id", value: classroomId)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run {
                self.hallPasses = response
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Listen to hall passes for a specific student (for parents)
    func listenToStudentHallPasses(studentId: String) {
        // First fetch existing data
        Task {
            await fetchStudentHallPasses(studentId: studentId)
        }

        // Set up realtime subscription
        hallPassChannel = supabase.realtimeV2.channel("hall_passes_student_\(studentId)")

        let changes = hallPassChannel?.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "hall_passes",
            filter: "student_id=eq.\(studentId)"
        )

        Task {
            await hallPassChannel?.subscribe()

            if let changes = changes {
                for await _ in changes {
                    // Refetch on any change for simplicity
                    await fetchStudentHallPasses(studentId: studentId)
                }
            }
        }
    }

    /// Fetch hall passes for a specific student
    private func fetchStudentHallPasses(studentId: String) async {
        do {
            let response: [HallPass] = try await supabase
                .from("hall_passes")
                .select()
                .eq("student_id", value: studentId)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run {
                self.hallPasses = response
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Get active hall passes count
    var activeHallPassesCount: Int {
        hallPasses.filter { $0.status == .active }.count
    }

    // MARK: - Student Methods

    /// Fetch students for a classroom
    func fetchStudents(classroomId: String) async throws {
        isLoading = true

        do {
            let response: [Student] = try await supabase
                .from("students")
                .select()
                .eq("classroom_id", value: classroomId)
                .execute()
                .value

            students = response
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Add a student to the classroom
    func addStudent(name: String, classroomId: String, parentEmail: String? = nil) async throws -> String {
        isLoading = true

        var studentData: [String: AnyJSON] = [
            "name": .string(name),
            "classroom_id": .string(classroomId)
        ]

        if let parentEmail = parentEmail {
            studentData["parent_email"] = .string(parentEmail)
        }

        do {
            let response: [Student] = try await supabase
                .from("students")
                .insert(studentData)
                .select()
                .execute()
                .value

            guard let newStudent = response.first, let studentId = newStudent.id else {
                throw NSError(domain: "DatabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to add student"])
            }

            isLoading = false
            return studentId
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Link a parent to a student
    func linkParentToStudent(studentId: String, parentId: String) async throws {
        try await supabase
            .from("students")
            .update(["parent_id": AnyJSON.string(parentId)])
            .eq("id", value: studentId)
            .execute()

        // Also update parent's student_ids array
        // First get current student_ids
        let parent: Parent = try await supabase
            .from("parents")
            .select()
            .eq("id", value: parentId)
            .single()
            .execute()
            .value

        var updatedStudentIds = parent.studentIds
        if !updatedStudentIds.contains(studentId) {
            updatedStudentIds.append(studentId)
        }

        try await supabase
            .from("parents")
            .update(["student_ids": AnyJSON.array(updatedStudentIds.map { .string($0) })])
            .eq("id", value: parentId)
            .execute()
    }

    // MARK: - Notification Methods

    /// Create an in-app notification
    func createNotification(
        userId: String,
        title: String,
        message: String,
        type: InAppNotification.NotificationType,
        hallPassId: String? = nil
    ) async throws {
        var notificationData: [String: AnyJSON] = [
            "user_id": .string(userId),
            "title": .string(title),
            "message": .string(message),
            "type": .string(type.rawValue),
            "is_read": .bool(false),
            "created_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]

        if let hallPassId = hallPassId {
            notificationData["hall_pass_id"] = .string(hallPassId)
        }

        try await supabase
            .from("notifications")
            .insert(notificationData)
            .execute()
    }

    /// Listen to notifications for a user (real-time updates)
    func listenToNotifications(userId: String) {
        // First fetch existing data
        Task {
            await fetchNotifications(userId: userId)
        }

        // Set up realtime subscription
        notificationChannel = supabase.realtimeV2.channel("notifications_\(userId)")

        let changes = notificationChannel?.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "notifications",
            filter: "user_id=eq.\(userId)"
        )

        Task {
            await notificationChannel?.subscribe()

            if let changes = changes {
                for await _ in changes {
                    // Refetch on any change
                    await fetchNotifications(userId: userId)
                }
            }
        }
    }

    /// Fetch notifications for a user
    private func fetchNotifications(userId: String) async {
        do {
            let response: [InAppNotification] = try await supabase
                .from("notifications")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            await MainActor.run {
                self.notifications = response
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Mark notification as read
    func markNotificationAsRead(notificationId: String) async throws {
        try await supabase
            .from("notifications")
            .update(["is_read": AnyJSON.bool(true)])
            .eq("id", value: notificationId)
            .execute()
    }

    /// Get unread notifications count
    var unreadNotificationsCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    // MARK: - Cleanup

    func stopListening() {
        Task {
            await hallPassChannel?.unsubscribe()
            await notificationChannel?.unsubscribe()
        }
    }
}
