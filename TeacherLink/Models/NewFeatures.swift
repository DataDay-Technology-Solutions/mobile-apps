//
//  NewFeatures.swift
//  TeacherLink
//
//  Models for Event Sign-Ups, Calendar, Supply Wishlist, Mood Check-In,
//  Achievement Badges, Class Pet, Random Picker, Permission Slips
//

import Foundation
import SwiftUI

// MARK: - Event Sign-Up System

struct ClassEvent: Identifiable, Codable {
    var id: String
    var classId: String
    var title: String
    var description: String
    var eventDate: Date
    var location: String
    var createdBy: String
    var createdAt: Date
    var slots: [EventSlot]
    var eventType: EventType

    enum EventType: String, Codable, CaseIterable {
        case fieldTrip = "Field Trip"
        case classParty = "Class Party"
        case volunteer = "Volunteer Opportunity"
        case conference = "Parent Conference"
        case special = "Special Event"

        var icon: String {
            switch self {
            case .fieldTrip: return "bus.fill"
            case .classParty: return "party.popper.fill"
            case .volunteer: return "hands.sparkles.fill"
            case .conference: return "person.2.fill"
            case .special: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .fieldTrip: return .blue
            case .classParty: return .purple
            case .volunteer: return .green
            case .conference: return .orange
            case .special: return .pink
            }
        }
    }
}

struct EventSlot: Identifiable, Codable {
    var id: String
    var title: String
    var maxSignups: Int
    var signedUpParents: [ParentSignup]

    var availableSpots: Int {
        maxSignups - signedUpParents.count
    }

    var isFull: Bool {
        availableSpots <= 0
    }
}

struct ParentSignup: Identifiable, Codable {
    var id: String
    var parentId: String
    var parentName: String
    var signedUpAt: Date
}

// MARK: - Weekly Calendar

struct CalendarItem: Identifiable, Codable {
    var id: String
    var classId: String
    var title: String
    var description: String?
    var date: Date
    var itemType: CalendarItemType
    var isAllDay: Bool
    var createdBy: String
    var createdAt: Date

    enum CalendarItemType: String, Codable, CaseIterable {
        case homework = "Homework"
        case test = "Test"
        case project = "Project"
        case event = "Event"
        case reminder = "Reminder"
        case noSchool = "No School"

        var icon: String {
            switch self {
            case .homework: return "book.fill"
            case .test: return "pencil.and.list.clipboard"
            case .project: return "paintbrush.fill"
            case .event: return "calendar.badge.clock"
            case .reminder: return "bell.fill"
            case .noSchool: return "house.fill"
            }
        }

        var color: Color {
            switch self {
            case .homework: return .blue
            case .test: return .red
            case .project: return .purple
            case .event: return .green
            case .reminder: return .orange
            case .noSchool: return .gray
            }
        }
    }
}

// MARK: - Supply Wishlist

struct SupplyItem: Identifiable, Codable {
    var id: String
    var classId: String
    var itemName: String
    var quantity: Int
    var description: String?
    var urgency: Urgency
    var claimedBy: String?
    var claimedByName: String?
    var claimedAt: Date?
    var fulfilled: Bool
    var createdBy: String
    var createdAt: Date

    enum Urgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }

    var isClaimed: Bool {
        claimedBy != nil
    }
}

// MARK: - Mood Check-In

struct MoodCheckIn: Identifiable, Codable {
    var id: String
    var studentId: String
    var studentName: String
    var mood: Mood
    var note: String?
    var checkedInAt: Date
    var classId: String

    enum Mood: String, Codable, CaseIterable {
        case happy = "Happy"
        case excited = "Excited"
        case okay = "Okay"
        case sad = "Sad"
        case anxious = "Anxious"

        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .excited: return "🤩"
            case .okay: return "😐"
            case .sad: return "😢"
            case .anxious: return "😰"
            }
        }

        var color: Color {
            switch self {
            case .happy: return .green
            case .excited: return .yellow
            case .okay: return .gray
            case .sad: return .blue
            case .anxious: return .purple
            }
        }
    }
}

// MARK: - Achievement Badges

struct Badge: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var description: String
    var iconName: String
    var color: String
    var classId: String
    var createdBy: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Badge, rhs: Badge) -> Bool {
        lhs.id == rhs.id
    }
}

struct StudentBadge: Identifiable, Codable {
    var id: String
    var studentId: String
    var studentName: String
    var badgeId: String
    var awardedBy: String
    var awardedAt: Date
    var note: String?
}

// MARK: - Class Pet

struct ClassPet: Identifiable, Codable {
    var id: String
    var classId: String
    var name: String
    var type: PetType
    var level: Int
    var experience: Int
    var happiness: Int // 0-100
    var lastFedAt: Date
    var lastPlayedAt: Date
    var createdAt: Date

    enum PetType: String, Codable, CaseIterable {
        case dog = "Dog"
        case cat = "Cat"
        case rabbit = "Rabbit"
        case hamster = "Hamster"
        case bird = "Bird"
        case fish = "Fish"

        var icon: String {
            switch self {
            case .dog: return "dog.fill"
            case .cat: return "cat.fill"
            case .rabbit: return "hare.fill"
            case .hamster: return "pawprint.fill"
            case .bird: return "bird.fill"
            case .fish: return "fish.fill"
            }
        }

        var color: Color {
            switch self {
            case .dog: return .brown
            case .cat: return .orange
            case .rabbit: return .gray
            case .hamster: return .yellow
            case .bird: return .blue
            case .fish: return .cyan
            }
        }
    }

    var experienceToNextLevel: Int {
        return level * 100
    }

    var experienceProgress: Double {
        return Double(experience % 100) / 100.0
    }
}

// MARK: - Random Student Picker

struct PickerHistory: Identifiable, Codable {
    var id: String
    var classId: String
    var studentId: String
    var studentName: String
    var pickedAt: Date
    var reason: String?
}

// MARK: - Permission Slips

struct PermissionSlip: Identifiable, Codable, Hashable {
    var id: String
    var classId: String
    var title: String
    var description: String
    var eventDate: Date
    var createdBy: String
    var createdAt: Date
    var dueDate: Date?
    var signatures: [Signature]

    var allSigned: Bool {
        signatures.allSatisfy { $0.status == .signed }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PermissionSlip, rhs: PermissionSlip) -> Bool {
        lhs.id == rhs.id
    }

    struct Signature: Identifiable, Codable {
        var id: String
        var parentId: String
        var parentName: String
        var studentName: String
        var signedAt: Date?
        var status: SignatureStatus
    }

    enum SignatureStatus: String, Codable {
        case pending
        case signed
        case declined
    }
}

// MARK: - Weekly Summary (for email)

struct WeeklySummary: Codable {
    var studentId: String
    var studentName: String
    var weekStartDate: Date
    var weekEndDate: Date
    var badgesEarned: [String]
    var moodSummary: String
    var upcomingEvents: [String]
    var teacherNote: String?
}
