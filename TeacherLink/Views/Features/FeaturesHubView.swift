//
//  FeaturesHubView.swift
//  TeacherLink
//
//  Hub for accessing all class features
//

import SwiftUI

struct FeaturesHubView: View {
    var body: some View {
        NavigationStack {
            List {
                // Class Tools Section
                Section("Class Tools") {
                    NavigationLink {
                        RandomPickerView()
                    } label: {
                        FeatureRow(
                            icon: "dice.fill",
                            title: "Random Picker",
                            description: "Pick students fairly",
                            color: .purple
                        )
                    }

                    NavigationLink {
                        WeeklyCalendarView()
                    } label: {
                        FeatureRow(
                            icon: "calendar",
                            title: "Calendar",
                            description: "Homework, tests & events",
                            color: .blue
                        )
                    }
                }

                // Recognition Section
                Section("Recognition") {
                    NavigationLink {
                        AchievementBadgesView()
                    } label: {
                        FeatureRow(
                            icon: "star.circle.fill",
                            title: "Badges",
                            description: "Award achievements",
                            color: .orange
                        )
                    }

                    NavigationLink {
                        ClassPetView()
                    } label: {
                        FeatureRow(
                            icon: "pawprint.fill",
                            title: "Class Pet",
                            description: "Virtual pet for the class",
                            color: .brown
                        )
                    }
                }

                // Parent Engagement Section
                Section("Parent Engagement") {
                    NavigationLink {
                        EventSignUpView()
                    } label: {
                        FeatureRow(
                            icon: "person.3.fill",
                            title: "Event Sign-Ups",
                            description: "Volunteer opportunities",
                            color: .green
                        )
                    }

                    NavigationLink {
                        SupplyWishlistView()
                    } label: {
                        FeatureRow(
                            icon: "gift.fill",
                            title: "Supply Wishlist",
                            description: "Request class supplies",
                            color: .pink
                        )
                    }
                }
            }
            .navigationTitle("Features")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FeaturesHubView()
}
