# Data Handling Documentation

**Last Updated:** January 12, 2026  
**Audience:** Developers, Technical Contributors, Security Auditors

## Overview

This document provides technical details about how Tiny Tastes Tracker collects, stores, processes, and deletes user data. It complements the user-facing [PRIVACY_POLICY.md](PRIVACY_POLICY.md) and is intended for developers working on the codebase.

## Table of Contents

1. [Data Architecture](#data-architecture)
2. [Data Models](#data-models)
3. [Data Storage](#data-storage)
4. [Data Flow](#data-flow)
5. [Third-Party Integrations](#third-party-integrations)
6. [Data Deletion](#data-deletion)
7. [Data Export](#data-export)
8. [Security Measures](#security-measures)
9. [Privacy Best Practices](#privacy-best-practices)

---

## Data Architecture

### Storage Layers

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface                        │
│  (SwiftUI Views - ContentView, TrackerPage, etc.)       │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  State Management                        │
│  (AppState, ProfileManager, RecipeManager, etc.)        │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                   Local Storage                          │
│         (SwiftData - SQLite Database)                    │
│  • UserProfile    • MealLog      • Recipe                │
│  • SleepLog       • DiaperLog    • MealPlan              │
│  • BottleLog      • GrowthEntry  • ShoppingListItem      │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              External Services (Optional)                │
│  • Google Gemini AI (AI features)                        │
│  • Open Food Facts API (nutrition data)                  │
│  • Apple EventKit (shopping list sync)                   │
└─────────────────────────────────────────────────────────┘
```

### Data Flow Principles

1. **Local-First**: All user data is stored locally on the device by default
2. **Explicit Consent**: External services are only used when user actively engages features
3. **Minimal Data Sharing**: Only necessary data is sent to third-party services
4. **No Central Server**: The app does not have a backend server collecting user data

---

## Data Models

All data models use SwiftData's `@Model` macro for persistence. Below are the primary models and the data they contain:

### User Profile Data

**Model:** `UserProfile.swift`

```swift
@Model
class UserProfile {
    var name: String                    // Child's name
    var dateOfBirth: Date              // Birth date
    var gender: String                 // Gender
    var birthWeight: Double?           // Birth weight (kg)
    var birthLength: Double?           // Birth length (cm)
    var birthHeadCircumference: Double? // Birth head circumference (cm)
    var allergens: [String]            // Known allergens
    var substitutedFoods: [String: String] // Allergen substitutions
    var profileImageData: Data?        // Profile photo (optional)
    var isActive: Bool                 // Active profile flag
}
```

**Sensitive Data:**
- Child's name (PII)
- Date of birth (PII)
- Health data (birth measurements, allergens)
- Photos (if provided)

**Storage:** Local SwiftData database  
**Retention:** Until user deletes profile or app  
**Backup:** Included in iCloud/iTunes backups (encrypted)

---

### Health & Activity Tracking

#### Meal Logs
**Model:** `MealLog.swift`

```swift
@Model
class MealLog {
    var timestamp: Date                // When meal occurred
    var foodName: String              // Food eaten
    var foodCategory: FoodCategory    // Category (fruit, vegetable, etc.)
    var portion: String               // Portion size
    var reaction: String?             // Child's reaction
    var notes: String?                // Additional notes
    var feedingStrategy: FeedingStrategy? // BLW, puree, etc.
    var photoData: Data?              // Meal photo (optional)
}
```

**Sensitive Data:** Health data (food intake, reactions)  
**Photos:** Stored as binary data in SwiftData (`.externalStorage`)

#### Sleep Logs
**Model:** `SleepLog.swift`

```swift
@Model
class SleepLog {
    var startTime: Date               // Sleep start
    var endTime: Date                 // Sleep end
    var duration: TimeInterval        // Calculated duration
    var quality: String?              // Sleep quality notes
    var notes: String?                // Additional notes
}
```

**Sensitive Data:** Health data (sleep patterns)

#### Diaper Logs
**Model:** `DiaperLog.swift`

```swift
@Model
class DiaperLog {
    var timestamp: Date               // Diaper change time
    var type: DiaperType             // Wet, dirty, both
    var notes: String?               // Additional notes
}
```

**Sensitive Data:** Health data (elimination patterns)

#### Bottle Logs
**Model:** `BottleLog.swift`

```swift
@Model
class BottleLog {
    var timestamp: Date               // Feeding time
    var amount: Double                // Amount in oz/ml
    var type: String                  // Formula, breast milk, etc.
    var notes: String?                // Additional notes
}
```

**Sensitive Data:** Health data (feeding patterns)

#### Growth Entries
**Model:** `GrowthEntry.swift`

```swift
@Model
class GrowthEntry {
    var date: Date                    // Measurement date
    var weight: Double?               // Weight (kg)
    var height: Double?               // Height (cm)
    var headCircumference: Double?    // Head circumference (cm)
    var notes: String?                // Additional notes
}
```

**Sensitive Data:** Health data (growth measurements)

---

### Recipes & Meal Planning

#### Recipe
**Model:** `Recipe.swift`

```swift
@Model
class Recipe {
    var title: String                 // Recipe name
    var ingredients: [String]         // Ingredient list
    var instructions: [String]        // Cooking steps
    var servings: Int                 // Number of servings
    var prepTime: Int?                // Prep time (minutes)
    var cookTime: Int?                // Cook time (minutes)
    var tags: [String]                // Recipe tags
    var imageData: Data?              // Recipe photo (optional)
    var source: String?               // Recipe source
}
```

**Sensitive Data:** User-created content  
**Photos:** Stored as binary data (`.externalStorage`)

#### Meal Plan
**Model:** `MealPlan.swift`

```swift
@Model
class MealPlan {
    var startDate: Date               // Plan start date
    var endDate: Date                 // Plan end date
    var meals: [PlannedMeal]          // Planned meals
    var shoppingList: [ShoppingListItem] // Shopping list
}
```

**Sensitive Data:** User preferences and planning data

---

## Data Storage

### SwiftData (Local SQLite Database)

**Location:** App's Documents directory (sandboxed)  
**Path:** `~/Library/Application Support/[App Bundle ID]/`  
**Encryption:** iOS file-level encryption (when device is locked)  
**Access:** Only accessible by the app (iOS sandbox)

#### Storage Configuration

```swift
// ModelContainer configuration
let container = try ModelContainer(
    for: UserProfile.self, 
        MealLog.self, 
        SleepLog.self,
        // ... other models
    configurations: ModelConfiguration(
        isStoredInMemoryOnly: false,  // Persist to disk
        allowsSave: true
    )
)
```

#### Image Storage

Large binary data (photos) uses `.externalStorage` attribute:

```swift
@Attribute(.externalStorage) 
var photoData: Data?
```

**Benefits:**
- Prevents database bloat
- Stores images as separate files
- Better performance for large datasets

**Considerations:**
- Images are still in the app's sandbox
- Deleted when app is deleted
- Included in backups

---

## Data Flow

### Local Data Flow (No Network)

```
User Action (e.g., log meal)
    ↓
SwiftUI View (MealLogSheet)
    ↓
AppState/Manager (ToddlerManager)
    ↓
SwiftData ModelContext.insert()
    ↓
Local SQLite Database
    ↓
Encrypted iOS Backup (iCloud/iTunes)
```

**Network:** None  
**Third-Party:** None  
**Privacy:** Maximum (data never leaves device)

---

### AI Feature Data Flow (Network Required)

#### Sage AI Chat

```
User Question
    ↓
SageChatView
    ↓
GeminiService.sendMessage()
    ↓
[NETWORK] → Google Gemini API
    ↓
AI Response
    ↓
Display in Chat (not stored)
```

**Data Sent to Google:**
- User's question text
- Child's age (for context)
- Child's allergens (for safety)
- Conversation history (current session only)

**Data NOT Sent:**
- Child's name
- Specific meal logs or sleep data
- Photos (unless user explicitly shares for analysis)

**Storage:**
- Conversation history: In-memory only (cleared on app restart)
- Google's retention: Per Gemini API terms (~30 days)

#### Food Photo Analysis

```
User Takes/Uploads Photo
    ↓
RecipeScannerSheet / FoodAnalysisView
    ↓
RecipeOCRService / GeminiService
    ↓
[NETWORK] → Google Gemini Vision API
    ↓
Structured Response (recipe or food info)
    ↓
User Reviews & Saves (optional)
    ↓
Local SwiftData Database
```

**Data Sent to Google:**
- Photo (JPEG, resized to max 1024x1024)
- Child's age and allergens (for context)

**Data NOT Sent:**
- Child's name
- Location metadata (stripped from photos)

---

### Third-Party API Calls

#### Open Food Facts (Barcode Scanning)

```
User Scans Barcode
    ↓
BarcodeScannerView
    ↓
OpenFoodFactsService.fetchProduct(barcode)
    ↓
[NETWORK] → https://world.openfoodfacts.org/api/v0/product/{barcode}
    ↓
Nutrition Data Response
    ↓
Display in UI (not automatically saved)
```

**Data Sent:**
- Barcode number only (e.g., "012345678901")

**Data NOT Sent:**
- User identity
- Child information
- Purchase history

**Privacy:** Open Food Facts is a non-profit open database. Requests are anonymous.

#### Apple EventKit (Shopping List Export)

```
User Taps "Export to Reminders"
    ↓
RemindersIntegrationManager.exportToReminders()
    ↓
Request EventKit Permission
    ↓
Create/Find "Tiny Tastes Shopping" List
    ↓
Add Shopping Items as Reminders
    ↓
[LOCAL] → iOS Reminders App
    ↓
[OPTIONAL] → iCloud Sync (user's choice)
```

**Data Sent:**
- Shopping list items (ingredient names, quantities)

**Storage:**
- User's iCloud account (if iCloud Reminders enabled)
- Controlled by iOS Settings, not the app

---

## Third-Party Integrations

### Google Gemini AI

**Purpose:** AI-powered recommendations, food analysis, voice chat  
**SDK:** `GoogleGenerativeAI` Swift package  
**API Key Storage:** Obfuscated (XOR cipher + Base64), see [SECURITY_IMPLEMENTATION.md](SECURITY_IMPLEMENTATION.md)

**Data Sent:**
| Feature | Data Sent | Retention |
|---------|-----------|-----------|
| Sage Chat | Questions, child's age/allergens, conversation history | ~30 days (Google's policy) |
| Food Analysis | Photos, child's age/allergens | ~30 days |
| Recipe OCR | Recipe photos | ~30 days |
| Voice Chat | Audio (streamed, not stored) | Real-time processing only |

**Privacy Controls:**
- Rate limiting (10/min, 100/hour, 1000/day)
- Usage monitoring and anomaly detection
- No automatic data sending (user must initiate)

**User Opt-Out:**
- Don't use Sage AI features
- Core tracking features work entirely offline

---

### Open Food Facts

**Purpose:** Nutrition data for packaged foods  
**API:** REST API (no SDK)  
**Authentication:** None (public API)

**Data Sent:**
- Barcode numbers only

**Privacy:**
- No user tracking
- No authentication required
- Open-source, non-profit project

---

### Apple EventKit

**Purpose:** Shopping list export to iOS Reminders  
**Framework:** `EventKit.framework`  
**Permission:** `NSRemindersUsageDescription` in Info.plist

**Data Sent:**
- Shopping list items (if user chooses to export)

**Privacy:**
- User controls via iOS Settings
- Data stays in user's iCloud account
- App cannot access other reminders

---

## Data Deletion

### User-Initiated Deletion

Users can delete data through the app's Privacy Settings:

#### Delete Specific Data Types

**Implementation:** `DataDeletionService.swift`

```swift
func deleteMealLogs() async throws {
    let descriptor = FetchDescriptor<MealLog>()
    let logs = try modelContext.fetch(descriptor)
    for log in logs {
        modelContext.delete(log)
    }
    try modelContext.save()
}
```

**Available Deletion Options:**
- Meal logs
- Sleep logs
- Diaper logs
- Bottle logs
- Growth data
- Recipes
- Meal plans
- Shopping lists
- User profiles

#### Delete All Data

```swift
func deleteAllData() async throws {
    try await deleteMealLogs()
    try await deleteSleepLogs()
    try await deleteDiaperLogs()
    try await deleteBottleLogs()
    try await deleteGrowthData()
    try await deleteRecipes()
    try await deleteMealPlans()
    try await deleteUserProfiles()
    
    try modelContext.save()
}
```

**Warning:** Deletion is permanent and cannot be undone (unless user has a backup).

---

### App Deletion

When the user deletes the app:

1. **Local Data:** All SwiftData files are deleted by iOS
2. **Photos:** All stored images are deleted
3. **Preferences:** UserDefaults are cleared
4. **Backups:** Data remains in iCloud/iTunes backups until backup is deleted

**Third-Party Data:**
- Google Gemini: Data sent to API is retained per Google's policy (~30 days)
- Open Food Facts: No user data is stored
- Apple Reminders: Shopping lists remain in Reminders app (user must delete manually)

---

## Data Export

### GDPR Compliance (Right to Data Portability)

**Implementation:** `DataExportService.swift`

#### JSON Export

```swift
func exportAllData(format: ExportFormat) async throws -> URL {
    let exportData = ExportData(
        profiles: try modelContext.fetch(FetchDescriptor<UserProfile>()),
        mealLogs: try modelContext.fetch(FetchDescriptor<MealLog>()),
        sleepLogs: try modelContext.fetch(FetchDescriptor<SleepLog>()),
        // ... other data types
    )
    
    let jsonData = try JSONEncoder().encode(exportData)
    let fileURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("TinyTastesExport_\(Date().ISO8601Format()).json")
    try jsonData.write(to: fileURL)
    
    return fileURL
}
```

**Export Includes:**
- All user profiles
- All meal, sleep, diaper, bottle logs
- All growth measurements
- All recipes and meal plans
- All shopping lists
- Metadata (export date, app version)

**Export Excludes:**
- Photos (too large for JSON, available separately)
- Conversation history (not stored)

#### CSV Export

Similar to JSON, but formatted as CSV files (one per data type):
- `profiles.csv`
- `meal_logs.csv`
- `sleep_logs.csv`
- etc.

**Use Cases:**
- Import into Excel/Google Sheets
- Transfer to another app
- Personal backup
- GDPR data portability request

---

## Security Measures

### API Key Protection

**Problem:** Gemini API key must be embedded in the app, but shouldn't be easily extractable.

**Solution:** Three-layer security (see [SECURITY_IMPLEMENTATION.md](SECURITY_IMPLEMENTATION.md))

1. **SecureAPIKeyManager**: XOR cipher + Base64 obfuscation
2. **APIRateLimiter**: Prevents quota exhaustion
3. **APIUsageMonitor**: Detects anomalies

**Limitations:**
- Obfuscation is NOT encryption
- Determined attackers can extract the key
- **Production apps should use a backend proxy**

---

### Data Encryption

#### At Rest
- iOS file-level encryption (when device is locked)
- SwiftData database is encrypted by iOS
- Protected by device passcode/biometric

#### In Transit
- All network requests use HTTPS/TLS
- Google Gemini API: TLS 1.2+
- Open Food Facts API: HTTPS

---

### Permissions

**Required Permissions:**
- **Camera**: For barcode scanning and meal photos
- **Photo Library**: For uploading existing photos

**Optional Permissions:**
- **Reminders**: For shopping list export (user can decline)

**Not Required:**
- Location
- Contacts
- Microphone (voice chat uses system audio)
- Notifications (not yet implemented)

---

## Privacy Best Practices

### For Developers Adding New Features

#### 1. **Minimize Data Collection**
- Only collect data necessary for the feature
- Don't collect data "just in case" it might be useful later

#### 2. **Local-First Architecture**
- Store data locally whenever possible
- Only use network for features that require it (AI, nutrition lookup)

#### 3. **Explicit User Consent**
- Don't send data to third parties without user action
- Make it clear when data will leave the device

#### 4. **Anonymize When Possible**
- Don't send child's name to APIs (use age instead)
- Strip metadata from photos before uploading

#### 5. **Provide Deletion Options**
- Every data type should have a deletion method
- Implement in `DataDeletionService.swift`

#### 6. **Document Data Flows**
- Update this document when adding new data models
- Update PRIVACY_POLICY.md when adding third-party services

#### 7. **Test Privacy Features**
- Test data export (verify all data is included)
- Test data deletion (verify data is actually removed)
- Test offline mode (ensure core features work without network)

---

### Code Review Checklist

When reviewing PRs that handle user data:

- [ ] Is the data stored locally (SwiftData) or sent to a server?
- [ ] If sent to a server, is it documented in PRIVACY_POLICY.md?
- [ ] Is the data necessary for the feature?
- [ ] Can the user delete this data?
- [ ] Is the data included in the export functionality?
- [ ] Are photos stripped of metadata before uploading?
- [ ] Is child's name excluded from API calls?
- [ ] Is error handling in place (don't log sensitive data)?

---

## Compliance Checklist

### COPPA (Children's Online Privacy Protection Act)

- [x] App is designed for parents (18+), not children
- [x] No direct data collection from children under 13
- [x] Parental consent implied (parent is the user)
- [x] Parents can delete child's data anytime
- [x] No behavioral advertising or tracking
- [x] Privacy policy clearly states data practices

### GDPR (General Data Protection Regulation)

- [x] **Right to Access**: Users can view all data in the app
- [x] **Right to Rectification**: Users can edit data anytime
- [x] **Right to Erasure**: Users can delete data anytime
- [x] **Right to Data Portability**: Users can export data (JSON/CSV)
- [x] **Right to Restrict Processing**: Users can avoid AI features
- [x] **Right to Object**: Users can contact us to object
- [x] **Data Minimization**: Only collect necessary data
- [x] **Purpose Limitation**: Data used only for stated purposes
- [x] **Storage Limitation**: Data retained only as long as needed (user controls)
- [x] **Transparency**: Privacy policy clearly explains practices

### App Store Requirements

- [x] Privacy policy created (PRIVACY_POLICY.md)
- [ ] Privacy policy hosted on public URL (TODO before submission)
- [ ] Privacy nutrition labels prepared (APP_STORE_PRIVACY.md)
- [x] Third-party SDKs disclosed (Google Gemini AI)
- [x] Data collection purposes documented
- [x] No tracking or advertising

---

## Incident Response

### Data Breach Procedure

If a security vulnerability is discovered:

1. **Assess Impact**: What data was exposed? How many users affected?
2. **Contain**: Release a patch ASAP
3. **Notify Users**: In-app alert and email (if we have contact info)
4. **Document**: Write incident report
5. **Comply with Laws**: GDPR requires notification within 72 hours

### Reporting Vulnerabilities

Security researchers can report vulnerabilities to:
- Email: security@tinytastestracker.com (placeholder)
- Response time: 48 hours
- Disclosure: Coordinated disclosure (90 days)

---

## Future Considerations

### Potential Privacy Enhancements

1. **End-to-End Encryption**: Encrypt data before iCloud backup
2. **Backend Proxy**: Move API key to secure backend server
3. **Differential Privacy**: Add noise to aggregate data for research
4. **Zero-Knowledge Architecture**: Store data in a way that even we can't access it
5. **Multi-Device Sync**: CloudKit sync with encryption
6. **Anonymous Analytics**: Privacy-preserving usage analytics (TelemetryDeck)

### Regulatory Monitoring

Stay updated on:
- COPPA amendments
- GDPR updates
- State privacy laws (CCPA, VCDPA, etc.)
- Apple's App Store privacy requirements
- Health data regulations (HIPAA, though not currently applicable)

---

## References

- [Apple Privacy Guidelines](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [COPPA Compliance](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)
- [GDPR Overview](https://gdpr.eu/)
- [Google Gemini API Terms](https://ai.google.dev/terms)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

---

**Last Updated:** January 12, 2026  
**Maintainer:** Development Team  
**Review Frequency:** Quarterly or when adding new features
