//
//  ClassPickerView.swift
//  TeacherLink
//

import SwiftUI

struct ClassPickerView: View {
    let classrooms: [Classroom]
    @Binding var selectedClassroom: Classroom?
    let onSelect: (Classroom) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(classrooms) { classroom in
                Button {
                    onSelect(classroom)
                } label: {
                    HStack {
                        Circle()
                            .fill(.blue)  // Default color
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(classroom.name.prefix(1))
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(classroom.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            HStack {
                                Text(classroom.gradeLevel)
                                Text("|")
                                Text("\(classroom.studentCount) students")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }

                        Spacer()

                        if classroom.id == selectedClassroom?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Class")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func colorFor(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default: return .blue
        }
    }
}

#Preview {
    ClassPickerView(
        classrooms: [
            Classroom(name: "Mrs. Smith's Class", gradeLevel: "1st Grade", teacherId: "1", teacherName: "Mrs. Smith"),
            Classroom(name: "Reading Group", gradeLevel: "1st Grade", teacherId: "1", teacherName: "Mrs. Smith")
        ],
        selectedClassroom: .constant(nil)
    ) { _ in }
}
