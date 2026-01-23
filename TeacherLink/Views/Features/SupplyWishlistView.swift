//
//  SupplyWishlistView.swift
//  TeacherLink
//
//  Teachers request supplies, parents claim them
//

import SwiftUI

struct SupplyWishlistView: View {
    @State private var supplies: [SupplyItem] = []
    @State private var showingAddSupply = false
    @State private var filterFulfilled = false

    var filteredSupplies: [SupplyItem] {
        if filterFulfilled {
            return supplies
        }
        return supplies.filter { !$0.fulfilled }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredSupplies.isEmpty {
                    ContentUnavailableView(
                        "No Supplies Needed",
                        systemImage: "checkmark.circle",
                        description: Text("All supplies have been fulfilled!")
                    )
                } else {
                    ForEach(filteredSupplies) { supply in
                        SupplyRow(supply: supply) {
                            claimSupply(supply)
                        }
                    }
                }
            }
            .navigationTitle("Supply Wishlist")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSupply = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        filterFulfilled.toggle()
                    } label: {
                        Image(systemName: filterFulfilled ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddSupply) {
                AddSupplyView { supply in
                    supplies.append(supply)
                }
            }
            .onAppear {
                loadSampleData()
            }
        }
    }

    private func claimSupply(_ supply: SupplyItem) {
        if let index = supplies.firstIndex(where: { $0.id == supply.id }) {
            supplies[index].claimedBy = "parent_001"
            supplies[index].claimedByName = "Sarah Johnson"
            supplies[index].claimedAt = Date()
        }
    }

    private func loadSampleData() {
        supplies = [
            SupplyItem(id: "1", classId: "class_001", itemName: "Tissues", quantity: 2, description: "Any brand, regular size boxes", urgency: .high, claimedBy: "parent_001", claimedByName: "Sarah Johnson", claimedAt: Date(), fulfilled: false, createdBy: "teacher", createdAt: Date()),
            SupplyItem(id: "2", classId: "class_001", itemName: "Hand Sanitizer", quantity: 3, description: "Pump bottles preferred", urgency: .medium, claimedBy: nil, claimedByName: nil, claimedAt: nil, fulfilled: false, createdBy: "teacher", createdAt: Date()),
            SupplyItem(id: "3", classId: "class_001", itemName: "Expo Markers", quantity: 1, description: "Assorted colors, chisel tip", urgency: .low, claimedBy: nil, claimedByName: nil, claimedAt: nil, fulfilled: false, createdBy: "teacher", createdAt: Date()),
            SupplyItem(id: "4", classId: "class_001", itemName: "Goldfish Crackers", quantity: 2, description: "For class snack time", urgency: .medium, claimedBy: nil, claimedByName: nil, claimedAt: nil, fulfilled: false, createdBy: "teacher", createdAt: Date()),
            SupplyItem(id: "5", classId: "class_001", itemName: "Paper Plates", quantity: 1, description: "Small size, 50 count", urgency: .low, claimedBy: nil, claimedByName: nil, claimedAt: nil, fulfilled: false, createdBy: "teacher", createdAt: Date()),
        ]
    }
}

struct SupplyRow: View {
    let supply: SupplyItem
    var onClaim: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(supply.itemName)
                            .font(.headline)

                        Text("×\(supply.quantity)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let description = supply.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(supply.urgency.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(supply.urgency.color.opacity(0.2))
                    .foregroundColor(supply.urgency.color)
                    .cornerRadius(6)
            }

            if supply.isClaimed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Claimed by \(supply.claimedByName ?? "Unknown")")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            } else {
                Button {
                    onClaim()
                } label: {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                        Text("I'll bring this!")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddSupplyView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (SupplyItem) -> Void

    @State private var itemName = ""
    @State private var quantity = 1
    @State private var description = ""
    @State private var urgency: SupplyItem.Urgency = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Item Name", text: $itemName)

                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...20)

                    TextField("Description (optional)", text: $description)
                }

                Section("Priority") {
                    Picker("Urgency", selection: $urgency) {
                        ForEach(SupplyItem.Urgency.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Request Supply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let supply = SupplyItem(
                            id: UUID().uuidString,
                            classId: "class_001",
                            itemName: itemName,
                            quantity: quantity,
                            description: description.isEmpty ? nil : description,
                            urgency: urgency,
                            claimedBy: nil,
                            claimedByName: nil,
                            claimedAt: nil,
                            fulfilled: false,
                            createdBy: "teacher",
                            createdAt: Date()
                        )
                        onSave(supply)
                        dismiss()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SupplyWishlistView()
}
