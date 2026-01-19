import Foundation
import FirebaseFirestore

// MARK: - Hall Pass Model
struct HallPass: Codable, Identifiable {
    @DocumentID var id: String?
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
}

// MARK: - Teacher Model
struct Teacher: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var classroomId: String
}

// MARK: - Parent Model
struct Parent: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var studentIds: [String]
}

// MARK: - In-App Notification Model
struct InAppNotification: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var message: String
    var type: NotificationType
    var hallPassId: String?
    var isRead: Bool
    var createdAt: Date
    
    enum NotificationType: String, Codable {
        case hallPassCreated
        case hallPassReturned
        case hallPassExpired
        case general
    }
}

// MARK: - Firestore Service
@MainActor
class FirestoreService: ObservableObject {
    @Published var hallPasses: [HallPass] = []
    @Published var students: [Student] = []
    @Published var notifications: [InAppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var hallPassListener: ListenerRegistration?
    private var notificationListener: ListenerRegistration?
    
    deinit {
        hallPassListener?.remove()
        notificationListener?.remove()
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
        
        let hallPassData: [String: Any] = [
            "studentId": studentId,
            "studentName": studentName,
            "teacherId": teacherId,
            "teacherName": teacherName,
            "destination": destination,
            "reason": reason,
            "status": HallPass.HallPassStatus.active.rawValue,
            "createdAt": Timestamp(date: Date()),
            "classroomId": classroomId
        ]
        
        do {
            let docRef = try await db.collection("hallPasses").addDocument(data: hallPassData)
            
            // Create notification for parent
            if let student = students.first(where: { $0.id == studentId }),
               let parentId = student.parentId {
                try await createNotification(
                    userId: parentId,
                    title: "Hall Pass Created",
                    message: "\(studentName) has left class for: \(destination)",
                    type: .hallPassCreated,
                    hallPassId: docRef.documentID
                )
            }
            
            isLoading = false
            return docRef.documentID
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
            try await db.collection("hallPasses").document(hallPassId).updateData([
                "status": HallPass.HallPassStatus.returned.rawValue,
                "returnedAt": Timestamp(date: Date())
            ])
            
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
        hallPassListener?.remove()
        
        hallPassListener = db.collection("hallPasses")
            .whereField("classroomId", isEqualTo: classroomId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.hallPasses = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: HallPass.self)
                } ?? []
            }
    }
    
    /// Listen to hall passes for a specific student (for parents)
    func listenToStudentHallPasses(studentId: String) {
        hallPassListener?.remove()
        
        hallPassListener = db.collection("hallPasses")
            .whereField("studentId", isEqualTo: studentId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.hallPasses = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: HallPass.self)
                } ?? []
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
            let snapshot = try await db.collection("students")
                .whereField("classroomId", isEqualTo: classroomId)
                .getDocuments()
            
            students = snapshot.documents.compactMap { doc in
                try? doc.data(as: Student.self)
            }
            
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
        
        var studentData: [String: Any] = [
            "name": name,
            "classroomId": classroomId
        ]
        
        if let parentEmail = parentEmail {
            studentData["parentEmail"] = parentEmail
        }
        
        do {
            let docRef = try await db.collection("students").addDocument(data: studentData)
            isLoading = false
            return docRef.documentID
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Link a parent to a student
    func linkParentToStudent(studentId: String, parentId: String) async throws {
        try await db.collection("students").document(studentId).updateData([
            "parentId": parentId
        ])
        
        // Also update parent's studentIds array
        try await db.collection("parents").document(parentId).updateData([
            "studentIds": FieldValue.arrayUnion([studentId])
        ])
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
        var notificationData: [String: Any] = [
            "userId": userId,
            "title": title,
            "message": message,
            "type": type.rawValue,
            "isRead": false,
            "createdAt": Timestamp(date: Date())
        ]
        
        if let hallPassId = hallPassId {
            notificationData["hallPassId"] = hallPassId
        }
        
        try await db.collection("notifications").addDocument(data: notificationData)
    }
    
    /// Listen to notifications for a user (real-time updates)
    func listenToNotifications(userId: String) {
        notificationListener?.remove()
        
        notificationListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.notifications = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: InAppNotification.self)
                } ?? []
            }
    }
    
    /// Mark notification as read
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    /// Get unread notifications count
    var unreadNotificationsCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Cleanup
    
    func stopListening() {
        hallPassListener?.remove()
        notificationListener?.remove()
    }
}
