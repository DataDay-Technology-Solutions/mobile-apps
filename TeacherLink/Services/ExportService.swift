//
//  ExportService.swift
//  HallPass (formerly TeacherLink)
//
//  Service for exporting data to CSV format
//

import Foundation
import UIKit

class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - Export Students

    func exportStudents(from classrooms: [Classroom]) async throws -> URL {
        var csvContent = "Student ID,First Name,Last Name,Grade Level,Classroom,Teacher,Points\n"

        for classroom in classrooms {
            guard let classId = classroom.id else { continue }

            // Load students for this classroom
            let students: [Student] = try await SupabaseConfig.client
                .from("students")
                .select()
                .eq("class_id", value: classId)
                .execute()
                .value

            // Load points summary
            let summaries: [StudentPointsSummary] = try await SupabaseConfig.client
                .from("student_points_summary")
                .select()
                .eq("class_id", value: classId)
                .execute()
                .value

            let pointsDict = Dictionary(uniqueKeysWithValues: summaries.map { ($0.studentId, $0.totalPoints) })

            for student in students {
                let points = pointsDict[student.id ?? ""] ?? 0
                let row = "\(student.id ?? ""),\"\(student.firstName)\",\"\(student.lastName)\",\(classroom.gradeLevel),\"\(classroom.name)\",\"\(classroom.teacherName)\",\(points)\n"
                csvContent += row
            }
        }

        return try saveCSV(content: csvContent, filename: "students_export")
    }

    // MARK: - Export Classrooms

    func exportClassrooms(_ classrooms: [Classroom]) async throws -> URL {
        var csvContent = "Classroom ID,Name,Grade Level,Teacher,Class Code,Student Count,Parent Count\n"

        for classroom in classrooms {
            let row = "\(classroom.id ?? ""),\"\(classroom.name)\",\(classroom.gradeLevel),\"\(classroom.teacherName)\",\(classroom.classCode),\(classroom.studentIds.count),\(classroom.parentIds.count)\n"
            csvContent += row
        }

        return try saveCSV(content: csvContent, filename: "classrooms_export")
    }

    // MARK: - Export Points History

    func exportPointsHistory(for classIds: [String]) async throws -> URL {
        var csvContent = "Date,Student ID,Behavior,Points,Awarded By,Note\n"

        let records: [PointRecord] = try await SupabaseConfig.client
            .from("point_records")
            .select()
            .in("class_id", values: classIds)
            .order("created_at", ascending: false)
            .execute()
            .value

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        for record in records {
            let date = dateFormatter.string(from: record.createdAt)
            let note = record.note?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
            let row = "\(date),\(record.studentId),\"\(record.behaviorName)\",\(record.points),\"\(record.awardedByName)\",\"\(note)\"\n"
            csvContent += row
        }

        return try saveCSV(content: csvContent, filename: "points_history_export")
    }

    // MARK: - Export Teachers

    func exportTeachers(for districtOrSchoolId: String, isDistrict: Bool) async throws -> URL {
        var csvContent = "Teacher ID,Name,Email,School ID,Classroom Count\n"

        let query = SupabaseConfig.client
            .from("users")
            .select()
            .eq(isDistrict ? "district_id" : "school_id", value: districtOrSchoolId)
            .eq("role", value: "teacher")

        let dbUsers: [DatabaseUser] = try await query.execute().value

        for user in dbUsers {
            // Count classrooms for this teacher
            let classrooms: [Classroom] = try await SupabaseConfig.client
                .from("classrooms")
                .select()
                .eq("teacher_id", value: user.id)
                .execute()
                .value

            let row = "\(user.id),\"\(user.name)\",\(user.email),\(user.schoolId ?? ""),\(classrooms.count)\n"
            csvContent += row
        }

        return try saveCSV(content: csvContent, filename: "teachers_export")
    }

    // MARK: - Export Summary Report

    func exportSummaryReport(
        districtName: String? = nil,
        schoolName: String? = nil,
        schoolCount: Int = 0,
        classroomCount: Int,
        teacherCount: Int,
        studentCount: Int,
        parentCount: Int,
        totalPoints: Int
    ) throws -> URL {
        var csvContent = "Report Summary\n"
        csvContent += "Generated,\(Date())\n\n"

        if let districtName = districtName {
            csvContent += "District,\(districtName)\n"
            csvContent += "Schools,\(schoolCount)\n"
        }

        if let schoolName = schoolName {
            csvContent += "School,\(schoolName)\n"
        }

        csvContent += "Classrooms,\(classroomCount)\n"
        csvContent += "Teachers,\(teacherCount)\n"
        csvContent += "Students,\(studentCount)\n"
        csvContent += "Parents,\(parentCount)\n"
        csvContent += "Total Points,\(totalPoints)\n"

        return try saveCSV(content: csvContent, filename: "summary_report")
    }

    // MARK: - Helper

    private func saveCSV(content: String, filename: String) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let fileName = "\(filename)_\(timestamp).csv"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}
