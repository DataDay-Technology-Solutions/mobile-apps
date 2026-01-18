//
//  ParentProfile.swift
//  TeacherLink
//
//  Extended parent profile with sentiment tracking and hostility scoring
//

import Foundation

struct ParentProfile: Identifiable, Codable {
    var id: String?
    var userId: String
    var classId: String
    var studentIds: [String]

    // Hostility tracking
    var hostilityScore: Double // 0-100, lower = more hostile
    var totalMessages: Int
    var positiveMessages: Int
    var negativeMessages: Int
    var neutralMessages: Int

    // Flag status
    var isFlaggedHostile: Bool
    var flaggedByTeacherId: String?
    var flaggedAt: Date?
    var flagReason: String?

    // Admin CC status
    var adminCCEnabled: Bool // Auto-enabled when hostilityScore < 50
    var adminCCEnabledAt: Date?

    var createdAt: Date
    var updatedAt: Date?

    // Computed properties
    var hostilityLevel: HostilityLevel {
        if hostilityScore >= 80 {
            return .friendly
        } else if hostilityScore >= 60 {
            return .neutral
        } else if hostilityScore >= 40 {
            return .concerning
        } else {
            return .hostile
        }
    }

    var shouldCCAdmin: Bool {
        hostilityScore < 50 || isFlaggedHostile
    }

    var formattedScore: String {
        String(format: "%.0f%%", hostilityScore)
    }

    init(
        id: String? = nil,
        userId: String,
        classId: String,
        studentIds: [String] = [],
        hostilityScore: Double = 100.0,
        totalMessages: Int = 0,
        positiveMessages: Int = 0,
        negativeMessages: Int = 0,
        neutralMessages: Int = 0,
        isFlaggedHostile: Bool = false,
        flaggedByTeacherId: String? = nil,
        flaggedAt: Date? = nil,
        flagReason: String? = nil,
        adminCCEnabled: Bool = false,
        adminCCEnabledAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.classId = classId
        self.studentIds = studentIds
        self.hostilityScore = hostilityScore
        self.totalMessages = totalMessages
        self.positiveMessages = positiveMessages
        self.negativeMessages = negativeMessages
        self.neutralMessages = neutralMessages
        self.isFlaggedHostile = isFlaggedHostile
        self.flaggedByTeacherId = flaggedByTeacherId
        self.flaggedAt = flaggedAt
        self.flagReason = flagReason
        self.adminCCEnabled = adminCCEnabled
        self.adminCCEnabledAt = adminCCEnabledAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Recalculate hostility score based on message counts
    mutating func recalculateScore() {
        guard totalMessages > 0 else {
            hostilityScore = 100.0
            return
        }

        // Score formula: positive messages boost score, negative messages lower it
        // Base score is 50, then adjusted by message ratios
        let positiveRatio = Double(positiveMessages) / Double(totalMessages)
        let negativeRatio = Double(negativeMessages) / Double(totalMessages)

        // Score ranges from 0-100
        // More positive = higher score (friendlier)
        // More negative = lower score (more hostile)
        hostilityScore = 50.0 + (positiveRatio * 50.0) - (negativeRatio * 50.0)
        hostilityScore = max(0, min(100, hostilityScore))

        // Auto-enable admin CC if score drops below 50
        if hostilityScore < 50 && !adminCCEnabled {
            adminCCEnabled = true
            adminCCEnabledAt = Date()
        }

        updatedAt = Date()
    }

    // Add a message and update sentiment tracking
    mutating func addMessage(sentiment: MessageSentiment) {
        totalMessages += 1

        switch sentiment {
        case .positive:
            positiveMessages += 1
        case .negative:
            negativeMessages += 1
        case .neutral:
            neutralMessages += 1
        }

        recalculateScore()
    }
}

enum HostilityLevel: String, Codable {
    case friendly = "Friendly"
    case neutral = "Neutral"
    case concerning = "Concerning"
    case hostile = "Hostile"

    var color: String {
        switch self {
        case .friendly: return "green"
        case .neutral: return "blue"
        case .concerning: return "orange"
        case .hostile: return "red"
        }
    }

    var icon: String {
        switch self {
        case .friendly: return "face.smiling"
        case .neutral: return "face.dashed"
        case .concerning: return "exclamationmark.triangle"
        case .hostile: return "exclamationmark.shield"
        }
    }
}

enum MessageSentiment: String, Codable {
    case positive
    case negative
    case neutral

    // Simple keyword-based sentiment detection
    // In production, this would use ML/NLP
    static func analyze(text: String) -> MessageSentiment {
        let lowercased = text.lowercased()

        // Negative/hostile keywords
        let negativeKeywords = [
            "angry", "upset", "frustrated", "disappointed", "unacceptable",
            "terrible", "awful", "horrible", "ridiculous", "incompetent",
            "demand", "immediately", "lawsuit", "lawyer", "complaint",
            "furious", "outraged", "disgusted", "appalled", "livid",
            "pathetic", "shameful", "disgrace", "worst", "hate",
            "stupid", "idiot", "useless", "waste", "fail",
            "never", "always wrong", "your fault", "blame",
            "unbelievable", "absurd", "insane", "crazy"
        ]

        // Positive/friendly keywords
        let positiveKeywords = [
            "thank", "thanks", "appreciate", "grateful", "wonderful",
            "great", "excellent", "amazing", "fantastic", "love",
            "happy", "pleased", "delighted", "excited", "proud",
            "helpful", "kind", "caring", "supportive", "awesome",
            "best", "perfect", "beautiful", "lovely", "blessed",
            "impressed", "thrilled", "enjoy", "fun", "glad"
        ]

        var negativeCount = 0
        var positiveCount = 0

        for keyword in negativeKeywords {
            if lowercased.contains(keyword) {
                negativeCount += 1
            }
        }

        for keyword in positiveKeywords {
            if lowercased.contains(keyword) {
                positiveCount += 1
            }
        }

        // Check for aggressive punctuation
        if lowercased.contains("!!!") || lowercased.contains("???") {
            negativeCount += 1
        }

        // Check for ALL CAPS words (indicates shouting)
        let words = text.split(separator: " ")
        let capsWords = words.filter { word in
            word.count > 2 && word == word.uppercased() && word.rangeOfCharacter(from: .letters) != nil
        }
        if capsWords.count >= 2 {
            negativeCount += 2
        }

        if negativeCount > positiveCount && negativeCount >= 1 {
            return .negative
        } else if positiveCount > negativeCount && positiveCount >= 1 {
            return .positive
        }

        return .neutral
    }
}

// User credentials for mock authentication
struct MockUserCredentials {
    let email: String
    let password: String
    let userId: String
    let role: UserRole
}
