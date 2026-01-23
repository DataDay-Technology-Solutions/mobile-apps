//
//  ParentScoreViewModel.swift
//  TeacherLink
//
//  Manages parent flagging for admin support
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

    // Flag a parent for admin support
    func flagParent(profileId: String, teacherId: String, reason: String) async {
        guard let index = parentProfiles.firstIndex(where: { $0.id == profileId }) else { return }

        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            parentProfiles[index].flag(byTeacherId: teacherId, reason: reason)
        }

        isLoading = false
    }

    // Remove flag from parent
    func unflagParent(profileId: String) async {
        guard let index = parentProfiles.firstIndex(where: { $0.id == profileId }) else { return }

        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)
            parentProfiles[index].unflag()
        }

        isLoading = false
    }

    // Get flagged profiles
    var flaggedProfiles: [ParentProfile] {
        parentProfiles.filter { $0.isFlagged }
    }

    // Get unflagged profiles
    var unflaggedProfiles: [ParentProfile] {
        parentProfiles.filter { !$0.isFlagged }
    }

    // Check if admin should be CC'd on conversation
    func shouldCCAdmin(parentUserId: String) -> Bool {
        guard let profile = getProfile(userId: parentUserId) else { return false }
        return profile.adminCCEnabled
    }

    // Get admin user to CC
    func getAdminUser() -> User? {
        return MockDataService.shared.adminUser
    }
}
