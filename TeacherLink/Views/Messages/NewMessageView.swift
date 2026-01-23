//
//  NewMessageView.swift
//  TeacherLink
//

import SwiftUI

struct NewMessageView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedStudent: Student?
    @State private var showBroadcast = false
    @State private var broadcastMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // Broadcast Section (for teachers)
                Section {
                    Button {
                        showBroadcast = true
                    } label: {
                        HStack {
                            Image(systemName: "megaphone.fill")
                                .foregroundColor(.orange)
                                .frame(width: 40, height: 40)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text("Message All Parents")
                                    .font(.headline)
                                Text("Send the same message to everyone")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Quick Actions")
                }

                // Students Section
                Section {
                    ForEach(classroomViewModel.students) { student in
                        Button {
                            selectedStudent = student
                        } label: {
                            HStack {
                                StudentAvatar(student: student, size: 40)

                                VStack(alignment: .leading) {
                                    Text(student.fullName)
                                        .font(.headline)
                                    Text("\(student.parentIds.count) parent(s) connected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("Message About a Student")
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBroadcast) {
                BroadcastMessageView()
                    .environmentObject(classroomViewModel)
                    .environmentObject(messageViewModel)
            }
            .sheet(item: $selectedStudent) { student in
                StudentParentMessagingView(student: student)
                    .environmentObject(messageViewModel)
                    .environmentObject(classroomViewModel)
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct BroadcastMessageView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var message = ""
    @State private var isSending = false
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info Banner
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text("This message will be sent to all \(classroomViewModel.selectedClassroom?.parentCount ?? 0) parents in your class.")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.blue.opacity(0.1))

                // Message Input
                TextEditor(text: $message)
                    .padding()
                    .overlay(alignment: .topLeading) {
                        if message.isEmpty {
                            Text("Type your message to all parents...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 24)
                                .allowsHitTesting(false)
                        }
                    }

                Spacer()
            }
            .navigationTitle("Message All Parents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendBroadcast()
                    }
                    .disabled(message.isEmpty || isSending)
                }
            }
            .alert("Message Sent!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your message has been sent to all parents.")
            }
        }
    }

    private func sendBroadcast() {
        guard let classroom = classroomViewModel.selectedClassroom,
              let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        isSending = true

        Task {
            await messageViewModel.sendBroadcastMessage(
                teacherId: userId,
                teacherName: userName,
                classId: classroom.id ?? "",
                parentIds: classroom.parentIds,
                content: message
            )
            isSending = false
            showSuccess = true
        }
    }
}

struct StudentParentMessagingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @Environment(\.dismiss) private var dismiss

    let student: Student
    @State private var selectedConversation: Conversation?
    @State private var showChat = false
    @State private var isLoadingParents = true
    @State private var parentUsers: [AppUser] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Student Info Header
                VStack(spacing: 12) {
                    StudentAvatar(student: student, size: 60)

                    Text(student.fullName)
                        .font(.title3.bold())

                    Text("\(student.parentIds.count) parent(s) connected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))

                if student.parentIds.isEmpty {
                    // No parents connected
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No Parents Connected")
                            .font(.headline)

                        Text("This student doesn't have any parents connected yet. Share the class code with them to get started.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                } else if isLoadingParents {
                    Spacer()
                    ProgressView("Loading parents...")
                    Spacer()
                } else {
                    // List of parents to message
                    List {
                        Section {
                            ForEach(parentUsers, id: \.id) { parent in
                                Button {
                                    startConversation(with: parent)
                                } label: {
                                    HStack(spacing: 12) {
                                        // Parent Avatar
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Text(String(parent.name.prefix(1)).uppercased())
                                                    .foregroundColor(.white)
                                                    .fontWeight(.bold)
                                            )

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(parent.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text(parent.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Image(systemName: "message.fill")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } header: {
                            Text("Select a parent to message")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Message Parent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let conversation = selectedConversation {
                    ChatView(conversation: conversation)
                        .environmentObject(messageViewModel)
                        .environmentObject(authViewModel)
                }
            }
            .onAppear {
                loadParents()
            }
        }
    }

    private func loadParents() {
        isLoadingParents = true

        Task {
            // Simulate loading
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Get parents from mock data or classroom
            if USE_MOCK_DATA {
                // Get parent users from mock data that match this student's parentIds
                parentUsers = MockDataService.shared.parentUsers.compactMap { user in
                    guard let userId = user.id, student.parentIds.contains(userId) else { return nil }
                    return AppUser(
                        id: userId,
                        email: user.email,
                        name: user.displayName ?? user.name,
                        role: .parent
                    )
                }
            }

            // If no parents found, create placeholder entries
            if parentUsers.isEmpty && !student.parentIds.isEmpty {
                parentUsers = student.parentIds.enumerated().map { index, parentId in
                    AppUser(
                        id: parentId,
                        email: "parent\(index + 1)@example.com",
                        name: "Parent \(index + 1)",
                        role: .parent
                    )
                }
            }

            isLoadingParents = false
        }
    }

    private func startConversation(with parent: AppUser) {
        guard let currentUser = authViewModel.currentUser,
              let currentUserId = currentUser.id,
              let classId = classroomViewModel.selectedClassroom?.id else { return }

        Task {
            // Create or get existing conversation
            let conversation = await messageViewModel.getOrCreateConversation(
                participantIds: [currentUserId, parent.id],
                participantNames: [currentUserId: currentUser.displayName ?? currentUser.name, parent.id: parent.name],
                classId: classId,
                studentId: student.id,
                studentName: student.fullName
            )

            await MainActor.run {
                selectedConversation = conversation
                showChat = true
            }
        }
    }
}

// MARK: - Parent New Message View
struct ParentNewMessageView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedConversation: Conversation?
    @State private var showChat = false
    @State private var isLoading = false
    @State private var teacherName: String = "Teacher"

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "message.badge.filled.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Message Your Child's Teacher")
                        .font(.title2.bold())

                    Text("Send a message about your child's progress or any questions you have.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Teacher Card
                if let classroom = classroomViewModel.selectedClassroom {
                    Button {
                        startConversationWithTeacher()
                    } label: {
                        HStack(spacing: 16) {
                            // Teacher Avatar
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(teacherName.prefix(1).uppercased())
                                        .foregroundColor(.white)
                                        .font(.title2.bold())
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(teacherName)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(classroom.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                if let student = linkedStudent {
                                    Text("About: \(student.fullName)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }

                            Spacer()

                            if isLoading {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                }

                Spacer()
                Spacer()
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let conversation = selectedConversation {
                    ChatView(conversation: conversation)
                        .environmentObject(messageViewModel)
                        .environmentObject(authViewModel)
                }
            }
            .onAppear {
                loadTeacherName()
            }
        }
    }

    private var linkedStudent: Student? {
        // Get the first student linked to this parent in the current classroom
        guard let userId = authViewModel.currentUser?.id else { return nil }
        return classroomViewModel.students.first { student in
            student.parentIds.contains(userId)
        }
    }

    private func loadTeacherName() {
        guard let teacherId = classroomViewModel.selectedClassroom?.teacherId else { return }

        Task {
            // Try to fetch teacher info from Supabase
            do {
                let user: AppUser = try await SupabaseConfig.client
                    .from("users")
                    .select()
                    .eq("id", value: teacherId)
                    .single()
                    .execute()
                    .value

                await MainActor.run {
                    teacherName = user.name
                }
            } catch {
                print("Could not fetch teacher name: \(error)")
            }
        }
    }

    private func startConversationWithTeacher() {
        guard let currentUser = authViewModel.currentUser,
              let currentUserId = currentUser.id,
              let classroom = classroomViewModel.selectedClassroom,
              let classId = classroom.id else { return }

        isLoading = true

        Task {
            let student = linkedStudent

            let conversation = await messageViewModel.getOrCreateConversation(
                participantIds: [currentUserId, classroom.teacherId],
                participantNames: [
                    currentUserId: currentUser.displayName ?? currentUser.name,
                    classroom.teacherId: teacherName
                ],
                classId: classId,
                studentId: student?.id,
                studentName: student?.fullName
            )

            await MainActor.run {
                isLoading = false
                selectedConversation = conversation
                showChat = true
            }
        }
    }
}

#Preview {
    NewMessageView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
        .environmentObject(MessageViewModel())
}
