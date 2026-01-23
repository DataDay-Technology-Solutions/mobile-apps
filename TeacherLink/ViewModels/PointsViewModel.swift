//
//  PointsViewModel.swift
//  TeacherLink
//

import Foundation

@MainActor
class PointsViewModel: ObservableObject {
    @Published var classSummaries: [StudentPointsSummary] = []
    @Published var recentPoints: [PointRecord] = []
    @Published var studentHistory: [PointRecord] = []
    @Published var selectedStudentSummary: StudentPointsSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var positiveBehaviors: [Behavior] = Behavior.defaultPositive
    @Published var negativeBehaviors: [Behavior] = Behavior.defaultNegative

    init() {
        if USE_MOCK_DATA {
            classSummaries = MockDataService.shared.pointsSummaries
            recentPoints = MockDataService.shared.pointsHistory
        }
    }

    // MARK: - Listen to Class Data

    func listenToClass(classId: String) {
        if USE_MOCK_DATA {
            classSummaries = MockDataService.shared.pointsSummaries
            recentPoints = MockDataService.shared.pointsHistory
        } else {
            PointsService.shared.listenToClassSummaries(classId: classId) { [weak self] summaries in
                self?.classSummaries = summaries
            }
            PointsService.shared.listenToRecentPoints(classId: classId) { [weak self] records in
                self?.recentPoints = records
            }
        }
    }

    // MARK: - Award Points

    func awardPoints(
        to student: Student,
        behavior: Behavior,
        note: String? = nil,
        awardedBy: String,
        awardedByName: String
    ) async {
        guard let studentId = student.id else { return }

        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 200_000_000)

            // Create point record
            let record = PointRecord(
                id: UUID().uuidString,
                studentId: studentId,
                classId: student.classId,
                behaviorId: behavior.id,
                behaviorName: behavior.name,
                points: behavior.points,
                note: note,
                awardedBy: awardedBy,
                awardedByName: awardedByName,
                createdAt: Date()
            )
            recentPoints.insert(record, at: 0)

            // Update summary
            if let index = classSummaries.firstIndex(where: { $0.studentId == studentId }) {
                classSummaries[index].totalPoints += behavior.points
                if behavior.isPositive {
                    classSummaries[index].positiveCount += 1
                } else {
                    classSummaries[index].negativeCount += 1
                }
            } else {
                let summary = StudentPointsSummary(
                    studentId: studentId,
                    classId: student.classId,
                    totalPoints: behavior.points,
                    positiveCount: behavior.isPositive ? 1 : 0,
                    negativeCount: behavior.isPositive ? 0 : 1
                )
                classSummaries.append(summary)
            }

            // Sort by points
            classSummaries.sort { $0.totalPoints > $1.totalPoints }
        } else {
            do {
                let record = try await PointsService.shared.awardPoints(
                    studentId: studentId,
                    classId: student.classId,
                    behavior: behavior,
                    note: note,
                    awardedBy: awardedBy,
                    awardedByName: awardedByName
                )
                recentPoints.insert(record, at: 0)

                // Update local summary
                if let index = classSummaries.firstIndex(where: { $0.studentId == studentId }) {
                    classSummaries[index].totalPoints += behavior.points
                    if behavior.isPositive {
                        classSummaries[index].positiveCount += 1
                    } else {
                        classSummaries[index].negativeCount += 1
                    }
                } else {
                    let summary = StudentPointsSummary(
                        studentId: studentId,
                        classId: student.classId,
                        totalPoints: behavior.points,
                        positiveCount: behavior.isPositive ? 1 : 0,
                        negativeCount: behavior.isPositive ? 0 : 1
                    )
                    classSummaries.append(summary)
                }

                classSummaries.sort { $0.totalPoints > $1.totalPoints }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func awardPointsToMultiple(
        students: [Student],
        behavior: Behavior,
        awardedBy: String,
        awardedByName: String
    ) async {
        isLoading = true
        errorMessage = nil

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            for student in students {
                guard let studentId = student.id else { continue }

                let record = PointRecord(
                    id: UUID().uuidString,
                    studentId: studentId,
                    classId: student.classId,
                    behaviorId: behavior.id,
                    behaviorName: behavior.name,
                    points: behavior.points,
                    awardedBy: awardedBy,
                    awardedByName: awardedByName,
                    createdAt: Date()
                )
                recentPoints.insert(record, at: 0)

                if let index = classSummaries.firstIndex(where: { $0.studentId == studentId }) {
                    classSummaries[index].totalPoints += behavior.points
                    if behavior.isPositive {
                        classSummaries[index].positiveCount += 1
                    } else {
                        classSummaries[index].negativeCount += 1
                    }
                }
            }

            classSummaries.sort { $0.totalPoints > $1.totalPoints }
        } else {
            do {
                let studentIds = students.compactMap { $0.id }
                guard let classId = students.first?.classId else { return }

                try await PointsService.shared.awardPointsToMultipleStudents(
                    studentIds: studentIds,
                    classId: classId,
                    behavior: behavior,
                    awardedBy: awardedBy,
                    awardedByName: awardedByName
                )

                // Update local state
                for student in students {
                    guard let studentId = student.id else { continue }

                    let record = PointRecord(
                        id: UUID().uuidString,
                        studentId: studentId,
                        classId: student.classId,
                        behaviorId: behavior.id,
                        behaviorName: behavior.name,
                        points: behavior.points,
                        awardedBy: awardedBy,
                        awardedByName: awardedByName,
                        createdAt: Date()
                    )
                    recentPoints.insert(record, at: 0)

                    if let index = classSummaries.firstIndex(where: { $0.studentId == studentId }) {
                        classSummaries[index].totalPoints += behavior.points
                        if behavior.isPositive {
                            classSummaries[index].positiveCount += 1
                        } else {
                            classSummaries[index].negativeCount += 1
                        }
                    }
                }

                classSummaries.sort { $0.totalPoints > $1.totalPoints }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Load Student History

    func loadStudentHistory(studentId: String, classId: String) async {
        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 200_000_000)
            studentHistory = MockDataService.shared.pointsHistory.filter { $0.studentId == studentId }
            selectedStudentSummary = classSummaries.first { $0.studentId == studentId }
                ?? StudentPointsSummary(studentId: studentId, classId: classId)
        } else {
            do {
                studentHistory = try await PointsService.shared.getPointsHistory(studentId: studentId)
                selectedStudentSummary = try await PointsService.shared.getStudentSummary(studentId: studentId, classId: classId)
            } catch {
                errorMessage = error.localizedDescription
                selectedStudentSummary = StudentPointsSummary(studentId: studentId, classId: classId)
            }
        }

        isLoading = false
    }

    func listenToStudent(studentId: String, classId: String) {
        if USE_MOCK_DATA {
            selectedStudentSummary = classSummaries.first { $0.studentId == studentId }
                ?? StudentPointsSummary(studentId: studentId, classId: classId)
        } else {
            PointsService.shared.listenToStudentPoints(studentId: studentId, classId: classId) { [weak self] summary in
                self?.selectedStudentSummary = summary
            }
        }
    }

    // MARK: - Reset Points

    func resetStudentPoints(studentId: String, classId: String) async {
        isLoading = true

        if USE_MOCK_DATA {
            try? await Task.sleep(nanoseconds: 300_000_000)

            recentPoints.removeAll { $0.studentId == studentId }
            studentHistory = []

            if let index = classSummaries.firstIndex(where: { $0.studentId == studentId }) {
                classSummaries[index] = StudentPointsSummary(studentId: studentId, classId: classId)
            }
            selectedStudentSummary = StudentPointsSummary(studentId: studentId, classId: classId)
        } else {
            do {
                try await PointsService.shared.resetStudentPoints(studentId: studentId, classId: classId)

                recentPoints.removeAll { $0.studentId == studentId }
                studentHistory = []

                if let index = classSummaries.firstIndex(where: { $0.studentId == studentId }) {
                    classSummaries[index] = StudentPointsSummary(studentId: studentId, classId: classId)
                }
                selectedStudentSummary = StudentPointsSummary(studentId: studentId, classId: classId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Get Summary for Student

    func getSummary(for studentId: String) -> StudentPointsSummary? {
        classSummaries.first { $0.studentId == studentId }
    }

    func getPoints(for studentId: String) -> Int {
        getSummary(for: studentId)?.totalPoints ?? 0
    }
}
