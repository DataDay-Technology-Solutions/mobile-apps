//
//  EventSignUpView.swift
//  TeacherLink
//
//  Event sign-up sheets for parents to volunteer
//

import SwiftUI

struct EventSignUpView: View {
    @State private var events: [ClassEvent] = []
    @State private var showingCreateEvent = false
    @State private var selectedEvent: ClassEvent?

    var body: some View {
        NavigationStack {
            List {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No Events Yet",
                        systemImage: "calendar.badge.plus",
                        description: Text("Create an event for parents to sign up")
                    )
                } else {
                    ForEach(events) { event in
                        EventRow(event: event)
                            .onTapGesture {
                                selectedEvent = event
                            }
                    }
                }
            }
            .navigationTitle("Event Sign-Ups")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView { newEvent in
                    events.append(newEvent)
                }
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            .onAppear {
                loadSampleEvents()
            }
        }
    }

    private func loadSampleEvents() {
        events = [
            ClassEvent(
                id: "event1",
                classId: "class_001",
                title: "Fall Festival",
                description: "Help run game booths and activities",
                eventDate: Date().addingTimeInterval(86400 * 14),
                location: "School Gymnasium",
                createdBy: "teacher_001",
                createdAt: Date(),
                slots: [
                    EventSlot(id: "slot1", title: "Face Painting (2-3pm)", maxSignups: 3, signedUpParents: [
                        ParentSignup(id: "ps1", parentId: "parent_001", parentName: "Sarah Johnson", signedUpAt: Date())
                    ]),
                    EventSlot(id: "slot2", title: "Ring Toss Game (2-3pm)", maxSignups: 2, signedUpParents: []),
                    EventSlot(id: "slot3", title: "Bake Sale Table", maxSignups: 4, signedUpParents: []),
                    EventSlot(id: "slot4", title: "Cleanup Crew (4-5pm)", maxSignups: 5, signedUpParents: [])
                ],
                eventType: .classParty
            ),
            ClassEvent(
                id: "event2",
                classId: "class_001",
                title: "Zoo Field Trip",
                description: "Chaperones needed for our trip to the zoo",
                eventDate: Date().addingTimeInterval(86400 * 21),
                location: "City Zoo",
                createdBy: "teacher_001",
                createdAt: Date(),
                slots: [
                    EventSlot(id: "slot5", title: "Chaperone Spot 1", maxSignups: 1, signedUpParents: []),
                    EventSlot(id: "slot6", title: "Chaperone Spot 2", maxSignups: 1, signedUpParents: []),
                    EventSlot(id: "slot7", title: "Chaperone Spot 3", maxSignups: 1, signedUpParents: [])
                ],
                eventType: .fieldTrip
            )
        ]
    }
}

struct EventRow: View {
    let event: ClassEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.eventType.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(event.eventType.color)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                Text(event.eventDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                let totalSlots = event.slots.reduce(0) { $0 + $1.maxSignups }
                let filledSlots = event.slots.reduce(0) { $0 + $1.signedUpParents.count }
                Text("\(filledSlots)/\(totalSlots) spots filled")
                    .font(.caption)
                    .foregroundColor(filledSlots == totalSlots ? .green : .orange)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EventDetailView: View {
    let event: ClassEvent
    @Environment(\.dismiss) var dismiss
    @State private var slots: [EventSlot]

    init(event: ClassEvent) {
        self.event = event
        _slots = State(initialValue: event.slots)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: event.eventType.icon)
                                .foregroundColor(event.eventType.color)
                            Text(event.eventType.rawValue)
                                .foregroundColor(.secondary)
                        }

                        Text(event.description)

                        HStack {
                            Image(systemName: "calendar")
                            Text(event.eventDate, style: .date)
                        }
                        .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "location")
                            Text(event.location)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Section("Sign-Up Slots") {
                    ForEach($slots) { $slot in
                        SlotRow(slot: $slot)
                    }
                }
            }
            .navigationTitle(event.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SlotRow: View {
    @Binding var slot: EventSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(slot.title)
                    .font(.headline)
                Spacer()
                Text("\(slot.signedUpParents.count)/\(slot.maxSignups)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(slot.isFull ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .cornerRadius(8)
            }

            if !slot.signedUpParents.isEmpty {
                ForEach(slot.signedUpParents) { parent in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(parent.parentName)
                            .font(.subheadline)
                    }
                }
            }

            if !slot.isFull {
                Button {
                    signUp()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Sign Up")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    private func signUp() {
        let newSignup = ParentSignup(
            id: UUID().uuidString,
            parentId: "current_parent",
            parentName: "Current User",
            signedUpAt: Date()
        )
        slot.signedUpParents.append(newSignup)
    }
}

struct CreateEventView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (ClassEvent) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var location = ""
    @State private var eventType: ClassEvent.EventType = .volunteer
    @State private var slots: [EventSlot] = []
    @State private var newSlotTitle = ""
    @State private var newSlotCount = 2

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker("Date", selection: $eventDate, displayedComponents: [.date, .hourAndMinute])
                    TextField("Location", text: $location)
                    Picker("Event Type", selection: $eventType) {
                        ForEach(ClassEvent.EventType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }

                Section("Volunteer Slots") {
                    ForEach(slots) { slot in
                        HStack {
                            Text(slot.title)
                            Spacer()
                            Text("\(slot.maxSignups) spots")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        slots.remove(atOffsets: indexSet)
                    }

                    HStack {
                        TextField("Slot name", text: $newSlotTitle)
                        Stepper("\(newSlotCount)", value: $newSlotCount, in: 1...10)
                            .frame(width: 100)
                        Button {
                            addSlot()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newSlotTitle.isEmpty)
                    }
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .disabled(title.isEmpty || slots.isEmpty)
                }
            }
        }
    }

    private func addSlot() {
        let slot = EventSlot(
            id: UUID().uuidString,
            title: newSlotTitle,
            maxSignups: newSlotCount,
            signedUpParents: []
        )
        slots.append(slot)
        newSlotTitle = ""
        newSlotCount = 2
    }

    private func saveEvent() {
        let event = ClassEvent(
            id: UUID().uuidString,
            classId: "class_001",
            title: title,
            description: description,
            eventDate: eventDate,
            location: location,
            createdBy: "teacher_001",
            createdAt: Date(),
            slots: slots,
            eventType: eventType
        )
        onSave(event)
        dismiss()
    }
}

#Preview {
    EventSignUpView()
}
