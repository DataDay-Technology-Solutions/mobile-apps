//
//  RandomPickerView.swift
//  TeacherLink
//
//  Random student picker for fair selection
//

import SwiftUI

struct RandomPickerView: View {
    @State private var students: [String] = []
    @State private var selectedStudent: String?
    @State private var isSpinning = false
    @State private var spinAngle: Double = 0
    @State private var recentPicks: [String] = []
    @State private var excludeRecent = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Wheel View
                ZStack {
                    // Background circle
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [.blue, .purple, .pink, .orange, .yellow, .green, .blue]),
                                center: .center
                            )
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(spinAngle))

                    // Inner circle
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 200, height: 200)

                    // Selected student or instruction
                    VStack(spacing: 8) {
                        if isSpinning {
                            Text("Spinning...")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        } else if let selected = selectedStudent {
                            Text(selected)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Text("was picked!")
                                .font(.headline)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)

                            Text("Tap to pick")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Pointer
                    Triangle()
                        .fill(Color.red)
                        .frame(width: 30, height: 40)
                        .offset(y: -160)
                }

                // Pick Button
                Button {
                    pickRandomStudent()
                } label: {
                    HStack {
                        Image(systemName: "dice.fill")
                        Text("Pick a Student")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSpinning || eligibleStudents.isEmpty)
                .padding(.horizontal)

                // Options
                Toggle("Exclude recently picked", isOn: $excludeRecent)
                    .padding(.horizontal)

                // Recent Picks
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Picks")
                            .font(.headline)

                        Spacer()

                        if !recentPicks.isEmpty {
                            Button("Clear") {
                                recentPicks.removeAll()
                            }
                            .font(.caption)
                        }
                    }

                    if recentPicks.isEmpty {
                        Text("No students picked yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(recentPicks.reversed(), id: \.self) { name in
                                    Text(name)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Random Picker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            resetPicker()
                        } label: {
                            Label("Reset All", systemImage: "arrow.counterclockwise")
                        }

                        Button {
                            // Settings action
                        } label: {
                            Label("Manage Students", systemImage: "person.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                loadStudents()
            }
        }
    }

    private var eligibleStudents: [String] {
        if excludeRecent {
            return students.filter { !recentPicks.contains($0) }
        }
        return students
    }

    private func loadStudents() {
        students = [
            "Emma Wilson",
            "Liam Chen",
            "Olivia Brown",
            "Noah Garcia",
            "Ava Martinez",
            "Lucas Johnson",
            "Sophia Lee",
            "Mason Kim",
            "Isabella Davis",
            "Ethan Rodriguez"
        ]
    }

    private func pickRandomStudent() {
        guard !eligibleStudents.isEmpty else { return }

        isSpinning = true
        selectedStudent = nil

        // Animate spin
        let spins = Double.random(in: 3...5)
        let finalAngle = spinAngle + (360 * spins) + Double.random(in: 0...360)

        withAnimation(.easeInOut(duration: 2.5)) {
            spinAngle = finalAngle
        }

        // Pick student after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if let picked = eligibleStudents.randomElement() {
                selectedStudent = picked
                recentPicks.append(picked)

                // Keep only last 5 picks
                if recentPicks.count > 5 {
                    recentPicks.removeFirst()
                }
            }
            isSpinning = false
        }
    }

    private func resetPicker() {
        selectedStudent = nil
        recentPicks.removeAll()
        spinAngle = 0
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// Alternative: Name Wheel View for classes with many students
struct NameWheelPickerView: View {
    let students: [String]
    @Binding var selectedIndex: Int?
    @State private var rotation: Double = 0

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                ForEach(Array(students.enumerated()), id: \.offset) { index, name in
                    let angle = Double(index) / Double(students.count) * 360

                    Text(name)
                        .font(.caption)
                        .rotationEffect(.degrees(-angle - rotation))
                        .offset(y: -size/3)
                        .rotationEffect(.degrees(angle + rotation))
                }
            }
            .frame(width: size, height: size)
        }
    }
}

#Preview {
    RandomPickerView()
}
