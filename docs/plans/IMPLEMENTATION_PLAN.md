## Overview

This plan outlines the implementation of features for Tiny Tastes Tracker organized into three categories:

### **User-Requested Features** (Priority: HIGH)
1. **Account Creation with iCloudKit** - User account system using only iCloud, no backend
2. **Pediatrician Summary** (Completed) - AI-generated health summaries for doctor visits
3. **Food Explorer Unchecking** (Completed) - Ability to unmark foods as tried
4. **Messy Face Photo Gallery** - Central photo gallery linked to food items
5. **Push Notifications for Next Feed** - Customizable feed reminders with lead time
6. **High-Risk Allergen Monitoring** - 2-hour check-in notifications after allergen exposure
7. **Complete Image Generation** - Finalize Imagen 4 integration and caching
8. **Extend Images to Toddler Mode** (Completed) - Full image support across toddler features
9. **Translations/Localization** - Multi-language support with priority on Spanish/French
10. **CloudKit Integration** - Complete iCloud sync with crash prevention
11. **Daycare Report Ingestion** - Import daily reports (PDF/Image) to auto-log events

### **Open Issues from ASSESSMENT.md** (Priority: MEDIUM-HIGH)
11. **Complete Accessibility** - Finish VoiceOver labels, Dynamic Type testing, color contrast fixes
12. **Analytics & Crash Reporting** - Firebase/TelemetryDeck integration for production monitoring

### **App Store Preparation** (Priority: CRITICAL for Launch)
13. **Legal & Privacy** - Host privacy policy, create Terms of Service
14. **App Store Assets** - Screenshots, app preview video, descriptions, keywords
15. **Technical Setup** - TestFlight, App Store Connect, build submission
16. **Pre-Submission Testing** - Multi-device testing, performance audit, accessibility verification

---

## User Review Required

> [!IMPORTANT]
> **CloudKit Configuration Dependencies**
> - Requires Apple Developer account access to configure CloudKit container
> - May require App Store Connect setup for production CloudKit
> - Testing will initially use development CloudKit environment

> [!WARNING]
> **Breaking Changes**
> - Localization will require extracting all hardcoded strings, which may temporarily break builds
> - CloudKit schema changes may require data migration for existing users
> - Notification permissions will trigger iOS system prompts on first launch

> [!CAUTION]
> **Third-Party Service Costs**
> - Google Imagen 4 API has usage costs - recommend setting monthly budget alerts
> - CloudKit has storage/bandwidth limits - monitor quota usage

---

## Proposed Changes

### Component 0A: Account Creation with iCloudKit

#### [NEW] [UserAccount.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Models/UserAccount.swift)

**Purpose:** User account model synced exclusively via CloudKit

**Data Model:**
```swift
@Model
class UserAccount {
    @Attribute(.unique) var id: UUID
    var iCloudUserID: String // CKRecord.ID from CloudKit
    var createdAt: Date
    var lastSyncedAt: Date?
    var preferences: UserPreferences
    
    // Relationships
    var childProfiles: [ChildProfile]
    
    init(iCloudUserID: String) {
        self.id = UUID()
        self.iCloudUserID = iCloudUserID
        self.createdAt = Date()
        self.preferences = UserPreferences()
        self.childProfiles = []
    }
}

struct UserPreferences: Codable {
    var language: String = "en"
    var useMetricUnits: Bool = true
    var notificationsEnabled: Bool = false
    var theme: String = "auto"
}
```

---

#### [NEW] [AccountManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/AccountManager.swift)

**Purpose:** Manage user account lifecycle and iCloud integration

**Key Features:**
```swift
@MainActor
class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published var currentAccount: UserAccount?
    @Published var iCloudStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSignedIn: Bool = false
    
    private let container = CKContainer.default()
    
    // Check iCloud availability
    func checkiCloudStatus() async throws -> CKAccountStatus {
        let status = try await container.accountStatus()
        await MainActor.run {
            self.iCloudStatus = status
            self.isSignedIn = (status == .available)
        }
        return status
    }
    
    // Create or fetch user account
    func setupAccount() async throws -> UserAccount {
        // Get iCloud user ID
        let userRecordID = try await container.userRecordID()
        let iCloudUserID = userRecordID.recordName
        
        // Check if account exists locally
        if let existingAccount = try await fetchLocalAccount(iCloudUserID: iCloudUserID) {
            currentAccount = existingAccount
            return existingAccount
        }
        
        // Create new account
        let newAccount = UserAccount(iCloudUserID: iCloudUserID)
        try await saveAccount(newAccount)
        currentAccount = newAccount
        return newAccount
    }
    
    // Sync account across devices
    func syncAccount() async throws {
        guard let account = currentAccount else { return }
        try await CloudKitSyncManager.shared.syncUserAccount(account)
    }
}
```

---

#### [NEW] [AccountCreationView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Onboarding/AccountCreationView.swift)

**Purpose:** Welcome screen with iCloud account setup

**UI Flow:**
1. Welcome message explaining iCloud-only approach
2. Check iCloud status
3. If signed in: Create account automatically
4. If not signed in: Show instructions to sign in to iCloud
5. Privacy explanation (data stays in user's iCloud)
6. Continue to child profile setup

**Key UI Elements:**
- iCloud status indicator
- "Get Started" button
- "Why iCloud?" explanation
- Offline mode notice
- Privacy badge

---

#### [MODIFY] [OnboardingCoordinator.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Onboarding/OnboardingCoordinator.swift)

**Changes:**
- Add account creation as first step (before child setup)
- Handle iCloud sign-in failures gracefully
- Allow offline account creation with sync when online
- Store account reference for child profile linking

---

### Component 0B: Pediatrician Summary Feature

#### [NEW] [PediatricianSummary.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Models/PediatricianSummary.swift)

**Purpose:** Data model for health visit summaries

**Data Model:**
```swift
@Model
class PediatricianSummary {
    @Attribute(.unique) var id: UUID
    var childID: UUID
    var startDate: Date
    var endDate: Date
    var generatedAt: Date
    
    // Aggregated Metrics
    var sleepMetrics: SleepSummaryMetrics
    var feedingMetrics: FeedingSummaryMetrics
    var explorerMetrics: ExplorerSummaryMetrics?
    var medicationMetrics: MedicationSummaryMetrics?
    var diaperMetrics: DiaperSummaryMetrics
    var growthMetrics: GrowthSummaryMetrics
    
    // AI-Generated Content
    var aiSummary: String
    var highlights: [String]
    var concerns: [String]
    
    // Parent Notes
    var parentNotes: String?
    
    // Export
    var pdfURL: URL?
}

struct SleepSummaryMetrics: Codable {
    var avgNapsPerDay: Double
    var avgNapDuration: TimeInterval
    var avgTotalSleepTime: TimeInterval
    var longestSleepStretch: TimeInterval
    var totalNaps: Int
}

struct FeedingSummaryMetrics: Codable {
    var avgFeedsPerDay: Double
    var avgFeedingInterval: TimeInterval
    var totalFeeds: Int
    var avgBottleVolume: Double?
    var avgNursingDuration: TimeInterval?
}

struct ExplorerSummaryMetrics: Codable {
    var newFoodsTried: Int
    var foodsByColor: [String: Int] // Rainbow tracking
    var allergenReactions: Int
    var allergenExposures: [String]
}

struct MedicationSummaryMetrics: Codable {
    var avgDosesPerDay: Double
    var medications: [String]
    var totalDoses: Int
}

struct DiaperSummaryMetrics: Codable {
    var avgChangesPerDay: Double
    var totalChanges: Int
    var wetDiapers: Int
    var dirtyDiapers: Int
}

struct GrowthSummaryMetrics: Codable {
    var startWeight: Double?
    var endWeight: Double?
    var weightChange: Double?
    var startHeight: Double?
    var endHeight: Double?
    var heightChange: Double?
}
```

---

#### [NEW] [DataAggregationService.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/DataAggregationService.swift)

**Purpose:** Aggregate tracking data for summary generation

**Key Methods:**
```swift
@MainActor
class DataAggregationService {
    static let shared = DataAggregationService()
    
    func generateSummary(
        for childID: UUID,
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) async throws -> PediatricianSummary {
        // Fetch all relevant data
        let sleepLogs = try fetchSleepLogs(childID: childID, from: startDate, to: endDate, context: context)
        let feedLogs = try fetchFeedLogs(childID: childID, from: startDate, to: endDate, context: context)
        let foodLogs = try fetchFoodLogs(childID: childID, from: startDate, to: endDate, context: context)
        let medicationLogs = try fetchMedicationLogs(childID: childID, from: startDate, to: endDate, context: context)
        let diaperLogs = try fetchDiaperLogs(childID: childID, from: startDate, to: endDate, context: context)
        let growthLogs = try fetchGrowthLogs(childID: childID, from: startDate, to: endDate, context: context)
        
        // Calculate metrics
        let sleepMetrics = calculateSleepMetrics(from: sleepLogs, startDate: startDate, endDate: endDate)
        let feedingMetrics = calculateFeedingMetrics(from: feedLogs, startDate: startDate, endDate: endDate)
        let explorerMetrics = calculateExplorerMetrics(from: foodLogs)
        let medicationMetrics = calculateMedicationMetrics(from: medicationLogs, startDate: startDate, endDate: endDate)
        let diaperMetrics = calculateDiaperMetrics(from: diaperLogs, startDate: startDate, endDate: endDate)
        let growthMetrics = calculateGrowthMetrics(from: growthLogs)
        
        // Generate AI summary
        let aiSummary = try await generateAISummary(
            sleepMetrics: sleepMetrics,
            feedingMetrics: feedingMetrics,
            explorerMetrics: explorerMetrics,
            medicationMetrics: medicationMetrics,
            diaperMetrics: diaperMetrics,
            growthMetrics: growthMetrics
        )
        
        // Create summary object
        let summary = PediatricianSummary(
            childID: childID,
            startDate: startDate,
            endDate: endDate,
            sleepMetrics: sleepMetrics,
            feedingMetrics: feedingMetrics,
            explorerMetrics: explorerMetrics,
            medicationMetrics: medicationMetrics,
            diaperMetrics: diaperMetrics,
            growthMetrics: growthMetrics,
            aiSummary: aiSummary.summary,
            highlights: aiSummary.highlights,
            concerns: aiSummary.concerns
        )
        
        return summary
    }
    
    private func generateAISummary(
        sleepMetrics: SleepSummaryMetrics,
        feedingMetrics: FeedingSummaryMetrics,
        explorerMetrics: ExplorerSummaryMetrics?,
        medicationMetrics: MedicationSummaryMetrics?,
        diaperMetrics: DiaperSummaryMetrics,
        growthMetrics: GrowthSummaryMetrics
    ) async throws -> (summary: String, highlights: [String], concerns: [String]) {
        // Use GeminiService to generate pediatric summary
        let prompt = """
        Generate a professional pediatric summary for a healthcare provider based on the following data:
        
        Sleep: \(sleepMetrics.avgNapsPerDay) naps/day, avg duration \(sleepMetrics.avgNapDuration/3600)h
        Feeding: \(feedingMetrics.avgFeedsPerDay) feeds/day
        \(explorerMetrics != nil ? "New foods tried: \(explorerMetrics!.newFoodsTried)" : "")
        \(medicationMetrics != nil ? "Medications: \(medicationMetrics!.medications.joined(separator: ", "))" : "")
        Diapers: \(diaperMetrics.avgChangesPerDay) changes/day
        Growth: Weight change: \(growthMetrics.weightChange ?? 0)kg
        
        Provide:
        1. A concise summary (2-3 paragraphs)
        2. Key highlights (3-5 bullet points)
        3. Any concerns or unusual patterns (if any)
        """
        
        let response = try await GeminiService.shared.generateText(prompt: prompt)
        // Parse response into summary, highlights, concerns
        return parseAIResponse(response)
    }
}
```

---

#### [NEW] [PediatricianSummaryView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Health/PediatricianSummaryView.swift)

**Purpose:** List view of all generated summaries

**UI Components:**
- List of past summaries with date ranges
- "Create New Summary" button
- Date range picker for custom summaries
- Quick actions: View, Export, Share, Delete
- Filter by child (if multiple)

---

#### [NEW] [SummaryDetailView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Health/SummaryDetailView.swift)

**Purpose:** Detailed view of a single summary

**UI Sections:**
1. Header: Date range, child name, generated date
2. AI Summary: Formatted text with highlights
3. Metrics Cards:
   - Sleep metrics with chart
   - Feeding metrics with chart
   - Explorer progress (if applicable)
   - Medication tracking
   - Diaper patterns
   - Growth chart
4. Concerns Section: Highlighted unusual patterns
5. Parent Notes: Editable text area
6. Export Options: PDF, Print, Share

---

### Component 0C: Food Explorer Unchecking

#### [MODIFY] [FoodLog.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Models/FoodLog.swift)

**Changes:**
```swift
@Model
class FoodLog {
    // ... existing properties
    
    // Add new property
    var isMarkedAsTried: Bool = true // Default true for backward compatibility
    var unmarkedAt: Date? // Track when food was unmarked
    
    // Method to unmark food
    func unmarkAsTried() {
        self.isMarkedAsTried = false
        self.unmarkedAt = Date()
    }
    
    // Method to re-mark food
    func markAsTried() {
        self.isMarkedAsTried = true
        self.unmarkedAt = nil
    }
}
```

---

#### [MODIFY] [ToddlerManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Managers/ToddlerManager.swift)

**Add Methods:**
```swift
// Unmark food as tried
func unmarkFoodAsTried(_ foodLog: FoodLog) async throws {
    foodLog.unmarkAsTried()
    try modelContext.save()
    
    // Update progress tracking
    await updateFoodProgress()
    
    // Sync to CloudKit
    try await CloudKitSyncManager.shared.syncFoodLog(foodLog)
}

// Get only foods marked as tried
func getTriedFoods(for childID: UUID) -> [FoodLog] {
    let descriptor = FetchDescriptor<FoodLog>(
        predicate: #Predicate { log in
            log.childID == childID && log.isMarkedAsTried == true
        }
    )
    return (try? modelContext.fetch(descriptor)) ?? []
}
```

---

#### [MODIFY] [FoodDetailView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Toddler/FoodDetailView.swift)

**Add UI:**
```swift
// Add button to unmark food
if foodLog.isMarkedAsTried {
    Button(role: .destructive) {
        showUnmarkConfirmation = true
    } label: {
        Label("Unmark as Tried", systemImage: "xmark.circle")
    }
}

// Confirmation dialog
.confirmationDialog(
    "Unmark this food as tried?",
    isPresented: $showUnmarkConfirmation,
    titleVisibility: .visible
) {
    Button("Unmark", role: .destructive) {
        Task {
            try await toddlerManager.unmarkFoodAsTried(foodLog)
        }
    }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("This will remove it from your tried foods list and update your rainbow progress.")
}
```

---

#### [MODIFY] [FoodExplorerView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Toddler/FoodExplorerView.swift)

**Add Swipe Actions:**
```swift
List {
    ForEach(triedFoods) { foodLog in
        FoodRow(foodLog: foodLog)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    Task {
                        try await toddlerManager.unmarkFoodAsTried(foodLog)
                    }
                } label: {
                    Label("Unmark", systemImage: "xmark")
                }
            }
    }
}
```

---

### Component 0D: Messy Face Photo Gallery

#### [NEW] [MessyFacePhoto.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Models/MessyFacePhoto.swift)

**Purpose:** Photo model linked to food logs

**Data Model:**
```swift
@Model
class MessyFacePhoto {
    @Attribute(.unique) var id: UUID
    var childID: UUID
    var foodLogID: UUID // Link to specific food
    var capturedAt: Date
    var imageData: Data? // Local storage
    var cloudKitAssetID: String? // CloudKit reference
    var caption: String?
    var thumbnailData: Data? // Optimized thumbnail
    
    // Computed properties
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    var thumbnail: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
    
    init(childID: UUID, foodLogID: UUID, image: UIImage, caption: String? = nil) {
        self.id = UUID()
        self.childID = childID
        self.foodLogID = foodLogID
        self.capturedAt = Date()
        self.caption = caption
        
        // Compress and store image
        self.imageData = image.jpegData(compressionQuality: 0.8)
        
        // Generate thumbnail
        self.thumbnailData = image.preparingThumbnail(of: CGSize(width: 200, height: 200))?.jpegData(compressionQuality: 0.7)
    }
}
```

---

#### [NEW] [PhotoStorageManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/PhotoStorageManager.swift)

**Purpose:** Manage photo storage, compression, and CloudKit sync

**Key Features:**
```swift
@MainActor
class PhotoStorageManager: ObservableObject {
    static let shared = PhotoStorageManager()
    
    @Published var uploadProgress: [UUID: Double] = [:]
    
    // Save photo locally and sync to CloudKit
    func savePhoto(
        _ image: UIImage,
        for foodLogID: UUID,
        childID: UUID,
        caption: String? = nil,
        context: ModelContext
    ) async throws -> MessyFacePhoto {
        // Create photo model
        let photo = MessyFacePhoto(
            childID: childID,
            foodLogID: foodLogID,
            image: image,
            caption: caption
        )
        
        // Save to SwiftData
        context.insert(photo)
        try context.save()
        
        // Upload to CloudKit in background
        Task {
            try await uploadToCloudKit(photo)
        }
        
        return photo
    }
    
    // Upload photo to CloudKit
    private func uploadToCloudKit(_ photo: MessyFacePhoto) async throws {
        guard let imageData = photo.imageData else { return }
        
        // Create CKAsset from image data
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(photo.id.uuidString)
            .appendingPathExtension("jpg")
        
        try imageData.write(to: tempURL)
        let asset = CKAsset(fileURL: tempURL)
        
        // Upload to CloudKit
        let record = CKRecord(recordType: "MessyFacePhoto")
        record["childID"] = photo.childID.uuidString
        record["foodLogID"] = photo.foodLogID.uuidString
        record["capturedAt"] = photo.capturedAt
        record["caption"] = photo.caption
        record["image"] = asset
        
        let container = CKContainer.default()
        let database = container.privateCloudDatabase
        
        try await database.save(record)
        
        // Update photo with CloudKit ID
        photo.cloudKitAssetID = record.recordID.recordName
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // Fetch photos for a food log
    func getPhotos(for foodLogID: UUID, context: ModelContext) -> [MessyFacePhoto] {
        let descriptor = FetchDescriptor<MessyFacePhoto>(
            predicate: #Predicate { photo in
                photo.foodLogID == foodLogID
            },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // Delete photo
    func deletePhoto(_ photo: MessyFacePhoto, context: ModelContext) async throws {
        // Delete from CloudKit
        if let assetID = photo.cloudKitAssetID {
            let recordID = CKRecord.ID(recordName: assetID)
            let container = CKContainer.default()
            let database = container.privateCloudDatabase
            try await database.deleteRecord(withID: recordID)
        }
        
        // Delete from SwiftData
        context.delete(photo)
        try context.save()
    }
}
```

---

#### [NEW] [MessyFaceGalleryView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Gallery/MessyFaceGalleryView.swift)

**Purpose:** Central gallery for all messy face photos

**UI Components:**
```swift
struct MessyFaceGalleryView: View {
    @Query private var photos: [MessyFacePhoto]
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedPhoto: MessyFacePhoto?
    
    enum FilterOption {
        case all, byChild(UUID), byFood(UUID), byDate(Date)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(filteredPhotos) { photo in
                        PhotoThumbnailView(photo: photo)
                            .onTapGesture {
                                selectedPhoto = photo
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Messy Face Gallery")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        Button("All Photos") { selectedFilter = .all }
                        // Add more filter options
                    }
                }
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
}
```

---

#### [MODIFY] [FoodLoggingView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Toddler/FoodLoggingView.swift)

**Add Photo Capture:**
```swift
// Add button to capture messy face photo
Button {
    showPhotoCapture = true
} label: {
    Label("Take Messy Face Photo", systemImage: "camera.fill")
}
.sheet(isPresented: $showPhotoCapture) {
    PhotoCaptureView { image in
        Task {
            try await PhotoStorageManager.shared.savePhoto(
                image,
                for: foodLog.id,
                childID: currentChild.id,
                context: modelContext
            )
        }
    }
}
```

---

### Component 1: Notification System

#### [NEW] [NotificationManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/NotificationManager.swift)

**Purpose:** Centralized notification scheduling and management service

**Key Features:**
- Request notification permissions
- Schedule feed reminder notifications with customizable lead time
- Schedule allergen monitoring check-ins
- Handle notification actions (mark as fed, snooze, report reaction)
- Cancel/update notifications when events are logged

**Architecture:**
```swift
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var feedNotificationsEnabled: Bool = false
    @Published var allergenNotificationsEnabled: Bool = true
    
    // Feed notification scheduling
    func scheduleFeedReminder(
        nextFeedTime: Date,
        leadTimeMinutes: Int,
        childName: String
    ) async throws
    
    // Allergen monitoring
    func scheduleAllergenCheckIn(
        allergenName: String,
        delayHours: Int,
        childName: String
    ) async throws
    
    // Permission management
    func requestPermissions() async -> Bool
    func checkPermissionStatus() async
}
```

---

#### [NEW] [NotificationSettingsView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Settings/NotificationSettingsView.swift)

**Purpose:** User interface for notification preferences

**UI Components:**
- Toggle for feed notifications
- Picker for lead time (15min, 30min, 45min, 1hr, 2hr)
- Toggle for allergen monitoring prompts
- Picker for allergen check-in duration (1hr, 2hr, 3hr, 4hr)
- Notification sound/style preferences
- Permission status indicator with re-request option

---

#### [MODIFY] [NewbornManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Managers/NewbornManager.swift)

**Changes:**
- Integrate `NotificationManager` to schedule feed reminders after logging
- Calculate next feed time based on feeding pattern
- Cancel existing notifications when new feed is logged
- Update widget data to show notification status

```swift
// Add to saveBottleFeed() and saveNursingSession()
if NotificationManager.shared.feedNotificationsEnabled {
    let nextFeedTime = calculateNextFeedTime()
    let leadTime = UserDefaults.standard.integer(forKey: "feed_notification_lead_time")
    try await NotificationManager.shared.scheduleFeedReminder(
        nextFeedTime: nextFeedTime,
        leadTimeMinutes: leadTime,
        childName: currentProfile.name
    )
}
```

---

#### [NEW] [AllergenMonitoringPrompt.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Toddler/AllergenMonitoringPrompt.swift)

**Purpose:** Modal prompt after logging high-risk allergen food

**UI Flow:**
1. User logs food with high-risk allergen (peanuts, eggs, shellfish, etc.)
2. Modal appears: "You just logged [Food] which contains [Allergen]"
3. Information card with symptoms to watch for
4. Button: "Set 2-Hour Check-In Reminder"
5. Button: "No Thanks" (dismisses)

**Integration Point:**
- Triggered from `ToddlerManager.saveFoodLog()` when allergen risk level is "high"

---

### Component 2: Image Generation Completion

#### [MODIFY] [ImageGenerationService.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/ImageGenerationService.swift)

**Current State:** Basic Imagen 4 integration with fallback logic

**Enhancements:**
1. **Add Caching Layer:**
   ```swift
   private var imageCache: [String: UIImage] = [:]
   private let cacheDirectory: URL
   
   func getCachedOrGenerate(for foodName: String) async throws -> UIImage {
       // Check memory cache
       if let cached = imageCache[foodName] {
           return cached
       }
       
       // Check disk cache
       if let diskImage = loadFromDisk(foodName) {
           imageCache[foodName] = diskImage
           return diskImage
       }
       
       // Generate new image
       let image = try await generateFoodImage(for: foodName)
       saveToDisk(image, for: foodName)
       imageCache[foodName] = image
       return image
   }
   ```

2. **Add Progress Tracking:**
   ```swift
   @Published var generationProgress: [String: Double] = [:]
   ```

3. **Batch Generation:**
   ```swift
   func generateBatch(foodNames: [String]) async throws -> [String: UIImage]
   ```

4. **Error Recovery:**
   - Implement retry logic with exponential backoff
   - Better error messages for API failures
   - Fallback to placeholder with visual indicator

---

#### [NEW] [ImageCacheManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/ImageCacheManager.swift)

**Purpose:** Manage image cache lifecycle

**Features:**
- Disk cache with size limits (e.g., 100MB)
- LRU eviction policy
- Cache statistics (hit rate, size)
- Manual cache clearing
- Pre-warming for common foods

---

### Component 3: Toddler Mode Image Integration

#### [MODIFY] [ToddlerManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Managers/ToddlerManager.swift)

**Changes:**
- Add image generation when creating new food items
- Integrate with `ImageGenerationService` for meal logging
- Update meal plan generation to include images

---

#### [MODIFY] [FoodImageView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/UI/Components/FoodImageView.swift)

**Enhancements for Toddler Mode:**
- Larger, more playful image presentations
- Animated loading states (fun spinners)
- Tap-to-enlarge functionality
- Sticker-like borders for toddler appeal
- Success animations when food is logged

---

#### Files to Update with Image Support:
- `MealPlanningView.swift` - Show images in meal plans
- `FoodTrackingView.swift` - Display images during logging
- `RecipeDetailView.swift` - Recipe step images
- `ProgressDashboardView.swift` - Achievement badges with food images

---

### Component 4: Localization System

#### [NEW] [Localizable.strings](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Resources/en.lproj/Localizable.strings)

**Structure:**
```
// Onboarding
"onboarding.welcome.title" = "Welcome to Tiny Tastes Tracker";
"onboarding.mode.newborn" = "Newborn Mode";

// Notifications
"notification.feed.title" = "Feeding Time Soon";
"notification.feed.body" = "%@ will be hungry in %d minutes";

// Allergens
"allergen.monitoring.prompt.title" = "Monitor for Reactions?";
```

**Additional Language Files:**
- `es.lproj/Localizable.strings` (Spanish)
- `fr.lproj/Localizable.strings` (French)

---

#### [NEW] [LocalizationManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/LocalizationManager.swift)

**Purpose:** Manage language selection and dynamic locale switching

**Features:**
```swift
@MainActor
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language = .english
    @Published var useMetricUnits: Bool = true
    
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        case french = "fr"
    }
    
    func setLanguage(_ language: Language)
    func localizedString(key: String) -> String
}
```

---

#### [NEW] [LanguageSettingsView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Settings/LanguageSettingsView.swift)

**UI Components:**
- Language picker (English, Spanish, French)
- Unit system toggle (Metric/Imperial)
- Preview of translated content
- Restart prompt if needed

---

#### [MODIFY] All View Files

**Changes Required:**
- Replace all hardcoded strings with `NSLocalizedString` or `String(localized:)`
- Update format strings to support parameter ordering for different languages
- Ensure date/number formatters respect locale

**Example:**
```swift
// Before
Text("Welcome to Tiny Tastes Tracker")

// After
Text(String(localized: "onboarding.welcome.title"))
```

---

#### [NEW] [FoodDatabase+Localization.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Data/FoodDatabase+Localization.swift)

**Purpose:** Localized food names and descriptions

**Structure:**
```swift
extension FoodItem {
    var localizedName: String {
        switch LocalizationManager.shared.currentLanguage {
        case .spanish:
            return spanishName ?? name
        case .french:
            return frenchName ?? name
        case .english:
            return name
        }
    }
}
```

---

### Component 5: CloudKit Integration

#### [MODIFY] [CloudKitSyncManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/CloudKitSyncManager.swift)

**Current State:** Basic framework with stub implementation

**Critical Enhancements:**

1. **Crash Prevention:**
   ```swift
   private var isSyncing = false
   private let syncQueue = DispatchQueue(label: "com.tinytastes.cloudkit.sync")
   
   func performSync() async {
       // Prevent concurrent syncs
       guard !isSyncing else {
           throw SyncError.syncInProgress
       }
       
       isSyncing = true
       defer { isSyncing = false }
       
       // Validate CloudKit availability
       guard await checkAccountStatus() else {
           throw SyncError.iCloudNotAvailable
       }
       
       // Perform sync with error handling
       do {
           try await syncData()
       } catch {
           await handleSyncError(error)
       }
   }
   ```

2. **Robust Error Handling:**
   ```swift
   private func handleSyncError(_ error: Error) async {
       switch error {
       case CKError.networkUnavailable:
           // Schedule retry
           await scheduleRetry(delay: 60)
       case CKError.quotaExceeded:
           // Alert user, disable auto-sync
           await disableAutoSync()
           await notifyQuotaExceeded()
       case CKError.serverRecordChanged:
           // Conflict resolution
           await resolveConflict()
       default:
           // Log and report
           await logError(error)
       }
   }
   ```

3. **Data Mapping:**
   ```swift
   private func convertToCloudKitRecord(_ foodLog: FoodLog) -> CKRecord {
       let record = CKRecord(recordType: "FoodLog")
       record["childID"] = foodLog.childID
       record["foodName"] = foodLog.foodName
       record["timestamp"] = foodLog.timestamp
       record["allergens"] = foodLog.allergens
       // ... map all fields
       return record
   }
   ```

4. **Conflict Resolution:**
   ```swift
   enum ConflictResolution {
       case serverWins
       case clientWins
       case merge
   }
   
   private func resolveConflict(
       local: CKRecord,
       server: CKRecord
   ) async -> CKRecord {
       // Use most recent timestamp
       if let localDate = local["timestamp"] as? Date,
          let serverDate = server["timestamp"] as? Date {
           return localDate > serverDate ? local : server
       }
       return server // Default to server
   }
   ```

---

#### [NEW] [CloudKitRecordMapper.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/CloudKitRecordMapper.swift)

**Purpose:** Bidirectional mapping between SwiftData models and CloudKit records

**Key Methods:**
```swift
protocol CloudKitMappable {
    func toCKRecord() -> CKRecord
    static func fromCKRecord(_ record: CKRecord) -> Self?
}

extension FoodLog: CloudKitMappable { ... }
extension BottleFeed: CloudKitMappable { ... }
extension NursingSession: CloudKitMappable { ... }
// ... all syncable models
```

---

#### [NEW] [CloudKitSyncView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Settings/CloudKitSyncView.swift)

**Purpose:** User interface for CloudKit sync management

**UI Components:**
- iCloud account status indicator
- Manual sync button with progress
- Auto-sync toggle
- Last sync timestamp
- Sync statistics (items synced, errors)
- Sync history log
- "Reset Sync" option (with confirmation)

---

#### [MODIFY] [project.yml](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/project.yml)

**Changes:**
```yaml
targets:
  TinyTastesTracker:
    entitlements:
      path: TinyTastesTracker/Resources/TinyTastesTracker.entitlements
      properties:
        com.apple.developer.icloud-container-identifiers:
          - iCloud.com.tinytastes.tracker
        com.apple.developer.icloud-services:
          - CloudKit
```

---

#### [MODIFY] [TinyTastesTracker.entitlements](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/TinyTastesTracker.entitlements)

**Add CloudKit Entitlements:**
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.tinytastes.tracker</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

---

### Component 7: Accessibility Completion

#### [MODIFY] Remaining View Files (12+ files)

**Files Requiring VoiceOver Labels:**
- `Features/Newborn/NewbornDashboardView.swift`
- `Features/Newborn/FeedingLogView.swift`
- `Features/Newborn/SleepTrackingView.swift`
- `Features/Toddler/ToddlerDashboardView.swift`
- `Features/Toddler/MealPlanningView.swift`
- `Features/Toddler/FoodTrackingView.swift`
- `Features/Recipe/RecipeListView.swift`
- `Features/Recipe/RecipeDetailView.swift`
- `Features/Settings/SettingsView.swift`
- `Features/Settings/ProfileManagementView.swift`
- `UI/Components/ChartViews/*.swift` (all chart components)

**VoiceOver Implementation Pattern:**
```swift
// Before
Button("Log Feed") { logFeed() }

// After
Button("Log Feed") { logFeed() }
    .accessibilityLabel("Log feeding session")
    .accessibilityHint("Opens feeding log form")
    .accessibilityAddTraits(.isButton)
```

**For Charts and Progress Indicators:**
```swift
Chart { ... }
    .accessibilityLabel("Food variety progress")
    .accessibilityValue("\(completedColors) of 7 colors achieved")
    .accessibilityHint("Shows rainbow food variety tracking")
```

---

#### [MODIFY] Color Contrast Fix

**File:** `Core/Theme/AppColors.swift` or equivalent

**Issue:** Warning Orange has 2.8:1 contrast ratio (needs 4.5:1 minimum for WCAG AA)

**Fix:**
```swift
// Before
static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

// After (darker for better contrast)
static let warningOrange = Color(red: 0.9, green: 0.45, blue: 0.0) // ~4.6:1 contrast
```

---

#### [NEW] [AccessibilityTests.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTrackerTests/AccessibilityTests.swift)

**Test Coverage:**
- All interactive elements have accessibility labels
- All images have meaningful descriptions or are marked decorative
- Color contrast meets WCAG AA standards
- Dynamic Type scaling works at all sizes
- VoiceOver navigation order is logical

---

### Component 8: Analytics & Crash Reporting

#### [NEW] [AnalyticsManager.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/AnalyticsManager.swift)

**Purpose:** Centralized analytics and event tracking

**Platform Options:**
1. **TelemetryDeck** (Recommended for privacy-focused apps)
   - Privacy-first analytics
   - No PII collection
   - GDPR compliant by default
   - $10/month for indie developers

2. **Firebase Analytics** (More features, Google ecosystem)
   - Free tier available
   - More detailed user insights
   - Requires careful privacy configuration

**Implementation:**
```swift
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private var telemetryDeck: TelemetryDeck?
    
    func initialize() {
        #if !DEBUG
        telemetryDeck = TelemetryDeck(appID: "YOUR_APP_ID")
        #endif
    }
    
    // User Journey Tracking
    func trackOnboardingStarted()
    func trackOnboardingCompleted(mode: String)
    func trackFirstLog(type: String)
    func trackFirstMealPlan()
    
    // Feature Usage
    func trackAIQuery(feature: String, success: Bool)
    func trackRecipeGeneration(success: Bool)
    func trackVoiceChatUsed()
    
    // Drop-off Points
    func trackScreenView(screen: String)
    func trackUserDropoff(at: String)
    
    // Errors
    func trackError(error: Error, context: String)
    func trackAPIFailure(endpoint: String, statusCode: Int)
}
```

---

#### [NEW] [CrashReporter.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/CrashReporter.swift)

**Purpose:** Crash reporting and error logging

**Platform Options:**
1. **Sentry** (Recommended)
   - Excellent Swift support
   - Free tier: 5K events/month
   - Source map support
   - Performance monitoring

2. **Firebase Crashlytics**
   - Free
   - Google ecosystem integration
   - Good iOS support

**Implementation:**
```swift
import Sentry

class CrashReporter {
    static func initialize() {
        SentrySDK.start { options in
            options.dsn = SecureAPIKeyManager.shared.getSentryDSN()
            options.debug = false
            options.enableAutoSessionTracking = true
            options.attachScreenshot = true
            
            // Set environment
            #if DEBUG
            options.environment = "debug"
            #else
            options.environment = "production"
            #endif
        }
    }
    
    static func logError(_ error: Error, context: [String: Any] = [:]) {
        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: context, key: "custom")
        }
    }
    
    static func logBreadcrumb(_ message: String, category: String) {
        let crumb = Breadcrumb(level: .info, category: category)
        crumb.message = message
        SentrySDK.addBreadcrumb(crumb)
    }
}
```

---

#### Integration Points

**Modify:** `TinyTastesTrackerApp.swift`
```swift
init() {
    // Initialize analytics and crash reporting
    AnalyticsManager.shared.initialize()
    CrashReporter.initialize()
}
```

**Modify:** All major view models and managers to add tracking:
```swift
// Example in NewbornManager
func saveBottleFeed(...) async throws {
    do {
        // ... existing code
        AnalyticsManager.shared.trackEvent("bottle_feed_logged")
    } catch {
        CrashReporter.logError(error, context: ["action": "save_bottle_feed"])
        throw error
    }
}
```

---

---

### Component 9: App Store Preparation

#### Legal & Privacy Setup

**[NEW] [Terms of Service](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TERMS_OF_SERVICE.md)**

**Sections to Include:**
1. Acceptance of Terms
2. Description of Service
3. User Responsibilities
4. Medical Disclaimer (CRITICAL - app is not medical advice)
5. Intellectual Property
6. Limitation of Liability
7. Termination
8. Governing Law
9. Changes to Terms

**Template:**
```markdown
# Terms of Service

Last Updated: [DATE]

## 1. Medical Disclaimer

**IMPORTANT:** Tiny Tastes Tracker is for informational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your pediatrician or other qualified health provider with any questions you may have regarding your child's health.

## 2. Acceptance of Terms

By downloading and using Tiny Tastes Tracker ("the App"), you agree to be bound by these Terms of Service...

[Continue with standard terms]
```

---

#### **Privacy Policy Hosting**

**Options:**
1. **GitHub Pages** (Free, recommended)
   ```bash
   # Create gh-pages branch
   git checkout -b gh-pages
   cp PRIVACY_POLICY.md index.md
   git add index.md
   git commit -m "Add privacy policy"
   git push origin gh-pages
   
   # URL will be: https://[username].github.io/[repo-name]/
   ```

2. **Custom Domain** (Professional, costs ~$12/year)
   - Register domain: tinytastestracker.com
   - Host privacy policy at: tinytastestracker.com/privacy
   - Host terms at: tinytastestracker.com/terms

---

#### App Store Assets Creation

**[NEW] App Icon Design Brief**

**Requirements:**
- 1024x1024 PNG (no transparency)
- Simple, recognizable at small sizes
- Avoid text (doesn't scale well)
- Consider: Baby bottle + rainbow colors (represents nutrition tracking)

**Tools:**
- Figma (free)
- Canva (free tier)
- SF Symbols for iOS-native look

---

**[NEW] Screenshot Strategy**

**Required Sizes:**
- iPhone 6.7" (1290 x 2796) - iPhone 15 Pro Max
- iPhone 6.5" (1242 x 2688) - iPhone 14 Plus

**Screenshot Plan (5 screenshots recommended):**
1. **Hero Shot** - Dashboard with "Track Every Tiny Taste" tagline
2. **AI Feature** - Sage AI assistant answering question
3. **Meal Planning** - Beautiful meal plan with food images
4. **Tracking** - Easy logging interface (bottle/nursing/food)
5. **Insights** - Charts showing progress and patterns

**Tools:**
- [Screenshots.pro](https://screenshots.pro) - Free templates
- [AppLaunchpad](https://theapplaunchpad.com) - Screenshot generator
- Figma - Custom designs

---

**[NEW] App Preview Video Script**

**Duration:** 15-30 seconds

**Storyboard:**
1. (0-5s) Open app → Beautiful dashboard
2. (5-10s) Log a feeding → Quick, easy tap
3. (10-15s) Ask Sage AI a question → Get instant answer
4. (15-20s) View meal plan → Colorful, organized
5. (20-25s) Show progress chart → "Track Every Tiny Taste"
6. (25-30s) App icon + tagline

**Tools:**
- QuickTime Screen Recording
- iMovie (free)
- Final Cut Pro (advanced)

---

**[NEW] App Store Copy Template**

**Title:** (30 characters max)
```
Tiny Tastes: Baby Tracker
```

**Subtitle:** (30 characters max)
```
AI Feeding & Sleep Assistant
```

**Promotional Text:** (170 characters, updatable)
```
Track every feeding, sleep, and meal with AI-powered insights. From newborn bottles to toddler adventures—all in one beautiful app. 🍼🌈
```

**Description:** (4000 characters max)
```
# Track Every Tiny Taste 🍼

Tiny Tastes Tracker is the all-in-one baby tracking app that grows with your child—from newborn feedings to toddler food adventures.

## ✨ SMART AI ASSISTANT
Meet Sage, your personal pediatric nutrition AI:
• Get instant answers to feeding questions
• Receive personalized meal suggestions
• Understand your baby's patterns with AI insights

## 🍼 NEWBORN MODE
Perfect for the early days:
• Track bottle feeds and nursing sessions
• Monitor sleep patterns
• Log diapers and growth measurements
• Get feeding predictions and reminders

## 🌈 TODDLER MODE
Make food exploration fun:
• "Eat the Rainbow" food variety tracking
• AI-powered meal planning
• Allergen monitoring and safety alerts
• Recipe generation from ingredients

## 📊 BEAUTIFUL INSIGHTS
• Visual progress charts
• Growth tracking
• Sleep pattern analysis
• Food variety reports

## 🔒 PRIVACY FIRST
• All data stored securely on your device
• Optional iCloud sync
• No data selling, ever
• COPPA & GDPR compliant

## 🎯 FEATURES
✓ Multi-child support
✓ Home screen widgets
✓ Dark mode
✓ Export data (CSV/JSON)
✓ Offline mode
✓ VoiceOver accessible

Perfect for new parents, experienced caregivers, and everyone in between!

---

*Medical Disclaimer: This app is for informational purposes only and is not a substitute for professional medical advice.*
```

**Keywords:** (100 characters, comma-separated)
```
baby tracker,feeding,sleep,nutrition,toddler,meal plan,AI,newborn,breastfeeding,bottle
```

---

#### TestFlight Setup

**Steps:**
1. **Create Internal Testing Group**
   - App Store Connect → TestFlight → Internal Testing
   - Add up to 100 internal testers (Apple IDs)
   - No review required

2. **Upload Build**
   ```bash
   # Archive in Xcode
   Product → Archive
   
   # Distribute
   Window → Organizer → Distribute App → App Store Connect
   ```

3. **Add Test Information**
   - What to Test: "Full app functionality, especially notifications and CloudKit sync"
   - Test Notes: Known issues, areas needing feedback

4. **External Testing** (Optional)
   - Requires App Review (1-2 days)
   - Up to 10,000 external testers
   - Public link or email invites

---

#### Pre-Submission Checklist

**Performance Benchmarks:**
- [ ] App launch time: <2 seconds (cold start)
- [ ] Memory usage: <150MB typical
- [ ] Battery drain: <5% per hour of active use
- [ ] Network efficiency: Minimal background data

**Security Verification:**
- [ ] No API keys in binary (use `strings` command to verify)
- [ ] All network calls use HTTPS
- [ ] Sensitive data encrypted
- [ ] Keychain used for credentials

**Compliance:**
- [ ] Privacy Policy URL accessible
- [ ] Terms of Service accessible
- [ ] Age rating appropriate (4+)
- [ ] COPPA compliance verified (no data collection from children without consent)

---



#### [NEW] [NotificationManagerTests.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTrackerTests/NotificationManagerTests.swift)

**Test Coverage:**
- Permission request flow
- Feed notification scheduling
- Allergen notification scheduling
- Notification cancellation
- Action handling

---

#### [NEW] [ImageGenerationServiceTests.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTrackerTests/ImageGenerationServiceTests.swift)

**Test Coverage:**
- Successful image generation
- API failure fallback
- Caching behavior
- Batch generation
- Placeholder creation

---

#### [NEW] [CloudKitSyncManagerTests.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTrackerTests/CloudKitSyncManagerTests.swift)

**Test Coverage:**
- Sync operation success
- Error handling (network, quota, conflicts)
- Concurrent sync prevention
- Data mapping accuracy
- Conflict resolution

---

#### [NEW] [LocalizationTests.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTrackerTests/LocalizationTests.swift)

**Test Coverage:**
- All strings have translations
- Format string parameter ordering
- Date/number formatting per locale
- Language switching

---

## Verification Plan

### Automated Tests

1. **Unit Tests:**
   ```bash
   # Run all new tests
   xcodebuild test -scheme TinyTastesTracker -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **UI Tests:**
   - Notification permission flow
   - Allergen prompt interaction
   - Language switching
   - CloudKit sync UI

3. **Integration Tests:**
   - End-to-end notification delivery
   - Image generation and caching
   - CloudKit sync with mock server

### Manual Verification

1. **Notifications:**
   - Grant/deny permissions and verify behavior
   - Schedule feed reminder and verify delivery
   - Log allergen food and verify prompt appears
   - Tap notification actions and verify app response

2. **Image Generation:**
   - Generate images for 20+ foods
   - Verify caching (second load should be instant)
   - Test offline behavior (placeholder)
   - Verify images in toddler mode

3. **Localization:**
   - Switch to Spanish and verify all screens
   - Switch to French and verify all screens
   - Test metric/imperial unit conversion
   - Verify food names are translated

4. **CloudKit:**
   - Enable sync on Device A, log data
   - Enable sync on Device B, verify data appears
   - Test offline sync (should queue)
   - Test conflict resolution (edit same item on both devices)
   - **Crash Test:** Reproduce tonight's crash scenario and verify fix

### Performance Testing

1. **Notification Performance:**
   - Schedule 100 notifications, verify no lag
   - Cancel 100 notifications, verify cleanup

2. **Image Cache Performance:**
   - Load 50 images, measure memory usage
   - Verify cache eviction works correctly

3. **CloudKit Performance:**
   - Sync 1000+ records, measure time
   - Monitor network usage
   - Test with poor network conditions

---

## Implementation Phases

### Phase 1: Notifications (Week 1)
**Priority:** HIGH - User-requested feature

1. Create `NotificationManager.swift`
2. Implement feed reminder scheduling
3. Create `NotificationSettingsView.swift`
4. Integrate with `NewbornManager`
5. Test notification delivery
6. Create allergen monitoring prompt
7. Implement 2-hour check-in notification

**Deliverable:** Fully functional notification system

---

### Phase 2: Image Generation Completion (Week 1-2)
**Priority:** HIGH - Core feature completion

1. Add caching layer to `ImageGenerationService`
2. Create `ImageCacheManager`
3. Implement batch generation
4. Add progress indicators
5. Test with various foods

**Deliverable:** Robust image generation with caching

---

### Phase 3: Toddler Mode Images (Week 2)
**Priority:** MEDIUM - Feature parity

1. Audit toddler views for image integration
2. Update `FoodImageView` for toddler styling
3. Integrate image generation in `ToddlerManager`
4. Update meal planning views
5. Test across all toddler screens

**Deliverable:** Full image support in toddler mode

---

### Phase 4: Localization (Week 2-3)
**Priority:** MEDIUM - Market expansion

1. Set up localization infrastructure
2. Extract all hardcoded strings
3. Create Spanish translations
4. Create French translations
5. Implement language selection UI
6. Test all screens in each language

**Deliverable:** Multi-language support (EN, ES, FR)

---

### Phase 5: CloudKit Integration (Week 3-4)
**Priority:** HIGH - Crash prevention critical

1. Complete CloudKit configuration
2. Implement robust error handling
3. Add crash prevention measures
4. Create data mapping layer
5. Implement conflict resolution
6. Create sync UI
7. **Test crash scenarios extensively**
8. Monitor sync operations

**Deliverable:** Production-ready CloudKit sync

---

### Phase 6: Testing & Polish (Week 4)
**Priority:** HIGH - Quality assurance

1. Write comprehensive tests for all features
2. Perform manual testing
3. Fix bugs and edge cases
4. Update documentation
5. Prepare for release

**Deliverable:** Tested, documented features ready for production

---

## Risk Mitigation

### Risk 1: CloudKit Crashes
**Mitigation:**
- Implement defensive programming (nil checks, availability checks)
- Add extensive logging for debugging
- Test with CloudKit disabled
- Implement graceful degradation

### Risk 2: Notification Permission Denial
**Mitigation:**
- Provide clear explanation before requesting
- Offer alternative in-app reminders
- Allow re-requesting permissions from settings

### Risk 3: Image Generation API Costs
**Mitigation:**
- Implement aggressive caching
- Set daily generation limits
- Pre-generate common foods
- Monitor API usage with alerts

### Risk 4: Translation Quality
**Mitigation:**
- Use professional translation service (not just Google Translate)
- Have native speakers review
- Test with actual users in target markets

---

## Success Metrics

1. **Notifications:**
   - 80%+ notification delivery rate
   - 50%+ users enable feed reminders
   - 70%+ users accept allergen monitoring

2. **Image Generation:**
   - 95%+ cache hit rate after initial load
   - <2 seconds average generation time
   - <1% API failure rate

3. **Localization:**
   - 100% string coverage
   - 90%+ translation accuracy (native speaker review)
   - 20%+ adoption in Spanish/French markets

4. **CloudKit:**
   - 0 crashes related to CloudKit
   - 99%+ sync success rate
   - <5 seconds average sync time

---

## Post-Implementation

1. **Monitor CloudKit operations** for 2 weeks after release
2. **Gather user feedback** on notification timing preferences
3. **Track image generation costs** and optimize if needed
4. **Expand translations** to additional languages based on demand
5. **Update ASSESSMENT.md** with completed features

---

### Component 10: Daycare Report Ingestion

#### [NEW] [DaycareReportParser.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Core/Services/DaycareReportParser.swift)

**Purpose:** Parse daily report images/PDFs and text files into tracking events.

**Key Features:**
```swift
import Vision
import UIKit

@MainActor
class DaycareReportParser {
    static let shared = DaycareReportParser()
    
    // Process image and return suggested logs
    func parseReportImage(_ image: UIImage) async throws -> [SuggestedLog] {
        let recognizedText = try await performOCR(on: image)
        return try await parseTextContent(recognizedText)
    }
    
    // Process text file content (txt, csv, json)
    func parseReportFile(content: String, fileType: String) async throws -> [SuggestedLog] {
        return try await parseTextContent(content, context: fileType)
    }
    
    // AI Parsing via Gemini
    private func parseTextContent(_ text: String, context: String = "report") async throws -> [SuggestedLog] {
        let prompt = """
        Parse the following text from a daycare daily \(context) into structured events.
        Format as JSON array with fields: type (nap/feed/diaper), startTime, endTime, quantity, details.
        
        Text Content:
        \(text)
        """
        
        let jsonResponse = try await GeminiService.shared.generateText(prompt: prompt)
        return try parseJSONToLogs(jsonResponse)
    }
    
    private func performOCR(on image: UIImage) async throws -> String {
        // Implementation using Vision framework
    }
}

struct SuggestedLog: Identifiable {
    let id = UUID()
    let type: LogType
    let time: Date
    let endTime: Date?
    let details: String
    var isConfirmed: Bool = true
}
```

---

#### [NEW] [ReportImportView.swift](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/TinyTastesTracker/Features/Daycare/ReportImportView.swift)

**Purpose:** UI for uploading reports (images/files) and reviewing parsed data.

**UI Flow:**
1. Upload Options: "Scan Document" (Camera) or "Import File" (File Picker)
2. Processing State (OCR or File Read + AI)
3. Review Screen: List of detected events
4. Edit/Delete specific events
5. "Import All" button

**Key Components:**
- `DocumentScannerView`: Camera interface for documents
- `FileImporter`: Supported types: .pdf, .png, .jpg, .txt, .csv, .json
- `ParsedEventRow`: Editable row for each detected event
- `ConflictAlert`: Warning if overlapping events exist

---
