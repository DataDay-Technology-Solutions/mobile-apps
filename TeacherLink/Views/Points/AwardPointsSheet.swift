//
//  AwardPointsSheet.swift
//  TeacherLink
//
//  Sheet for awarding positive or negative points
//

import SwiftUI

struct AwardPointsSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    let students: [Student]
    @ObservedObject var pointsViewModel: PointsViewModel

    @State private var selectedTab = 0  // 0 = positive, 1 = negative
    @State private var showSuccess = false
    @State private var awardedBehavior: Behavior?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Students being awarded
                StudentPreviewRow(students: students)

                // Tab Picker
                Picker("Behavior Type", selection: $selectedTab) {
                    Text("Positive").tag(0)
                    Text("Needs Work").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // Behavior Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(selectedTab == 0 ? pointsViewModel.positiveBehaviors : pointsViewModel.negativeBehaviors) { behavior in
                            BehaviorButton(behavior: behavior) {
                                awardBehavior(behavior)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(students.count == 1 ? students[0].firstName : "\(students.count) Students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showSuccess, let behavior = awardedBehavior {
                    SuccessOverlay(behavior: behavior) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func awardBehavior(_ behavior: Behavior) {
        guard let userId = authViewModel.currentUser?.id,
              let userName = authViewModel.currentUser?.displayName else { return }

        Task {
            if students.count == 1 {
                await pointsViewModel.awardPoints(
                    to: students[0],
                    behavior: behavior,
                    awardedBy: userId,
                    awardedByName: userName
                )
            } else {
                await pointsViewModel.awardPointsToMultiple(
                    students: students,
                    behavior: behavior,
                    awardedBy: userId,
                    awardedByName: userName
                )
            }

            awardedBehavior = behavior
            showSuccess = true

            // Auto dismiss after delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }
    }
}

struct StudentPreviewRow: View {
    let students: [Student]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(students) { student in
                    VStack(spacing: 4) {
                        StudentAvatar(student: student, size: 50)
                        Text(student.firstName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
    }
}

struct BehaviorButton: View {
    let behavior: Behavior
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(behaviorColor.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: behavior.icon)
                        .font(.title2)
                        .foregroundColor(behaviorColor)
                }

                Text(behavior.name)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(behavior.points > 0 ? "+\(behavior.points)" : "\(behavior.points)")
                    .font(.caption2.bold())
                    .foregroundColor(behaviorColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(behaviorColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var behaviorColor: Color {
        switch behavior.color {
        case "green": return .green
        case "blue": return .blue
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "orange": return .orange
        case "indigo": return .indigo
        case "red": return .red
        case "gray": return .gray
        default: return .blue
        }
    }
}

struct SuccessOverlay: View {
    let behavior: Behavior
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 16) {
                Image(systemName: behavior.isPositive ? "star.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(behavior.isPositive ? .yellow : .orange)

                Text(behavior.isPositive ? "Great Job!" : "Points Recorded")
                    .font(.title.bold())

                Text(behavior.name)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(behavior.points > 0 ? "+\(behavior.points)" : "\(behavior.points)")
                    .font(.title.bold())
                    .foregroundColor(behavior.isPositive ? .green : .red)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    AwardPointsSheet(
        students: [
            Student(firstName: "Emma", lastName: "Smith", classId: "1"),
            Student(firstName: "Liam", lastName: "Johnson", classId: "1")
        ],
        pointsViewModel: PointsViewModel()
    )
    .environmentObject(AuthViewModel())
}
