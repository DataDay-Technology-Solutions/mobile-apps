//
//  SchoolProfileView.swift
//  HallPass (formerly TeacherLink)
//
//  View for editing school profile information
//

import SwiftUI

struct SchoolProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SchoolProfileViewModel()

    let schoolId: String

    @State private var name = ""
    @State private var code = ""
    @State private var city = ""
    @State private var state = ""
    @State private var showingSaveAlert = false
    @State private var saveSuccess = false

    var body: some View {
        Form {
            Section("School Information") {
                TextField("School Name", text: $name)
                    .textContentType(.organizationName)

                TextField("School Code", text: $code)
                    .textInputAutocapitalization(.characters)

                TextField("City", text: $city)
                    .textContentType(.addressCity)

                TextField("State", text: $state)
                    .textContentType(.addressState)
                    .textInputAutocapitalization(.characters)
            }

            if let school = viewModel.school, let grades = school.gradeLevels, !grades.isEmpty {
                Section("Grade Levels") {
                    Text(grades.joined(separator: ", "))
                        .foregroundColor(.secondary)

                    NavigationLink("Manage Grade Levels") {
                        GradeLevelsView(schoolId: schoolId)
                    }
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
                .disabled(viewModel.isLoading || !hasChanges)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("School Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadSchool(id: schoolId)
                if let school = viewModel.school {
                    name = school.name
                    code = school.code
                    city = school.city
                    state = school.state ?? ""
                }
            }
        }
        .alert(saveSuccess ? "Success" : "Error", isPresented: $showingSaveAlert) {
            Button("OK") {
                if saveSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(saveSuccess ? "School profile updated successfully." : viewModel.errorMessage ?? "An error occurred.")
        }
    }

    private var hasChanges: Bool {
        guard let school = viewModel.school else { return false }
        return name != school.name ||
               code != school.code ||
               city != school.city ||
               state != (school.state ?? "")
    }

    private func saveChanges() {
        Task {
            let success = await viewModel.updateSchool(
                id: schoolId,
                name: name,
                code: code,
                city: city,
                state: state
            )
            saveSuccess = success
            showingSaveAlert = true
        }
    }
}

// MARK: - SchoolProfileViewModel

@MainActor
class SchoolProfileViewModel: ObservableObject {
    @Published var school: School?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadSchool(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            school = try await SupabaseConfig.client
                .from("schools")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateSchool(id: String, name: String, code: String, city: String, state: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await SupabaseConfig.client
                .from("schools")
                .update([
                    "name": name,
                    "code": code,
                    "city": city,
                    "state": state
                ])
                .eq("id", value: id)
                .execute()

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

#Preview {
    NavigationView {
        SchoolProfileView(schoolId: "test-school-001")
    }
}
