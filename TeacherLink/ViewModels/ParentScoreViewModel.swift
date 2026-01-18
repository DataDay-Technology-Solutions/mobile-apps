//
//  ParentScoreViewModel.swift
//  TeacherLink
//
//  Manages parent hostility scores and sentiment tracking
//

import Foundation

@MainActor
class ParentScoreViewModel: ObservableObject {
    @Published var parentProfiles: [ParentProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        if USE_MOCK_DATA {
            loadMockData()
        }
    }

    private func loadMockData() {
        parentProfiles = MockDataService.shared.parentProfiles
    }

    // Load parent profiles for a class
    func loadProfiles(classId: String) async {
        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            parentProfiles = MockDataService.shared.parentProfiles.filter { $0.classId == classId }
        }

        isLoading = false
    }

    // Get profile for a specific parent
    func getProfile(userId: String) -> ParentProfile? {
        return parentProfiles.first { $0.userId == userId }
    }

    // Get parent user for a profile
    func getParentUser(for profile: ParentProfile) -> User? {
        return MockDataService.shared.parentUsers.first { $0.id == profile.userId }
    }

    // Get student names for a parent
    func getStudentNames(for profile: ParentProfile) -> [String] {
        return profile.studentIds.compactMap { studentId in
            MockDataService.shared.students.first { $0.id == studentId }?.fullName
        }
    }

    // Flag a parent as hostile
    func flagParent(profileId: String, teacherId: String, reason: String) async {
        guard let index = parentProfiles.firstIndex(where: { $0.id == profileId }) else { return }

        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            parentProfiles[index].isFlaggedHostile = true
            parentProfiles[index].flaggedByTeacherId = teacherId
            parentProfiles[index].flaggedAt = Date()
            parentProfiles[index].flagReason = reason
            parentProfiles[index].adminCCEnabled = true
            parentProfiles[index].adminCCEnabledAt = Date()
            parentProfiles[index].updatedAt = Date()
        }

        isLoading = false
    }

    // Unflag a parent
    func unflagParent(profileId: String) async {
        guard let index = parentProfiles.firstIndex(where: { $0.id == profileId }) else { return }

        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            parentProfiles[index].isFlaggedHostile = false
            parentProfiles[index].flaggedByTeacherId = nil
            parentProfiles[index].flaggedAt = nil
            parentProfiles[index].flagReason = nil
            parentProfiles[index].updatedAt = Date()

            // Only disable admin CC if score is above threshold
            if parentProfiles[index].hostilityScore >= 50 {
                parentProfiles[index].adminCCEnabled = false
                parentProfiles[index].adminCCEnabledAt = nil
            }
        }

        isLoading = false
    }

    // Analyze and record message sentiment
    func analyzeMessage(content: String, parentUserId: String) async {
        guard let index = parentProfiles.firstIndex(where: { $0.userId == parentUserId }) else { return }

        let sentiment = MessageSentiment.analyze(text: content)

        if USE_MOCK_DATA {
            parentProfiles[index].addMessage(sentiment: sentiment)
        }
    }

    // Get profiles that need admin attention
    var hostileProfiles: [ParentProfile] {
        parentProfiles.filter { $0.hostilityLevel == .hostile || $0.isFlaggedHostile }
    }

    var concerningProfiles: [ParentProfile] {
        parentProfiles.filter { $0.hostilityLevel == .concerning && !$0.isFlaggedHostile }
    }

    var friendlyProfiles: [ParentProfile] {
        parentProfiles.filter { $0.hostilityLevel == .friendly || $0.hostilityLevel == .neutral }
    }

    // Get profiles sorted by hostility (most hostile first)
    var profilesSortedByHostility: [ParentProfile] {
        parentProfiles.sorted { $0.hostilityScore < $1.hostilityScore }
    }

    // Check if admin should be CC'd on conversation
    func shouldCCAdmin(parentUserId: String) -> Bool {
        guard let profile = getProfile(userId: parentUserId) else { return false }
        return profile.shouldCCAdmin
    }

    // Get admin user to CC
    func getAdminUser() -> User? {
        return MockDataService.shared.adminUser
    }
}
