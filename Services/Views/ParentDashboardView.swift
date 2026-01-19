import SwiftUI

// MARK: - Parent Dashboard
struct ParentDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var firestoreService = FirestoreService()
    
    @State private var showingNotifications = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Child Status Header
                ChildStatusHeader(
                    isOutOfClass: !firestoreService.hallPasses.filter({ $0.status == .active }).isEmpty,
                    activePass: firestoreService.hallPasses.first(where: { $0.status == .active })
                )
                
                List {
                    // Current Status Section
                    if let activePass = firestoreService.hallPasses.first(where: { $0.status == .active }) {
                        Section("Currently Out of Class") {
                            ActivePassDetailView(pass: activePass)
                        }
                    }
                    
                    // Today's Activity
                    Section("Today's Activity") {
                        let todayPasses = firestoreService.hallPasses.filter { isToday($0.createdAt) }
                        
                        if todayPasses.isEmpty {
                            Text("No hall passes today")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(todayPasses) { pass in
                                ParentHallPassRow(pass: pass)
                            }
                        }
                    }
                    
                    // History
                    Section("Recent History") {
                        let pastPasses = firestoreService.hallPasses.filter { !isToday($0.createdAt) }.prefix(10)
                        
                        if pastPasses.isEmpty {
                            Text("No previous hall passes")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(Array(pastPasses)) { pass in
                                ParentHallPassRow(pass: pass)
                            }
                        }
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
                        Button(role: .destructive, action: signOut) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
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
        // For parents, we'd need to get their child's ID and listen to their passes
        // This would come from the parent's profile in Firestore
        if let userId = authService.currentUser?.uid {
            firestoreService.listenToNotifications(userId: userId)
            
            // In a real app, fetch parent's children and listen to their passes
            // For now, using a placeholder
            // firestoreService.listenToStudentHallPasses(studentId: childId)
        }
    }
    
    private func signOut() {
        try? authService.signOut()
    }
    
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Child Status Header
struct ChildStatusHeader: View {
    let isOutOfClass: Bool
    let activePass: HallPass?
    
    var body: some View {
        VStack(spacing: 12) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(isOutOfClass ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: isOutOfClass ? "figure.walk" : "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(isOutOfClass ? .orange : .green)
            }
            
            // Status Text
            Text(isOutOfClass ? "Out of Class" : "In Class")
                .font(.title2)
                .fontWeight(.bold)
            
            // Details if out of class
            if let pass = activePass {
                VStack(spacing: 4) {
                    Text("At: \(pass.destination)")
                        .font(.subheadline)
                    
                    Text("Since \(formatTime(pass.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemGray6))
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Active Pass Detail View
struct ActivePassDetailView: View {
    let pass: HallPass
    @State private var elapsedTime = ""
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Destination")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(pass.destination)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(elapsedTime)
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
            
            if !pass.reason.isEmpty {
                VStack(alignment: .leading) {
                    Text("Reason")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(pass.reason)
                        .font(.subheadline)
                }
            }
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.secondary)
                Text("Teacher: \(pass.teacherName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .onReceive(timer) { _ in
            updateElapsedTime()
        }
        .onAppear {
            updateElapsedTime()
        }
    }
    
    private func updateElapsedTime() {
        let interval = Date().timeIntervalSince(pass.createdAt)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        elapsedTime = String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Parent Hall Pass Row
struct ParentHallPassRow: View {
    let pass: HallPass
    
    var body: some View {
        HStack {
            // Status Icon
            Image(systemName: pass.status == .active ? "circle.fill" : "checkmark.circle.fill")
                .foregroundColor(pass.status == .active ? .orange : .green)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(pass.destination)
                    .font(.headline)
                
                HStack {
                    Text(formatDate(pass.createdAt))
                    
                    if let returnedAt = pass.returnedAt {
                        Text("•")
                        Text(duration(from: pass.createdAt, to: returnedAt))
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Badge
            Text(pass.status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(pass.status == .active ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                .foregroundColor(pass.status == .active ? .orange : .green)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func duration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let minutes = Int(interval) / 60
        return "\(minutes) min"
    }
}

// MARK: - Preview
#Preview {
    ParentDashboardView()
        .environmentObject(AuthenticationService())
}
