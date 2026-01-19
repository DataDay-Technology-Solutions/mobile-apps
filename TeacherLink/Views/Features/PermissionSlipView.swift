//
//  PermissionSlipView.swift
//  TeacherLink
//
//  Digital permission slips for parents to e-sign
//

import SwiftUI

struct PermissionSlipView: View {
    @State private var permissionSlips: [PermissionSlip] = []
    @State private var showingCreateSlip = false
    @State private var selectedSlip: PermissionSlip?

    var body: some View {
        NavigationStack {
            List {
                // Active Slips
                Section("Pending Signatures") {
                    let pending = permissionSlips.filter { !$0.allSigned }
                    if pending.isEmpty {
                        Text("All permission slips are signed!")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(pending) { slip in
                            PermissionSlipRow(slip: slip)
                                .onTapGesture {
                                    selectedSlip = slip
                                }
                        }
                    }
                }

                // Completed Slips
                Section("Completed") {
                    let completed = permissionSlips.filter { $0.allSigned }
                    if completed.isEmpty {
                        Text("No completed slips yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(completed) { slip in
                            PermissionSlipRow(slip: slip)
                                .onTapGesture {
                                    selectedSlip = slip
                                }
                        }
                    }
                }
            }
            .navigationTitle("Permission Slips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSlip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSlip) {
                CreatePermissionSlipView { newSlip in
                    permissionSlips.append(newSlip)
                }
            }
            .sheet(item: $selectedSlip) { slip in
                PermissionSlipDetailView(slip: slip)
            }
            .onAppear {
                loadSampleData()
            }
        }
    }

    private func loadSampleData() {
        permissionSlips = [
            PermissionSlip(
                id: "slip1",
                classId: "class_001",
                title: "Zoo Field Trip",
                description: "Permission for your child to attend our class field trip to the City Zoo on March 15th. Students should bring a packed lunch and wear comfortable walking shoes.",
                eventDate: Date().addingTimeInterval(86400 * 21),
                createdBy: "Mrs. Koelpin",
                createdAt: Date().addingTimeInterval(-86400 * 7),
                dueDate: Date().addingTimeInterval(86400 * 14),
                signatures: [
                    PermissionSlip.Signature(id: "sig1", parentId: "p1", parentName: "Sarah Wilson", studentName: "Emma Wilson", signedAt: Date().addingTimeInterval(-86400 * 2), status: .signed),
                    PermissionSlip.Signature(id: "sig2", parentId: "p2", parentName: "Michael Chen", studentName: "Liam Chen", signedAt: nil, status: .pending),
                    PermissionSlip.Signature(id: "sig3", parentId: "p3", parentName: "Jennifer Brown", studentName: "Olivia Brown", signedAt: nil, status: .pending),
                    PermissionSlip.Signature(id: "sig4", parentId: "p4", parentName: "David Garcia", studentName: "Noah Garcia", signedAt: Date().addingTimeInterval(-86400), status: .signed)
                ]
            ),
            PermissionSlip(
                id: "slip2",
                classId: "class_001",
                title: "Science Museum Trip",
                description: "Field trip to the Science Discovery Museum. Cost: $10 per student.",
                eventDate: Date().addingTimeInterval(86400 * 35),
                createdBy: "Mrs. Koelpin",
                createdAt: Date().addingTimeInterval(-86400 * 3),
                dueDate: Date().addingTimeInterval(86400 * 28),
                signatures: [
                    PermissionSlip.Signature(id: "sig5", parentId: "p1", parentName: "Sarah Wilson", studentName: "Emma Wilson", signedAt: nil, status: .pending),
                    PermissionSlip.Signature(id: "sig6", parentId: "p2", parentName: "Michael Chen", studentName: "Liam Chen", signedAt: nil, status: .pending)
                ]
            )
        ]
    }
}

struct PermissionSlipRow: View {
    let slip: PermissionSlip

    var signedCount: Int {
        slip.signatures.filter { $0.status == .signed }.count
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(slip.allSigned ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: slip.allSigned ? "checkmark.seal.fill" : "doc.text.fill")
                    .foregroundColor(slip.allSigned ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(slip.title)
                    .font(.headline)

                Text("\(signedCount)/\(slip.signatures.count) signed")
                    .font(.subheadline)
                    .foregroundColor(slip.allSigned ? .green : .orange)

                if let dueDate = slip.dueDate {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("Due: \(formatDate(dueDate))")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !slip.allSigned {
                Circle()
                    .fill(.orange)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct PermissionSlipDetailView: View {
    let slip: PermissionSlip
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(slip.description)
                            .font(.body)

                        HStack {
                            Image(systemName: "calendar")
                            Text("Event Date: \(formatDate(slip.eventDate))")
                        }
                        .foregroundColor(.secondary)

                        if let dueDate = slip.dueDate {
                            HStack {
                                Image(systemName: "clock")
                                Text("Signatures Due: \(formatDate(dueDate))")
                            }
                            .foregroundColor(dueDate < Date() ? .red : .secondary)
                        }
                    }
                }

                Section("Signatures (\(signedCount)/\(slip.signatures.count))") {
                    ForEach(slip.signatures) { signature in
                        SignatureRow(signature: signature)
                    }
                }

                Section {
                    Button {
                        sendReminder()
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                            Text("Send Reminder to Unsigned")
                        }
                    }
                    .disabled(slip.allSigned)
                }
            }
            .navigationTitle(slip.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var signedCount: Int {
        slip.signatures.filter { $0.status == .signed }.count
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func sendReminder() {
        // Send push notification to unsigned parents
    }
}

struct SignatureRow: View {
    let signature: PermissionSlip.Signature

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(signature.studentName)
                    .font(.headline)

                Text(signature.parentName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            switch signature.status {
            case .signed:
                VStack(alignment: .trailing) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Signed")
                            .foregroundColor(.green)
                    }
                    .font(.caption)

                    if let signedAt = signature.signedAt {
                        Text(formatDate(signedAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

            case .pending:
                Text("Pending")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(6)

            case .declined:
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("Declined")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct CreatePermissionSlipView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (PermissionSlip) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var dueDate = Date()
    @State private var hasDueDate = true

    let students = ["Emma Wilson", "Liam Chen", "Olivia Brown", "Noah Garcia", "Ava Martinez"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section("Dates") {
                    DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)

                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Signatures Due", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Send To") {
                    ForEach(students, id: \.self) { student in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(student)
                        }
                    }

                    Text("All \(students.count) students will receive this permission slip")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Permission Slip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        let signatures = students.map { student in
                            PermissionSlip.Signature(
                                id: UUID().uuidString,
                                parentId: "parent_\(UUID().uuidString)",
                                parentName: "Parent of \(student)",
                                studentName: student,
                                signedAt: nil,
                                status: .pending
                            )
                        }

                        let slip = PermissionSlip(
                            id: UUID().uuidString,
                            classId: "class_001",
                            title: title,
                            description: description,
                            eventDate: eventDate,
                            createdBy: "Mrs. Koelpin",
                            createdAt: Date(),
                            dueDate: hasDueDate ? dueDate : nil,
                            signatures: signatures
                        )
                        onSave(slip)
                        dismiss()
                    }
                    .disabled(title.isEmpty || description.isEmpty)
                }
            }
        }
    }
}

// Parent View for signing permission slips
struct ParentSignatureView: View {
    let slip: PermissionSlip
    @State private var showingSignatureConfirm = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    Text(slip.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("From: \(slip.createdBy)")
                        .foregroundColor(.secondary)

                    Divider()

                    // Description
                    Text(slip.description)
                        .font(.body)

                    // Event Details
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Event Date:")
                                    .fontWeight(.medium)
                                Text(formatDate(slip.eventDate))
                            }

                            if let dueDate = slip.dueDate {
                                HStack {
                                    Image(systemName: "clock")
                                    Text("Please sign by:")
                                        .fontWeight(.medium)
                                    Text(formatDate(dueDate))
                                        .foregroundColor(dueDate < Date() ? .red : .primary)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Signature Area
                    VStack(spacing: 16) {
                        Text("By tapping 'Sign', I give permission for my child to participate in this activity.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            showingSignatureConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "signature")
                                Text("Sign Permission Slip")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button(role: .destructive) {
                            // Decline action
                        } label: {
                            Text("I do not give permission")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Confirm Signature", isPresented: $showingSignatureConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign") {
                    // Save signature
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign this permission slip?")
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

#Preview {
    PermissionSlipView()
}
