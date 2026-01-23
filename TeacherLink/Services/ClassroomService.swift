//
//  ClassroomService.swift
//  HallPass (formerly TeacherLink)
//

import Foundation
import Supabase

class ClassroomService {
    static let shared = ClassroomService()
    private let supabase = SupabaseConfig.client

    private init() {}

    // MARK: - Classroom CRUD

    func createClassroom(_ classroom: Classroom) async throws -> Classroom {
        print("🟦 [ClassroomService] Starting classroom creation...")
        print("🟦 [ClassroomService] Name: \(classroom.name)")
        print("🟦 [ClassroomService] Grade: \(classroom.gradeLevel)")
        print("🟦 [ClassroomService] Teacher ID: \(classroom.teacherId)")
        print("🟦 [ClassroomService] Class Code: \(classroom.classCode)")

        do {
            let response: [Classroom] = try await supabase
                .from("classrooms")
                .insert(classroom)
                .select()
                .execute()
                .value

            print("🟦 [ClassroomService] Insert response count: \(response.count)")

            guard let newClassroom = response.first else {
                print("🔴 [ClassroomService] ERROR: No classroom returned from insert")
                throw ClassroomError.notFound
            }

            guard let classId = newClassroom.id else {
                print("🔴 [ClassroomService] ERROR: Classroom returned but has no ID")
                throw ClassroomError.notFound
            }

            print("🟩 [ClassroomService] Classroom created successfully! ID: \(classId)")

            // Add class to teacher's class list
            print("🟦 [ClassroomService] Updating teacher's classroom_id...")
            try await supabase
                .from("users")
                .update(["classroom_id": AnyJSON.string(classId)])
                .eq("id", value: classroom.teacherId)
                .execute()

            print("🟩 [ClassroomService] Teacher updated successfully")
            return newClassroom

        } catch {
            print("🔴 [ClassroomService] ERROR creating classroom: \(error)")
            print("🔴 [ClassroomService] Error details: \(error.localizedDescription)")
            throw error
        }
    }

    func getClassroom(id: String) async throws -> Classroom {
        print("🟦 [ClassroomService] Fetching classroom with ID: \(id)")
        let classroom: Classroom = try await supabase
            .from("classrooms")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        print("🟩 [ClassroomService] Classroom fetched: \(classroom.name)")
        return classroom
    }

    func getClassroomsForTeacher(teacherId: String) async throws -> [Classroom] {
        print("🟦 [ClassroomService] Fetching classrooms for teacher: \(teacherId)")
        let response: [Classroom] = try await supabase
            .from("classrooms")
            .select()
            .eq("teacher_id", value: teacherId)
            .order("created_at", ascending: false)
            .execute()
            .value

        print("🟩 [ClassroomService] Found \(response.count) classrooms")
        return response
    }

    func getClassroomsForParent(parentId: String) async throws -> [Classroom] {
        print("🟦 [ClassroomService] Fetching classrooms for parent: \(parentId)")
        let response: [Classroom] = try await supabase
            .from("classrooms")
            .select()
            .contains("parent_ids", value: [parentId])
            .execute()
            .value

        print("🟩 [ClassroomService] Found \(response.count) classrooms")
        return response
    }

    func updateClassroom(_ classroom: Classroom) async throws {
        guard let classId = classroom.id else { return }
        print("🟦 [ClassroomService] Updating classroom: \(classId)")
        try await supabase
            .from("classrooms")
            .update(classroom)
            .eq("id", value: classId)
            .execute()
        print("🟩 [ClassroomService] Classroom updated")
    }

    func deleteClassroom(id: String) async throws {
        print("🟦 [ClassroomService] Deleting classroom: \(id)")
        try await supabase
            .from("classrooms")
            .delete()
            .eq("id", value: id)
            .execute()
        print("🟩 [ClassroomService] Classroom deleted")
    }

    // MARK: - Class Code Join

    func joinClassWithCode(code: String, parentId: String) async throws -> Classroom {
        print("🟦 [ClassroomService] Joining class with code: \(code.uppercased())")
        let classrooms: [Classroom] = try await supabase
            .from("classrooms")
            .select()
            .eq("class_code", value: code.uppercased())
            .limit(1)
            .execute()
            .value

        guard var classroom = classrooms.first, let classId = classroom.id else {
            print("🔴 [ClassroomService] Invalid class code")
            throw ClassroomError.invalidCode
        }

        guard !classroom.parentIds.contains(parentId) else {
            print("🔴 [ClassroomService] Parent already joined")
            throw ClassroomError.alreadyJoined
        }

        // Update classroom with new parent
        classroom.parentIds.append(parentId)
        try await supabase
            .from("classrooms")
            .update(["parent_ids": AnyJSON.array(classroom.parentIds.map { AnyJSON.string($0) })])
            .eq("id", value: classId)
            .execute()

        // Update parent's class - AppUser uses classroomId (single)
        try await supabase
            .from("users")
            .update(["classroom_id": AnyJSON.string(classId)])
            .eq("id", value: parentId)
            .execute()

        print("🟩 [ClassroomService] Successfully joined class")
        return classroom
    }

    // MARK: - Students

    func addStudent(_ student: Student) async throws -> Student {
        print("🟦 [ClassroomService] Adding student: \(student.firstName) \(student.lastName)")
        let response: [Student] = try await supabase
            .from("students")
            .insert(student)
            .select()
            .execute()
            .value

        guard let newStudent = response.first, let studentId = newStudent.id else {
            print("🔴 [ClassroomService] Failed to add student")
            throw ClassroomError.studentNotFound
        }

        // Update classroom's student list
        let classroom = try await getClassroom(id: student.classId)
        var studentIds = classroom.studentIds
        studentIds.append(studentId)

        try await supabase
            .from("classrooms")
            .update(["student_ids": AnyJSON.array(studentIds.map { AnyJSON.string($0) })])
            .eq("id", value: student.classId)
            .execute()

        print("🟩 [ClassroomService] Student added successfully")
        return newStudent
    }

    func getStudentsForClass(classId: String) async throws -> [Student] {
        print("🟦 [ClassroomService] Fetching students for class: \(classId)")
        let response: [Student] = try await supabase
            .from("students")
            .select()
            .eq("class_id", value: classId)
            .order("last_name", ascending: true)
            .execute()
            .value

        print("🟩 [ClassroomService] Found \(response.count) students")
        return response
    }

    func getStudent(id: String) async throws -> Student {
        let student: Student = try await supabase
            .from("students")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value

        return student
    }

    func updateStudent(_ student: Student) async throws {
        guard let studentId = student.id else { return }
        print("🟦 [ClassroomService] Updating student: \(studentId)")
        try await supabase
            .from("students")
            .update(student)
            .eq("id", value: studentId)
            .execute()
        print("🟩 [ClassroomService] Student updated")
    }

    func deleteStudent(id: String, classId: String) async throws {
        print("🟦 [ClassroomService] Deleting student: \(id)")
        try await supabase
            .from("students")
            .delete()
            .eq("id", value: id)
            .execute()

        // Update classroom's student list
        let classroom = try await getClassroom(id: classId)
        let studentIds = classroom.studentIds.filter { $0 != id }

        try await supabase
            .from("classrooms")
            .update(["student_ids": AnyJSON.array(studentIds.map { AnyJSON.string($0) })])
            .eq("id", value: classId)
            .execute()

        print("🟩 [ClassroomService] Student deleted")
    }

    func linkParentToStudent(studentId: String, parentId: String) async throws {
        print("🟦 [ClassroomService] Linking parent \(parentId) to student \(studentId)")
        let student = try await getStudent(id: studentId)
        var parentIds = student.parentIds ?? []
        if !parentIds.contains(parentId) {
            parentIds.append(parentId)
        }

        try await supabase
            .from("students")
            .update(["parent_ids": AnyJSON.array(parentIds.map { AnyJSON.string($0) })])
            .eq("id", value: studentId)
            .execute()

        print("🟩 [ClassroomService] Parent linked successfully")
    }

    // MARK: - Real-time Listeners

    private var classroomChannel: RealtimeChannelV2?
    private var studentsChannel: RealtimeChannelV2?

    func listenToClassroom(id: String, completion: @escaping (Classroom?) -> Void) {
        // Initial fetch
        Task {
            let classroom = try? await getClassroom(id: id)
            await MainActor.run {
                completion(classroom)
            }
        }

        // Set up realtime subscription
        classroomChannel = supabase.realtimeV2.channel("classroom_\(id)")

        Task {
            // IMPORTANT: Set up postgresChange BEFORE subscribing
            let changes = classroomChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "classrooms",
                filter: .eq("id", value: "\(id)")
            )

            try? await classroomChannel?.subscribe()

            if let changes = changes {
                for await _ in changes {
                    let classroom = try? await getClassroom(id: id)
                    await MainActor.run {
                        completion(classroom)
                    }
                }
            }
        }
    }

    func listenToStudents(classId: String, completion: @escaping ([Student]) -> Void) {
        // Initial fetch
        Task {
            let students = try? await getStudentsForClass(classId: classId)
            await MainActor.run {
                completion(students ?? [])
            }
        }

        // Set up realtime subscription
        studentsChannel = supabase.realtimeV2.channel("students_\(classId)")

        Task {
            // IMPORTANT: Set up postgresChange BEFORE subscribing
            let changes = studentsChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "students",
                filter: .eq("class_id", value: "\(classId)")
            )

            try? await studentsChannel?.subscribe()

            if let changes = changes {
                for await _ in changes {
                    let students = try? await getStudentsForClass(classId: classId)
                    await MainActor.run {
                        completion(students ?? [])
                    }
                }
            }
        }
    }

    func stopListening() {
        Task {
            await classroomChannel?.unsubscribe()
            await studentsChannel?.unsubscribe()
        }
    }
}

enum ClassroomError: LocalizedError {
    case notFound
    case invalidCode
    case alreadyJoined
    case studentNotFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Classroom not found"
        case .invalidCode:
            return "Invalid class code"
        case .alreadyJoined:
            return "You have already joined this class"
        case .studentNotFound:
            return "Student not found"
        }
    }
}
