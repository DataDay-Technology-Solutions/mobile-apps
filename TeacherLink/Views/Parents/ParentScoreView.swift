//
//  ParentScoreView.swift
//  TeacherLink
//
//  Teacher view to monitor and manage parent hostility scores
//

import SwiftUI

struct ParentScoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @StateObject private var parentScoreViewModel = ParentScoreViewModel()

    @State private var selectedFilter: ParentFilter = .all
    @State private var selectedProfile: ParentProfile?
    @State private var showFlagSheet = false
    @State private var showUnflagConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Header
                ParentScoreSummaryHeader(viewModel: parentScoreViewModel)

                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ParentFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Parent List
                if parentScoreViewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if filteredProfiles.isEmpty {
                    EmptyParentScoreView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredProfiles) { profile in
                            ParentScoreRow(
                                profile: profile,
                                parentUser: parentScoreViewModel.getParentUser(for: profile),
                                studentNames: parentScoreViewModel.getStudentNames(for: profile)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedProfile = profile
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Parent Scores")
            .sheet(item: $selectedProfile) { profile in
                ParentScoreDetailView(
                    profile: profile,
                    parentUser: parentScoreViewModel.getParentUser(for: profile),
                    studentNames: parentScoreViewModel.getStudentNames(for: profile),
                    onFlag: { reason in
                        Task {
                            await parentScoreViewModel.flagParent(
                                profileId: profile.id ?? "",
                                teacherId: authViewModel.currentUser?.id ?? "",
                                reason: reason
                            )
                        }
                        selectedProfile = nil
                    },
                    onUnflag: {
                        Task {
                            await parentScoreViewModel.unflagParent(profileId: profile.id ?? "")
                        }
                        selectedProfile = nil
                    }
                )
            }
            .onAppear {
                if let classId = classroomViewModel.selectedClassroom?.id {
                    Task {
                        await parentScoreViewModel.loadProfiles(classId: classId)
                    }
                }
            }
        }
    }

    private var filteredProfiles: [ParentProfile] {
        switch selectedFilter {
        case .all:
            return parentScoreViewModel.profilesSortedByHostility
        case .hostile:
            return parentScoreViewModel.hostileProfiles
        case .concerning:
            return parentScoreViewModel.concerningProfiles
        case .friendly:
            return parentScoreViewModel.friendlyProfiles
        }
    }
}

enum ParentFilter: String, CaseIterable {
    case all = "All"
    case hostile = "Hostile"
    case concerning = "Concerning"
    case friendly = "Friendly"
}

struct ParentScoreSummaryHeader: View {
    @ObservedObject var viewModel: ParentScoreViewModel

    var body: some View {
        HStack(spacing: 16) {
            SummaryCard(
                count: viewModel.hostileProfiles.count,
                label: "Hostile",
                color: .red,
                icon: "exclamationmark.shield.fill"
            )

            SummaryCard(
                count: viewModel.concerningProfiles.count,
                label: "Concerning",
                color: .orange,
                icon: "exclamationmark.triangle.fill"
            )

            SummaryCard(
                count: viewModel.friendlyProfiles.count,
                label: "Friendly",
                color: .green,
                icon: "face.smiling.fill"
            )
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct SummaryCard: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text("\(count)")
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ParentScoreRow: View {
    let profile: ParentProfile
    let parentUser: User?
    let studentNames: [String]

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with score indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(hostilityColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(parentUser?.initials ?? "?")
                            .font(.headline)
                            .foregroundColor(hostilityColor)
                    )

                if profile.isFlaggedHostile {
                    Image(systemName: "flag.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(parentUser?.displayName ?? "Unknown Parent")
                        .font(.headline)

                    if profile.adminCCEnabled {
                        Image(systemName: "person.2.badge.gearshape.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("Parent of: \(studentNames.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    HostilityBadge(level: profile.hostilityLevel)

                    Text("\(profile.totalMessages) messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing) {
                Text(profile.formattedScore)
                    .font(.title3.bold())
                    .foregroundColor(hostilityColor)

                Text("score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var hostilityColor: Color {
        switch profile.hostilityLevel {
        case .friendly: return .green
        case .neutral: return .blue
        case .concerning: return .orange
        case .hostile: return .red
        }
    }
}

struct HostilityBadge: View {
    let level: HostilityLevel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
            Text(level.rawValue)
        }
        .font(.caption2.bold())
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor)
        .cornerRadius(8)
    }

    private var badgeColor: Color {
        switch level {
        case .friendly: return .green
        case .neutral: return .blue
        case .concerning: return .orange
        case .hostile: return .red
        }
    }
}

struct EmptyParentScoreView: View {
    let filter: ParentFilter

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: filter == .hostile ? "checkmark.shield.fill" : "person.3.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(filter == .hostile ? "No Hostile Parents" : "No Parents in This Category")
                .font(.headline)

            Text(filter == .hostile
                 ? "Great news! No parents have been flagged as hostile."
                 : "No parents match the selected filter.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

struct ParentScoreDetailView: View {
    let profile: ParentProfile
    let parentUser: User?
    let studentNames: [String]
    let onFlag: (String) -> Void
    let onUnflag: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var flagReason = ""
    @State private var showFlagInput = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(hostilityColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(parentUser?.initials ?? "?")
                                    .font(.title)
                                    .foregroundColor(hostilityColor)
                            )

                        Text(parentUser?.displayName ?? "Unknown Parent")
                            .font(.title2.bold())

                        Text(parentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HostilityBadge(level: profile.hostilityLevel)
                    }
                    .padding(.top)

                    // Score Card
                    VStack(spacing: 12) {
                        Text("Parent Score")
                            .font(.headline)

                        Text(profile.formattedScore)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(hostilityColor)

                        if profile.adminCCEnabled {
                            Label("Admin CC Enabled", systemImage: "person.2.badge.gearshape.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Message Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message Analysis")
                            .font(.headline)

                        HStack(spacing: 16) {
                            StatBox(value: profile.positiveMessages, label: "Positive", color: .green)
                            StatBox(value: profile.neutralMessages, label: "Neutral", color: .blue)
                            StatBox(value: profile.negativeMessages, label: "Negative", color: .red)
                        }

                        Text("Total: \(profile.totalMessages) messages analyzed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Children
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Children in Class")
                            .font(.headline)

                        ForEach(studentNames, id: \.self) { name in
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                Text(name)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Flag Status
                    if profile.isFlaggedHostile {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Flagged as Hostile", systemImage: "flag.fill")
                                .font(.headline)
                                .foregroundColor(.red)

                            if let reason = profile.flagReason {
                                Text("Reason: \(reason)")
                                    .font(.subheadline)
                            }

                            if let flaggedAt = profile.flaggedAt {
                                Text("Flagged on \(flaggedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Button {
                                onUnflag()
                            } label: {
                                Label("Remove Flag", systemImage: "flag.slash")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        // Flag Button
                        VStack(spacing: 12) {
                            if showFlagInput {
                                TextField("Reason for flagging...", text: $flagReason, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)

                                HStack {
                                    Button("Cancel") {
                                        showFlagInput = false
                                        flagReason = ""
                                    }
                                    .foregroundColor(.secondary)

                                    Spacer()

                                    Button {
                                        onFlag(flagReason)
                                    } label: {
                                        Text("Confirm Flag")
                                            .bold()
                                    }
                                    .disabled(flagReason.isEmpty)
                                }
                            } else {
                                Button {
                                    showFlagInput = true
                                } label: {
                                    Label("Flag as Hostile", systemImage: "flag.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.red)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle("Parent Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var hostilityColor: Color {
        switch profile.hostilityLevel {
        case .friendly: return .green
        case .neutral: return .blue
        case .concerning: return .orange
        case .hostile: return .red
        }
    }
}

struct StatBox: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack {
            Text("\(value)")
                .font(.title2.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    ParentScoreView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
}
