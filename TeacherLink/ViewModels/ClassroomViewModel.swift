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
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        if USE_MOCK_DATA {
            loadMockData()
        }
    }

    private func loadMockData() {
        classrooms = [MockDataService.shared.classroom]
        selectedClassroom = MockDataService.shared.classroom
        students = MockDataService.shared.students
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
        }
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
