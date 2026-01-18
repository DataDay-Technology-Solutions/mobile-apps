//
//  SettingsView.swift
//  TeacherLink
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel

    @State private var showCreateClass = false
    @State private var showJoinClass = false
    @State private var showSignOutConfirm = false
    @State private var showQRInvite = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(authViewModel.currentUser?.initials ?? "?")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.displayName ?? "User")
                                .font(.headline)

                            Text(authViewModel.isTeacher ? "Teacher" : "Parent")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(authViewModel.isTeacher ? Color.blue : Color.green)
                                .cornerRadius(4)

                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Classes Section
                Section {
                    ForEach(classroomViewModel.classrooms) { classroom in
                        ClassroomRow(
                            classroom: classroom,
                            isSelected: classroom.id == classroomViewModel.selectedClassroom?.id
                        ) {
                            classroomViewModel.selectClassroom(classroom)
                        }
                    }

                    if authViewModel.isTeacher {
                        Button {
                            showCreateClass = true
                        } label: {
                            Label("Create New Class", systemImage: "plus.circle")
                        }
                    } else {
                        Button {
                            showJoinClass = true
                        } label: {
                            Label("Join a Class", systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("My Classes")
                }

                // Class Code Section (for teachers)
                if authViewModel.isTeacher, let classroom = classroomViewModel.selectedClassroom {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Class Code")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(classroom.classCode)
                                    .font(.title2.monospaced().bold())

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = classroom.classCode
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }

                                ShareLink(item: "Join my class \"\(classroom.name)\" on TeacherLink!\n\nClass Code: \(classroom.classCode)\n\nDownload the app and enter this code to connect with your child's classroom.") {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        Button {
                            showQRInvite = true
                        } label: {
                            Label("Show QR Code Invite", systemImage: "qrcode")
                        }

                        Button {
                            Task {
                                await classroomViewModel.regenerateClassCode()
                            }
                        } label: {
                            Label("Generate New Code", systemImage: "arrow.clockwise")
                        }
                    } header: {
                        Text("Invite Parents")
                    } footer: {
                        Text("Share this code with parents so they can join your class and receive updates.")
                    }
                }

                // App Section
                Section {
                    Link(destination: URL(string: "https://example.com/help")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }

                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showCreateClass) {
                CreateClassView()
                    .environmentObject(classroomViewModel)
            }
            .sheet(isPresented: $showJoinClass) {
                JoinClassView()
                    .environmentObject(classroomViewModel)
            }
            .sheet(isPresented: $showQRInvite) {
                if let classroom = classroomViewModel.selectedClassroom {
                    ClassInviteView(classroom: classroom)
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct ClassroomRow: View {
    let classroom: Classroom
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Circle()
                    .fill(classColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(classroom.name.prefix(1))
                            .font(.headline)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(classroom.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(classroom.gradeLevel) | \(classroom.studentCount) students")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }

    private var classColor: Color {
        switch classroom.avatarColor {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default: return .blue
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
}
