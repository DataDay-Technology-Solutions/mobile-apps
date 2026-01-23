//
//  MoodCheckInView.swift
//  TeacherLink
//
//  Daily mood check-in for students
//

import SwiftUI

struct MoodCheckInView: View {
    @State private var checkIns: [MoodCheckIn] = []
    @State private var showingCheckInSheet = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Today's Mood Summary
                TodayMoodSummary(checkIns: todayCheckIns)

                // Check-ins List
                List {
                    Section("Today's Check-Ins") {
                        if todayCheckIns.isEmpty {
                            ContentUnavailableView(
                                "No Check-Ins Yet",
                                systemImage: "face.smiling",
                                description: Text("Students haven't checked in today")
                            )
                        } else {
                            ForEach(todayCheckIns) { checkIn in
                                MoodCheckInRow(checkIn: checkIn)
                            }
                        }
                    }

                    Section("Weekly Trends") {
                        WeeklyMoodChart(checkIns: checkIns)
                    }
                }
            }
            .navigationTitle("Mood Check-In")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCheckInSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCheckInSheet) {
                StudentMoodCheckInView { newCheckIn in
                    checkIns.append(newCheckIn)
                }
            }
            .onAppear {
                loadSampleData()
            }
        }
    }

    private var todayCheckIns: [MoodCheckIn] {
        checkIns.filter { Calendar.current.isDateInToday($0.checkedInAt) }
    }

    private func loadSampleData() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        checkIns = [
            MoodCheckIn(id: "1", studentId: "s1", studentName: "Emma Wilson", mood: .happy, note: "Excited about art class!", checkedInAt: today, classId: "class_001"),
            MoodCheckIn(id: "2", studentId: "s2", studentName: "Liam Chen", mood: .okay, note: nil, checkedInAt: today, classId: "class_001"),
            MoodCheckIn(id: "3", studentId: "s3", studentName: "Olivia Brown", mood: .sad, note: "Missing my grandma", checkedInAt: today, classId: "class_001"),
            MoodCheckIn(id: "4", studentId: "s4", studentName: "Noah Garcia", mood: .excited, note: "Field trip tomorrow!", checkedInAt: today, classId: "class_001"),
            MoodCheckIn(id: "5", studentId: "s1", studentName: "Emma Wilson", mood: .okay, note: nil, checkedInAt: yesterday, classId: "class_001"),
            MoodCheckIn(id: "6", studentId: "s2", studentName: "Liam Chen", mood: .happy, note: nil, checkedInAt: yesterday, classId: "class_001"),
        ]
    }
}

struct TodayMoodSummary: View {
    let checkIns: [MoodCheckIn]

    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Class Mood")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(MoodCheckIn.Mood.allCases, id: \.self) { mood in
                    VStack {
                        Text(mood.emoji)
                            .font(.system(size: 32))

                        let count = checkIns.filter { $0.mood == mood }.count
                        Text("\(count)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }

            if !checkIns.isEmpty {
                let total = checkIns.count
                let needsAttention = checkIns.filter { $0.mood == .sad || $0.mood == .anxious }.count
                if needsAttention > 0 {
                    Text("\(needsAttention) student\(needsAttention == 1 ? "" : "s") may need check-in")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}

struct MoodCheckInRow: View {
    let checkIn: MoodCheckIn

    var body: some View {
        HStack(spacing: 12) {
            Text(checkIn.mood.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.studentName)
                    .font(.headline)

                if let note = checkIn.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(formatTime(checkIn.checkedInAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if checkIn.mood == .sad || checkIn.mood == .anxious {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WeeklyMoodChart: View {
    let checkIns: [MoodCheckIn]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mood Distribution")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(MoodCheckIn.Mood.allCases, id: \.self) { mood in
                    let count = checkIns.filter { $0.mood == mood }.count
                    let percentage = checkIns.isEmpty ? 0 : Double(count) / Double(checkIns.count)

                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(mood.color)
                            .frame(height: max(20, CGFloat(percentage) * 100))

                        Text(mood.emoji)
                            .font(.caption)
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(.vertical, 8)
    }
}

struct StudentMoodCheckInView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (MoodCheckIn) -> Void

    @State private var selectedMood: MoodCheckIn.Mood = .okay
    @State private var note = ""
    @State private var selectedStudent: String = ""

    let students = ["Emma Wilson", "Liam Chen", "Olivia Brown", "Noah Garcia", "Ava Martinez"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("How are you feeling today?")
                    .font(.title2)
                    .fontWeight(.bold)

                // Student Picker (for teacher mode)
                Picker("Student", selection: $selectedStudent) {
                    Text("Select Student").tag("")
                    ForEach(students, id: \.self) { student in
                        Text(student).tag(student)
                    }
                }
                .pickerStyle(.menu)

                // Mood Selection
                HStack(spacing: 16) {
                    ForEach(MoodCheckIn.Mood.allCases, id: \.self) { mood in
                        Button {
                            selectedMood = mood
                        } label: {
                            VStack {
                                Text(mood.emoji)
                                    .font(.system(size: 48))
                                Text(mood.rawValue)
                                    .font(.caption)
                            }
                            .padding()
                            .background(selectedMood == mood ? mood.color.opacity(0.3) : Color.clear)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Note
                TextField("Want to share more? (optional)", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Mood Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let checkIn = MoodCheckIn(
                            id: UUID().uuidString,
                            studentId: "student_\(selectedStudent.lowercased().replacingOccurrences(of: " ", with: "_"))",
                            studentName: selectedStudent,
                            mood: selectedMood,
                            note: note.isEmpty ? nil : note,
                            checkedInAt: Date(),
                            classId: "class_001"
                        )
                        onSave(checkIn)
                        dismiss()
                    }
                    .disabled(selectedStudent.isEmpty)
                }
            }
        }
    }
}

#Preview {
    MoodCheckInView()
}
