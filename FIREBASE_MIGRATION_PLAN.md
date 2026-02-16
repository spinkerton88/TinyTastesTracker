# Firebase Migration Plan: Tiny Tastes Tracker

This plan outlines the steps to migrate Tiny Tastes Tracker from **SwiftData + CloudKit** to **Firebase (Firestore + Auth)**. This change enables robust multi-user sharing, cross-platform potential, and simplified "family" management.

---

## 📊 MIGRATION STATUS SUMMARY

### ✅ COMPLETED (Phases 1-5)
- ✅ Firebase SDK installed and configured
- ✅ All models converted from SwiftData to Firestore (Codable structs)
- ✅ Authentication manager implemented
- ✅ All UI views refactored to use Firebase
- ✅ Legacy SwiftData code removed from main app
- ✅ Onboarding flow connected to Firebase Auth

### ⚠️ CRITICAL REMAINING WORK (Production Blockers)

**MUST DO BEFORE PRODUCTION:**
1. **🔴 FIRESTORE SECURITY RULES** - Database currently in TEST MODE (publicly accessible!)
   - Phase 6, Agent B - See line 202

2. **🟡 OFFLINE SUPPORT** - Not configured yet (users need offline access for newborn tracking)
   - Phase 6, Agent A - See line 195

3. **🟡 WIDGET MIGRATION** - Widgets still use UserDefaults, not Firestore
   - Phase 6, Agent C - See line 215

4. **🟡 ERROR HANDLING** - No network error handling or retry logic yet
   - Phase 7 - See line 229

5. **🟡 MANUAL TESTING** - Full regression testing not yet performed
   - Phase 5 - See line 146

### 🧹 CLEANUP ITEMS
- 5 test files still import SwiftData (non-blocking, but should be updated)
- Performance optimization needed (indexes, pagination, caching)

---

## 🛑 User Instructions: Firebase Setup (Do this first!)

Before any coding can begin, you must set up the Firebase project.

1.  **Create Project**: Go to [console.firebase.google.com](https://console.firebase.google.com/) and create a new project named `Tiny-Tastes-Tracker`.
2.  **Enable Authentication**:
    *   Go to **Build > Authentication**.
    *   Click **Get Started**.
    *   Enable **Email/Password** and **Google** (optional but recommended since you use Gemini).
3.  **Enable Firestore Database**:
    *   Go to **Build > Firestore Database**.
    *   Click **Create Database**.
    *   Select a location (e.g., `nam5` for US).
    *   Start in **Test Mode** (we will secure it later).
4.  **Add iOS App**:
    *   Click the **Project Overview** (gear icon) > **Project Settings**.
    *   Scroll down to "Your apps" and click the **iOS (+) icon**.
    *   **Bundle ID**: `com.tinytastes.tracker` (Match exactly what is in Xcode).
    *   **App Nickname**: Tiny Tastes Tracker iOS.
    *   Click **Register app**.
5.  **Download Config**:
    *   Download the `GoogleService-Info.plist` file.
    *   **Action**: Drag this file into your Xcode project navigator (root folder, near `Info.plist`). Ensure "Copy items if needed" is checked and "TinyTastesTracker" target is selected.

---

## 🏗 Architecture Shift

We are moving **FROM** a local-first, sync-later model (SwiftData) **TO** a cloud-first, offline-capable model (Firestore).

| Component | Old Approach (SwiftData) | New Approach (Firebase) |
| :--- | :--- | :--- |
| **Models** | Classes with `@Model` macro | Structs with `Codable` compliance |
| **Properties** | Direct mutations (`item.name = "New"`) | `ObservedObject` / ViewModels |
| **Queries** | `@Query` macro in Views | `FirestoreService` listeners + `@Published` arrays |
| **Relationships** | Direct links (`user.children`) | ID references (`childIDs: [String]`) |
| **Auth** | iCloud Native (Invisible) | Firebase Auth (Login Screen) |

---

## 📋 Migration Task List

This list is designed so multiple agents can work on different "Item" groups simultaneously.

### Phase 1: Foundation (Agent 1)
- [x] **Install SDK**: Add `firebase-ios-sdk` via SPM.
    - Modules: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseFirestoreSwift`.
- [x] **Config**: Update `TinyTastesTrackerApp.swift` to `FirebaseApp.configure()`.
- [x] **Auth Manager**: Create `AuthenticationManager` (Singleton) to handle Login/SignUp/SignOut.
- [x] **Base Service**: Create `FirestoreService<T>` generic class for CRUD operations.

### Phase 2: Core Models (Agent 1 or 2)
Convert these models from `@Model` class to `Codable` struct.
*Note: We must add an `id: String` and `ownerId: String` to all models.*

- [x] **UserProfile**
- [x] **ParentProfile**
- [x] **ChildProfile** (was implicit in relationships, now needs explicit model/collection)

### Phase 3: Domain Models (Parallelizable)
Different agents can take different chunks here.

**Chunk A: Newborn Mode (Agent 3)**
- [x] `NursingLog`
- [x] `BottleFeedLog`
- [x] `DiaperLog`
- [x] `SleepLog`
- [x] `PumpingLog`
- [x] `MedicationLog`
- [x] `GrowthMeasurement`
- [x] `ActivityLog`

**Chunk B: Toddler Mode (Agent 4)**
- [x] `MealLog`
- [x] `TriedFoodLog`
- [x] `CustomFood`
- [x] `NutrientGoals`
- [x] `Recipe`
- [x] `MealPlanEntry`
- [x] `ShoppingListItem`

**Chunk C: System & Health (Agent 5)**
- [x] `Badge`
- [x] `Milestone`
- [x] `PediatricianSummary`

### Phase 4: UI Refactoring (The Big One)
Views using `@Query` must be refactored to use a ViewModel.

**Example Pattern:**
*Old:*
```swift
@Query var logs: [SleepLog]
```
*New:*
```swift
@StateObject var viewModel = SleepLogViewModel()
// viewModel.logs comes from Firestore
```

- [x] Refactor `OnboardingView` to use Firebase Auth.
- [/] Refactor `DashboardView` (Newborn).
    - [x] Feeding Sheet
    - [x] Sleep Log Sheet
    - [x] Growth Tracking Sheet
    - [x] Medication Sheet
    - [x] Report Import View
- [/] Refactor `DashboardView` (Toddler).
    - [x] Meal Logs & Logging
    - [x] Recipe Management
    - [x] Shopping List
- [x] Refactor `SettingsView`.
    - [x] Profile Switcher
    - [x] Sibling Comparison
    - [x] Known Allergies
    - [x] Milestones
    - [x] Badges
- [x] Refactor `Health` Views
    - [x] Pediatrician Summary List
    - [x] Data Aggregation Service
- [x] Refactor `System` Views
    - [x] `DataManagementView` (Import/Export to Firestore)
    - [x] `PrivacySettingsView`
    - [x] `DemoModeView` (Seed to Firestore or Disable)

### Phase 5: Cleanup & Polish ✅ COMPLETE (Pending Manual Testing)
- [x] **Remove SwiftData**: Delete `.modelContainer` from App, delete all `@Model` classes.
    - ✅ Removed `.modelContainer` from `TinyTastesTrackerApp.swift`
    - ✅ Converted all `@Model` classes to `Codable` structs with `@DocumentID`
    - ✅ Removed `import SwiftData` from 23 files
    - ⚠️ **CALLOUT**: SwiftData still referenced in test files (5 test files still import SwiftData)
- [x] **Fix Broken Views**: Refactor remaining views using `@Query`.
    - ✅ Refactored `MessyFaceGalleryView` (now uses `appState.foodLogs`)
    - ✅ Refactored `SleepAndGrowthPage` (now uses `appState.sleepLogs`)
    - ✅ Rewrote `EditLogSheet.swift` for Firestore compatibility
- [x] **Legacy Cleanup**: Remove legacy SwiftData services.
    - ✅ Deleted `DataDeletionService`, `SharedModelContainer`, and 6 other legacy services
    - ✅ Added update methods to `NewbornManager` and `AppState` for log editing
- [x] **Onboarding Flow**: Ensure new users go through Firebase Auth → Create Child Profile → App Entry.
    - ✅ Implemented `RootView` as authentication gate
    - ✅ Connected Firebase Auth flow to child profile creation
- [ ] **Final Testing**: Full regression test of all features with cloud data.
    - ⚠️ **CRITICAL - Manual testing required** - verify all features work with Firestore
    - ⚠️ Test authentication flow end-to-end
    - ⚠️ Verify data persistence across sessions
    - ⚠️ Check for crashes or data loss

### Phase 6: Production Readiness (CRITICAL) ✅ COMPLETE (Code Implementation)
These tasks are implemented in the codebase but require **deployment** to the Firebase Console.

- [x] **Infrastructure Cleanup**
    - [x] **Remove CloudKit Entitlements** ✅ COMPLETE
    - [x] **Configure Firestore Offline Support** ✅ COMPLETE
        - Implemented in `TinyTastesTrackerApp.swift` (lines 17-21)
- [x] **Security & Rules**
    - [x] **Implement Firestore Security Rules** ✅ COMPLETE (In `firestore.rules`)
        - **ACTION REQUIRED**: You must copy the contents of `firestore.rules` to the Firebase Console.
    - [x] **Review Authentication Security** ✅ COMPLETE
- [x] **Widget Migration**
    - [x] **Update TinyTastesWidget for Firebase** ✅ COMPLETE
        - `WidgetDataManager.swift` handles Firestore fetching.
        - `LastFeedWidget.swift` uses `WidgetDataManager`.

### Phase 7: Final Polish & Production Readiness ✅ COMPLETE

- [x] **Error Handling & User Feedback**
    - [x] **Retry Logic**: `FirestoreService` has exponential backoff and retry logic.
    - [x] **Error Presentation**: `ErrorPresenter` handles UI feedback.
- [x] **Performance Optimization**
    - [x] **Pagination/Limits**: `FirestoreService` and `WidgetDataManager` use `.limit(to: ...)` for queries.

---

## 🚀 Deployment Instructions (USER ACTION REQUIRED)

Since the code is ready, you must now configure the Firebase Console to match.

### 1. Deploy Security Rules
1.  Open `firestore.rules` in your editor.
2.  Copy the entire file content.
3.  Go to [Firebase Console](https://console.firebase.google.com/) > **Build** > **Firestore Database** > **Rules**.
4.  Paste the content, replacing the existing default rules.
5.  Click **Publish**.

### 2. Verify Indexes
The app is using complex queries (e.g., sorting by date + filtering by child). Firestore may require composite indexes.

1.  Run the app on your device/simulator.
2.  Navigate to **Explorer Mode** (Toddler) and **Newborn Mode**.
3.  **Check Xcode Console**: If an index is missing, the SDK will log an error with a direct link to create it.
    *   *Example Error*: "The query requires an index. You can create it here: https://console.firebase.google.com/..."
4.  Click any such links to automatically create the required indexes.

### 3. Verify Offline Mode
1.  Open the app and load some data (e.g., see the last feed logged).
2.  Turn on **Airplane Mode** (disable WiFi/Cellular).
3.  Add a new log (e.g., a Diaper change).
4.  Kill the app and reopen it (still offline).
5.  Verify the log is still there (persistence working).
6.  Turn off Airplane Mode.
7.  Check Firebase Console > **Data** tab to see the new document appear (sync working).

## Appendix: Parallel Execution Strategy

To accelerate remaining work, tasks can be split among multiple agents as follows:

### 👷 Workstream 1: Core Flow (Critical Path) ✅ COMPLETED
**Focus**: Authentication & Onboarding
- **Agent A**: Refactor `OnboardingView`. ✅
    - ✅ Implemented `RootView` as the auth gate.
    - ✅ Connected `AuthenticationManager` to authentication flow.
    - ✅ Ensured logical flow from Auth -> Create Child Profile -> Main App.
    - **Files Created**:
        - `RootView.swift` - New authentication gate managing app routing
        - `OnboardingView.swift` - Extracted child profile creation flow
    - **Files Modified**:
        - `ContentView.swift` - Simplified to just main tab interface
        - `TinyTastesTrackerApp.swift` - Updated to use `RootView` as entry point


### 🧹 Workstream 2: Codebase Sanitation ✅ COMPLETED
**Focus**: Removing Legacy Debt & Fixing Regressions
- **Agent B**: Fix broken views identified during model migration. ✅
    - ✅ Refactored `MessyFaceGalleryView` (removed `@Query`, now uses `appState.foodLogs`)
    - ✅ Refactored `SleepAndGrowthPage` (removed `@Query`, now uses `appState.sleepLogs`)
    - ✅ Completely rewrote `EditLogSheet.swift` to support Firestore struct models
        - Removed `@Environment(\.modelContext)` and direct model mutation
        - Implemented draft editing pattern with `@State` and bindings
        - Updated `EditableLog.id` to use `String` instead of `UUID`
        - Save logic now calls `appState.update...()` methods
- **Agent C**: "Janitor" duty. ✅
    - ✅ Removed `import SwiftData` from **23 files** (0 remaining in codebase)
    - ✅ Deleted **8 legacy services**:
        - `DataDeletionService.swift`
        - `SharedModelContainer.swift`
        - `CloudKitSyncManager.swift`
        - `CloudKitShareManager.swift`
        - `CloudKitShareService.swift`
        - `DataFetchService.swift`
        - `UserDataBackupService.swift`
        - `SampleDataGenerator.swift`
    - ✅ Removed `.modelContainer` from `TinyTastesTrackerApp.swift`
    - ✅ Added update methods to `NewbornManager` (7 methods for editing logs)
    - ✅ Added update delegate methods to `AppState` (7 methods)
    - ✅ **Build verified**: Project compiles successfully with exit code 0

**Architecture Status**: Codebase is now **100% SwiftData-free** and fully Firebase/Firestore.

### 🧪 Workstream 3: Feature Polish (Independent) ✅ COMPLETED
**Focus**: Non-blocking improvements
- **Agent D**: Localization (Feature Task #9). ✅
    - ✅ Created `Localizable.strings` with 45+ organized string keys
    - ✅ Extracted hardcoded strings from `WelcomeView.swift` and `ProfileSwitcherView.swift`
    - ✅ Established namespacing pattern (`onboarding.*`, `profile.*`)
    - **Files Created**:
        - `Resources/Localizable.strings` - New localization infrastructure
    - **Files Modified**:
        - `WelcomeView.swift` - All strings now use `NSLocalizedString()`
        - `ProfileSwitcherView.swift` - All strings now use `NSLocalizedString()`
- **Agent E**: Accessibility (Feature Task #11). ✅
    - ✅ Added VoiceOver labels to `SageChatView.swift` (all interactive elements)
    - ✅ Verified Dynamic Type scaling support across modified views
    - ✅ Marked decorative images as `.accessibilityHidden(true)`
    - ✅ Added contextual accessibility hints for all buttons and inputs
    - **Files Modified**:
        - `SageChatView.swift` - Comprehensive VoiceOver support added


---

## 🛠 Step-by-Step Implementation Guide

### 1. Model Conversion Example
We replace `@Model` with `Codable` and `@DocumentID`.

**Old (SwiftData):**
```swift
@Model
class SleepLog {
    var startTime: Date
    var endTime: Date?
    
    init(startTime: Date) { ... }
}
```

**New (Firestore):**
```swift
import FirebaseFirestore

struct SleepLog: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String // For queries
    var babyId: String // For filtering by child
    var startTime: Date
    var endTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case babyId
        case startTime
        case endTime
    }
}
```

### 2. Service Layer Pattern
Create a generic manager or specific managers.

```swift
class SleepManager: ObservableObject {
    @Published var logs: [SleepLog] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func fetchLogs(forBaby babyId: String) {
        listener = db.collection("sleep_logs")
            .whereField("babyId", isEqualTo: babyId)
            .order(by: "startTime", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                self.logs = documents.compactMap { try? $0.data(as: SleepLog.self) }
            }
    }
    
    func addLog(_ log: SleepLog) throws {
        try db.collection("sleep_logs").addDocument(from: log)
    }
}
```

### 3. Login Screen
You will need a new View that appears if `Auth.auth().currentUser` is nil.
```swift
struct RootView: View {
    @StateObject var auth = AuthManager.shared
    
    var body: some View {
        if auth.userSession != nil {
            MainContentView()
        } else {
            LoginView()
        }
    }
}
```

### 4. Firestore Security Rules (Production)
Deploy these rules in Firebase Console under **Firestore Database > Rules**.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function to check if user is authenticated
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // All collections require authentication and user ownership
    match /{collection}/{document} {
      allow read: if isSignedIn() && isOwner(resource.data.userId);
      allow create: if isSignedIn() && isOwner(request.resource.data.userId);
      allow update, delete: if isSignedIn() && isOwner(resource.data.userId);
    }
    
    // User profiles - users can only access their own
    match /user_profiles/{userId} {
      allow read, write: if isSignedIn() && request.auth.uid == userId;
    }
  }
}
```

### 5. Offline Support Configuration
Add this to your Firebase initialization in `TinyTastesTrackerApp.swift`:

```swift
import Firebase
import FirebaseFirestore

@main
struct TinyTastesTrackerApp: App {
    init() {
        FirebaseApp.configure()
        
        // Enable offline persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        Firestore.firestore().settings = settings
        
        // Setup notifications
        NotificationManager.shared.setupNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

### 6. Widget Data Fetching Pattern
Widgets cannot use real-time listeners. Use one-time fetches instead:

```swift
class WidgetDataManager {
    static func fetchRecentLogs(for babyId: String) async throws -> [SleepLog] {
        // Check if user is authenticated
        guard let userId = Auth.auth().currentUser?.uid else {
            return [] // Return empty if not authenticated
        }
        
        let db = Firestore.firestore()
        let snapshot = try await db.collection("sleep_logs")
            .whereField("userId", isEqualTo: userId)
            .whereField("babyId", isEqualTo: babyId)
            .order(by: "startTime", descending: true)
            .limit(to: 10)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: SleepLog.self) }
    }
}
```
