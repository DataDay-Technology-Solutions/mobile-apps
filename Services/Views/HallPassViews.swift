import SwiftUI

// MARK: - Create Hall Pass View
struct CreateHallPassView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject var firestoreService: FirestoreService
    
    var preselectedStudent: Student?
    
    @State private var selectedStudent: Student?
    @State private var destination = ""
    @State private var reason = ""
    @State private var isCreating = false
    
    let destinations = [
        "Restroom",
        "Nurse's Office",
        "Main Office",
        "Counselor",
        "Library",
        "Locker",
        "Other Classroom",
        "Other"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Student Selection
                Section("Student") {
                    if let preselected = preselectedStudent {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text(preselected.name)
                                .fontWeight(.medium)
                        }
                    } else {
                        Picker("Select Student", selection: $selectedStudent) {
                            Text("Choose a student").tag(nil as Student?)
                            ForEach(firestoreService.students) { student in
                                Text(student.name).tag(student as Student?)
                            }
                        }
                    }
                }
                
                // Destination
                Section("Destination") {
                    Picker("Where to?", selection: $destination) {
                        Text("Select destination").tag("")
                        ForEach(destinations, id: \.self) { dest in
                            Text(dest).tag(dest)
                        }
                    }
                }
                
                // Reason (Optional)
                Section("Reason (Optional)") {
                    TextField("Brief reason for leaving", text: $reason)
                }
                
                // Time Estimate
                Section {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Estimated time: 5-10 minutes")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("New Hall Pass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createHallPass()
                    }
                    .disabled(!isFormValid || isCreating)
                }
            }
            .onAppear {
                if let preselected = preselectedStudent {
                    selectedStudent = preselected
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        let student = preselectedStudent ?? selectedStudent
        return student != nil && !destination.isEmpty
    }
    
    private func createHallPass() {
        guard let student = preselectedStudent ?? selectedStudent,
              let studentId = student.id,
              let teacher = authService.appUser,
              let classroomId = teacher.classroomId else {
            return
        }
        
        isCreating = true
        
        Task {
            do {
                _ = try await firestoreService.createHallPass(
                    studentId: studentId,
                    studentName: student.name,
                    teacherId: teacher.id,
                    teacherName: teacher.name,
                    destination: destination,
                    reason: reason,
                    classroomId: classroomId
                )
                dismiss()
            } catch {
                isCreating = false
            }
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var firestoreService: FirestoreService
    
    var body: some View {
        NavigationStack {
            List {
                if firestoreService.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("You're all caught up!")
                    )
                } else {
                    ForEach(firestoreService.notifications) { notification in
                        NotificationRow(notification: notification) {
                            markAsRead(notification)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func markAsRead(_ notification: InAppNotification) {
        guard let id = notification.id, !notification.isRead else { return }
        
        Task {
            try? await firestoreService.markNotificationAsRead(notificationId: id)
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: InAppNotification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(notification.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(notification.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        switch notification.type {
        case .hallPassCreated:
            return "door.left.hand.open"
        case .hallPassReturned:
            return "checkmark.circle.fill"
        case .hallPassExpired:
            return "exclamationmark.triangle.fill"
        case .general:
            return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .hallPassCreated:
            return .orange
        case .hallPassReturned:
            return .green
        case .hallPassExpired:
            return .red
        case .general:
            return .blue
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview
#Preview("Create Hall Pass") {
    CreateHallPassView(firestoreService: FirestoreService())
        .environmentObject(AuthenticationService())
}

#Preview("Notifications") {
    NotificationsView(firestoreService: FirestoreService())
}
