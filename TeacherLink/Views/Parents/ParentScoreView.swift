//
//  ParentScoreView.swift
//  TeacherLink
//
//  Teacher view to mark parents for admin attention
//

import SwiftUI

struct ParentScoreView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @StateObject private var viewModel = ParentScoreViewModel()

    @State private var selectedFilter: ParentFilter = .all
    @State private var selectedProfile: ParentProfile?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Header
                AdminAttentionHeader(
                    markedCount: viewModel.flaggedProfiles.count,
                    totalCount: viewModel.parentProfiles.count
                )

                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ParentFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Parent List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if filteredProfiles.isEmpty {
                    EmptyParentListView(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredProfiles) { profile in
                            ParentListRow(
                                profile: profile,
                                parentUser: viewModel.getParentUser(for: profile),
                                studentNames: viewModel.getStudentNames(for: profile)
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
            .navigationTitle("Admin Attention")
            .sheet(item: $selectedProfile) { profile in
                ParentDetailSheet(
                    profile: profile,
                    parentUser: viewModel.getParentUser(for: profile),
                    studentNames: viewModel.getStudentNames(for: profile),
                    onMark: { reason in
                        Task {
                            await viewModel.flagParent(
                                profileId: profile.id ?? "",
                                teacherId: authViewModel.currentUser?.id ?? "",
                                reason: reason
                            )
                        }
                        selectedProfile = nil
                    },
                    onRemove: {
                        Task {
                            await viewModel.unflagParent(profileId: profile.id ?? "")
                        }
                        selectedProfile = nil
                    }
                )
            }
            .onAppear {
                if let classId = classroomViewModel.selectedClassroom?.id {
                    Task {
                        await viewModel.loadProfiles(classId: classId)
                    }
                }
            }
        }
    }

    private var filteredProfiles: [ParentProfile] {
        switch selectedFilter {
        case .all:
            return viewModel.parentProfiles
        case .marked:
            return viewModel.flaggedProfiles
        case .unmarked:
            return viewModel.unflaggedProfiles
        }
    }
}

enum ParentFilter: String, CaseIterable {
    case all = "All"
    case marked = "Marked"
    case unmarked = "Unmarked"
}

struct AdminAttentionHeader: View {
    let markedCount: Int
    let totalCount: Int

    var body: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundColor(markedCount > 0 ? .orange : .gray)

                Text("\(markedCount)")
                    .font(.title2.bold())

                Text("Admin Attention")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)

            VStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("\(totalCount)")
                    .font(.title2.bold())

                Text("Total Parents")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct ParentListRow: View {
    let profile: ParentProfile
    let parentUser: User?
    let studentNames: [String]

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(profile.isFlagged ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(parentUser?.initials ?? "?")
                            .font(.headline)
                            .foregroundColor(profile.isFlagged ? .orange : .blue)
                    )

                if profile.isFlagged {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(parentUser?.displayName ?? "Unknown Parent")
                        .font(.headline)

                    if profile.adminCCEnabled {
                        Image(systemName: "envelope.badge.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Text("Parent of: \(studentNames.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if profile.isFlagged {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.badge.fill")
                            .font(.caption2)
                        Text("Admin Attention")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct EmptyParentListView: View {
    let filter: ParentFilter

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: filter == .marked ? "checkmark.circle.fill" : "person.3.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text(filter == .marked ? "No Parents Marked" : "No Parents Found")
                .font(.headline)

            Text(filter == .marked
                 ? "No parents are currently marked for admin attention."
                 : "No parents match the selected filter.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

struct ParentDetailSheet: View {
    let profile: ParentProfile
    let parentUser: User?
    let studentNames: [String]
    let onMark: (String) -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) var dismiss
    @AppStorage("adminEmail") private var adminEmail: String = ""
    @State private var noteText = ""
    @State private var showNoteInput = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(profile.isFlagged ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(parentUser?.initials ?? "?")
                                    .font(.title)
                                    .foregroundColor(profile.isFlagged ? .orange : .blue)
                            )

                        Text(parentUser?.displayName ?? "Unknown Parent")
                            .font(.title2.bold())

                        Text(parentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

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

                    // Info about admin attention
                    VStack(alignment: .leading, spacing: 8) {
                        Label("About Admin Attention", systemImage: "info.circle")
                            .font(.headline)

                        Text("When you mark a parent for admin attention, your configured admin email will be CC'd on all future messages with this parent.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if !adminEmail.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text("CC: \(adminEmail)")
                                    .font(.caption)
                            }
                            .padding(.top, 4)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("No admin email configured. Set one in Settings.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Status
                    if profile.isFlagged {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Marked for Admin Attention", systemImage: "bell.badge.fill")
                                .font(.headline)
                                .foregroundColor(.orange)

                            if let reason = profile.flagReason {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Note:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(reason)
                                        .font(.subheadline)
                                }
                            }

                            if let flaggedAt = profile.flaggedAt {
                                Text("Marked on \(flaggedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "envelope.badge.fill")
                                    .font(.caption)
                                if !adminEmail.isEmpty {
                                    Text("CC: \(adminEmail)")
                                        .font(.caption)
                                } else {
                                    Text("Admin CC enabled (configure email in Settings)")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.orange)

                            Button {
                                onRemove()
                            } label: {
                                Label("Remove from Admin Attention", systemImage: "bell.slash")
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
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    } else {
                        // Mark Button
                        VStack(spacing: 12) {
                            if showNoteInput {
                                TextField("Add a note (optional)...", text: $noteText, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)

                                HStack {
                                    Button("Cancel") {
                                        showNoteInput = false
                                        noteText = ""
                                    }
                                    .foregroundColor(.secondary)

                                    Spacer()

                                    Button {
                                        onMark(noteText.isEmpty ? "Marked for admin attention" : noteText)
                                    } label: {
                                        Text("Confirm")
                                            .bold()
                                    }
                                }
                            } else {
                                Button {
                                    showNoteInput = true
                                } label: {
                                    Label("Mark for Admin Attention", systemImage: "bell.badge.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.orange)
                                        .cornerRadius(12)
                                }

                                if !adminEmail.isEmpty {
                                    Text("\(adminEmail) will be CC'd on all communications")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Configure admin email in Settings to enable CC")
                                        .font(.caption)
                                        .foregroundColor(.orange)
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
}

#Preview {
    ParentScoreView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
}
