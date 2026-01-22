//
//  TeacherHomeView.swift
//  TeacherLink
//
//  Dashboard home view for teachers with quick access to all features
//

import SwiftUI

// MARK: - Feature Definition
struct QuickFeature: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let badge: Int?

    init(id: String, title: String, icon: String, color: Color, badge: Int? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
        self.badge = badge
    }

    static let allFeatures: [QuickFeature] = [
        QuickFeature(id: "picker", title: "Random Picker", icon: "dice.fill", color: .purple),
        QuickFeature(id: "calendar", title: "Calendar", icon: "calendar", color: .blue),
        QuickFeature(id: "badges", title: "Badges", icon: "star.circle.fill", color: .orange),
        QuickFeature(id: "events", title: "Event Sign-Ups", icon: "person.3.fill", color: .green),
        QuickFeature(id: "wishlist", title: "Supply Wishlist", icon: "gift.fill", color: .pink),
        QuickFeature(id: "pet", title: "Class Pet", icon: "pawprint.fill", color: .brown)
    ]
}

// MARK: - Teacher Home View
struct TeacherHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var classroomViewModel: ClassroomViewModel
    @EnvironmentObject var storyViewModel: StoryViewModel

    @AppStorage("favoriteFeatures") private var favoriteFeaturesData: Data = Data()
    @State private var favoriteIds: Set<String> = ["picker", "calendar", "badges", "events"]
    @State private var showAllFeatures = false
    @State private var selectedFeature: QuickFeature?
    @State private var showCreateStory = false
    @State private var isEditingFavorites = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting Header
                    greetingHeader

                    // Quick Actions Grid (Favorites)
                    quickActionsSection

                    // Pending Items
                    pendingItemsSection

                    // Today's Schedule
                    todaySection

                    // Recent Stories
                    recentStoriesSection
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateStory = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAllFeatures) {
                AllFeaturesSheet(
                    favoriteIds: $favoriteIds,
                    selectedFeature: $selectedFeature
                )
            }
            .sheet(isPresented: $showCreateStory) {
                CreateStoryView()
                    .environmentObject(classroomViewModel)
                    .environmentObject(storyViewModel)
            }
            .fullScreenCover(item: $selectedFeature) { feature in
                featureView(for: feature)
            }
            .onAppear {
                loadFavorites()
            }
            .onChange(of: favoriteIds) { _, _ in
                saveFavorites()
            }
        }
    }

    // MARK: - Greeting Header
    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text(authViewModel.currentUser?.displayName ?? "Teacher")
                    .font(.title.bold())
            }

            Spacer()

            // Class selector
            if let classroom = classroomViewModel.selectedClassroom {
                Menu {
                    ForEach(classroomViewModel.classrooms) { c in
                        Button {
                            classroomViewModel.selectClassroom(c)
                        } label: {
                            HStack {
                                Text(c.name)
                                if c.id == classroom.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppTheme.gradient)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(classroom.name.prefix(1))
                                    .font(.headline)
                                    .foregroundColor(.white)
                            )

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning,"
        } else if hour < 17 {
            return "Good afternoon,"
        } else {
            return "Good evening,"
        }
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)

                Spacer()

                Button {
                    showAllFeatures = true
                } label: {
                    HStack(spacing: 4) {
                        Text(isEditingFavorites ? "Done" : "Edit")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }

            // 2x4 Grid of favorite features
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(favoriteFeatures) { feature in
                    QuickActionCard(feature: feature) {
                        selectedFeature = feature
                    }
                }

                // Add more button if less than 8 favorites
                if favoriteFeatures.count < 8 {
                    AddFeatureCard {
                        showAllFeatures = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var favoriteFeatures: [QuickFeature] {
        QuickFeature.allFeatures.filter { favoriteIds.contains($0.id) }
    }

    // MARK: - Pending Items Section
    private var pendingItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Needs Attention")
                .font(.headline)

            VStack(spacing: 8) {
                PendingItemRow(
                    icon: "person.3.fill",
                    iconColor: .green,
                    title: "3 volunteer spots open",
                    subtitle: "Field Trip - Sign up by Friday"
                ) {
                    selectedFeature = QuickFeature.allFeatures.first { $0.id == "events" }
                }

                PendingItemRow(
                    icon: "gift.fill",
                    iconColor: .pink,
                    title: "Supply wishlist updated",
                    subtitle: "5 items needed for art project"
                ) {
                    selectedFeature = QuickFeature.allFeatures.first { $0.id == "wishlist" }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Today Section
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today")
                    .font(.headline)

                Spacer()

                Button {
                    selectedFeature = QuickFeature.allFeatures.first { $0.id == "calendar" }
                } label: {
                    Text("View Calendar")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primary)
                }
            }

            VStack(spacing: 8) {
                TodayEventRow(time: "9:00 AM", title: "Math Quiz", icon: "pencil.and.list.clipboard")
                TodayEventRow(time: "11:30 AM", title: "Library Time", icon: "books.vertical")
                TodayEventRow(time: "2:00 PM", title: "Parent Volunteer: Sarah Wilson", icon: "person.badge.clock")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Recent Stories Section
    private var recentStoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Posts")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    StoriesView()
                        .environmentObject(authViewModel)
                        .environmentObject(classroomViewModel)
                        .environmentObject(storyViewModel)
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primary)
                }
            }

            if storyViewModel.stories.isEmpty {
                Text("No stories yet. Tap + to create your first post!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(storyViewModel.stories.prefix(2)) { story in
                    MiniStoryCard(story: story)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Feature View Router
    @ViewBuilder
    private func featureView(for feature: QuickFeature) -> some View {
        NavigationStack {
            Group {
                switch feature.id {
                case "picker":
                    RandomPickerView()
                case "calendar":
                    WeeklyCalendarView()
                case "badges":
                    AchievementBadgesView()
                case "events":
                    EventSignUpView()
                case "wishlist":
                    SupplyWishlistView()
                case "pet":
                    ClassPetView()
                default:
                    Text("Feature not found")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        selectedFeature = nil
                    }
                }
            }
        }
    }

    // MARK: - Persistence
    private func loadFavorites() {
        if let decoded = try? JSONDecoder().decode(Set<String>.self, from: favoriteFeaturesData) {
            favoriteIds = decoded
        }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteIds) {
            favoriteFeaturesData = encoded
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let feature: QuickFeature
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(feature.color)
                        .cornerRadius(12)

                    if let badge = feature.badge, badge > 0 {
                        Text("\(badge)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }

                Text(feature.title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Feature Card
struct AddFeatureCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)

                Text("Add More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pending Item Row
struct PendingItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(iconColor)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Today Event Row
struct TodayEventRow: View {
    let time: String
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.primary)

            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Mini Story Card
struct MiniStoryCard: View {
    let story: Story

    var body: some View {
        HStack(spacing: 12) {
            if let imageURL = story.mediaUrls.first {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(story.content ?? "")
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                HStack {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                    Text("\(story.likeCount)")
                        .font(.caption2)

                    Image(systemName: "bubble.right.fill")
                        .font(.caption2)
                    Text("\(story.commentCount)")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - All Features Sheet
struct AllFeaturesSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var favoriteIds: Set<String>
    @Binding var selectedFeature: QuickFeature?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Tap to open a feature. Use the star to add/remove from your home screen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Class Tools") {
                    FeatureListRow(feature: QuickFeature.allFeatures[0], favoriteIds: $favoriteIds) {
                        selectedFeature = QuickFeature.allFeatures[0]
                        dismiss()
                    }
                    FeatureListRow(feature: QuickFeature.allFeatures[1], favoriteIds: $favoriteIds) {
                        selectedFeature = QuickFeature.allFeatures[1]
                        dismiss()
                    }
                }

                Section("Recognition") {
                    FeatureListRow(feature: QuickFeature.allFeatures[2], favoriteIds: $favoriteIds) {
                        selectedFeature = QuickFeature.allFeatures[2]
                        dismiss()
                    }
                    FeatureListRow(feature: QuickFeature.allFeatures[5], favoriteIds: $favoriteIds) {
                        selectedFeature = QuickFeature.allFeatures[5]
                        dismiss()
                    }
                }

                Section("Parent Engagement") {
                    FeatureListRow(feature: QuickFeature.allFeatures[3], favoriteIds: $favoriteIds) {
                        selectedFeature = QuickFeature.allFeatures[3]
                        dismiss()
                    }
                    FeatureListRow(feature: QuickFeature.allFeatures[4], favoriteIds: $favoriteIds) {
                        selectedFeature = QuickFeature.allFeatures[4]
                        dismiss()
                    }
                }
            }
            .navigationTitle("All Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Feature List Row
struct FeatureListRow: View {
    let feature: QuickFeature
    @Binding var favoriteIds: Set<String>
    let action: () -> Void

    var isFavorite: Bool {
        favoriteIds.contains(feature.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(feature.color)
                        .cornerRadius(10)

                    Text(feature.title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.spring(response: 0.3)) {
                    if isFavorite {
                        favoriteIds.remove(feature.id)
                    } else {
                        favoriteIds.insert(feature.id)
                    }
                }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(isFavorite ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TeacherHomeView()
        .environmentObject(AuthViewModel())
        .environmentObject(ClassroomViewModel())
        .environmentObject(StoryViewModel())
}
