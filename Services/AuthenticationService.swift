import Foundation
import Foundation
import Supabase

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

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case role
        case classroomId = "classroom_id"
        case studentIds = "student_ids"
        case parentId = "parent_id"
        case createdAt = "created_at"
    }
}

// MARK: - Database User Model (for Supabase table)
struct DatabaseUser: Codable {
    let id: String
    let email: String
    let name: String
    let role: String
    let classroomId: String?
    let studentIds: [String]?
    let parentId: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case role
        case classroomId = "classroom_id"
        case studentIds = "student_ids"
        case parentId = "parent_id"
        case createdAt = "created_at"
    }

    init(from appUser: AppUser) {
        self.id = appUser.id
        self.email = appUser.email
        self.name = appUser.name
        self.role = appUser.role.rawValue
        self.classroomId = appUser.classroomId
        self.studentIds = appUser.studentIds
        self.parentId = appUser.parentId
        self.createdAt = appUser.createdAt
    }

    func toAppUser() -> AppUser {
        var user = AppUser(
            id: id,
            email: email,
            name: name,
            role: UserRole(rawValue: role) ?? .parent,
            classroomId: classroomId
        )
        user.studentIds = studentIds
        user.parentId = parentId
        return user
    }
}

// MARK: - Authentication Service
@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: Supabase.User?
    @Published var appUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseConfig.client
    private var authStateTask: Task<Void, Never>?

    init() {
        setupAuthStateListener()
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateTask = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    print("Auth state changed: \(event)")
                    self.currentUser = session?.user
                    self.isAuthenticated = session?.user != nil

                    if let user = session?.user {
                        print("User authenticated, fetching profile...")
                        Task {
                            await self.fetchAppUserWithTimeout(userId: user.id)
                        }
                    } else {
                        self.appUser = nil
                    }
                }
            }
        }
    }

    /// Fetch user with a timeout to prevent hanging
    private func fetchAppUserWithTimeout(userId: UUID) async {
        // Get current auth user directly from Supabase
        guard let supabaseUser = supabase.auth.currentUser else {
            print("No current user found")
            return
        }
        
        let email = supabaseUser.email ?? ""
        let role = await determineRoleByEmail(email: email)
        
        // Get name from user metadata (raw JSON from Supabase)
        let name: String
        if let userMeta = supabaseUser.userMetadata?["name"],
           case let .string(metadataName) = userMeta {
            name = metadataName
        } else {
            name = email.components(separatedBy: "@").first ?? "User"
        }

        let fallbackUser = AppUser(
            id: userId.uuidString,
            email: email,
            name: name,
            role: role,
            classroomId: role == .teacher ? "class_001" : nil
        )

        // Set immediately so UI doesn't hang
        self.appUser = fallbackUser
        print("Set immediate fallback appUser: \(email) as \(role.rawValue)")

        // Then try to fetch/update from Supabase in background
        Task {
            await fetchAppUser(userId: userId.uuidString)
        }
    }

    // MARK: - Sign Up with Email
    func signUp(email: String, password: String, name: String, role: UserRole, classroomId: String? = nil) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": AnyJSON.string(name)]
            )

            let user = response.user

            // Create user profile in database
            let newUser = AppUser(
                id: user.id.uuidString,
                email: email,
                name: name,
                role: role,
                classroomId: classroomId
            )

            try await createUserProfile(user: newUser)

            // Also add to role-specific table
            try await addToRoleTable(user: newUser)

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
            try await supabase.auth.signIn(email: email, password: password)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        Task {
            do {
                try await supabase.auth.signOut()
                await MainActor.run {
                    appUser = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.resetPasswordForEmail(email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Supabase User Profile
    private func createUserProfile(user: AppUser) async throws {
        let dbUser = DatabaseUser(from: user)
        try await supabase
            .from("users")
            .insert(dbUser)
            .execute()
    }

    private func addToRoleTable(user: AppUser) async throws {
        let tableName: String
        switch user.role {
        case .teacher:
            tableName = "teachers"
        case .parent:
            tableName = "parents"
        case .student:
            tableName = "students"
        }

        var data: [String: AnyJSON] = [
            "id": AnyJSON.string(user.id),
            "name": AnyJSON.string(user.name),
            "email": AnyJSON.string(user.email)
        ]

        if let classroomId = user.classroomId {
            data["classroom_id"] = AnyJSON.string(classroomId)
        }

        try await supabase
            .from(tableName)
            .insert(data)
            .execute()
    }

    func fetchAppUser(userId: String) async {
        print("fetchAppUser called for userId: \(userId)")

        do {
            let response: DatabaseUser = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            print("Found existing user document")
            appUser = response.toAppUser()
        } catch {
            print("Error fetching user or user not found: \(error.localizedDescription)")

            // User document doesn't exist - create one
            guard let supabaseUser = supabase.auth.currentUser else {
                print("No current user found")
                return
            }
            
            let email = supabaseUser.email ?? ""
            print("Email: \(email)")

            // Get name from metadata if available
            let name: String
            if let userMeta = supabaseUser.userMetadata?["name"],
               case let .string(metadataName) = userMeta {
                name = metadataName
            } else {
                name = email.components(separatedBy: "@").first ?? "User"
            }

            // Check if this email matches a known teacher/parent
            let role = await determineRoleByEmail(email: email)
            let classroomId = role == .teacher ? "class_001" : nil
            print("Determined role: \(role.rawValue)")

            // Create the user profile
            let newUser = AppUser(
                id: userId,
                email: email,
                name: name,
                role: role,
                classroomId: classroomId
            )

            // Try to save to Supabase, but set appUser regardless
            do {
                try await createUserProfile(user: newUser)
                try await addToRoleTable(user: newUser)
                print("Created user profile in Supabase")
            } catch {
                print("Could not save to Supabase (permissions?): \(error.localizedDescription)")
                // Continue anyway - user can still use the app
            }

            // Set appUser even if Supabase save failed
            appUser = newUser
            print("Set appUser: \(newUser.email) as \(newUser.role.rawValue)")
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
    /// Populates Supabase with test data for development
    /// Call this once to set up test teacher and students
    func populateTestData() async throws {
        print("Starting test data population...")

        let classroomId = "class_001"

        // 1. Create classroom
        let classroomData: [String: AnyJSON] = [
            "id": AnyJSON.string(classroomId),
            "name": AnyJSON.string("Mrs. Koelpin's Class"),
            "teacher_id": AnyJSON.string("teacher_koelpin"),
            "class_code": AnyJSON.string("KOELPIN2024"),
            "grade_level": AnyJSON.string("5th Grade"),
            "created_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        try await supabase.from("classrooms").upsert(classroomData).execute()
        print("Created classroom: \(classroomId)")

        // 2. Create teacher (Mrs. Koelpin)
        let teacherUserData: [String: AnyJSON] = [
            "id": AnyJSON.string("teacher_koelpin"),
            "name": AnyJSON.string("Mrs. Koelpin"),
            "email": AnyJSON.string("kkoelpin@pasco.k12.fl.us"),
            "classroom_id": AnyJSON.string(classroomId),
            "role": AnyJSON.string("teacher"),
            "created_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        try await supabase.from("users").upsert(teacherUserData).execute()

        let teacherData: [String: AnyJSON] = [
            "id": AnyJSON.string("teacher_koelpin"),
            "name": AnyJSON.string("Mrs. Koelpin"),
            "email": AnyJSON.string("kkoelpin@pasco.k12.fl.us"),
            "classroom_id": AnyJSON.string(classroomId)
        ]
        try await supabase.from("teachers").upsert(teacherData).execute()
        print("Created teacher: Mrs. Koelpin")

        // 3. Create test students
        let students = [
            ("student_001", "Emma", "Johnson"),
            ("student_002", "Liam", "Williams"),
            ("student_003", "Olivia", "Brown"),
            ("student_004", "Noah", "Davis")
        ]

        for (studentId, firstName, lastName) in students {
            let studentData: [String: AnyJSON] = [
                "id": AnyJSON.string(studentId),
                "first_name": AnyJSON.string(firstName),
                "last_name": AnyJSON.string(lastName),
                "name": AnyJSON.string("\(firstName) \(lastName)"),
                "class_id": AnyJSON.string(classroomId),
                "classroom_id": AnyJSON.string(classroomId),
                "parent_ids": AnyJSON.array([]),
                "created_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
            ]
            try await supabase.from("students").upsert(studentData).execute()
            print("Created student: \(firstName) \(lastName)")
        }

        // 4. Create a sample parent
        let parentUserData: [String: AnyJSON] = [
            "id": AnyJSON.string("parent_001"),
            "name": AnyJSON.string("Sarah Johnson"),
            "email": AnyJSON.string("sarah.johnson@email.com"),
            "role": AnyJSON.string("parent"),
            "student_ids": AnyJSON.array([AnyJSON.string("student_001")]),
            "classroom_id": AnyJSON.string(classroomId),
            "created_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
        ]
        try await supabase.from("users").upsert(parentUserData).execute()

        let parentData: [String: AnyJSON] = [
            "id": AnyJSON.string("parent_001"),
            "name": AnyJSON.string("Sarah Johnson"),
            "email": AnyJSON.string("sarah.johnson@email.com"),
            "student_ids": AnyJSON.array([AnyJSON.string("student_001")])
        ]
        try await supabase.from("parents").upsert(parentData).execute()
        print("Created parent: Sarah Johnson")

        // Update student with parent reference
        try await supabase.from("students")
            .update(["parent_ids": AnyJSON.array([AnyJSON.string("parent_001")]), "parent_id": AnyJSON.string("parent_001")])
            .eq("id", value: "student_001")
            .execute()

        print("Test data population complete!")
        print("Teacher: kkoelpin@pasco.k12.fl.us")
        print("Parent: sarah.johnson@email.com")
        print("Students: Emma Johnson, Liam Williams, Olivia Brown, Noah Davis")
        print("Classroom Code: KOELPIN2024")
    }
}
