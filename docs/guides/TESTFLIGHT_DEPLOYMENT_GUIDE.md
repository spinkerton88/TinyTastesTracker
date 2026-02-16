# TestFlight Deployment Guide
**TinyTastesTracker - Complete App Store Connect Upload Process**

---

## Overview

This guide walks you through uploading TinyTastesTracker to TestFlight for beta testing. TestFlight allows you to distribute your app to up to 10,000 testers before submitting to the App Store.

**Time to complete:** 1-2 hours (first time) | 15-30 minutes (subsequent uploads)

---

## Prerequisites Checklist

### Required:

- [ ] **Apple Developer Account** ($99/year)
  - Sign up at: https://developer.apple.com/programs/
  - Must be enrolled and active

- [ ] **App Store Connect Access**
  - Access at: https://appstoreconnect.apple.com

- [ ] **Xcode 15+** installed
  - Open Xcode.app to ensure command line tools are installed

- [ ] **Valid Apple ID** with 2FA enabled

- [ ] **Development Team ID**
  - Find at: https://developer.apple.com/account/#!/membership/

### Recommended:

- [ ] **App Icon** (required for TestFlight)
  - 1024x1024 PNG without transparency
  - Located at: `TinyTastesTracker/Assets.xcassets/AppIcon.appiconset/`

- [ ] **Privacy Policy URL** (required for TestFlight)
  - Can use placeholder initially

- [ ] **Test Devices** for internal testing
  - iOS 17.0+ devices for initial validation

---

## Part 1: Apple Developer Portal Setup

### Step 1.1: Get Your Development Team ID

**Option A: Via Terminal (Fastest)**

```bash
# List all available teams
security find-identity -v -p codesigning

# Or use fastlane (if installed)
fastlane fastlane-credentials
```

**Option B: Via Developer Portal**

1. Go to https://developer.apple.com/account/#!/membership/
2. Copy your **Team ID** (10-character alphanumeric code)
3. Save it - you'll need this!

---

### Step 1.2: Set Development Team in Your Project

**Edit your shell profile (one-time setup):**

```bash
# For zsh (macOS default)
echo 'export DEVELOPMENT_TEAM="YOUR_TEAM_ID_HERE"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export DEVELOPMENT_TEAM="YOUR_TEAM_ID_HERE"' >> ~/.bash_profile
source ~/.bash_profile

# Verify it's set
echo $DEVELOPMENT_TEAM
```

**Or create a local config file:**

```bash
# In TinyTastesTracker directory
cat > .env.local << 'EOF'
DEVELOPMENT_TEAM=YOUR_TEAM_ID_HERE
GEMINI_API_KEY=your_gemini_key_here
EOF

# Add to .gitignore (already done!)
```

Then load it before building:
```bash
source .env.local
```

---

### Step 1.3: Create App ID in Developer Portal

1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Click **+** to create new App ID
3. Select **App IDs** → **App** → Continue
4. **Description:** TinyTastesTracker
5. **Bundle ID:** `com.tinytastes.tracker` (Explicit)
6. **Capabilities:** Check these:
   - ✅ App Groups
   - ✅ Push Notifications (if you plan to add later)
   - ✅ Sign In with Apple (if you plan to add later)
7. Click **Continue** → **Register**

---

### Step 1.4: Create Widget Extension ID

Repeat for the widget:

1. Click **+** again
2. **Description:** TinyTastesTracker Widget
3. **Bundle ID:** `com.tinytastes.tracker.widget` (Explicit)
4. **Capabilities:**
   - ✅ App Groups (must match main app)
5. **Register**

---

### Step 1.5: Configure App Groups

1. Go to https://developer.apple.com/account/resources/identifiers/list/applicationGroup
2. Click **+** to add App Group
3. **Description:** TinyTastes Tracker Shared Data
4. **Identifier:** `group.com.tinytastes.tracker`
5. Click **Continue** → **Register**

6. **Link to App IDs:**
   - Go back to Identifiers list
   - Click `com.tinytastes.tracker`
   - Find **App Groups** capability
   - Click **Configure**
   - Select `group.com.tinytastes.tracker`
   - Save
   - Repeat for `com.tinytastes.tracker.widget`

---

## Part 2: App Store Connect Setup

### Step 2.1: Create App in App Store Connect

1. Go to https://appstoreconnect.apple.com/apps
2. Click **+** → **New App**
3. Fill in details:

   **Platforms:** ✅ iOS

   **Name:** TinyTastesTracker (or "Tiny Tastes Tracker" with spaces)
   - Check availability (must be unique across App Store)

   **Primary Language:** English (U.S.)

   **Bundle ID:** Select `com.tinytastes.tracker` from dropdown

   **SKU:** `tinytastes-tracker-001` (your internal tracking ID)

   **User Access:** Full Access

4. Click **Create**

---

### Step 2.2: Set App Version Information

After creating, you'll see the app dashboard:

1. **App Information** (left sidebar):
   - **Privacy Policy URL:**
     - If you have one: https://yourdomain.com/privacy
     - Temporary placeholder: https://www.freeprivacypolicy.com/live/[your-id]
   - **Category:**
     - Primary: **Medical** or **Health & Fitness**
     - Secondary: **Lifestyle**
   - **Content Rights:** Check if you have all rights

2. **Pricing and Availability:**
   - **Price:** Free (for now)
   - **Availability:** All countries or select specific ones
   - Click **Save**

---

### Step 2.3: Prepare TestFlight Information

Still in App Store Connect:

1. Click **TestFlight** tab (top of page)
2. Under **Test Information**:
   - **What to Test:** (Example)
     ```
     Welcome to TinyTastesTracker TestFlight beta!

     This version includes:
     - Newborn tracking (feeding, sleep, diapers)
     - First 100 Foods explorer mode
     - Toddler meal planning
     - AI-powered nutrition guidance

     Please test:
     1. Creating a child profile
     2. Logging a feeding/diaper/sleep
     3. Trying foods in Explorer mode
     4. Building a meal in Toddler mode

     Known Issues:
     - None yet!

     Feedback welcome at: feedback@tinytastes.app
     ```

   - **Feedback Email:** your-email@example.com
   - **Marketing URL:** (optional)
   - **Privacy Policy URL:** (same as above)

3. Click **Save**

---

## Part 3: Xcode Project Configuration

### Step 3.1: Open Project in Xcode

```bash
cd "/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker"

# Regenerate project with your team ID
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"
xcodegen generate

# Open in Xcode
open TinyTastesTracker.xcodeproj
```

---

### Step 3.2: Configure Signing (CRITICAL)

In Xcode:

1. **Select the project** (TinyTastesTracker at top of navigator)
2. **Select TinyTastesTracker target**
3. **Signing & Capabilities** tab:

   **Automatically manage signing:** ✅ Checked

   **Team:** Select your team from dropdown

   **Bundle Identifier:** `com.tinytastes.tracker` (should already be set)

   **Signing Certificate:** Apple Distribution (automatic)

   **Provisioning Profile:** Xcode Managed Profile

4. **Repeat for TinyTastesWidget target:**
   - Team: Same as above
   - Bundle ID: `com.tinytastes.tracker.widget`
   - Automatically manage signing: ✅ Checked

5. **Verify App Groups are configured:**
   - In **Signing & Capabilities**, you should see:
     ```
     App Groups
     ✅ group.com.tinytastes.tracker
     ```
   - If not, click **+ Capability** → **App Groups** → Add `group.com.tinytastes.tracker`

---

### Step 3.3: Set Version and Build Numbers

1. **Select TinyTastesTracker target**
2. **General** tab:
   - **Display Name:** TinyTastesTracker (or with spaces)
   - **Bundle Identifier:** com.tinytastes.tracker
   - **Version:** 1.0.0
   - **Build:** 1

3. **Repeat for TinyTastesWidget:**
   - Version: 1.0
   - Build: 1

**Important:** Build number must be **higher** than any previous upload. Use format:
- Version: Major.Minor.Patch (e.g., 1.0.0, 1.0.1, 1.1.0)
- Build: Increment each upload (1, 2, 3, ...)

---

### Step 3.4: Check Info.plist Requirements

Verify these keys exist in `TinyTastesTracker/Resources/Info.plist`:

**Required Privacy Descriptions:**

```xml
<key>NSCameraUsageDescription</key>
<string>TinyTastesTracker uses your camera to identify foods and scan product barcodes.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>TinyTastesTracker accesses your photo library to save and view food photos.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>TinyTastesTracker sends notifications to remind you of feeding times and sleep schedules.</string>

<key>NSCalendarsUsageDescription</key>
<string>TinyTastesTracker accesses your calendar to schedule feeding reminders.</string>
```

If missing, add them now.

---

## Part 4: Building and Archiving

### Step 4.1: Select Build Destination

In Xcode toolbar:

1. Click the device/simulator selector (next to TinyTastesTracker scheme)
2. Select **Any iOS Device (arm64)**
   - Do NOT select a simulator
   - Do NOT select a specific device (unless connected)

---

### Step 4.2: Clean Build Folder

**Product** → **Clean Build Folder** (or Cmd+Shift+K)

This ensures a fresh build with no cached artifacts.

---

### Step 4.3: Archive the App

**Product** → **Archive** (or Cmd+Shift+Option+K)

This will:
1. Build your app in Release mode
2. Create an archive (.xcarchive) in Xcode Organizer
3. Take 2-10 minutes depending on your Mac

**Wait for "Archive succeeded" message.**

If build fails, see **Troubleshooting** section below.

---

### Step 4.4: Open Organizer

Xcode will automatically open the Organizer window showing your archive.

If it doesn't appear:
- **Window** → **Organizer** (or Cmd+Shift+Option+O)
- Click **Archives** tab
- You should see your TinyTastesTracker archive

---

## Part 5: Uploading to App Store Connect

### Step 5.1: Validate Archive (Recommended)

In the Organizer:

1. Select your archive
2. Click **Validate App** button (blue button on right)
3. **App Store Connect distribution** → Next
4. **Upload your app's symbols** → ✅ Checked → Next
5. **Automatically manage signing** → Next
6. Wait 2-5 minutes for validation

If validation **succeeds:** ✅ Continue to upload
If validation **fails:** See error message and fix issues

---

### Step 5.2: Distribute to App Store Connect

1. Click **Distribute App** button
2. **App Store Connect** → Next
3. **Upload** → Next
4. Options:
   - ✅ Upload your app's symbols (for crash reports)
   - ✅ Manage version and build number (Xcode will auto-increment)
5. **Automatically manage signing** → Next
6. Review summary → **Upload**

**This will take 5-15 minutes** depending on app size and connection speed.

---

### Step 5.3: Monitor Upload Progress

You'll see a progress bar in Xcode.

**When complete:**
- ✅ "Upload Successful" message
- You'll receive an email from App Store Connect (within 30 minutes)

**If upload fails:**
- Check error message
- Common issues: Missing entitlements, invalid signing, version conflicts

---

## Part 6: TestFlight Configuration

### Step 6.1: Wait for Processing

After upload:

1. Go to https://appstoreconnect.apple.com/apps
2. Click your app → **TestFlight** tab
3. You'll see your build under **iOS builds** section
4. Status will show:
   - 🔵 **Processing** (10-30 minutes)
   - ⏳ **Waiting for Export Compliance** (action needed)
   - ✅ **Ready to Test** (good to go!)

**During processing:**
- App Store Connect analyzes your binary
- Checks for missing info, invalid assets, etc.
- Generates app preview for TestFlight

---

### Step 6.2: Export Compliance

When status changes to "Waiting for Export Compliance":

1. Click **Manage** next to the build
2. **Export Compliance Information:**
   - "Is your app designed to use cryptography?"
     - **YES** (you use Firebase/HTTPS)
   - "Does your app contain, display, or access third-party content?"
     - **YES** (Gemini AI, OpenFoodFacts API)
   - "Does your app use encryption?"
     - **YES** - Select "App uses standard encryption"
   - "Is your app exempt from encryption export compliance?"
     - **YES** - You only use:
       - HTTPS/TLS
       - Standard iOS encryption APIs
       - No custom encryption algorithms
3. Click **Start Internal Testing** or **Submit**

**Build status will change to "Ready to Test"** ✅

---

### Step 6.3: Add Internal Testers

Internal testers can start testing immediately (no review needed):

1. **TestFlight** tab → **Internal Testing** section
2. Click **+** next to testers
3. **Add existing users** or **Invite new testers**:
   - Enter email addresses
   - Select groups (optional)
4. Click **Add**

Testers will receive an email with TestFlight invitation link.

---

### Step 6.4: Add External Testers (Optional)

External testers require Apple review (1-2 days):

1. **TestFlight** tab → **External Testing** section
2. Click **+** to create a new group
3. **Group Name:** "Beta Testers" or "Public Beta"
4. **Enable automatic distribution:** ✅ (new builds auto-distribute)
5. Add testers via email
6. **Submit for Review**
7. **Beta App Review Information:**
   - **Beta App Description:** (what testers will see)
   - **Feedback Email:** your-email@example.com
   - **Marketing URL:** (optional)
   - **Privacy Policy URL:** (required)
   - **Notes for Reviewer:** (login credentials if needed)
8. Click **Submit**

**Apple will review within 24-48 hours.**

---

## Part 7: Testing Your Beta

### Step 7.1: Install TestFlight on Test Device

1. Download **TestFlight** app from App Store (free)
2. Open invitation email on iOS device
3. Tap **View in TestFlight**
4. Tap **Install**
5. App installs like normal App Store app

---

### Step 7.2: Provide Feedback

Testers can:
- Take screenshots → shake device → send to developers
- Submit written feedback via TestFlight app
- Crash reports automatically sent to App Store Connect

---

### Step 7.3: Monitor Crashes and Feedback

In App Store Connect:

1. **TestFlight** → **Crashes** tab
   - View crash logs
   - See stack traces
   - Identify problem areas

2. **Feedback** section:
   - Read tester comments
   - View screenshots
   - Reply to testers (via email)

---

## Automated Upload with Fastlane (Advanced)

### Option: Use Fastlane for Future Uploads

**One-time setup:**

```bash
# Install fastlane
sudo gem install fastlane

# Initialize in project directory
cd "/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker"
fastlane init
```

**Configure Fastfile:**

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    # Increment build number
    increment_build_number(xcodeproj: "TinyTastesTracker.xcodeproj")

    # Build archive
    build_app(
      scheme: "TinyTastesTracker",
      export_method: "app-store"
    )

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      skip_submission: true
    )

    # Optional: Send Slack notification
    # slack(message: "New beta uploaded to TestFlight! 🚀")
  end
end
```

**Upload with one command:**

```bash
fastlane beta
```

This automates:
- ✅ Increment build number
- ✅ Build archive
- ✅ Upload to TestFlight
- ✅ Notify team (optional)

---

## Troubleshooting Common Issues

### Issue: "No signing certificate found"

**Fix:**
1. Xcode → Preferences → Accounts
2. Select your Apple ID
3. Click **Manage Certificates**
4. Click **+** → **Apple Distribution**
5. Close and retry archive

---

### Issue: "Provisioning profile doesn't match"

**Fix:**
1. Select target in Xcode
2. Signing & Capabilities tab
3. Uncheck "Automatically manage signing"
4. Re-check it (forces refresh)
5. Clean build folder and retry

---

### Issue: "Missing App Icon"

**Fix:**
1. Add 1024x1024 PNG to `Assets.xcassets/AppIcon.appiconset/`
2. Name it `AppIcon-1024.png`
3. In Assets catalog, assign it to "App Store iOS 1024pt" slot

---

### Issue: "Missing required architecture"

**Fix:**
1. Build Settings → Architectures
2. Set to: `$(ARCHS_STANDARD)` (arm64)
3. Remove any x86_64 or i386 references
4. Clean and rebuild

---

### Issue: "Entitlements mismatch"

**Fix:**
1. Verify App ID in Developer Portal has correct capabilities
2. In Xcode, Signing & Capabilities:
   - Remove capability
   - Re-add capability
   - Regenerate provisioning profile
3. Clean and archive again

---

### Issue: "Upload stuck at 'Processing'"

**Wait time:** Normal processing: 10-30 minutes

**If >1 hour:**
1. Check App Store Connect status page: https://developer.apple.com/system-status/
2. Try uploading from a different network
3. Contact Apple Support if persists >24 hours

---

### Issue: "Invalid Swift Support"

**Fix:**
1. Make sure all Swift Package dependencies are resolved
2. Product → Clean Build Folder
3. Product → Build (not Archive)
4. Fix any warnings
5. Then archive again

---

## Quick Reference Commands

### Build and Archive via Command Line:

```bash
# Set team ID
export DEVELOPMENT_TEAM="YOUR_TEAM_ID"

# Regenerate project
xcodegen generate

# Clean
xcodebuild clean -project TinyTastesTracker.xcodeproj -scheme TinyTastesTracker

# Archive
xcodebuild archive \
  -project TinyTastesTracker.xcodeproj \
  -scheme TinyTastesTracker \
  -archivePath build/TinyTastesTracker.xcarchive \
  -destination 'generic/platform=iOS' \
  DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/TinyTastesTracker.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

**ExportOptions.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

---

## Versioning Strategy

### Recommended version numbering:

**Version format:** `MAJOR.MINOR.PATCH`

- **1.0.0** - Initial TestFlight release
- **1.0.1** - Bug fixes
- **1.1.0** - New features (Explorer mode improvements)
- **2.0.0** - Major release (App Store public release)

**Build number:** Increment on every upload
- Build 1, 2, 3, 4...
- Or use timestamp: `20260216001`

**Update in project.yml:**

```yaml
settings:
  base:
    MARKETING_VERSION: 1.0.0
    CURRENT_PROJECT_VERSION: 1
```

Then regenerate: `xcodegen generate`

---

## Checklist for Each New Build

- [ ] Increment build number (or version if features added)
- [ ] Run all tests: `Cmd+U`
- [ ] Check for SwiftLint warnings
- [ ] Update "What to Test" in TestFlight notes
- [ ] Clean build folder
- [ ] Archive build
- [ ] Validate archive
- [ ] Upload to App Store Connect
- [ ] Wait for processing
- [ ] Handle export compliance
- [ ] Test on physical device via TestFlight
- [ ] Monitor crash reports for 24-48 hours

---

## Next Steps After TestFlight

Once TestFlight is stable:

1. **Collect Feedback:** Get 5-10 testers to use app for 1-2 weeks
2. **Fix Critical Bugs:** Priority on crashes and data loss issues
3. **Prepare App Store Listing:**
   - Screenshots (required: 5.5" and 6.5" iPhone)
   - App preview video (optional but recommended)
   - Description and keywords
   - Privacy policy finalized
4. **Submit for App Store Review:**
   - From App Store Connect → App Store tab
   - Fill out all metadata
   - Submit for review (7-14 days)
5. **Release!** 🎉

---

## Resources

- **App Store Connect:** https://appstoreconnect.apple.com
- **Developer Portal:** https://developer.apple.com/account
- **TestFlight Documentation:** https://developer.apple.com/testflight/
- **App Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/
- **Human Interface Guidelines:** https://developer.apple.com/design/human-interface-guidelines/
- **Fastlane Documentation:** https://docs.fastlane.tools/

---

## Support

If you encounter issues not covered here:

1. **Apple Developer Forums:** https://developer.apple.com/forums/
2. **Stack Overflow:** Tag with `ios`, `xcode`, `testflight`
3. **Apple Developer Support:** https://developer.apple.com/support/

---

**Document Version:** 1.0
**Last Updated:** 2026-02-16
**Tested with:** Xcode 15.0+, iOS 17.0+
