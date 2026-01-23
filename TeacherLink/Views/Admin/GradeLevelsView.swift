//
//  GradeLevelsView.swift
//  HallPass (formerly TeacherLink)
//
//  View for managing grade levels in a school
//

import SwiftUI

struct GradeLevelsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = GradeLevelsViewModel()

    let schoolId: String

    @State private var showingAddGrade = false
    @State private var newGrade = ""
    @State private var showingSaveAlert = false
    @State private var saveSuccess = false

    private let allGrades = ["Pre-K", "K", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]

    var body: some View {
        List {
            Section("Current Grade Levels") {
                if viewModel.gradeLevels.isEmpty {
                    Text("No grade levels configured")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.gradeLevels, id: \.self) { grade in
                        HStack {
                            Text(gradeDisplayName(grade))
                            Spacer()
                            Button(action: {
                                viewModel.gradeLevels.removeAll { $0 == grade }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            Section("Add Grade Levels") {
                ForEach(availableGrades, id: \.self) { grade in
                    Button(action: {
                        viewModel.gradeLevels.append(grade)
                        viewModel.gradeLevels.sort { gradeOrder($0) < gradeOrder($1) }
                    }) {
                        HStack {
                            Text(gradeDisplayName(grade))
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }

            Section {
                Button(action: saveChanges) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.isLoading || !viewModel.hasChanges)
            }
        }
        .navigationTitle("Grade Levels")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadSchool(id: schoolId)
            }
        }
        .alert(saveSuccess ? "Success" : "Error", isPresented: $showingSaveAlert) {
            Button("OK") {
                if saveSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(saveSuccess ? "Grade levels updated successfully." : viewModel.errorMessage ?? "An error occurred.")
        }
    }

    private var availableGrades: [String] {
        allGrades.filter { !viewModel.gradeLevels.contains($0) }
    }

    private func gradeDisplayName(_ grade: String) -> String {
        switch grade {
        case "Pre-K": return "Pre-Kindergarten"
        case "K": return "Kindergarten"
        default: return "Grade \(grade)"
        }
    }

    private func gradeOrder(_ grade: String) -> Int {
        switch grade {
        case "Pre-K": return -1
        case "K": return 0
        default: return Int(grade) ?? 99
        }
    }

    private func saveChanges() {
        Task {
            let success = await viewModel.saveGradeLevels(schoolId: schoolId)
            saveSuccess = success
            showingSaveAlert = true
        }
    }
}

// MARK: - GradeLevelsViewModel

@MainActor
class GradeLevelsViewModel: ObservableObject {
    @Published var gradeLevels: [String] = []
    @Published var originalGradeLevels: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var hasChanges: Bool {
        gradeLevels != originalGradeLevels
    }

    func loadSchool(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let school: School = try await SupabaseConfig.client
                .from("schools")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value

            gradeLevels = school.gradeLevels ?? []
            originalGradeLevels = gradeLevels
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveGradeLevels(schoolId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await SupabaseConfig.client
                .from("schools")
                .update(["grade_levels": gradeLevels])
                .eq("id", value: schoolId)
                .execute()

            originalGradeLevels = gradeLevels
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

#Preview {
    NavigationView {
        GradeLevelsView(schoolId: "test-school-001")
    }
}
