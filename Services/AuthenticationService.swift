import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - User Types
enum UserRole: String, Codable {
    case teacher
    case parent
    case student
}

// MARK: - User Model
struct AppUser: Codable, Identifiable {
    let id: String
    var email: String
    var name: String
    var role: UserRole
    var classroomId: String?
    var studentIds: [String]? // For parents - their children
    var parentId: String? // For students - their parent
    var createdAt: Date
    
    init(id: String, email: String, name: String, role: UserRole, classroomId: String? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.classroomId = classroomId
        self.createdAt = Date()
    }
}

// MARK: - Authentication Service
@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var appUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("🔐 Auth state changed: \(user?.email ?? "nil")")
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil

                if let user = user {
                    print("🔐 User authenticated, fetching profile...")
                    // Use a timeout to prevent hanging
                    await self?.fetchAppUserWithTimeout(userId: user.uid)
                } else {
                    self?.appUser = nil
                }
            }
        }
    }

    /// Fetch user with a timeout to prevent hanging
    private func fetchAppUserWithTimeout(userId: String) async {
        // Create the user immediately as a fallback
        if let firebaseUser = currentUser {
            let email = firebaseUser.email ?? ""
            let role = await determineRoleByEmail(email: email)

            let fallbackUser = AppUser(
                id: userId,
                email: email,
                name: firebaseUser.displayName ?? email.components(separatedBy: "@").first ?? "User",
                role: role,
                classroomId: role == .teacher ? "class_001" : nil
            )

            // Set immediately so UI doesn't hang
            self.appUser = fallbackUser
            print("✅ Set immediate fallback appUser: \(email) as \(role.rawValue)")

            // Then try to fetch/update from Firestore in background
            Task {
                await fetchAppUser(userId: userId)
            }
        }
    }
    
    // MARK: - Sign Up with Email
    func signUp(email: String, password: String, name: String, role: UserRole, classroomId: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let newUser = AppUser(
                id: result.user.uid,
                email: email,
                name: name,
                role: role,
                classroomId: classroomId
            )
            
            try await createUserProfile(user: newUser)
            
            // Also add to role-specific collection
            try await addToRoleCollection(user: newUser)
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign In with Email
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            appUser = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Firestore User Profile
    private func createUserProfile(user: AppUser) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "role": user.role.rawValue,
            "classroomId": user.classroomId ?? "",
            "createdAt": Timestamp(date: user.createdAt)
        ]
        
        try await db.collection("users").document(user.id).setData(userData)
    }
    
    private func addToRoleCollection(user: AppUser) async throws {
        let collectionName: String
        switch user.role {
        case .teacher:
            collectionName = "teachers"
        case .parent:
            collectionName = "parents"
        case .student:
            collectionName = "students"
        }
        
        var data: [String: Any] = [
            "name": user.name,
            "email": user.email
        ]
        
        if let classroomId = user.classroomId {
            data["classroomId"] = classroomId
        }
        
        try await db.collection(collectionName).document(user.id).setData(data)
    }
    
    func fetchAppUser(userId: String) async {
        print("🔍 fetchAppUser called for userId: \(userId)")

        do {
            let document = try await db.collection("users").document(userId).getDocument()
            print("📄 Document exists: \(document.exists)")

            if document.exists, let data = document.data() {
                print("✅ Found existing user document")
                appUser = AppUser(
                    id: userId,
                    email: data["email"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    role: UserRole(rawValue: data["role"] as? String ?? "parent") ?? .parent,
                    classroomId: data["classroomId"] as? String
                )
            } else {
                // User document doesn't exist - create one
                print("⚠️ No user document found, creating one...")

                if let firebaseUser = currentUser {
                    let email = firebaseUser.email ?? ""
                    print("📧 Email: \(email)")

                    // Check if this email matches a known teacher/parent
                    let role = await determineRoleByEmail(email: email)
                    let classroomId = role == .teacher ? "class_001" : nil
                    print("👤 Determined role: \(role.rawValue)")

                    // Create the user profile
                    let newUser = AppUser(
                        id: userId,
                        email: email,
                        name: firebaseUser.displayName ?? email.components(separatedBy: "@").first ?? "User",
                        role: role,
                        classroomId: classroomId
                    )

                    // Try to save to Firestore, but set appUser regardless
                    do {
                        try await createUserProfile(user: newUser)
                        try await addToRoleCollection(user: newUser)
                        print("✅ Created user profile in Firestore")
                    } catch {
                        print("⚠️ Could not save to Firestore (permissions?): \(error.localizedDescription)")
                        // Continue anyway - user can still use the app
                    }

                    // Set appUser even if Firestore save failed
                    appUser = newUser
                    print("✅ Set appUser: \(newUser.email) as \(newUser.role.rawValue)")
                } else {
                    print("❌ No currentUser available")
                }
            }
        } catch {
            print("❌ Error fetching user document: \(error.localizedDescription)")

            // Fallback: Create a basic user profile anyway so app doesn't hang
            if let firebaseUser = currentUser {
                let email = firebaseUser.email ?? ""
                let role = await determineRoleByEmail(email: email)

                appUser = AppUser(
                    id: userId,
                    email: email,
                    name: firebaseUser.displayName ?? email.components(separatedBy: "@").first ?? "User",
                    role: role,
                    classroomId: role == .teacher ? "class_001" : nil
                )
                print("✅ Created fallback appUser: \(email) as \(role.rawValue)")
            }
        }
    }

    /// Determines user role based on email domain or known emails
    private func determineRoleByEmail(email: String) async -> UserRole {
        let lowercasedEmail = email.lowercased()

        // Known teacher emails
        let teacherEmails = [
            "kkoelpin@pasco.k12.fl.us"
        ]

        if teacherEmails.contains(lowercasedEmail) {
            return .teacher
        }

        // Check if email domain suggests a teacher (school email)
        if lowercasedEmail.contains("@pasco.k12.fl.us") ||
           lowercasedEmail.contains(".edu") ||
           lowercasedEmail.contains("teacher") {
            return .teacher
        }

        // Default to parent
        return .parent
    }

    // MARK: - Test Data Population
    /// Populates Firestore with test data for development
    /// Call this once to set up test teacher and students
    func populateTestData() async throws {
        print("🔥 Starting test data population...")

        let classroomId = "class_001"

        // 1. Create classroom
        let classroomData: [String: Any] = [
            "id": classroomId,
            "name": "Mrs. Koelpin's Class",
            "teacherId": "teacher_koelpin",
            "classCode": "KOELPIN2024",
            "gradeLevel": "5th Grade",
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("classrooms").document(classroomId).setData(classroomData)
        print("✅ Created classroom: \(classroomId)")

        // 2. Create teacher (Mrs. Koelpin)
        let teacherData: [String: Any] = [
            "id": "teacher_koelpin",
            "name": "Mrs. Koelpin",
            "email": "kkoelpin@pasco.k12.fl.us",
            "classroomId": classroomId,
            "role": "teacher",
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("users").document("teacher_koelpin").setData(teacherData)
        try await db.collection("teachers").document("teacher_koelpin").setData([
            "name": "Mrs. Koelpin",
            "email": "kkoelpin@pasco.k12.fl.us",
            "classroomId": classroomId
        ])
        print("✅ Created teacher: Mrs. Koelpin")

        // 3. Create test students
        let students = [
            ("student_001", "Emma", "Johnson"),
            ("student_002", "Liam", "Williams"),
            ("student_003", "Olivia", "Brown"),
            ("student_004", "Noah", "Davis")
        ]

        for (studentId, firstName, lastName) in students {
            let studentData: [String: Any] = [
                "id": studentId,
                "firstName": firstName,
                "lastName": lastName,
                "name": "\(firstName) \(lastName)",
                "classId": classroomId,
                "classroomId": classroomId,
                "parentIds": [],
                "createdAt": Timestamp(date: Date())
            ]
            try await db.collection("students").document(studentId).setData(studentData)
            print("✅ Created student: \(firstName) \(lastName)")
        }

        // 4. Create a sample parent
        let parentData: [String: Any] = [
            "id": "parent_001",
            "name": "Sarah Johnson",
            "email": "sarah.johnson@email.com",
            "role": "parent",
            "studentIds": ["student_001"],
            "classroomId": classroomId,
            "createdAt": Timestamp(date: Date())
        ]
        try await db.collection("users").document("parent_001").setData(parentData)
        try await db.collection("parents").document("parent_001").setData([
            "name": "Sarah Johnson",
            "email": "sarah.johnson@email.com",
            "studentIds": ["student_001"]
        ])
        print("✅ Created parent: Sarah Johnson")

        // Update student with parent reference
        try await db.collection("students").document("student_001").updateData([
            "parentIds": ["parent_001"],
            "parentId": "parent_001"
        ])

        print("🎉 Test data population complete!")
        print("📧 Teacher: kkoelpin@pasco.k12.fl.us")
        print("📧 Parent: sarah.johnson@email.com")
        print("🎒 Students: Emma Johnson, Liam Williams, Olivia Brown, Noah Davis")
        print("🏫 Classroom Code: KOELPIN2024")
    }
}
