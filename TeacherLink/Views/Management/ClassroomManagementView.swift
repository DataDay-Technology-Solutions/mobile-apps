//
//  ClassroomManagementView.swift
//  TeacherLink
//
//  Manage students and parents in the classroom
//

import SwiftUI

struct ClassroomManagementView: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Management", selection: $selectedTab) {
                    Text("Students").tag(0)
                    Text("Parents").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                TabView(selection: $selectedTab) {
                    StudentManagementTab()
                        .environmentObject(classroomViewModel)
                        .tag(0)

                    ParentManagementTab()
                        .environmentObject(classroomViewModel)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Manage Class")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Student Management Tab

struct StudentManagementTab: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @State private var showAddStudent = false
    @State private var studentToEdit: Student?
    @State private var studentToDelete: Student?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Summary Header
            HStack(spacing: 20) {
                ManagementStatBox(
                    value: classroomViewModel.students.count,
                    label: "Students",
                    color: .blue
                )

                ManagementStatBox(
                    value: classroomViewModel.getUnlinkedStudents().count,
                    label: "No Parent",
                    color: .orange
                )
            }
            .padding()
            .background(Color(.systemGray6))

            // Student List
            if classroomViewModel.students.isEmpty {
                ManagementEmptyStateView(
                    icon: "person.3.fill",
                    title: "No Students Yet",
                    message: "Add students to your class to get started."
                )
            } else {
                List {
                    ForEach(classroomViewModel.students) { student in
                        StudentManagementRow(
                            student: student,
                            parents: classroomViewModel.getParentsForStudent(student),
                            onEdit: { studentToEdit = student },
                            onDelete: {
                                studentToDelete = student
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddStudent = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showAddStudent) {
            AddStudentSheet()
                .environmentObject(classroomViewModel)
        }
        .sheet(item: $studentToEdit) { student in
            EditStudentSheet(student: student)
                .environmentObject(classroomViewModel)
        }
        .alert("Remove Student?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let student = studentToDelete {
                    Task {
                        await classroomViewModel.deleteStudent(student)
                    }
                }
            }
        } message: {
            if let student = studentToDelete {
                Text("Are you sure you want to remove \(student.fullName) from the class? This cannot be undone.")
            }
        }
    }
}

struct StudentManagementRow: View {
    let student: Student
    let parents: [User]
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ManagementStudentAvatar(student: student, size: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(student.fullName)
                    .font(.headline)

                if parents.isEmpty {
                    Label("No parent linked", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text(parents.map { $0.displayName }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Parent Management Tab

struct ParentManagementTab: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @State private var showAddParent = false
    @State private var parentToEdit: User?
    @State private var parentToDelete: User?
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Summary Header
            HStack(spacing: 20) {
                ManagementStatBox(
                    value: classroomViewModel.parents.count,
                    label: "Parents",
                    color: .green
                )

                ManagementStatBox(
                    value: parentsWithStudents,
                    label: "Linked",
                    color: .blue
                )
            }
            .padding()
            .background(Color(.systemGray6))

            // Parent List
            if classroomViewModel.parents.isEmpty {
                ManagementEmptyStateView(
                    icon: "figure.2.and.child.holdinghands",
                    title: "No Parents Yet",
                    message: "Add parents and link them to their children."
                )
            } else {
                List {
                    ForEach(classroomViewModel.parents) { parent in
                        ParentManagementRow(
                            parent: parent,
                            students: classroomViewModel.getStudentsForParent(parent),
                            onEdit: { parentToEdit = parent },
                            onDelete: {
                                parentToDelete = parent
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddParent = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .sheet(isPresented: $showAddParent) {
            AddParentSheet()
                .environmentObject(classroomViewModel)
        }
        .sheet(item: $parentToEdit) { parent in
            EditParentSheet(parent: parent)
                .environmentObject(classroomViewModel)
        }
        .alert("Remove Parent?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                if let parent = parentToDelete {
                    Task {
                        await classroomViewModel.removeParent(parent)
                    }
                }
            }
        } message: {
            if let parent = parentToDelete {
                Text("Are you sure you want to remove \(parent.displayName)? They will no longer have access to the class.")
            }
        }
    }

    private var parentsWithStudents: Int {
        classroomViewModel.parents.filter { parent in
            !classroomViewModel.getStudentsForParent(parent).isEmpty
        }.count
    }
}

struct ParentManagementRow: View {
    let parent: User
    let students: [Student]
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(parent.initials)
                        .font(.headline)
                        .foregroundColor(.green)
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(parent.displayName)
                    .font(.headline)

                Text(parent.email)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if students.isEmpty {
                    Label("No student linked", systemImage: "link.badge.plus")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Parent of: \(students.map { $0.firstName }.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Actions
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit & Link", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Student Sheet

struct AddStudentSheet: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedParentId: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)

                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                }

                Section("Link to Parent (Optional)") {
                    Picker("Parent", selection: $selectedParentId) {
                        Text("None").tag(nil as String?)
                        ForEach(classroomViewModel.parents) { parent in
                            Text(parent.displayName).tag(parent.id as String?)
                        }
                    }
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await addStudent()
                            dismiss()
                        }
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
    }

    private func addStudent() async {
        await classroomViewModel.addStudent(firstName: firstName, lastName: lastName)

        // Link to parent if selected
        if let parentId = selectedParentId,
           let newStudent = classroomViewModel.students.last {
            if let studentId = newStudent.id {
                await classroomViewModel.linkParentToStudent(parentId: parentId, studentId: studentId)
            }
        }
    }
}

// MARK: - Edit Student Sheet

struct EditStudentSheet: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) var dismiss
    let student: Student
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var linkedParentIds: Set<String> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)

                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                }

                Section("Linked Parents") {
                    if classroomViewModel.parents.isEmpty {
                        Text("No parents available to link")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(classroomViewModel.parents) { parent in
                            HStack {
                                Text(parent.displayName)

                                Spacer()

                                if let parentId = parent.id {
                                    if linkedParentIds.contains(parentId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleParent(parent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                            dismiss()
                        }
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .onAppear {
                firstName = student.firstName
                lastName = student.lastName
                linkedParentIds = Set(student.parentIds)
            }
        }
    }

    private func toggleParent(_ parent: User) {
        guard let parentId = parent.id else { return }
        if linkedParentIds.contains(parentId) {
            linkedParentIds.remove(parentId)
        } else {
            linkedParentIds.insert(parentId)
        }
    }

    private func saveChanges() async {
        guard let studentId = student.id else { return }

        // Update student info
        await classroomViewModel.updateStudent(student, firstName: firstName, lastName: lastName)

        // Update parent links
        let currentParentIds = Set(student.parentIds)
        let newParentIds = linkedParentIds

        // Unlink removed parents
        for parentId in currentParentIds.subtracting(newParentIds) {
            await classroomViewModel.unlinkParentFromStudent(parentId: parentId, studentId: studentId)
        }

        // Link new parents
        for parentId in newParentIds.subtracting(currentParentIds) {
            await classroomViewModel.linkParentToStudent(parentId: parentId, studentId: studentId)
        }
    }
}

// MARK: - Add Parent Sheet

struct AddParentSheet: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var selectedStudentId: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Parent Information") {
                    TextField("Full Name", text: $displayName)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Link to Student (Optional)") {
                    Picker("Student", selection: $selectedStudentId) {
                        Text("None").tag(nil as String?)
                        ForEach(classroomViewModel.students) { student in
                            Text(student.fullName).tag(student.id as String?)
                        }
                    }
                }

                Section {
                    Text("The parent will receive an invitation email to join TeacherLink and access the classroom.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await classroomViewModel.addParent(
                                email: email,
                                displayName: displayName,
                                studentId: selectedStudentId
                            )
                            dismiss()
                        }
                    }
                    .disabled(displayName.isEmpty || email.isEmpty || !isValidEmail)
                }
            }
        }
    }

    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Edit Parent Sheet

struct EditParentSheet: View {
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) var dismiss
    let parent: User
    @State private var linkedStudentIds: Set<String> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Parent Information") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(parent.displayName)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        Text(parent.email)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Linked Students") {
                    if classroomViewModel.students.isEmpty {
                        Text("No students in the class")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(classroomViewModel.students) { student in
                            HStack {
                                ManagementStudentAvatar(student: student, size: 32)

                                Text(student.fullName)

                                Spacer()

                                if let studentId = student.id {
                                    if linkedStudentIds.contains(studentId) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleStudent(student)
                            }
                        }
                    }
                }

                Section {
                    Text("Tap students to link or unlink them from this parent.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                // Initialize with current linked students
                let currentStudents = classroomViewModel.getStudentsForParent(parent)
                linkedStudentIds = Set(currentStudents.compactMap { $0.id })
            }
        }
    }

    private func toggleStudent(_ student: Student) {
        guard let studentId = student.id else { return }
        if linkedStudentIds.contains(studentId) {
            linkedStudentIds.remove(studentId)
        } else {
            linkedStudentIds.insert(studentId)
        }
    }

    private func saveChanges() async {
        guard let parentId = parent.id else { return }

        let currentStudents = classroomViewModel.getStudentsForParent(parent)
        let currentStudentIds = Set(currentStudents.compactMap { $0.id })

        // Unlink removed students
        for studentId in currentStudentIds.subtracting(linkedStudentIds) {
            await classroomViewModel.unlinkParentFromStudent(parentId: parentId, studentId: studentId)
        }

        // Link new students
        for studentId in linkedStudentIds.subtracting(currentStudentIds) {
            await classroomViewModel.linkParentToStudent(parentId: parentId, studentId: studentId)
        }
    }
}

// MARK: - Helper Views

struct ManagementStatBox: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title.bold())
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ManagementEmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(title)
                .font(.title2.bold())

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }
}

struct ManagementStudentAvatar: View {
    let student: Student
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(avatarColor.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Text(student.initials)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(avatarColor)
            )
    }

    private var avatarColor: Color {
        switch student.avatarStyle.backgroundColor {
        case "avatarBlue": return .blue
        case "avatarGreen": return .green
        case "avatarPurple": return .purple
        case "avatarOrange": return .orange
        case "avatarPink": return .pink
        case "avatarTeal": return .teal
        case "avatarYellow": return .yellow
        case "avatarRed": return .red
        default: return .blue
        }
    }
}

#Preview {
    ClassroomManagementView()
        .environmentObject(ClassroomViewModel())
}
