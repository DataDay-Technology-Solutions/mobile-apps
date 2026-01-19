import SwiftUI

// MARK: - Teacher Dashboard
struct TeacherDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var firestoreService = FirestoreService()
    
    @State private var showingCreatePass = false
    @State private var showingNotifications = false
    @State private var selectedStudent: Student?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Active Passes Summary
                ActivePassesSummaryView(count: firestoreService.activeHallPassesCount)
                
                // Main Content
                List {
                    // Active Hall Passes Section
                    Section {
                        if firestoreService.hallPasses.filter({ $0.status == .active }).isEmpty {
                            Text("No active hall passes")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(firestoreService.hallPasses.filter { $0.status == .active }) { pass in
                                ActiveHallPassRow(pass: pass) {
                                    Task {
                                        try? await firestoreService.returnHallPass(hallPassId: pass.id ?? "")
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Active Hall Passes")
                    }
                    
                    // Recent Hall Passes Section
                    Section {
                        ForEach(firestoreService.hallPasses.filter { $0.status == .returned }.prefix(5)) { pass in
                            RecentHallPassRow(pass: pass)
                        }
                    } header: {
                        Text("Recently Returned")
                    }
                    
                    // Students Section
                    Section {
                        ForEach(firestoreService.students) { student in
                            HallPassStudentRow(student: student) {
                                selectedStudent = student
                                showingCreatePass = true
                            }
                        }
                    } header: {
                        Text("Students")
                    }
                }
            }
            .navigationTitle("Hall Pass")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingNotifications = true }) {
                        Image(systemName: "bell.fill")
                            .overlay(
                                NotificationBadge(count: firestoreService.unreadNotificationsCount)
                            )
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showingCreatePass = true }) {
                            Label("New Hall Pass", systemImage: "plus")
                        }
                        
                        Button(role: .destructive, action: signOut) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePass) {
                CreateHallPassView(
                    firestoreService: firestoreService,
                    preselectedStudent: selectedStudent
                )
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationsView(firestoreService: firestoreService)
            }
            .onAppear {
                setupListeners()
            }
            .onDisappear {
                firestoreService.stopListening()
            }
        }
    }
    
    private func setupListeners() {
        if let classroomId = authService.appUser?.classroomId {
            firestoreService.listenToHallPasses(classroomId: classroomId)
            Task {
                try? await firestoreService.fetchStudents(classroomId: classroomId)
            }
        }
        
        if let userId = authService.currentUser?.uid {
            firestoreService.listenToNotifications(userId: userId)
        }
    }
    
    private func signOut() {
        try? authService.signOut()
    }
}

// MARK: - Active Passes Summary
struct ActivePassesSummaryView: View {
    let count: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(count > 0 ? .orange : .green)
                
                Text("Active Hall Passes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: count > 0 ? "door.left.hand.open" : "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(count > 0 ? .orange : .green)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

// MARK: - Active Hall Pass Row
struct ActiveHallPassRow: View {
    let pass: HallPass
    let onReturn: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pass.studentName)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(pass.destination)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                Text(timeAgo(from: pass.createdAt))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Button("Return") {
                onReturn()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Recent Hall Pass Row
struct RecentHallPassRow: View {
    let pass: HallPass
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pass.studentName)
                    .font(.subheadline)
                
                Text(pass.destination)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let returnedAt = pass.returnedAt {
                Text(formatTime(returnedAt))
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Hall Pass Student Row
struct HallPassStudentRow: View {
    let student: Student
    let onCreatePass: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(student.name)
            
            Spacer()
            
            Button(action: onCreatePass) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Notification Badge
struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.red)
                .clipShape(Circle())
                .offset(x: 10, y: -10)
        }
    }
}

// MARK: - Preview
#Preview {
    TeacherDashboardView()
        .environmentObject(AuthenticationService())
}
