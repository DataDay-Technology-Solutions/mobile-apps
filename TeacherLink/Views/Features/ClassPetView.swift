//
//  ClassPetView.swift
//  TeacherLink
//
//  Virtual class pet that students can interact with
//

import SwiftUI

struct ClassPetView: View {
    @State private var classPet: ClassPet?
    @State private var showingSetupSheet = false
    @State private var feedingAnimation = false
    @State private var playingAnimation = false

    var body: some View {
        NavigationStack {
            if let pet = classPet {
                PetDetailView(pet: $classPet, feedingAnimation: $feedingAnimation, playingAnimation: $playingAnimation)
            } else {
                NoPetView(showingSetupSheet: $showingSetupSheet)
            }
        }
        .sheet(isPresented: $showingSetupSheet) {
            SetupPetView { newPet in
                classPet = newPet
            }
        }
        .onAppear {
            loadSamplePet()
        }
    }

    private func loadSamplePet() {
        classPet = ClassPet(
            id: "pet1",
            classId: "class_001",
            name: "Bubbles",
            type: .fish,
            level: 5,
            experience: 450,
            happiness: 80,
            lastFedAt: Date().addingTimeInterval(-3600),
            lastPlayedAt: Date().addingTimeInterval(-7200),
            createdAt: Date().addingTimeInterval(-86400 * 30)
        )
    }
}

struct NoPetView: View {
    @Binding var showingSetupSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "pawprint.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("No Class Pet Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create a virtual class pet for your students to care for together!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingSetupSheet = true
            } label: {
                Label("Adopt a Pet", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Class Pet")
    }
}

struct PetDetailView: View {
    @Binding var pet: ClassPet?
    @Binding var feedingAnimation: Bool
    @Binding var playingAnimation: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pet Display
                PetAvatarView(pet: pet!, feedingAnimation: feedingAnimation, playingAnimation: playingAnimation)

                // Stats
                PetStatsView(pet: pet!)

                // Actions
                HStack(spacing: 20) {
                    Button {
                        feedPet()
                    } label: {
                        VStack {
                            Image(systemName: "fork.knife")
                                .font(.title)
                            Text("Feed")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        playWithPet()
                    } label: {
                        VStack {
                            Image(systemName: "gamecontroller.fill")
                                .font(.title)
                            Text("Play")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button {
                        // Clean action
                    } label: {
                        VStack {
                            Image(systemName: "sparkles")
                                .font(.title)
                            Text("Clean")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }

                // Activity Log
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)

                    ActivityRow(icon: "fork.knife", text: "Fed by Emma", time: "2 hours ago", color: .green)
                    ActivityRow(icon: "gamecontroller.fill", text: "Played with by Liam", time: "4 hours ago", color: .orange)
                    ActivityRow(icon: "sparkles", text: "Cleaned by Olivia", time: "Yesterday", color: .blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle(pet?.name ?? "Class Pet")
    }

    private func feedPet() {
        feedingAnimation = true
        if var currentPet = pet {
            currentPet.happiness = min(100, currentPet.happiness + 10)
            currentPet.experience += 10
            currentPet.lastFedAt = Date()
            pet = currentPet
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            feedingAnimation = false
        }
    }

    private func playWithPet() {
        playingAnimation = true
        if var currentPet = pet {
            currentPet.happiness = min(100, currentPet.happiness + 15)
            currentPet.experience += 15
            currentPet.lastPlayedAt = Date()
            pet = currentPet
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            playingAnimation = false
        }
    }
}

struct PetAvatarView: View {
    let pet: ClassPet
    let feedingAnimation: Bool
    let playingAnimation: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(pet.type.color.opacity(0.2))
                .frame(width: 180, height: 180)

            Image(systemName: pet.type.icon)
                .font(.system(size: 80))
                .foregroundColor(pet.type.color)
                .scaleEffect(feedingAnimation || playingAnimation ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: feedingAnimation || playingAnimation)

            // Happiness indicator
            if pet.happiness < 30 {
                Image(systemName: "cloud.rain.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                    .offset(x: 60, y: -60)
            } else if pet.happiness > 80 {
                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundColor(.pink)
                    .offset(x: 60, y: -60)
            }
        }
    }
}

struct PetStatsView: View {
    let pet: ClassPet

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(pet.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text("Level \(pet.level)")
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(12)
            }

            // XP Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Experience")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(pet.experience)/\(pet.level * 100)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(pet.experience % 100), total: 100)
                    .tint(.purple)
            }
            .padding(.horizontal)

            // Happiness Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Happiness")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(pet.happiness)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: Double(pet.happiness), total: 100)
                    .tint(pet.happiness > 60 ? .green : (pet.happiness > 30 ? .yellow : .red))
            }
            .padding(.horizontal)
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let text: String
    let time: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()

            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct SetupPetView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (ClassPet) -> Void

    @State private var name = ""
    @State private var selectedType: ClassPet.PetType = .dog

    var body: some View {
        NavigationStack {
            Form {
                Section("Choose Your Pet") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(ClassPet.PetType.allCases, id: \.self) { type in
                            Button {
                                selectedType = type
                            } label: {
                                VStack {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 36))
                                        .foregroundColor(type.color)

                                    Text(type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                                .frame(width: 80, height: 80)
                                .background(selectedType == type ? type.color.opacity(0.2) : Color.clear)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Name Your Pet") {
                    TextField("Pet Name", text: $name)
                }

                Section {
                    HStack {
                        Spacer()
                        VStack {
                            Image(systemName: selectedType.icon)
                                .font(.system(size: 60))
                                .foregroundColor(selectedType.color)

                            Text(name.isEmpty ? "Your Pet" : name)
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Adopt a Pet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adopt") {
                        let pet = ClassPet(
                            id: UUID().uuidString,
                            classId: "class_001",
                            name: name,
                            type: selectedType,
                            level: 1,
                            experience: 0,
                            happiness: 100,
                            lastFedAt: Date(),
                            lastPlayedAt: Date(),
                            createdAt: Date()
                        )
                        onSave(pet)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ClassPetView()
}
