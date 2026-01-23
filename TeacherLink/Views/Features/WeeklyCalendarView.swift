//
//  WeeklyCalendarView.swift
//  TeacherLink
//
//  Weekly calendar showing homework, tests, events
//

import SwiftUI

struct WeeklyCalendarView: View {
    @State private var selectedDate = Date()
    @State private var calendarItems: [CalendarItem] = []
    @State private var showingAddItem = false

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week Navigation
                weekNavigationHeader

                // Week Days Grid
                weekDaysGrid

                Divider()

                // Items List for Selected Date
                itemsListForSelectedDate
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Today") {
                        selectedDate = Date()
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddCalendarItemView { item in
                    calendarItems.append(item)
                }
            }
            .onAppear {
                loadSampleData()
            }
        }
    }

    private var weekNavigationHeader: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(weekRangeText)
                .font(.headline)

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = formatter.string(from: weekDates.first!)
        let end = formatter.string(from: weekDates.last!)
        return "\(start) - \(end)"
    }

    private var weekDaysGrid: some View {
        HStack(spacing: 4) {
            ForEach(weekDates, id: \.self) { date in
                DayCell(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    items: itemsFor(date: date)
                )
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
    }

    private var itemsListForSelectedDate: some View {
        let items = itemsFor(date: selectedDate)

        return List {
            if items.isEmpty {
                ContentUnavailableView(
                    "No Items",
                    systemImage: "calendar",
                    description: Text("Nothing scheduled for this day")
                )
            } else {
                ForEach(items) { item in
                    CalendarItemRow(item: item)
                }
                .onDelete { indexSet in
                    // Delete items
                }
            }
        }
        .listStyle(.plain)
    }

    private func itemsFor(date: Date) -> [CalendarItem] {
        calendarItems.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func loadSampleData() {
        let calendar = Calendar.current
        let today = Date()

        calendarItems = [
            CalendarItem(id: "1", classId: "class_001", title: "Spelling Test", description: "Chapters 5-6 words", date: calendar.date(byAdding: .day, value: 2, to: today)!, itemType: .test, isAllDay: false, createdBy: "teacher", createdAt: Date()),
            CalendarItem(id: "2", classId: "class_001", title: "Math Homework", description: "Pages 45-46", date: calendar.date(byAdding: .day, value: 1, to: today)!, itemType: .homework, isAllDay: false, createdBy: "teacher", createdAt: Date()),
            CalendarItem(id: "3", classId: "class_001", title: "Art Project Due", description: "Self-portrait painting", date: calendar.date(byAdding: .day, value: 4, to: today)!, itemType: .project, isAllDay: false, createdBy: "teacher", createdAt: Date()),
            CalendarItem(id: "4", classId: "class_001", title: "Pizza Party!", description: "Class reward for good behavior", date: calendar.date(byAdding: .day, value: 5, to: today)!, itemType: .event, isAllDay: false, createdBy: "teacher", createdAt: Date()),
            CalendarItem(id: "5", classId: "class_001", title: "Reading Log Due", description: "Weekly reading minutes", date: today, itemType: .homework, isAllDay: false, createdBy: "teacher", createdAt: Date()),
            CalendarItem(id: "6", classId: "class_001", title: "No School - Teacher Workday", description: nil, date: calendar.date(byAdding: .day, value: 7, to: today)!, itemType: .noSchool, isAllDay: true, createdBy: "teacher", createdAt: Date()),
        ]
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let items: [CalendarItem]

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayName)
                .font(.caption2)
                .foregroundColor(.secondary)

            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                Text(dayNumber)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }

            // Dots for items
            HStack(spacing: 2) {
                ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                    Circle()
                        .fill(item.itemType.color)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(12)
    }
}

struct CalendarItemRow: View {
    let item: CalendarItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.itemType.icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(item.itemType.color)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                if let description = item.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "tag")
                        .font(.caption)
                    Text(item.itemType.rawValue)
                        .font(.caption)
                }
                .foregroundColor(item.itemType.color)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct AddCalendarItemView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (CalendarItem) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var itemType: CalendarItem.CalendarItemType = .homework
    @State private var isAllDay = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $description)

                    Picker("Type", selection: $itemType) {
                        ForEach(CalendarItem.CalendarItemType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                }

                Section("Date & Time") {
                    Toggle("All Day", isOn: $isAllDay)
                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = CalendarItem(
                            id: UUID().uuidString,
                            classId: "class_001",
                            title: title,
                            description: description.isEmpty ? nil : description,
                            date: date,
                            itemType: itemType,
                            isAllDay: isAllDay,
                            createdBy: "teacher",
                            createdAt: Date()
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

#Preview {
    WeeklyCalendarView()
}
