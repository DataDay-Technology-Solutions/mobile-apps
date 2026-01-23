//
//  DistrictProfileView.swift
//  HallPass (formerly TeacherLink)
//
//  View for editing district profile information
//

import SwiftUI

struct DistrictProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = DistrictProfileViewModel()

    let districtId: String

    @State private var name = ""
    @State private var code = ""
    @State private var city = ""
    @State private var state = ""
    @State private var showingSaveAlert = false
    @State private var saveSuccess = false

    var body: some View {
        Form {
            Section("District Information") {
                TextField("District Name", text: $name)
                    .textContentType(.organizationName)

                TextField("District Code", text: $code)
                    .textInputAutocapitalization(.characters)

                TextField("City", text: $city)
                    .textContentType(.addressCity)

                TextField("State", text: $state)
                    .textContentType(.addressState)
                    .textInputAutocapitalization(.characters)
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
        .navigationTitle("District Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.loadDistrict(id: districtId)
                if let district = viewModel.district {
                    name = district.name
                    code = district.code
                    city = district.city
                    state = district.state ?? ""
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
            Text(saveSuccess ? "District profile updated successfully." : viewModel.errorMessage ?? "An error occurred.")
        }
    }

    private var hasChanges: Bool {
        guard let district = viewModel.district else { return false }
        return name != district.name ||
               code != district.code ||
               city != district.city ||
               state != (district.state ?? "")
    }

    private func saveChanges() {
        Task {
            let success = await viewModel.updateDistrict(
                id: districtId,
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

// MARK: - DistrictProfileViewModel

@MainActor
class DistrictProfileViewModel: ObservableObject {
    @Published var district: District?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadDistrict(id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            district = try await SupabaseConfig.client
                .from("districts")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateDistrict(id: String, name: String, code: String, city: String, state: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await SupabaseConfig.client
                .from("districts")
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
        DistrictProfileView(districtId: "test-district-001")
    }
}
