//
//  ClassroomService.swift
//  TeacherLink
//

import Foundation
import FirebaseFirestore

class ClassroomService {
    static let shared = ClassroomService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Classroom CRUD

    func createClassroom(_ classroom: Classroom) async throws -> Classroom {
        let docRef = db.collection("classrooms").document()
        var newClassroom = classroom
        newClassroom.id = docRef.documentID

        try docRef.setData(from: newClassroom)

        // Add class to teacher's class list
        try await db.collection("users").document(classroom.teacherId).updateData([
            "classIds": FieldValue.arrayUnion([docRef.documentID])
        ])

        return newClassroom
    }

    func getClassroom(id: String) async throws -> Classroom {
        let document = try await db.collection("classrooms").document(id).getDocument()
        guard let classroom = try? document.data(as: Classroom.self) else {
            throw ClassroomError.notFound
        }
        return classroom
    }

    func getClassroomsForTeacher(teacherId: String) async throws -> [Classroom] {
        let snapshot = try await db.collection("classrooms")
            .whereField("teacherId", isEqualTo: teacherId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Classroom.self) }
    }

    func getClassroomsForParent(parentId: String) async throws -> [Classroom] {
        let snapshot = try await db.collection("classrooms")
            .whereField("parentIds", arrayContains: parentId)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Classroom.self) }
    }

    func updateClassroom(_ classroom: Classroom) async throws {
        guard let classId = classroom.id else { return }
        try db.collection("classrooms").document(classId).setData(from: classroom, merge: true)
    }

    func deleteClassroom(id: String) async throws {
        try await db.collection("classrooms").document(id).delete()
    }

    // MARK: - Class Code Join

    func joinClassWithCode(code: String, parentId: String) async throws -> Classroom {
        let snapshot = try await db.collection("classrooms")
            .whereField("classCode", isEqualTo: code.uppercased())
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first,
              var classroom = try? document.data(as: Classroom.self) else {
            throw ClassroomError.invalidCode
        }

        guard !classroom.parentIds.contains(parentId) else {
            throw ClassroomError.alreadyJoined
        }

        try await db.collection("classrooms").document(document.documentID).updateData([
            "parentIds": FieldValue.arrayUnion([parentId])
        ])

        try await db.collection("users").document(parentId).updateData([
            "classIds": FieldValue.arrayUnion([document.documentID])
        ])

        classroom.parentIds.append(parentId)
        return classroom
    }

    // MARK: - Students

    func addStudent(_ student: Student) async throws -> Student {
        let docRef = db.collection("students").document()
        var newStudent = student
        newStudent.id = docRef.documentID

        try docRef.setData(from: newStudent)

        try await db.collection("classrooms").document(student.classId).updateData([
            "studentIds": FieldValue.arrayUnion([docRef.documentID])
        ])

        return newStudent
    }

    func getStudentsForClass(classId: String) async throws -> [Student] {
        let snapshot = try await db.collection("students")
            .whereField("classId", isEqualTo: classId)
            .order(by: "lastName")
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Student.self) }
    }

    func getStudent(id: String) async throws -> Student {
        let document = try await db.collection("students").document(id).getDocument()
        guard let student = try? document.data(as: Student.self) else {
            throw ClassroomError.studentNotFound
        }
        return student
    }

    func updateStudent(_ student: Student) async throws {
        guard let studentId = student.id else { return }
        try db.collection("students").document(studentId).setData(from: student, merge: true)
    }

    func deleteStudent(id: String, classId: String) async throws {
        try await db.collection("students").document(id).delete()
        try await db.collection("classrooms").document(classId).updateData([
            "studentIds": FieldValue.arrayRemove([id])
        ])
    }

    func linkParentToStudent(studentId: String, parentId: String) async throws {
        try await db.collection("students").document(studentId).updateData([
            "parentIds": FieldValue.arrayUnion([parentId])
        ])
    }

    // MARK: - Real-time Listeners

    func listenToClassroom(id: String, completion: @escaping (Classroom?) -> Void) -> ListenerRegistration {
        return db.collection("classrooms").document(id).addSnapshotListener { snapshot, _ in
            let classroom = try? snapshot?.data(as: Classroom.self)
            completion(classroom)
        }
    }

    func listenToStudents(classId: String, completion: @escaping ([Student]) -> Void) -> ListenerRegistration {
        return db.collection("students")
            .whereField("classId", isEqualTo: classId)
            .order(by: "lastName")
            .addSnapshotListener { snapshot, _ in
                let students = snapshot?.documents.compactMap { try? $0.data(as: Student.self) } ?? []
                completion(students)
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
