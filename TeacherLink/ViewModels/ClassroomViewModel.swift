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
        } else {
            // Real Supabase implementation
            do {
                guard let userId = user.id else {
                    errorMessage = "User ID not found"
                    isLoading = false
                    return
                }

                if user.role == .teacher {
                    classrooms = try await ClassroomService.shared.getClassroomsForTeacher(teacherId: userId)
                } else if user.role == .parent {
                    classrooms = try await ClassroomService.shared.getClassroomsForParent(parentId: userId)
                }

                print("🟪 [ClassroomViewModel] Loaded \(classrooms.count) classrooms:")
                for (index, classroom) in classrooms.enumerated() {
                    print("🟪 [ClassroomViewModel]   [\(index)] id=\(classroom.id ?? "nil"), name=\(classroom.name), code=\(classroom.classCode)")
                }

                // Select the first classroom if available
                if let first = classrooms.first {
                    selectedClassroom = first
                    // Load students for the selected classroom
                    students = try await ClassroomService.shared.getStudentsForClass(classId: first.id ?? "")
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func selectClassroom(_ classroom: Classroom) {
        selectedClassroom = classroom
        if USE_MOCK_DATA {
            students = MockDataService.shared.students
        } else {
            // Load students for selected classroom
            Task {
                if let classId = classroom.id {
                    do {
                        students = try await ClassroomService.shared.getStudentsForClass(classId: classId)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
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
        } else {
            // Real Supabase implementation
            do {
                let classroom = Classroom(
                    id: nil,
                    name: name,
                    gradeLevel: gradeLevel,
                    teacherId: teacherId,
                    teacherName: teacherName
                )
                let created = try await ClassroomService.shared.createClassroom(classroom)
                classrooms.insert(created, at: 0)
                selectedClassroom = created
                successMessage = "Class '\(name)' created successfully!"
            } catch {
                errorMessage = error.localizedDescription
            }
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
        } else {
            // Real Supabase implementation
            do {
                let classroom = try await ClassroomService.shared.joinClassWithCode(code: code, parentId: parentId)
                classrooms.append(classroom)
                selectedClassroom = classroom
                successMessage = "Successfully joined '\(classroom.name)'!"
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func addStudent(firstName: String, lastName: String) async {
        guard let classId = selectedClassroom?.id else {
            print("🔴 [ClassroomViewModel] ERROR: No classroom selected or classroom has no ID")
            errorMessage = "No classroom selected. Please select a class first."
            return
        }

        print("🟦 [ClassroomViewModel] Adding student: \(firstName) \(lastName) to class: \(classId)")
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
            print("🟩 [ClassroomViewModel] Mock student added successfully")
        } else {
            // Real Supabase implementation
            do {
                let student = Student(
                    id: nil,
                    firstName: firstName,
                    lastName: lastName,
                    classId: classId,
                    parentIds: []
                )
                print("🟦 [ClassroomViewModel] Calling ClassroomService.addStudent...")
                let created = try await ClassroomService.shared.addStudent(student)
                print("🟩 [ClassroomViewModel] Student created with ID: \(created.id ?? "nil")")
                students.append(created)
                students.sort { $0.lastName < $1.lastName }
                successMessage = "\(firstName) \(lastName) added to class!"
                print("🟩 [ClassroomViewModel] Student added to local array. Total students: \(students.count)")
            } catch {
                print("🔴 [ClassroomViewModel] ERROR adding student: \(error)")
                print("🔴 [ClassroomViewModel] Error details: \(error.localizedDescription)")
                errorMessage = "Failed to add student: \(error.localizedDescription)"
            }
        }

        isLoading = false
    }

    func deleteStudent(_ student: Student) async {
        if USE_MOCK_DATA {
            students.removeAll { $0.id == student.id }
            successMessage = "\(student.fullName) has been removed from the class."
        } else {
            // Real Supabase implementation
            guard let studentId = student.id else { return }
            do {
                try await ClassroomService.shared.deleteStudent(id: studentId, classId: student.classId)
                students.removeAll { $0.id == student.id }
                successMessage = "\(student.fullName) has been removed from the class."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func updateStudent(_ student: Student, firstName: String, lastName: String) async {
        guard let index = students.firstIndex(where: { $0.id == student.id }) else { return }

        if USE_MOCK_DATA {
            students[index].firstName = firstName
            students[index].lastName = lastName
            students.sort { $0.lastName < $1.lastName }
            successMessage = "Student updated successfully."
        } else {
            // Real Supabase implementation
            do {
                var updatedStudent = student
                updatedStudent.firstName = firstName
                updatedStudent.lastName = lastName
                try await ClassroomService.shared.updateStudent(updatedStudent)
                students[index].firstName = firstName
                students[index].lastName = lastName
                students.sort { $0.lastName < $1.lastName }
                successMessage = "Student updated successfully."
            } catch {
                errorMessage = error.localizedDescription
            }
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
                name: displayName,
                displayName: displayName,
                role: .parent,
                classIds: [classId]
            )
            parents.append(parent)
            parents.sort { ($0.displayName ?? $0.name) < ($1.displayName ?? $1.name) }

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
        } else {
            // Real Supabase implementation
            do {
                try await ClassroomService.shared.linkParentToStudent(studentId: studentId, parentId: parentId)
                if let studentIndex = students.firstIndex(where: { $0.id == studentId }) {
                    if !students[studentIndex].parentIds.contains(parentId) {
                        students[studentIndex].parentIds.append(parentId)
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
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
        } else {
            // Real Supabase implementation
            do {
                classroom.classCode = Classroom.generateClassCode()
                try await ClassroomService.shared.updateClassroom(classroom)
                selectedClassroom = classroom
                if let index = classrooms.firstIndex(where: { $0.id == classroom.id }) {
                    classrooms[index] = classroom
                }
                successMessage = "Class code regenerated!"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
