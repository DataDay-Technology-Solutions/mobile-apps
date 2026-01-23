//
//  AchievementBadgesView.swift
//  TeacherLink
//
//  Achievement badges for students (non-points based recognition)
//

import SwiftUI

struct AchievementBadgesView: View {
    @State private var badges: [Badge] = []
    @State private var studentBadges: [StudentBadge] = []
    @State private var showingAwardBadge = false
    @State private var selectedBadge: Badge?

    var body: some View {
        NavigationStack {
            List {
                Section("Available Badges") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(badges) { badge in
                            BadgeIcon(badge: badge)
                                .onTapGesture {
                                    selectedBadge = badge
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Recent Awards") {
                    if studentBadges.isEmpty {
                        ContentUnavailableView(
                            "No Badges Awarded",
                            systemImage: "star.circle",
                            description: Text("Tap a badge above to award it")
                        )
                    } else {
                        ForEach(studentBadges.sorted(by: { $0.awardedAt > $1.awardedAt }).prefix(10)) { award in
                            StudentBadgeRow(award: award, badge: badges.first(where: { $0.id == award.badgeId }))
                        }
                    }
                }

                Section("Leaderboard") {
                    BadgeLeaderboard(studentBadges: studentBadges)
                }
            }
            .navigationTitle("Badges")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAwardBadge = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $selectedBadge) { badge in
                AwardBadgeView(badge: badge, badges: badges) { newAward in
                    studentBadges.append(newAward)
                }
            }
            .sheet(isPresented: $showingAwardBadge) {
                CreateBadgeView { newBadge in
                    badges.append(newBadge)
                }
            }
            .onAppear {
                loadSampleData()
            }
        }
    }

    private func loadSampleData() {
        badges = [
            Badge(id: "1", name: "Helpful Hand", description: "Helped a classmate", iconName: "hand.raised.fill", color: "#4CAF50", classId: "class_001", createdBy: "teacher"),
            Badge(id: "2", name: "Reading Star", description: "Completed reading goal", iconName: "book.fill", color: "#2196F3", classId: "class_001", createdBy: "teacher"),
            Badge(id: "3", name: "Math Whiz", description: "Mastered math concept", iconName: "function", color: "#9C27B0", classId: "class_001", createdBy: "teacher"),
            Badge(id: "4", name: "Creative Genius", description: "Outstanding creativity", iconName: "paintbrush.fill", color: "#FF9800", classId: "class_001", createdBy: "teacher"),
            Badge(id: "5", name: "Team Player", description: "Great collaboration", iconName: "person.3.fill", color: "#00BCD4", classId: "class_001", createdBy: "teacher"),
            Badge(id: "6", name: "Super Listener", description: "Excellent attention", iconName: "ear.fill", color: "#E91E63", classId: "class_001", createdBy: "teacher"),
        ]

        studentBadges = [
            StudentBadge(id: "sb1", studentId: "s1", studentName: "Emma Wilson", badgeId: "1", awardedBy: "Mrs. Koelpin", awardedAt: Date(), note: "Helped new student find their way"),
            StudentBadge(id: "sb2", studentId: "s2", studentName: "Liam Chen", badgeId: "2", awardedBy: "Mrs. Koelpin", awardedAt: Date().addingTimeInterval(-86400), note: nil),
            StudentBadge(id: "sb3", studentId: "s1", studentName: "Emma Wilson", badgeId: "3", awardedBy: "Mrs. Koelpin", awardedAt: Date().addingTimeInterval(-172800), note: "Solved bonus problem"),
        ]
    }
}

struct BadgeIcon: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: badge.color).opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: badge.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: badge.color))
            }

            Text(badge.name)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 80)
    }
}

struct StudentBadgeRow: View {
    let award: StudentBadge
    let badge: Badge?

    var body: some View {
        HStack(spacing: 12) {
            if let badge = badge {
                ZStack {
                    Circle()
                        .fill(Color(hex: badge.color).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: badge.iconName)
                        .font(.title3)
                        .foregroundColor(Color(hex: badge.color))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(award.studentName)
                        .font(.headline)
                    Text("earned")
                        .foregroundColor(.secondary)
                    Text(badge?.name ?? "Badge")
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: badge?.color ?? "#000000"))
                }

                if let note = award.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(formatDate(award.awardedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct BadgeLeaderboard: View {
    let studentBadges: [StudentBadge]

    var leaderboard: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: studentBadges, by: { $0.studentName })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        if leaderboard.isEmpty {
            Text("No badges awarded yet")
                .foregroundColor(.secondary)
                .italic()
        } else {
            ForEach(Array(leaderboard.prefix(5).enumerated()), id: \.offset) { index, item in
                HStack {
                    Text("\(index + 1)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(width: 24)

                    if index == 0 {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                    }

                    Text(item.name)
                        .font(.body)

                    Spacer()

                    Text("\(item.count) badge\(item.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AwardBadgeView: View {
    @Environment(\.dismiss) var dismiss
    let badge: Badge
    let badges: [Badge]
    var onAward: (StudentBadge) -> Void

    @State private var selectedStudent = ""
    @State private var note = ""

    let students = ["Emma Wilson", "Liam Chen", "Olivia Brown", "Noah Garcia", "Ava Martinez"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        BadgeIcon(badge: badge)
                        Spacer()
                    }

                    Text(badge.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Section("Award To") {
                    Picker("Student", selection: $selectedStudent) {
                        Text("Select Student").tag("")
                        ForEach(students, id: \.self) { student in
                            Text(student).tag(student)
                        }
                    }
                }

                Section("Note (Optional)") {
                    TextField("Why are they getting this badge?", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Award Badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Award") {
                        let award = StudentBadge(
                            id: UUID().uuidString,
                            studentId: "student_id",
                            studentName: selectedStudent,
                            badgeId: badge.id,
                            awardedBy: "Mrs. Koelpin",
                            awardedAt: Date(),
                            note: note.isEmpty ? nil : note
                        )
                        onAward(award)
                        dismiss()
                    }
                    .disabled(selectedStudent.isEmpty)
                }
            }
        }
    }
}

struct CreateBadgeView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (Badge) -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "#4CAF50"

    let icons = ["star.fill", "hand.raised.fill", "book.fill", "function", "paintbrush.fill", "person.3.fill", "ear.fill", "lightbulb.fill", "heart.fill", "flame.fill"]
    let colors = ["#4CAF50", "#2196F3", "#9C27B0", "#FF9800", "#00BCD4", "#E91E63", "#F44336", "#795548"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Badge Details") {
                    TextField("Badge Name", text: $name)
                    TextField("Description", text: $description)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Preview") {
                    HStack {
                        Spacer()
                        BadgeIcon(badge: Badge(id: "preview", name: name.isEmpty ? "Badge Name" : name, description: description, iconName: selectedIcon, color: selectedColor, classId: "", createdBy: ""))
                        Spacer()
                    }
                }
            }
            .navigationTitle("Create Badge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let badge = Badge(
                            id: UUID().uuidString,
                            name: name,
                            description: description,
                            iconName: selectedIcon,
                            color: selectedColor,
                            classId: "class_001",
                            createdBy: "teacher"
                        )
                        onSave(badge)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

#Preview {
    AchievementBadgesView()
}
