# CloudKit Family Sharing Implementation Plan

**Status**: Planning Phase
**Priority**: High (Production Blocker)
**Estimated Effort**: 2-3 weeks
**Last Updated**: 2026-01-24

## Executive Summary

This document outlines the implementation plan for real-time, cross-account CloudKit family sharing in Tiny Tastes Tracker. The current JSON export/import approach is a temporary workaround. For production, we need true CloudKit sharing that allows two parents with different iCloud accounts to collaborate in real-time on the same baby profile.

## Problem Statement

**Current State**:
- SwiftData with automatic CloudKit sync (`.automatic`)
- JSON export/import for cross-account sharing
- No real-time collaboration between different iCloud accounts

**Desired State**:
- CKShare-based family sharing
- Real-time sync between different iCloud accounts
- UICloudSharingController for native iOS sharing UX
- Proper participant management

**Key Challenge**: SwiftData's `.automatic` CloudKit integration doesn't expose CKShare APIs needed for cross-account sharing.

## Architecture Overview

### Current Architecture
```
SwiftData ModelContext
    ↓
ModelConfiguration(cloudKitDatabase: .automatic)
    ↓
Automatic CloudKit Sync (Black Box)
```

### Proposed Architecture
```
SwiftData ModelContext
    ↓
NSPersistentCloudKitContainer (Custom)
    ↓
Private Database + Shared Database
    ↓
CKShare for cross-account collaboration
```

## Implementation Plan

### Phase 1: Core Data + CloudKit Foundation (Week 1)

#### 1.1 Migrate to NSPersistentCloudKitContainer

**Current Implementation** (`SharedModelContainer.swift`):
```swift
let cloudKitConfig = ModelConfiguration(
    schema: schema,
    url: containerURL,
    cloudKitDatabase: .automatic  // ❌ Too abstracted
)
```

**New Implementation**:
```swift
import CoreData
import CloudKit

class PersistentContainer: NSPersistentCloudKitContainer {

    static let shared = PersistentContainer()

    private init() {
        // Define schema
        let schema = Schema([
            UserProfile.self,
            MealLog.self,
            TriedFoodLog.self,
            // ... all other models
        ])

        // Create model configuration
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        // Get container URL
        let appGroupID = "group.com.tinytastes.tracker"
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("TinyTastesTracker.sqlite") else {
            fatalError("Unable to get container URL")
        }

        // Create store description
        let storeDescription = NSPersistentStoreDescription(url: containerURL)

        // Configure CloudKit
        let cloudKitOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.tinytastes.tracker"
        )
        storeDescription.cloudKitContainerOptions = cloudKitOptions

        // Initialize container
        super.init(name: "TinyTastesTracker", managedObjectModel: /* NSManagedObjectModel */)

        persistentStoreDescriptions = [storeDescription]

        loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }

        // Enable automatic merging
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
```

**Tasks**:
- [ ] Create new `PersistentContainer.swift` class
- [ ] Convert SwiftData schema to Core Data NSManagedObjectModel
- [ ] Set up private + shared database configuration
- [ ] Test basic CloudKit sync with new container
- [ ] Verify app group access for widget

**Risks**:
- Breaking change - requires data migration
- SwiftData models need Core Data equivalents
- Potential data loss if migration fails

---

#### 1.2 Create Core Data Model Definitions

SwiftData models need to be replicated as Core Data entities. Create a new `.xcdatamodeld` file.

**Example: UserProfile Entity**
```xml
<entity name="UserProfile" representedClassName="UserProfileManagedObject">
    <attribute name="id" attributeType="UUID" usesScalarValueType="NO"/>
    <attribute name="babyName" attributeType="String"/>
    <attribute name="birthDate" attributeType="Date" usesScalarValueType="NO"/>
    <attribute name="gender" attributeType="String"/>
    <attribute name="knownAllergies" attributeType="Transformable" valueTransformerName="NSSecureUnarchiveFromData"/>
    <attribute name="preferredMode" attributeType="String" optional="YES"/>

    <!-- Relationships -->
    <relationship name="mealLogs" toMany="YES" destinationEntity="MealLog" inverseName="userProfile"/>
    <relationship name="triedFoodLogs" toMany="YES" destinationEntity="TriedFoodLog" inverseName="userProfile"/>
    <!-- ... all other relationships -->
</entity>
```

**Tasks**:
- [ ] Create `TinyTastesTracker.xcdatamodeld` file
- [ ] Define all entities (UserProfile, MealLog, TriedFoodLog, etc.)
- [ ] Set up relationships and delete rules
- [ ] Configure CloudKit attributes (record zones, indexes)
- [ ] Generate NSManagedObject subclasses

**Critical**: Maintain exact same data structure to enable migration from SwiftData.

---

#### 1.3 Implement Data Migration Strategy

**Migration Approach**: Export SwiftData → Import to Core Data

```swift
class DataMigrationService {

    func migrateFromSwiftDataToCoreData() async throws {
        // 1. Export all SwiftData models to JSON
        let swiftDataContext = /* existing ModelContext */
        let userProfiles = try swiftDataContext.fetch(FetchDescriptor<UserProfile>())

        // 2. Create backup
        let backupURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("migration-backup.json")
        let encoder = JSONEncoder()
        let backupData = try encoder.encode(userProfiles)
        try backupData.write(to: backupURL)

        // 3. Import into Core Data
        let coreDataContext = PersistentContainer.shared.viewContext

        for profile in userProfiles {
            let managedProfile = UserProfileManagedObject(context: coreDataContext)
            managedProfile.id = profile.id
            managedProfile.babyName = profile.babyName
            managedProfile.birthDate = profile.birthDate
            // ... map all properties
        }

        try coreDataContext.save()

        // 4. Verify migration
        let migratedCount = try coreDataContext.count(for: UserProfileManagedObject.fetchRequest())
        guard migratedCount == userProfiles.count else {
            throw MigrationError.countMismatch
        }
    }

    func rollbackMigration() async throws {
        // Restore from backup if migration fails
    }
}
```

**Tasks**:
- [ ] Implement migration service
- [ ] Create backup/restore functionality
- [ ] Add migration UI (progress indicator, error handling)
- [ ] Test migration with sample data
- [ ] Test rollback on migration failure

**Critical Path**: Migration must be bulletproof - data loss is unacceptable.

---

### Phase 2: CKShare Implementation (Week 2)

#### 2.1 Implement Share Creation

```swift
import CloudKit
import CoreData

class CloudKitShareService: ObservableObject {

    let container: CKContainer
    let persistentContainer: NSPersistentCloudKitContainer

    @Published var activeShares: [CKShare] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        self.container = CKContainer(identifier: "iCloud.com.tinytastes.tracker")
        self.persistentContainer = PersistentContainer.shared
    }

    // MARK: - Share Creation

    func createShare(for profile: UserProfileManagedObject) async throws -> (CKShare, CKContainer) {
        guard let persistentStore = profile.objectID.persistentStore else {
            throw ShareError.invalidProfile
        }

        // Create share using NSPersistentCloudKitContainer
        let (_, share, _) = try await persistentContainer.share(
            [profile],
            to: persistentStore
        )

        // Configure share properties
        share[CKShare.SystemFieldKey.title] = profile.babyName
        share.publicPermission = .none

        // Set participant permissions
        share[CKShare.SystemFieldKey.shareType] = "com.tinytastes.tracker.profile"

        // Save share
        try await persistentContainer.viewContext.save()

        return (share, container)
    }

    // MARK: - Share Management

    func fetchShares(for profile: UserProfileManagedObject) async throws -> [CKShare] {
        guard let persistentStore = profile.objectID.persistentStore else {
            return []
        }

        let shares = try await persistentContainer.fetchShares(
            matching: [profile.objectID]
        )

        return Array(shares.values)
    }

    func stopSharing(_ share: CKShare) async throws {
        try await persistentContainer.purgeObjectsAndRecordsInZone(
            with: share.recordID.zoneID
        )
    }

    func removeParticipant(_ participant: CKShare.Participant, from share: CKShare) async throws {
        share.removeParticipant(participant)
        try await persistentContainer.viewContext.save()
    }
}
```

**Tasks**:
- [ ] Implement `CloudKitShareService`
- [ ] Create share creation UI flow
- [ ] Add error handling for CloudKit errors
- [ ] Test share creation with real iCloud accounts
- [ ] Verify share appears in CloudKit Dashboard

---

#### 2.2 Implement UICloudSharingController Integration

```swift
import SwiftUI
import CloudKit
import UIKit

struct CloudKitSharingViewController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let profile: UserProfileManagedObject

    func makeUIViewController(context: Context) -> UICloudSharingController {
        // Create sharing controller
        let sharingController = UICloudSharingController(
            share: share,
            container: container
        )

        sharingController.delegate = context.coordinator
        sharingController.availablePermissions = [.allowPrivate, .allowReadWrite]

        return sharingController
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let parent: CloudKitSharingViewController

        init(_ parent: CloudKitSharingViewController) {
            self.parent = parent
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            print("Failed to save share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            return parent.profile.babyName
        }
    }
}
```

**SwiftUI Integration**:
```swift
struct SettingsPage: View {
    @State private var showingShareSheet = false
    @State private var activeShare: (CKShare, CKContainer)?

    var body: some View {
        Button("Share Profile") {
            Task {
                let (share, container) = try await shareService.createShare(for: profile)
                activeShare = (share, container)
                showingShareSheet = true
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let (share, container) = activeShare {
                CloudKitSharingViewController(
                    share: share,
                    container: container,
                    profile: profile
                )
            }
        }
    }
}
```

**Tasks**:
- [ ] Create `CloudKitSharingViewController`
- [ ] Implement delegate methods
- [ ] Integrate into SettingsPage
- [ ] Test share sheet presentation
- [ ] Test sending share via Messages/Mail

---

#### 2.3 Implement Share Acceptance

Share acceptance happens when a user taps a share link.

**App Delegate / Scene Delegate**:
```swift
import UIKit
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Handle share acceptance from cold launch
        if let userActivity = connectionOptions.userActivities.first {
            handleIncomingShare(userActivity: userActivity)
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // Handle share acceptance while app is running
        handleIncomingShare(userActivity: userActivity)
    }

    private func handleIncomingShare(userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return
        }

        Task {
            await acceptShare(from: url)
        }
    }

    private func acceptShare(from url: URL) async {
        do {
            // Fetch share metadata
            let container = CKContainer(identifier: "iCloud.com.tinytastes.tracker")

            let metadata = try await withCheckedThrowingContinuation { continuation in
                let operation = CKFetchShareMetadataOperation(shareURLs: [url])

                operation.perShareMetadataResultBlock = { url, result in
                    switch result {
                    case .success(let metadata):
                        continuation.resume(returning: metadata)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }

                operation.fetchShareMetadataResultBlock = { result in
                    if case .failure(let error) = result {
                        continuation.resume(throwing: error)
                    }
                }

                container.add(operation)
            }

            // Accept the share
            let acceptedShare = try await container.accept(metadata)

            print("✅ Successfully accepted share: \(acceptedShare.recordID)")

            // Trigger UI update
            NotificationCenter.default.post(name: .didAcceptShare, object: acceptedShare)

        } catch {
            print("❌ Failed to accept share: \(error)")
        }
    }
}

extension Notification.Name {
    static let didAcceptShare = Notification.Name("didAcceptShare")
}
```

**Tasks**:
- [ ] Implement share acceptance in SceneDelegate
- [ ] Handle share URLs from Messages/Mail
- [ ] Show acceptance confirmation UI
- [ ] Test share acceptance flow
- [ ] Handle edge cases (already accepted, permission denied)

---

### Phase 3: Share Management UI (Week 2-3)

#### 3.1 Active Shares View

```swift
struct ShareManagementView: View {
    @StateObject private var shareService = CloudKitShareService()
    @State private var shares: [ShareViewModel] = []

    var body: some View {
        List {
            if shares.isEmpty {
                EmptyStateView()
            } else {
                ForEach(shares) { shareVM in
                    ShareRow(viewModel: shareVM) {
                        await showParticipants(for: shareVM.share)
                    } onStop: {
                        await stopSharing(shareVM.share)
                    }
                }
            }
        }
        .task {
            await loadShares()
        }
    }

    private func loadShares() async {
        // Fetch all profiles
        let profiles = try? await fetchProfiles()

        // For each profile, fetch its shares
        for profile in profiles ?? [] {
            if let profileShares = try? await shareService.fetchShares(for: profile) {
                shares.append(contentsOf: profileShares.map {
                    ShareViewModel(share: $0, profile: profile)
                })
            }
        }
    }
}

struct ShareViewModel: Identifiable {
    let id: String
    let share: CKShare
    let profile: UserProfileManagedObject

    init(share: CKShare, profile: UserProfileManagedObject) {
        self.id = share.recordID.recordName
        self.share = share
        self.profile = profile
    }

    var title: String {
        share[CKShare.SystemFieldKey.title] as? String ?? "Unknown"
    }

    var participantCount: Int {
        share.participants.count - 1 // Exclude owner
    }

    var participants: [CKShare.Participant] {
        share.participants.filter { $0 != share.owner }
    }
}
```

**Tasks**:
- [ ] Create `ShareManagementView`
- [ ] Implement share listing
- [ ] Add pull-to-refresh
- [ ] Show loading states
- [ ] Handle empty state

---

#### 3.2 Participant Management

```swift
struct ParticipantListView: View {
    let share: CKShare
    @StateObject private var shareService = CloudKitShareService()

    var body: some View {
        List {
            Section("Owner") {
                if let owner = share.owner {
                    ParticipantRow(participant: owner, isOwner: true)
                }
            }

            Section("Participants") {
                ForEach(share.participants.filter { $0 != share.owner }, id: \.userIdentity.userRecordID) { participant in
                    ParticipantRow(participant: participant, isOwner: false)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    try await shareService.removeParticipant(participant, from: share)
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

struct ParticipantRow: View {
    let participant: CKShare.Participant
    let isOwner: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(participant.userIdentity.nameComponents?.formatted() ?? "Unknown")
                    .font(.headline)

                HStack {
                    if isOwner {
                        Text("Owner")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    Text(permissionText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if participant.acceptanceStatus == .pending {
                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if participant.acceptanceStatus == .accepted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }

    private var permissionText: String {
        switch participant.permission {
        case .readOnly: return "Can View"
        case .readWrite: return "Can Edit"
        case .none: return "No Access"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}
```

**Tasks**:
- [ ] Create `ParticipantListView`
- [ ] Show participant status (pending/accepted)
- [ ] Implement remove participant
- [ ] Show permission levels
- [ ] Handle participant changes in real-time

---

### Phase 4: Testing & Validation (Week 3)

#### 4.1 Unit Tests

```swift
import XCTest
@testable import TinyTastesTracker

class CloudKitSharingTests: XCTestCase {

    var shareService: CloudKitShareService!
    var testProfile: UserProfileManagedObject!

    override func setUp() async throws {
        shareService = CloudKitShareService()

        // Create test profile
        let context = PersistentContainer.shared.viewContext
        testProfile = UserProfileManagedObject(context: context)
        testProfile.id = UUID()
        testProfile.babyName = "Test Baby"
        testProfile.birthDate = Date()
        try context.save()
    }

    func testShareCreation() async throws {
        let (share, container) = try await shareService.createShare(for: testProfile)

        XCTAssertNotNil(share)
        XCTAssertEqual(share[CKShare.SystemFieldKey.title] as? String, "Test Baby")
        XCTAssertEqual(share.publicPermission, .none)
    }

    func testFetchShares() async throws {
        // Create share
        _ = try await shareService.createShare(for: testProfile)

        // Fetch shares
        let shares = try await shareService.fetchShares(for: testProfile)

        XCTAssertEqual(shares.count, 1)
    }

    func testRemoveParticipant() async throws {
        // Create share
        let (share, _) = try await shareService.createShare(for: testProfile)

        // Add mock participant
        let participant = CKShare.Participant()
        share.addParticipant(participant)

        // Remove participant
        try await shareService.removeParticipant(participant, from: share)

        // Verify removed
        XCTAssertFalse(share.participants.contains(participant))
    }
}
```

**Test Coverage**:
- [ ] Share creation
- [ ] Share fetching
- [ ] Participant management
- [ ] Share acceptance
- [ ] Error handling
- [ ] Edge cases (offline, permissions)

---

#### 4.2 Integration Tests

**Test Scenarios**:

1. **Happy Path - Complete Sharing Flow**
   - [ ] Parent A creates profile
   - [ ] Parent A shares with Parent B
   - [ ] Parent B receives share link
   - [ ] Parent B accepts share
   - [ ] Both see same data
   - [ ] Parent B makes edit
   - [ ] Parent A sees edit (real-time sync)

2. **Permission Tests**
   - [ ] Read-only participant cannot edit
   - [ ] Read-write participant can edit
   - [ ] Owner can remove participants
   - [ ] Participant cannot remove others

3. **Offline Tests**
   - [ ] Edits while offline queue for sync
   - [ ] Sync resumes when online
   - [ ] Conflict resolution works correctly

4. **Edge Cases**
   - [ ] Accepting already accepted share
   - [ ] Removing last participant
   - [ ] Owner removes self
   - [ ] Share with deleted profile

---

#### 4.3 Manual Testing Checklist

**Device Requirements**: 2 physical iOS devices with different iCloud accounts

**Test Plan**:

| Step | Device A | Device B | Expected Result |
|------|----------|----------|-----------------|
| 1 | Sign in with iCloud Account A | Sign in with iCloud Account B | ✅ Both signed in |
| 2 | Create baby profile "Emma" | - | ✅ Profile created |
| 3 | Add meal log entry | - | ✅ Entry added |
| 4 | Tap "Share Profile" | - | ✅ Share sheet appears |
| 5 | Send via Messages to Device B | - | ✅ Message sent |
| 6 | - | Receive message | ✅ Message received |
| 7 | - | Tap share link | ✅ Acceptance prompt |
| 8 | - | Accept share | ✅ Profile appears |
| 9 | - | Verify meal log is visible | ✅ Data synced |
| 10 | - | Add new meal log | ✅ Entry added |
| 11 | Wait for sync (~5 sec) | - | ✅ New entry appears on Device A |
| 12 | Edit meal log | - | ✅ Edit saved |
| 13 | - | Verify edit appears | ✅ Changes synced |
| 14 | Open "Manage Sharing" | - | ✅ Shows 1 participant |
| 15 | Remove Device B participant | - | ✅ Participant removed |
| 16 | - | Verify access lost | ✅ Profile no longer visible |

---

### Phase 5: Migration & Deployment

#### 5.1 User Migration Flow

**Migration UI**:
```swift
struct MigrationView: View {
    @State private var migrationState: MigrationState = .notStarted
    @StateObject private var migrationService = DataMigrationService()

    enum MigrationState {
        case notStarted
        case inProgress(progress: Double)
        case completed
        case failed(Error)
    }

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("CloudKit Upgrade Available")
                .font(.title)
                .fontWeight(.bold)

            Text("Enable real-time family sharing with improved CloudKit sync.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            switch migrationState {
            case .notStarted:
                Button("Upgrade Now") {
                    Task {
                        await performMigration()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Maybe Later") {
                    // Dismiss
                }

            case .inProgress(let progress):
                ProgressView(value: progress)
                Text("\(Int(progress * 100))% complete")

            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Upgrade Complete!")

            case .failed(let error):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("Migration failed: \(error.localizedDescription)")

                Button("Retry") {
                    Task { await performMigration() }
                }
            }
        }
        .padding()
    }

    private func performMigration() async {
        migrationState = .inProgress(progress: 0)

        do {
            try await migrationService.migrate { progress in
                migrationState = .inProgress(progress: progress)
            }
            migrationState = .completed
        } catch {
            migrationState = .failed(error)
        }
    }
}
```

**Migration Trigger**:
- Show migration prompt on app launch (v2.0)
- Optional initially, required after 30 days
- Clear communication about benefits

---

#### 5.2 Rollout Strategy

**Phase 5.1: Beta Testing (2 weeks)**
- [ ] Deploy to TestFlight
- [ ] Invite 10-20 beta testers
- [ ] Monitor crash reports
- [ ] Gather feedback on UX
- [ ] Fix critical bugs

**Phase 5.2: Soft Launch (1 week)**
- [ ] Release to 10% of users
- [ ] Monitor CloudKit usage metrics
- [ ] Watch for sync errors
- [ ] Gradual rollout to 25%, 50%, 100%

**Phase 5.3: Full Deployment**
- [ ] Release to all users
- [ ] Monitor support requests
- [ ] Track adoption rate
- [ ] Celebrate! 🎉

---

## Technical Specifications

### CloudKit Schema

**Record Types**:
- `CD_UserProfile`
- `CD_MealLog`
- `CD_TriedFoodLog`
- `CD_Recipe`
- (All other entities)

**Zones**:
- `com.apple.coredata.cloudkit.zone` (Private)
- Custom shared zones for CKShare

**Indexes**:
- `modificationDate` (Queryable, Sortable)
- `id` (Unique)

### Performance Considerations

**CloudKit Quotas** (per user):
- Database size: 1 GB private, 1 GB shared
- Requests: 400 requests/second
- Bandwidth: 50 GB/month

**Optimization**:
- Batch operations where possible
- Use `NSPersistentCloudKitContainer`'s automatic batching
- Implement offline queue
- Cache frequently accessed data

### Error Handling

**Common CloudKit Errors**:
```swift
enum CloudKitError: Error {
    case notAuthenticated           // User not signed into iCloud
    case quotaExceeded             // Storage limit reached
    case networkUnavailable        // No internet connection
    case partialFailure            // Some records failed
    case zoneNotFound              // Shared zone deleted
    case permissionDenied          // User revoked permissions
}
```

**Handling Strategy**:
- Show user-friendly error messages
- Retry transient errors (network)
- Prompt user action for auth errors
- Log all errors for debugging

---

## Risks & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Data loss during migration | **Critical** | Low | Comprehensive backup, rollback plan, extensive testing |
| CloudKit quota exceeded | High | Medium | Implement data cleanup, warn users at 80% |
| Share acceptance failures | Medium | Medium | Detailed error messages, fallback to JSON export |
| Sync conflicts | Medium | High | Use Last-Write-Wins, show conflict UI for important data |
| Performance degradation | Medium | Low | Load testing, optimize queries, implement caching |
| User confusion | Low | High | Clear onboarding, help documentation, tooltips |

---

## Success Metrics

**Technical Metrics**:
- [ ] Migration success rate > 99%
- [ ] Share creation success rate > 95%
- [ ] Share acceptance success rate > 90%
- [ ] Sync latency < 5 seconds (p95)
- [ ] Zero data loss incidents

**User Metrics**:
- [ ] Family sharing adoption > 40%
- [ ] Share retention (30-day) > 80%
- [ ] Support tickets < 1% of users
- [ ] User satisfaction score > 4.5/5

---

## Alternative Approaches Considered

### 1. **Firebase Realtime Database**
**Pros**: Easier to implement, real-time out of box
**Cons**: Additional dependency, monthly costs, data not in Apple ecosystem
**Decision**: ❌ Rejected - prefer native CloudKit

### 2. **Custom Backend + API**
**Pros**: Full control, custom logic
**Cons**: Expensive, maintenance burden, scaling complexity
**Decision**: ❌ Rejected - not sustainable for small team

### 3. **Keep JSON Export Approach**
**Pros**: Already implemented, no migration needed
**Cons**: Poor UX, no real-time sync, not competitive
**Decision**: ❌ Rejected - not production-ready

---

## Resources & References

### Apple Documentation
- [NSPersistentCloudKitContainer](https://developer.apple.com/documentation/coredata/nspersistentcloudkitcontainer)
- [CKShare](https://developer.apple.com/documentation/cloudkit/ckshare)
- [UICloudSharingController](https://developer.apple.com/documentation/uikit/uicloudsharingcontroller)
- [CloudKit Best Practices](https://developer.apple.com/videos/play/wwdc2021/10086/)

### Sample Projects
- [CoreDataCloudKitShare](https://developer.apple.com/documentation/coredata/sharing_core_data_objects_between_icloud_users)
- [WWDC21 Sample Code](https://developer.apple.com/documentation/coredata/synchronizing_a_local_store_to_the_cloud)

### Tools
- CloudKit Console: https://icloud.developer.apple.com/dashboard
- CloudKit Logging: Enable CloudKit debug logging in Xcode
- Network Link Conditioner: Test offline scenarios

---

## Timeline

```
Week 1: Core Data Foundation
├─ Day 1-2: Create PersistentContainer
├─ Day 3-4: Define Core Data model
└─ Day 5-7: Implement migration

Week 2: CKShare Implementation
├─ Day 1-3: Share creation & UICloudSharingController
├─ Day 4-5: Share acceptance flow
└─ Day 6-7: Share management UI

Week 3: Testing & Polish
├─ Day 1-3: Unit & integration tests
├─ Day 4-5: Manual testing with real devices
├─ Day 6-7: Bug fixes & UI polish

Week 4: Deployment (if needed)
├─ Day 1-3: Beta testing
├─ Day 4-5: Soft launch
└─ Day 6-7: Full deployment
```

---

## Next Steps

**Immediate Actions**:
1. ✅ Review and approve this implementation plan
2. [ ] Set up CloudKit Console with proper schema
3. [ ] Create feature branch: `feature/cloudkit-sharing`
4. [ ] Start Phase 1: Core Data migration
5. [ ] Schedule weekly progress reviews

**Questions to Answer**:
- [ ] What's the target release date?
- [ ] Do we need legal review for data sharing?
- [ ] Should migration be optional or required?
- [ ] What's the support plan for migration issues?

---

## Appendix A: Code Migration Checklist

**SwiftData → Core Data Mapping**:

| SwiftData | Core Data |
|-----------|-----------|
| `@Model` | `NSManagedObject` subclass |
| `@Attribute` | `@NSManaged var` |
| `@Relationship` | `NSSet` or custom accessor |
| `ModelContext` | `NSManagedObjectContext` |
| `ModelConfiguration` | `NSPersistentStoreDescription` |
| `@Query` | `NSFetchRequest` |

**Files to Create**:
- [ ] `TinyTastesTracker.xcdatamodeld`
- [ ] `PersistentContainer.swift`
- [ ] `CloudKitShareService.swift`
- [ ] `DataMigrationService.swift`
- [ ] `CloudKitSharingViewController.swift`
- [ ] `MigrationView.swift`
- [ ] All NSManagedObject subclasses

**Files to Update**:
- [ ] `AppState.swift` - use Core Data context
- [ ] All view models - fetch from Core Data
- [ ] All views with `@Query` - use FetchedResultsController
- [ ] `SharedModelContainer.swift` - remove or deprecate

---

## Appendix B: Testing Devices

**Recommended Test Devices**:
- iPhone 14 Pro (iOS 17) - Parent A
- iPhone 12 (iOS 16) - Parent B
- iPad Air (iOS 17) - Tablet testing

**iCloud Accounts**:
- Test Account A: `parent.a@icloud.com`
- Test Account B: `parent.b@icloud.com`

---

## Contact & Support

**Implementation Lead**: TBD
**Code Review**: TBD
**QA Lead**: TBD

**Questions?** Create an issue in GitHub or contact the team.

---

**Document Version**: 1.0
**Last Updated**: 2026-01-24
**Status**: Ready for Review ✅
