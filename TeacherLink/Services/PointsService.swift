//
//  PointsService.swift
//  HallPass (formerly TeacherLink)
//
//  Handles behavior points storage and retrieval in Supabase
//

import Foundation
import Supabase

class PointsService {
    static let shared = PointsService()
    private let supabase = SupabaseConfig.client

    private init() {}

    // MARK: - Award Points

    func awardPoints(
        studentId: String,
        classId: String,
        behavior: Behavior,
        note: String? = nil,
        awardedBy: String,
        awardedByName: String
    ) async throws -> PointRecord {
        var record = PointRecord(
            studentId: studentId,
            classId: classId,
            behaviorId: behavior.id,
            behaviorName: behavior.name,
            points: behavior.points,
            note: note,
            awardedBy: awardedBy,
            awardedByName: awardedByName
        )

        // Add point record
        let response: [PointRecord] = try await supabase
            .from("point_records")
            .insert(record)
            .select()
            .execute()
            .value

        guard let newRecord = response.first else {
            throw NSError(domain: "PointsError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create point record"])
        }

        // Update student's summary
        try await updateStudentSummary(
            studentId: studentId,
            classId: classId,
            pointsDelta: behavior.points,
            isPositive: behavior.isPositive
        )

        return newRecord
    }

    // MARK: - Bulk Award Points

    func awardPointsToMultipleStudents(
        studentIds: [String],
        classId: String,
        behavior: Behavior,
        awardedBy: String,
        awardedByName: String
    ) async throws {
        var records: [[String: AnyJSON]] = []

        for studentId in studentIds {
            let record: [String: AnyJSON] = [
                "student_id": .string(studentId),
                "class_id": .string(classId),
                "behavior_id": .string(behavior.id ?? ""),
                "behavior_name": .string(behavior.name),
                "points": .integer(behavior.points),
                "awarded_by": .string(awardedBy),
                "awarded_by_name": .string(awardedByName),
                "created_at": .string(ISO8601DateFormatter().string(from: Date()))
            ]
            records.append(record)
        }

        try await supabase
            .from("point_records")
            .insert(records)
            .execute()

        // Update summaries for each student
        for studentId in studentIds {
            try await updateStudentSummary(
                studentId: studentId,
                classId: classId,
                pointsDelta: behavior.points,
                isPositive: behavior.isPositive
            )
        }
    }

    // MARK: - Get Points History

    func getPointsHistory(
        studentId: String,
        limit: Int = 50
    ) async throws -> [PointRecord] {
        let response: [PointRecord] = try await supabase
            .from("point_records")
            .select()
            .eq("student_id", value: studentId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    func getClassPointsHistory(
        classId: String,
        limit: Int = 100
    ) async throws -> [PointRecord] {
        let response: [PointRecord] = try await supabase
            .from("point_records")
            .select()
            .eq("class_id", value: classId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }

    // MARK: - Get Student Summary

    func getStudentSummary(studentId: String, classId: String) async throws -> StudentPointsSummary {
        do {
            let summary: StudentPointsSummary = try await supabase
                .from("student_points_summaries")
                .select()
                .eq("student_id", value: studentId)
                .eq("class_id", value: classId)
                .single()
                .execute()
                .value

            return summary
        } catch {
            // Create new summary if doesn't exist
            return StudentPointsSummary(studentId: studentId, classId: classId)
        }
    }

    func getClassSummaries(classId: String) async throws -> [StudentPointsSummary] {
        let response: [StudentPointsSummary] = try await supabase
            .from("student_points_summaries")
            .select()
            .eq("class_id", value: classId)
            .order("total_points", ascending: false)
            .execute()
            .value

        return response
    }

    // MARK: - Update Summary

    private func updateStudentSummary(
        studentId: String,
        classId: String,
        pointsDelta: Int,
        isPositive: Bool
    ) async throws {
        // Try to get existing summary
        do {
            var summary: StudentPointsSummary = try await supabase
                .from("student_points_summaries")
                .select()
                .eq("student_id", value: studentId)
                .eq("class_id", value: classId)
                .single()
                .execute()
                .value

            // Update existing summary
            summary.totalPoints += pointsDelta
            if isPositive {
                summary.positiveCount += 1
            } else {
                summary.negativeCount += 1
            }
            summary.lastUpdated = Date()

            try await supabase
                .from("student_points_summaries")
                .update(summary)
                .eq("student_id", value: studentId)
                .eq("class_id", value: classId)
                .execute()
        } catch {
            // Create new summary
            let summary = StudentPointsSummary(
                studentId: studentId,
                classId: classId,
                totalPoints: pointsDelta,
                positiveCount: isPositive ? 1 : 0,
                negativeCount: isPositive ? 0 : 1
            )
            try await supabase
                .from("student_points_summaries")
                .insert(summary)
                .execute()
        }
    }

    // MARK: - Delete Points Record

    func deletePointRecord(recordId: String, studentId: String, classId: String, points: Int, wasPositive: Bool) async throws {
        // Delete the record
        try await supabase
            .from("point_records")
            .delete()
            .eq("id", value: recordId)
            .execute()

        // Update summary (reverse the points)
        var summary = try await getStudentSummary(studentId: studentId, classId: classId)
        summary.totalPoints -= points
        if wasPositive {
            summary.positiveCount -= 1
        } else {
            summary.negativeCount -= 1
        }
        summary.lastUpdated = Date()

        try await supabase
            .from("student_points_summaries")
            .update(summary)
            .eq("student_id", value: studentId)
            .eq("class_id", value: classId)
            .execute()
    }

    // MARK: - Reset Student Points

    func resetStudentPoints(studentId: String, classId: String) async throws {
        // Delete all point records for this student
        try await supabase
            .from("point_records")
            .delete()
            .eq("student_id", value: studentId)
            .eq("class_id", value: classId)
            .execute()

        // Reset summary
        let resetSummary = StudentPointsSummary(
            studentId: studentId,
            classId: classId,
            totalPoints: 0,
            positiveCount: 0,
            negativeCount: 0
        )

        try await supabase
            .from("student_points_summaries")
            .upsert(resetSummary)
            .execute()
    }

    // MARK: - Real-time Listeners (using Supabase Realtime)

    private var summaryChannel: RealtimeChannelV2?
    private var recordsChannel: RealtimeChannelV2?

    func listenToStudentPoints(studentId: String, classId: String, completion: @escaping (StudentPointsSummary) -> Void) {
        // Initial fetch
        Task {
            let summary = try? await getStudentSummary(studentId: studentId, classId: classId)
            await MainActor.run {
                completion(summary ?? StudentPointsSummary(studentId: studentId, classId: classId))
            }
        }

        // Set up realtime subscription
        summaryChannel = supabase.realtimeV2.channel("student_summary_\(studentId)_\(classId)")

        Task {
            await summaryChannel?.subscribe()

            let changes = summaryChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "student_points_summaries"
            )

            if let changes = changes {
                for await _ in changes {
                    let summary = try? await getStudentSummary(studentId: studentId, classId: classId)
                    await MainActor.run {
                        completion(summary ?? StudentPointsSummary(studentId: studentId, classId: classId))
                    }
                }
            }
        }
    }

    func listenToClassSummaries(classId: String, completion: @escaping ([StudentPointsSummary]) -> Void) {
        // Initial fetch
        Task {
            let summaries = try? await getClassSummaries(classId: classId)
            await MainActor.run {
                completion(summaries ?? [])
            }
        }

        // Set up realtime subscription
        summaryChannel = supabase.realtimeV2.channel("class_summaries_\(classId)")

        Task {
            await summaryChannel?.subscribe()

            let changes = summaryChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "student_points_summaries",
                filter: "class_id=eq.\(classId)"
            )

            if let changes = changes {
                for await _ in changes {
                    let summaries = try? await getClassSummaries(classId: classId)
                    await MainActor.run {
                        completion(summaries ?? [])
                    }
                }
            }
        }
    }

    func listenToRecentPoints(classId: String, limit: Int = 20, completion: @escaping ([PointRecord]) -> Void) {
        // Initial fetch
        Task {
            let records = try? await getClassPointsHistory(classId: classId, limit: limit)
            await MainActor.run {
                completion(records ?? [])
            }
        }

        // Set up realtime subscription
        recordsChannel = supabase.realtimeV2.channel("recent_points_\(classId)")

        Task {
            await recordsChannel?.subscribe()

            let changes = recordsChannel?.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "point_records",
                filter: "class_id=eq.\(classId)"
            )

            if let changes = changes {
                for await _ in changes {
                    let records = try? await getClassPointsHistory(classId: classId, limit: limit)
                    await MainActor.run {
                        completion(records ?? [])
                    }
                }
            }
        }
    }

    func stopListening() {
        Task {
            await summaryChannel?.unsubscribe()
            await recordsChannel?.unsubscribe()
        }
    }
}
