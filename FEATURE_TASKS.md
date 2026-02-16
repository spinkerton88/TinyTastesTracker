# Tiny Tastes Tracker - Feature Implementation Task List

## 1. Account Creation with iCloudKit
- [x] Create account creation screen before child setup
  - [x] Design welcome/account setup UI
  - [x] Implement iCloud account detection
  - [x] Create user profile model synced via CloudKit
  - [x] Add iCloud sign-in prompt if not signed in
  - [x] Store user preferences in CloudKit
- [x] Integrate with existing onboarding flow
  - [x] Show account creation before child profile setup
  - [x] Link user account to child profiles
  - [x] Handle multiple devices with same iCloud account
- [x] Remove backend dependencies
  - [x] Ensure all data storage uses CloudKit/SwiftData
  - [x] Remove any server-side authentication code
  - [x] Implement offline-first architecture
- [ ] Implement Data Sharing (CKShare) - Explicit Family Sharing
  - [ ] Create `CloudKitShareService` to handle CKShare lifecycle
  - [ ] Implement `CloudKitSharingViewController` wrapper
  - [ ] Add "Family Sharing" section to SettingsPage
  - [ ] Implement Share Management UI (Participants, Remove Access)
  - [ ] Handle incoming share links (Universal Links) in App Delegate
  - [ ] Test sharing flow between two iCloud accounts

## 2. Pediatrician Summary Feature
- [x] Design Pediatrician Summary data model
  - [x] Define summary period (between visits)
  - [x] Create data aggregation structure
  - [x] Support multiple summary types (sleep, feeding, growth, etc.)
- [x] Implement data aggregation logic
  - [x] Sleep metrics (avg naps/day, avg nap length, total sleep time)
  - [x] Feeding metrics (avg feeds/day, avg quantity, feeding patterns)
  - [x] Explorer mode: new foods tried, allergen reactions
  - [x] Medication tracking (avg doses/day, medication names)
  - [x] Diaper metrics (avg changes/day, patterns)
  - [x] Growth measurements (height, weight changes)
- [x] Create AI summary generation
  - [x] Integrate with GeminiService for summary generation
  - [x] Create prompts for pediatric-appropriate summaries
  - [x] Format summary for easy reading by healthcare providers
  - [x] Include visual charts and graphs
  - [x] Highlight concerns or unusual patterns
- [x] Build Pediatrician Summary UI
  - [x] Summary list view (all past summaries)
  - [x] Summary detail view with all metrics
  - [x] Date range selector for custom summaries
  - [x] Export options (PDF, print, share)
  - [x] Add notes section for parent observations
- [x] Add summary scheduling
  - [x] Set up appointment dates
  - [x] Auto-generate summary before appointments
  - [x] Reminder notifications for upcoming visits
- [x] Test with sample data
  - [x] Verify accuracy of aggregated metrics
  - [x] Test AI summary quality and relevance
  - [x] Validate export functionality

## 3. Food Explorer Enhancements
- [x] Implement food unchecking functionality
  - [x] Add "Unmark as Tried" option in food detail view
  - [x] Update FoodLog model to support soft deletion/unmarking
  - [x] Show confirmation dialog before unchecking
  - [x] Update food progress tracking when unchecked
  - [x] Sync uncheck actions via CloudKit
- [x] Update Explorer UI for unchecking
  - [x] Add swipe action to uncheck foods
  - [x] Show visual indicator for "tried" vs "not tried"
  - [x] Update rainbow progress when foods unchecked
  - [x] Add undo functionality
- [x] Test edge cases
  - [x] Uncheck food with allergen reaction logged
  - [x] Uncheck food with multiple log entries
  - [x] Verify data integrity after unchecking

## 4. Messy Face Photo Management
- [x] Create central Messy Face gallery
  - [x] Design gallery view for all messy face photos
  - [x] Grid layout with photo thumbnails
  - [x] Filter by date, food name, meal type
  - [x] Sort options (newest, oldest, by food)
- [x] Link photos to food items
  - [x] Associate each photo with specific food log entry
  - [x] Show food name and date on photo
  - [x] Enable navigation from photo to food details
  - [x] Enable navigation from food to related photos
- [x] Enhance photo capture flow
  - [x] "Add Photo" button in food logging (PhotosPicker)
  - [ ] Support multiple photos per food (deferred - requires model migration)
  - [ ] Add photo editing (crop, rotate, filters) (future enhancement)
  - [ ] Optional caption/notes for each photo (future enhancement)
- [x] Photo storage and sync
  - [x] Store photos locally with SwiftData (as compressed Data in TriedFoodLog)
  - [x] Sync photos via CloudKit (automatic with SwiftData)
  - [x] Implement photo compression (via ImageCompression utility)
  - [x] Handle photo deletion
- [x] Gallery features
  - [x] Full-screen photo viewer with pinch-to-zoom
  - [x] Share photos (social media, messages)
  - [x] Save to Photos library
  - [x] Create photo collages/memories
  - [x] Export photos with food timeline
- [x] Test photo management
  - [x] Test with large number of photos (100+)
  - [x] Verify CloudKit photo sync
  - [x] Test photo quality and compression
  - [x] Validate storage limits
  - [x] Test collage generation with various templates
  - [x] Test timeline PDF export
  - [x] Test ZIP export with metadata

## 5. Push Notifications for Next Feed
- [x] Create notification permission request system
- [x] Implement `NotificationManager.swift` service
- [x] Add feed notification scheduling logic
  - [x] Schedule notification based on last feed time + interval
  - [x] Support customizable lead time (15min, 30min, 45min, 1hr, 2hr)
  - [x] Handle notification updates when feed is logged
- [x] Create notification settings UI
  - [x] Toggle for feed notifications
  - [x] Lead time picker (15min, 30min, 45min, 1hr, 2hr)
  - [x] Permission status indicator
- [x] Integrate with `NewbornManager` to trigger scheduling
- [x] Add notification action handlers (mark as fed, snooze)
- [x] Integrate with `ToddlerManager` for meal reminders (Explorer/Toddler modes)
- [ ] Test notification delivery and cancellation
- [ ] Link NotificationSettingsView to main Settings

## 6. High-Risk Allergen Notification Prompt
- [x] Detect high-risk allergen logging in food tracking
- [x] Create allergen reaction monitoring prompt UI
  - [x] Modal/alert after logging high-risk food
  - [x] Option to set check-in notification (1hr, 2hr, 3hr, 4hr)
  - [x] Include allergen name and symptoms to watch for
  - [x] Allergen-specific descriptions and guidance
  - [x] Symptom severity indicators (mild, moderate, severe)
  - [x] Emergency warning for severe symptoms
- [x] Implement delayed notification scheduling
  - [x] Configurable duration (1-4 hours)
  - [x] Quick action buttons (No Reaction, Report Reaction)
- [x] Add allergen notification settings
  - [x] Toggle for allergen monitoring
  - [x] Customize check-in duration picker
- [x] Add `checkForHighRiskAllergen()` method to ToddlerManager
- [ ] Integrate AllergenMonitoringPrompt into food logging views
- [ ] Track allergen monitoring history (optional enhancement)

## 7. Finish Image Generation
- [x] Review current `ImageGenerationService.swift` implementation
- [x] Fix any outstanding API integration issues
  - [x] Verify Imagen 4 endpoint compatibility
  - [x] Test fallback to fast model
  - [x] Ensure placeholder generation works
- [x] Implement image caching strategy
  - [x] Cache generated images locally
  - [x] Implement cache invalidation policy
  - [x] Add cache size management
- [x] Add batch image generation for common foods
- [x] Optimize image quality vs. file size
- [x] Add progress indicators for image generation
- [x] Test with various food names and edge cases

## 8. Extend Images to Toddler Mode
- [x] Audit toddler mode views for image integration points
  - [x] Meal planning screens
  - [x] Food tracking interface
  - [x] Recipe displays
  - [x] Progress/achievement views
- [x] Update `FoodImageView.swift` for toddler-specific styling
  - [x] Age-appropriate visual treatments
  - [x] Larger touch targets for toddlers
  - [x] Playful animations/transitions
- [x] Generate toddler-friendly food images
  - [x] Adjust prompts for kid-appealing presentations
  - [x] Include common toddler meals/snacks
- [x] Add image generation to toddler meal logging
- [x] Update `ToddlerManager` to handle image generation
- [x] Test image display across all toddler mode screens

## 9. Translations (Localization)
- [ ] Set up localization infrastructure
  - [ ] Create `Localizable.strings` files
  - [ ] Configure project for multiple languages
  - [ ] Set up string catalogs (iOS 17+)
- [ ] Extract all hardcoded strings
  - [ ] UI text and labels
  - [ ] Error messages
  - [ ] Notification content
  - [ ] Onboarding flow text
- [ ] Implement language selection in settings
- [ ] Translate to priority languages
  - [ ] Spanish (US market)
  - [ ] French (Canadian market)
  - [ ] Mandarin (optional)
- [ ] Localize food database
  - [ ] Food names
  - [ ] Allergen information
  - [ ] Serving suggestions
- [ ] Add unit system toggle (metric/imperial)
- [ ] Test RTL language support (if applicable)
- [ ] Update AI prompts for multilingual support

## 10. CloudKit Integration and Crash Prevention
- [x] Review current `CloudKitSyncManager.swift` implementation
- [x] Complete CloudKit capability configuration
  - [x] Update `project.yml` with CloudKit entitlements
  - [x] Configure CloudKit container in Apple Developer
  - [x] Set up CloudKit schema/record types
- [x] Implement robust error handling
  - [x] Account status validation
  - [x] Network error recovery
  - [x] Quota limit handling
  - [x] Conflict resolution strategy
- [x] Add crash prevention measures
  - [x] Validate CloudKit availability before operations
  - [x] Implement graceful degradation when offline
  - [x] Add retry logic with exponential backoff
  - [x] Prevent concurrent sync operations
- [x] Create CloudKit sync UI
  - [x] Sync status indicator
  - [x] Manual sync trigger
  - [x] Sync history/logs
  - [x] Error reporting to user
- [x] Implement data migration strategy
  - [x] SwiftData to CloudKit record mapping (automatic)
  - [x] Handle schema changes (SwiftData automatic)
  - [x] Backup before sync (via DataExportService)
- [ ] Add comprehensive testing
  - [ ] Unit tests for sync logic
  - [ ] Integration tests with mock CloudKit
  - [x] Test crash scenarios from tonight's incident
  - [ ] Test multi-device sync
- [x] Monitor and log CloudKit operations
  - [x] Track sync success/failure rates
  - [x] Log quota usage
  - [x] Alert on repeated failures

## 11. [x] Complete Accessibility Implementation (ASSESSMENT.md #9)
- [x] Add VoiceOver labels to remaining 12+ view files
  - [x] Newborn mode views
  - [x] Toddler mode views
  - [x] Settings screens
  - [x] Recipe/meal planning views
- [x] Test layouts at all Dynamic Type sizes (XS to XXXL)
- [x] Fix Warning Orange color contrast (2.8:1 → 4.5:1 minimum)
- [x] Add `.minimumScaleFactor()` where needed for text truncation
- [ ] Create automated accessibility test suite
- [ ] Perform comprehensive manual testing with VoiceOver
- [ ] Test with Reduce Motion enabled
- [ ] Verify color contrast in both light and dark modes

## 12. Analytics & Crash Reporting (ASSESSMENT.md #8)
- [ ] Choose analytics platform (Firebase Analytics or TelemetryDeck)
- [ ] Integrate analytics SDK
- [ ] Implement event tracking
  - [ ] User journeys (onboarding, first log, first meal plan)
  - [ ] Feature usage (AI queries, recipe generation, voice chat)
  - [ ] Drop-off points
  - [ ] Error rates
- [ ] Add crash reporting (Crashlytics or Sentry)
- [ ] Create analytics dashboard
- [ ] Set up alerts for critical errors
- [ ] Track AI feature success rates
- [ ] Monitor API usage patterns

## 13. Enhanced Onboarding (ASSESSMENT.md #12 - Optional)
- [ ] Enhance sample data generation with more variety
- [ ] Create progress indicator UI component
- [ ] Run and verify UI tests pass
- [ ] Perform comprehensive manual testing
- [ ] Add onboarding analytics dashboard

## 14. Visual "How-to-Serve" Database (Future - ASSESSMENT.md #12)
- [ ] Research pediatric nutritionist partnerships
- [ ] Define AgeBasedServingGuide data model
- [ ] Start with top 50 common allergen foods
- [ ] AI-generate serving instructions with safety warnings
- [ ] Add choking hazard warnings
- [ ] Create visual guide UI component
- [ ] Test with parents for usability

## 15. Advanced Sleep Prediction (Future - ASSESSMENT.md #13)
- [ ] Collect sleep log data for ML training
- [ ] Train custom ML model with Create ML
- [ ] Implement precise wake window countdown
- [ ] Add prediction accuracy tracking
- [ ] Create "Sweet Spot" algorithm
- [ ] Integrate with existing sleep prediction widget
- [ ] A/B test against current AI predictions

## 16. Daycare Report And Data Ingestion (New Request)
- [x] Research PDF/Image parsing libraries (Vision.framework)
- [x] Design "Report Import" feature flow
- [x] Create parser for Daycare Summary formats (Procare, Brightwheel)
  - [x] Extract time-based events (naps, bottles, diapers) using AI
  - [x] Map external data to `FoodLog`, `SleepLog`, `DiaperLog`
- [x] Add generic file import support
  - [x] Support .txt, .csv, .json file uploads
  - [x] Create file picker for data files
  - [x] Implement text content extraction (skip OCR)
- [x] Implement AI-assisted parsing (Gemini) for unstructured text/files
- [x] Build "Report Review" UI
  - [x] Show detected events for user confirmation
  - [x] Allow editing before saving
  - [x] Merge logic (duplicates handled by user review)
- [x] Test with sample reports (images/PDFs) and export files

## Testing & Validation
- [ ] Create comprehensive test suite for notifications
- [ ] Test all notification scenarios (permissions, delivery, actions)
- [ ] Validate image generation across all modes
- [ ] Test localization with all supported languages
- [ ] Perform CloudKit stress testing
- [ ] Test offline/online transitions
- [ ] Validate crash scenarios are resolved
- [ ] Perform accessibility testing with new features
- [ ] Run all existing tests (220+ tests should pass)
- [ ] Achieve 60%+ code coverage for new code
- [ ] Update documentation for new features

## 13. App Store Preparation (CRITICAL for Launch)

### Legal & Privacy
- [ ] Host Privacy Policy on public URL
  - [ ] Set up GitHub Pages or custom domain
  - [ ] Upload PRIVACY_POLICY.md
  - [ ] Get public URL for App Store Connect
- [ ] Create Terms of Service document
- [ ] Review COPPA compliance (app targets children)
- [ ] Review GDPR compliance for international users
- [ ] Prepare App Store Privacy details
  - [ ] Data collection disclosure
  - [ ] Third-party SDK disclosure (Google Gemini)
  - [ ] Data usage purposes

### App Store Assets
- [ ] Create app icon (1024x1024)
  - [ ] Design final icon
  - [ ] Export all required sizes
  - [ ] Test on device home screen
- [ ] Create App Store screenshots (all device sizes)
  - [ ] iPhone 6.7" (iPhone 15 Pro Max) - Required
  - [ ] iPhone 6.5" (iPhone 14 Plus) - Required
  - [ ] iPhone 5.5" (iPhone 8 Plus) - Optional
  - [ ] iPad Pro 12.9" (6th gen) - Required if iPad support
  - [ ] iPad Pro 12.9" (2nd gen) - Optional
  - [ ] Minimum 3-10 screenshots per device size
  - [ ] Localized screenshots for Spanish/French (if applicable)
- [ ] Create App Preview video (optional but recommended)
  - [ ] 15-30 second demo video
  - [ ] Show key features (tracking, AI, meal planning)
  - [ ] Export for all required device sizes
- [ ] Write App Store description
  - [ ] Compelling title (max 30 characters)
  - [ ] Subtitle (max 30 characters)
  - [ ] Description (max 4000 characters)
  - [ ] Keywords (max 100 characters, comma-separated)
  - [ ] What's New text for version 1.0
  - [ ] Promotional text (170 characters, updatable)
- [ ] Determine age rating
  - [ ] Complete Apple's age rating questionnaire
  - [ ] Likely 4+ (no objectionable content)
  - [ ] Note: Medical/treatment information disclaimer

### Technical Preparation
- [ ] Configure App Store Connect
  - [ ] Create app record
  - [ ] Set bundle ID
  - [ ] Configure app information
  - [ ] Set pricing (free or paid)
- [ ] Set up TestFlight
  - [ ] Create internal testing group
  - [ ] Add internal testers (up to 100)
  - [ ] Upload first build
  - [ ] Test installation and basic flows
  - [ ] Create external testing group (optional)
  - [ ] Submit for external beta review
- [ ] Configure In-App Purchases (if monetizing)
  - [ ] Create subscription products
  - [ ] Set pricing tiers
  - [ ] Write subscription descriptions
  - [ ] Test purchase flow in sandbox
  - [ ] Implement StoreKit 2
  - [ ] Handle subscription states
- [ ] Archive and upload build
  - [ ] Set version number (1.0.0)
  - [ ] Set build number (1)
  - [ ] Archive in Xcode
  - [ ] Upload to App Store Connect
  - [ ] Wait for processing
  - [ ] Verify build appears

### Pre-Submission Checklist
- [ ] Test on multiple devices
  - [ ] iPhone SE (small screen)
  - [ ] iPhone 15 Pro (standard)
  - [ ] iPhone 15 Pro Max (large screen)
  - [ ] iPad (if supporting)
- [ ] Test on multiple iOS versions
  - [ ] iOS 17.0 (minimum supported)
  - [ ] iOS 17.6 (latest 17.x)
  - [ ] iOS 18.0+ (if available)
- [ ] Verify all features work
  - [ ] Onboarding flow
  - [ ] All tracking features
  - [ ] AI features (Sage, predictions, recipes)
  - [ ] Widgets
  - [ ] Notifications (if implemented)
  - [ ] CloudKit sync (if implemented)
  - [ ] Data export/import
- [ ] Check for crashes
  - [ ] Run through all major flows
  - [ ] Test error scenarios
  - [ ] Verify crash reporting works
- [x] Verify API key security
  - [x] Ensure API key not in binary
  - [x] Test rate limiting (handled by Cloudflare)
  - [ ] Monitor API usage
- [ ] Review app performance
  - [ ] Launch time <2 seconds
  - [ ] Smooth scrolling
  - [ ] No memory leaks
  - [ ] Battery usage acceptable
- [ ] Accessibility audit
  - [ ] VoiceOver navigation works
  - [ ] Dynamic Type support
  - [ ] Color contrast compliance
  - [ ] Reduce Motion support

### Submission
- [ ] Complete App Store Connect submission form
  - [ ] Select build
  - [ ] Add screenshots
  - [ ] Add app preview (if created)
  - [ ] Fill in description and keywords
  - [ ] Set age rating
  - [ ] Add privacy policy URL
  - [ ] Configure App Store availability
  - [ ] Set release options (manual or automatic)
- [ ] Submit for review
- [ ] Monitor review status
- [ ] Respond to any rejection feedback
- [ ] Celebrate when approved! 🎉

### Post-Launch
- [ ] Monitor crash reports
- [ ] Track analytics for first week
- [ ] Respond to user reviews
- [ ] Plan first update based on feedback
- [ ] Monitor API costs
- [ ] Track CloudKit usage (if enabled)

## Documentation
- [ ] Update README with new features
- [ ] Document notification system architecture
- [ ] Create localization guide for contributors
- [ ] Document CloudKit setup process
- [ ] Update ASSESSMENT.md with completed features
- [ ] Create user-facing help documentation
- [ ] Write App Store release notes
- [ ] Create support documentation/FAQ
