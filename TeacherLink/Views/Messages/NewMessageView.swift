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
    @Environment(\.dismiss) private var dismiss

    let student: Student

    var body: some View {
        NavigationStack {
            VStack {
                // Student Info
                VStack(spacing: 12) {
                    StudentAvatar(student: student, size: 80)

                    Text(student.fullName)
                        .font(.title2.bold())

                    Text("\(student.parentIds.count) parent(s) connected")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)

                Spacer()

                if student.parentIds.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.fill.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)

                        Text("No Parents Connected")
                            .font(.headline)

                        Text("This student doesn't have any parents connected yet. Share the class code with them to get started.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    Text("Select a parent to message")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer()
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
        }
    }
}

#Preview {
    NewMessageView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
        .environmentObject(MessageViewModel())
}
