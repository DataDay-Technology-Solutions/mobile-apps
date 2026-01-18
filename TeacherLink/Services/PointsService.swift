//
//  PointsService.swift
//  TeacherLink
//
//  Handles behavior points storage and retrieval in Firebase
//

import Foundation
import FirebaseFirestore

class PointsService {
    static let shared = PointsService()
    private let db = Firestore.firestore()

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
        let record = PointRecord(
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
        let docRef = db.collection("pointRecords").document()
        var newRecord = record
        newRecord.id = docRef.documentID
        try docRef.setData(from: newRecord)

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
        let batch = db.batch()

        for studentId in studentIds {
            let record = PointRecord(
                studentId: studentId,
                classId: classId,
                behaviorId: behavior.id,
                behaviorName: behavior.name,
                points: behavior.points,
                awardedBy: awardedBy,
                awardedByName: awardedByName
            )

            let docRef = db.collection("pointRecords").document()
            try batch.setData(from: record, forDocument: docRef)
        }

        try await batch.commit()

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
        let snapshot = try await db.collection("pointRecords")
            .whereField("studentId", isEqualTo: studentId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: PointRecord.self) }
    }

    func getClassPointsHistory(
        classId: String,
        limit: Int = 100
    ) async throws -> [PointRecord] {
        let snapshot = try await db.collection("pointRecords")
            .whereField("classId", isEqualTo: classId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: PointRecord.self) }
    }

    // MARK: - Get Student Summary

    func getStudentSummary(studentId: String, classId: String) async throws -> StudentPointsSummary {
        let document = try await db.collection("studentPointsSummaries")
            .document("\(studentId)_\(classId)")
            .getDocument()

        if let summary = try? document.data(as: StudentPointsSummary.self) {
            return summary
        }

        // Create new summary if doesn't exist
        return StudentPointsSummary(studentId: studentId, classId: classId)
    }

    func getClassSummaries(classId: String) async throws -> [StudentPointsSummary] {
        let snapshot = try await db.collection("studentPointsSummaries")
            .whereField("classId", isEqualTo: classId)
            .order(by: "totalPoints", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: StudentPointsSummary.self) }
    }

    // MARK: - Update Summary

    private func updateStudentSummary(
        studentId: String,
        classId: String,
        pointsDelta: Int,
        isPositive: Bool
    ) async throws {
        let docRef = db.collection("studentPointsSummaries").document("\(studentId)_\(classId)")

        try await db.runTransaction { transaction, _ in
            let document = try? transaction.getDocument(docRef)

            if let existingData = document?.data(),
               var summary = try? document?.data(as: StudentPointsSummary.self) {
                summary.totalPoints += pointsDelta
                if isPositive {
                    summary.positiveCount += 1
                } else {
                    summary.negativeCount += 1
                }
                summary.lastUpdated = Date()
                try? transaction.setData(from: summary, forDocument: docRef)
            } else {
                // Create new summary
                let summary = StudentPointsSummary(
                    studentId: studentId,
                    classId: classId,
                    totalPoints: pointsDelta,
                    positiveCount: isPositive ? 1 : 0,
                    negativeCount: isPositive ? 0 : 1
                )
                try? transaction.setData(from: summary, forDocument: docRef)
            }

            return nil
        }
    }

    // MARK: - Delete Points Record

    func deletePointRecord(recordId: String, studentId: String, classId: String, points: Int, wasPositive: Bool) async throws {
        // Delete the record
        try await db.collection("pointRecords").document(recordId).delete()

        // Update summary (reverse the points)
        let docRef = db.collection("studentPointsSummaries").document("\(studentId)_\(classId)")

        try await docRef.updateData([
            "totalPoints": FieldValue.increment(Int64(-points)),
            "positiveCount": FieldValue.increment(Int64(wasPositive ? -1 : 0)),
            "negativeCount": FieldValue.increment(Int64(wasPositive ? 0 : -1)),
            "lastUpdated": Timestamp(date: Date())
        ])
    }

    // MARK: - Reset Student Points

    func resetStudentPoints(studentId: String, classId: String) async throws {
        // Delete all point records for this student
        let snapshot = try await db.collection("pointRecords")
            .whereField("studentId", isEqualTo: studentId)
            .whereField("classId", isEqualTo: classId)
            .getDocuments()

        let batch = db.batch()
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }

        // Reset summary
        let summaryRef = db.collection("studentPointsSummaries").document("\(studentId)_\(classId)")
        batch.setData([
            "studentId": studentId,
            "classId": classId,
            "totalPoints": 0,
            "positiveCount": 0,
            "negativeCount": 0,
            "lastUpdated": Timestamp(date: Date())
        ], forDocument: summaryRef)

        try await batch.commit()
    }

    // MARK: - Real-time Listeners

    func listenToStudentPoints(studentId: String, classId: String, completion: @escaping (StudentPointsSummary) -> Void) -> ListenerRegistration {
        return db.collection("studentPointsSummaries")
            .document("\(studentId)_\(classId)")
            .addSnapshotListener { snapshot, _ in
                if let summary = try? snapshot?.data(as: StudentPointsSummary.self) {
                    completion(summary)
                } else {
                    completion(StudentPointsSummary(studentId: studentId, classId: classId))
                }
            }
    }

    func listenToClassSummaries(classId: String, completion: @escaping ([StudentPointsSummary]) -> Void) -> ListenerRegistration {
        return db.collection("studentPointsSummaries")
            .whereField("classId", isEqualTo: classId)
            .order(by: "totalPoints", descending: true)
            .addSnapshotListener { snapshot, _ in
                let summaries = snapshot?.documents.compactMap { try? $0.data(as: StudentPointsSummary.self) } ?? []
                completion(summaries)
            }
    }

    func listenToRecentPoints(classId: String, limit: Int = 20, completion: @escaping ([PointRecord]) -> Void) -> ListenerRegistration {
        return db.collection("pointRecords")
            .whereField("classId", isEqualTo: classId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .addSnapshotListener { snapshot, _ in
                let records = snapshot?.documents.compactMap { try? $0.data(as: PointRecord.self) } ?? []
                completion(records)
            }
    }
}
