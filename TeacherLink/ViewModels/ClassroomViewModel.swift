//
//  ClassroomViewModel.swift
//  TeacherLink
//

import Foundation

@MainActor
class ClassroomViewModel: ObservableObject {
    @Published var classrooms: [Classroom] = []
    @Published var selectedClassroom: Classroom?
    @Published var students: [Student] = []
    @Published var parents: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    init() {
        if USE_MOCK_DATA {
            loadMockData()
        }
    }

    private func loadMockData() {
        classrooms = [MockDataService.shared.classroom]
        selectedClassroom = MockDataService.shared.classroom
        students = MockDataService.shared.students
        parents = MockDataService.shared.parentUsers
    }

    func loadClassrooms(for user: User) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            loadMockData()
        }

        isLoading = false
    }

    func selectClassroom(_ classroom: Classroom) {
        selectedClassroom = classroom
        if USE_MOCK_DATA {
            students = MockDataService.shared.students
        }
    }

    func createClassroom(name: String, gradeLevel: String, teacherId: String, teacherName: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let classroom = Classroom(
                id: UUID().uuidString,
                name: name,
                gradeLevel: gradeLevel,
                teacherId: teacherId,
                teacherName: teacherName
            )
            classrooms.insert(classroom, at: 0)
            selectedClassroom = classroom
        }

        isLoading = false
    }

    func joinClassWithCode(_ code: String, parentId: String) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 500_000_000)

            if code.uppercased() == "ABC123" {
                let classroom = MockDataService.shared.classroom
                classrooms.append(classroom)
                selectedClassroom = classroom
            } else {
                errorMessage = "Invalid class code"
            }
        }

        isLoading = false
    }

    func addStudent(firstName: String, lastName: String) async {
        guard let classId = selectedClassroom?.id else { return }

        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let student = Student(
                id: UUID().uuidString,
                firstName: firstName,
                lastName: lastName,
                classId: classId
            )
            students.append(student)
            students.sort { $0.lastName < $1.lastName }
        }

        isLoading = false
    }

    func deleteStudent(_ student: Student) async {
        if USE_MOCK_DATA {
            students.removeAll { $0.id == student.id }
            successMessage = "\(student.fullName) has been removed from the class."
        }
    }

    func updateStudent(_ student: Student, firstName: String, lastName: String) async {
        guard let index = students.firstIndex(where: { $0.id == student.id }) else { return }

        if USE_MOCK_DATA {
            students[index].firstName = firstName
            students[index].lastName = lastName
            students.sort { $0.lastName < $1.lastName }
            successMessage = "Student updated successfully."
        }
    }

    // MARK: - Parent Management

    func addParent(email: String, displayName: String, studentId: String? = nil) async {
        guard let classId = selectedClassroom?.id else { return }

        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Check if parent already exists
            if parents.contains(where: { $0.email.lowercased() == email.lowercased() }) {
                errorMessage = "A parent with this email already exists."
                isLoading = false
                return
            }

            let parent = User(
                id: UUID().uuidString,
                email: email,
                displayName: displayName,
                role: .parent,
                classIds: [classId]
            )
            parents.append(parent)
            parents.sort { $0.displayName < $1.displayName }

            // Link to student if provided
            if let studentId = studentId, let parentId = parent.id {
                await linkParentToStudent(parentId: parentId, studentId: studentId)
            }

            successMessage = "\(displayName) has been added as a parent."
        }

        isLoading = false
    }

    func removeParent(_ parent: User) async {
        if USE_MOCK_DATA {
            // Unlink from all students first
            if let parentId = parent.id {
                for i in students.indices {
                    students[i].parentIds.removeAll { $0 == parentId }
                }
            }
            parents.removeAll { $0.id == parent.id }
            successMessage = "\(parent.displayName) has been removed."
        }
    }

    func linkParentToStudent(parentId: String, studentId: String) async {
        if USE_MOCK_DATA {
            guard let studentIndex = students.firstIndex(where: { $0.id == studentId }) else { return }

            if !students[studentIndex].parentIds.contains(parentId) {
                students[studentIndex].parentIds.append(parentId)
            }
        }
    }

    func unlinkParentFromStudent(parentId: String, studentId: String) async {
        if USE_MOCK_DATA {
            guard let studentIndex = students.firstIndex(where: { $0.id == studentId }) else { return }
            students[studentIndex].parentIds.removeAll { $0 == parentId }
        }
    }

    func getParentsForStudent(_ student: Student) -> [User] {
        return parents.filter { parent in
            guard let parentId = parent.id else { return false }
            return student.parentIds.contains(parentId)
        }
    }

    func getStudentsForParent(_ parent: User) -> [Student] {
        guard let parentId = parent.id else { return [] }
        return students.filter { $0.parentIds.contains(parentId) }
    }

    func getUnlinkedStudents() -> [Student] {
        return students.filter { $0.parentIds.isEmpty }
    }

    func regenerateClassCode() async {
        guard var classroom = selectedClassroom else { return }

        if USE_MOCK_DATA {
            classroom.classCode = Classroom.generateClassCode()
            selectedClassroom = classroom
            if let index = classrooms.firstIndex(where: { $0.id == classroom.id }) {
                classrooms[index] = classroom
            }
        }
    }
}
