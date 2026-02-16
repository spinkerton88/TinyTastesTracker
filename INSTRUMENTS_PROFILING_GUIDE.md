# Instruments Performance Profiling Guide
**TinyTastesTracker - Establishing Performance Baseline**

**Date:** February 15, 2026
**Purpose:** Profile app performance to establish baseline metrics before TestFlight deployment
**Estimated Time:** 1 hour
**Status:** Ready for execution

---

## Why Profile Before TestFlight?

Performance profiling helps you:
- ✅ Identify memory leaks before users report crashes
- ✅ Detect CPU-intensive operations that drain battery
- ✅ Find bottlenecks in data loading and UI rendering
- ✅ Establish baseline metrics for future optimization
- ✅ Ensure smooth 60fps scrolling in lists
- ✅ Verify background tasks don't impact foreground performance

---

## Prerequisites

- ✅ Xcode 15.2+ installed
- ✅ TinyTastesTracker builds successfully
- ✅ Physical iOS device OR simulator (device preferred for accurate battery data)
- ✅ Test account with sample data:
  - At least 1 child profile
  - 20+ sleep logs
  - 20+ nursing logs
  - 10+ meal logs
  - 5+ recipes
  - 10+ foods tried

---

## Part 1: Setup (5 minutes)

### Step 1: Prepare Test Data

1. Open TinyTastesTracker app
2. Sign in with test account
3. Verify you have sample data (logs, recipes, etc.)
4. If not, create sample data for realistic profiling

### Step 2: Close Background Apps

1. Close all other apps on device/simulator
2. Disable notifications (Settings → Notifications → Off)
3. Enable Airplane Mode to isolate network performance
4. **Note:** You'll re-enable network for Firestore profiling later

### Step 3: Build for Profiling

1. Open TinyTastesTracker.xcodeproj in Xcode
2. Select **Product → Scheme → Edit Scheme** (⌘<)
3. Select **Run** in left sidebar
4. Change **Build Configuration** to **Release**
5. Enable **"Debug executable"** (if not already enabled)
6. Click **Close**

**Why Release mode?** Debug builds include extra instrumentation that skews performance metrics. Release builds match what users experience.

---

## Part 2: Memory Profiling (15 minutes)

### Profiling Goal
Detect memory leaks, excessive allocations, and high memory usage patterns.

### Step 1: Launch Allocations Instrument

1. In Xcode, select your target device
2. Press **⌘I** (Product → Profile)
3. Wait for Instruments to open
4. Select **Allocations** template
5. Click **Choose**
6. App will launch automatically

### Step 2: Profile Critical Flows

**Test Flow 1: Photo Upload (High Memory Risk)**

1. Click **Record** button (red circle) in Instruments
2. In app, navigate to **Toddler → Add New Food**
3. Tap **Add Photo** button
4. Select a photo from library
5. Wait for upload to complete
6. Take screenshot and add to food entry
7. Save the food entry
8. Repeat 3 times to test photo caching

**What to Watch:**
- Memory spike when loading photo
- Memory release after upload completes
- Look for **Persistent** memory (doesn't drop)

**Expected:** Memory spike ~10-20MB per photo, then drops after upload

**Red Flags:**
- ❌ Memory never drops (leak)
- ❌ Memory grows >100MB
- ❌ App crashes with memory warning

**Test Flow 2: Large Data Lists (Scroll Performance)**

1. Navigate to **Newborn → Today's Logs**
2. Scroll through list of 20+ logs
3. Scroll up and down rapidly (test cell reuse)
4. Navigate to **Toddler → Food Tracker**
5. Scroll through foods list
6. Switch to **Recipes** page
7. Scroll through recipes

**What to Watch:**
- Memory allocation during scrolling
- Instances of image caching
- Cell reuse efficiency

**Expected:** Memory increases slightly during scroll, stabilizes

**Red Flags:**
- ❌ Memory continuously grows while scrolling
- ❌ New allocations every scroll (cell reuse broken)
- ❌ Memory >200MB for lists

**Test Flow 3: Timer-Based Updates**

1. Navigate to **Newborn Dashboard**
2. Leave app idle for 2 minutes
3. Watch for memory allocations every 60 seconds

**What to Watch:**
- Timer in NewbornDashboardViewModel:36 triggers updates
- Check if timer creates new objects or reuses existing

**Expected:** Minimal allocations every 60s (< 1MB)

**Red Flags:**
- ❌ Significant memory allocations every minute
- ❌ Memory grows continuously while idle

### Step 3: Stop and Analyze

1. Click **Stop** button in Instruments
2. Click **Allocations** in left sidebar
3. Sort by **Persistent Bytes** (highest first)
4. Look for:
   - Large allocations that never deallocate (leaks)
   - UIImage or NSData in persistent memory (image cache issues)
   - Growing arrays or dictionaries

### Step 4: Document Baseline

**Memory Baseline Template:**

```
MEMORY PROFILING RESULTS
Date: February 15, 2026
Device: [iPhone 15 Pro / Simulator]

Baseline Memory Usage:
- App Launch: _____ MB
- After Login: _____ MB
- Newborn Dashboard: _____ MB
- Toddler Food Tracker: _____ MB

Peak Memory Usage:
- Photo Upload: _____ MB
- Scrolling Large Lists: _____ MB
- AI Request (Gemini): _____ MB

Memory Leaks Detected: [ ] Yes [ ] No
If Yes, describe: _____________________________

Persistent Memory Issues: [ ] Yes [ ] No
If Yes, describe: _____________________________

Overall Memory Health: [ ] Good [ ] Needs Investigation [ ] Critical
```

---

## Part 3: CPU Profiling (15 minutes)

### Profiling Goal
Identify CPU-intensive operations that cause UI lag or battery drain.

### Step 1: Launch Time Profiler

1. Press **⌘I** again (or choose **File → New Session**)
2. Select **Time Profiler** template
3. Click **Choose**

### Step 2: Profile Critical Flows

**Test Flow 1: AI Service Calls**

1. Click **Record**
2. Navigate to **Sage** (AI assistant)
3. Ask a question: "What foods should I introduce next?"
4. Wait for AI response
5. Ask follow-up: "Create a meal plan for this week"
6. Wait for response

**What to Watch:**
- CPU spike during request preparation
- CPU usage during JSON parsing
- Main thread activity during AI response

**Expected:** CPU spike < 50% during request, < 20% idle

**Red Flags:**
- ❌ CPU at 100% for >2 seconds (UI will freeze)
- ❌ Main thread blocked during network request
- ❌ Parsing takes >1 second

**Test Flow 2: Data Aggregation**

1. Navigate to **Newborn Dashboard**
2. Watch CPU during initial load
3. Switch between tabs (Today, Week, Month)
4. Observe CPU during data aggregation

**What to Watch:**
- DataAggregationService calculations
- Chart rendering
- Statistics computation

**Expected:** CPU spike < 30% for < 1 second

**Red Flags:**
- ❌ CPU at 100% for >1 second (UI lag)
- ❌ Main thread blocks during calculation
- ❌ Dashboard takes >2 seconds to load

**Test Flow 3: Firestore Listeners**

1. **Disable Airplane Mode** (enable network)
2. Navigate to different screens
3. Watch CPU during Firestore sync
4. Create a new sleep log
5. Watch CPU during write + listener updates

**What to Watch:**
- 15+ active Firestore listeners
- Listener callback CPU usage
- Document decoding performance

**Expected:** CPU < 10% for listener updates

**Red Flags:**
- ❌ CPU spike >50% on every Firestore update
- ❌ UI freezes during data sync
- ❌ Excessive listener re-registrations

### Step 3: Analyze Call Tree

1. Click **Stop**
2. In bottom pane, select **Call Tree**
3. Check **Hide System Libraries** (top right)
4. Check **Invert Call Tree**
5. Sort by **Weight** (highest first)
6. Look for:
   - Your app's functions taking >10% CPU
   - Main thread blocked by synchronous operations
   - Expensive JSON parsing or image processing

### Step 4: Document Baseline

**CPU Baseline Template:**

```
CPU PROFILING RESULTS
Date: February 15, 2026
Device: [iPhone 15 Pro / Simulator]

CPU Usage During Operations:
- App Launch: _____% (duration: _____ s)
- AI Request: _____% (duration: _____ s)
- Data Aggregation: _____% (duration: _____ s)
- Firestore Sync: _____% (duration: _____ s)
- Photo Upload: _____% (duration: _____ s)

Main Thread Blocking:
- AI Requests: [ ] Async [ ] Blocking
- Firestore Writes: [ ] Async [ ] Blocking
- Image Processing: [ ] Async [ ] Blocking

Hotspots (>10% CPU):
1. Function: _____________ | CPU: _____% | Thread: _______
2. Function: _____________ | CPU: _____% | Thread: _______
3. Function: _____________ | CPU: _____% | Thread: _______

Overall CPU Health: [ ] Good [ ] Needs Investigation [ ] Critical
```

---

## Part 4: Energy & Battery Profiling (15 minutes)

### Profiling Goal
Ensure app doesn't drain battery excessively (critical for all-day baby tracking).

### Step 1: Launch Energy Log

**Note:** Energy profiling requires a **physical device** (not simulator).

1. Connect physical iPhone via USB
2. Press **⌘I**
3. Select **Energy Log** template
4. Click **Choose**

### Step 2: Profile Realistic Usage

**Test Scenario: Typical Parent Day**

1. Click **Record**
2. Simulate realistic usage:
   - Leave app open on Newborn Dashboard (2 minutes idle)
   - Create 3 nursing logs
   - Create 2 sleep logs
   - Switch to Toddler tab
   - Log 1 meal
   - Take photo of food
   - Ask Sage a question
   - Leave app idle (2 minutes)
3. Click **Stop** after 10 minutes total

### Step 3: Analyze Energy Usage

1. View **Energy Impact** graph
2. Check **Overhead** column (right side)
3. Look for:
   - **Red/Yellow bars** = High energy usage
   - **Blue bars** = Normal usage
   - **Consistent high usage** while idle = Problem

**Energy Categories:**
- **CPU**: Processing work
- **Network**: Firestore sync, API calls
- **Location**: (Should be minimal/none)
- **Display**: Screen brightness (user-controlled)
- **Background**: (Should be none when app is active)

### Step 4: Document Baseline

**Energy Baseline Template:**

```
ENERGY PROFILING RESULTS
Date: February 15, 2026
Device: [Physical iPhone model]

Energy Impact (10-minute test):
- Overall Energy: [ ] Low [ ] Medium [ ] High [ ] Very High
- Idle Energy: [ ] Low [ ] Medium [ ] High
- Active Use Energy: [ ] Low [ ] Medium [ ] High

Energy Consumers:
- CPU: [ ] Low [ ] Medium [ ] High
- Network: [ ] Low [ ] Medium [ ] High
- Location: [ ] None [ ] Low [ ] Medium [ ] High
- GPU: [ ] Low [ ] Medium [ ] High

Timer Impact (60s updates):
- Detectable in Energy Log: [ ] Yes [ ] No
- Energy overhead: [ ] Negligible [ ] Noticeable [ ] High

Battery Drain Estimate:
- App usage for 1 hour: ~_____% battery drain

Overall Energy Health: [ ] Good [ ] Needs Investigation [ ] Critical
```

---

## Part 5: Network Profiling (10 minutes)

### Profiling Goal
Ensure Firestore operations are efficient and don't cause excessive data usage.

### Step 1: Launch Network Profiler

1. Press **⌘I**
2. Select **Network** template
3. Click **Choose**
4. Ensure device has network enabled

### Step 2: Profile Firestore Operations

1. Click **Record**
2. Force quit and relaunch app
3. Sign in
4. Navigate to Newborn Dashboard (triggers 8+ listeners)
5. Create 1 sleep log
6. Create 1 nursing log
7. Navigate to Toddler tab (more listeners)
8. Scroll through Food Tracker
9. Click **Stop** after 2 minutes

### Step 3: Analyze Network Activity

1. View **Bytes In/Out** columns
2. Check **Connections** tab (bottom)
3. Look for:
   - Firestore requests (firestore.googleapis.com)
   - Cloud Functions (cloudflareworkers.com)
   - Excessive polling or redundant requests

**Expected Network Usage:**
- Initial load: ~100-500 KB
- Per log creation: ~1-5 KB
- Listener updates: ~1-2 KB each
- AI request: ~10-50 KB (prompt + response)

### Step 4: Document Baseline

**Network Baseline Template:**

```
NETWORK PROFILING RESULTS
Date: February 15, 2026

Data Usage (2-minute test):
- Bytes Received: _____ KB
- Bytes Sent: _____ KB
- Total: _____ KB

Request Breakdown:
- Firestore reads: _____ requests | _____ KB
- Firestore writes: _____ requests | _____ KB
- Firestore listeners: _____ active | _____ KB
- Cloud Functions (AI): _____ requests | _____ KB
- Image uploads: _____ requests | _____ KB

Efficiency Concerns:
- Redundant requests: [ ] Yes [ ] No
- Excessive polling: [ ] Yes [ ] No
- Uncompressed data: [ ] Yes [ ] No

Data Usage Estimate:
- Light usage (1 hour): ~_____ MB
- Heavy usage (1 hour): ~_____ MB

Overall Network Health: [ ] Good [ ] Needs Investigation [ ] Critical
```

---

## Part 6: Interpreting Results

### What Good Looks Like ✅

**Memory:**
- Launch: 50-100 MB
- Peak: < 300 MB
- No persistent leaks
- Memory drops after photo upload completes

**CPU:**
- Idle: < 5%
- Active use: 20-40%
- Peaks < 2 seconds
- No main thread blocking

**Energy:**
- Overall impact: Low to Medium
- Idle: Low
- No red/yellow bars while idle
- 1-hour use: < 10% battery drain

**Network:**
- Initial load: < 1 MB
- Per operation: < 10 KB
- No redundant requests
- Efficient listener usage

---

### Red Flags 🚨

**Critical Issues (Must Fix Before TestFlight):**

1. **Memory:**
   - ❌ Memory grows continuously without limit
   - ❌ Crashes with memory warning
   - ❌ Memory > 500 MB

2. **CPU:**
   - ❌ Main thread blocked for > 2 seconds
   - ❌ UI freezes or stutters
   - ❌ CPU at 100% for extended periods

3. **Energy:**
   - ❌ "Very High" energy impact while idle
   - ❌ Consistent high CPU usage in background
   - ❌ Location services running unexpectedly

4. **Network:**
   - ❌ Excessive polling (requests every second)
   - ❌ Uncompressed large payloads
   - ❌ Redundant listener registrations

**Moderate Issues (Should Investigate):**

1. **Memory:**
   - ⚠️ Memory doesn't drop after photo processing
   - ⚠️ Memory grows slowly over time
   - ⚠️ Large persistent allocations (>50 MB)

2. **CPU:**
   - ⚠️ CPU spikes > 80% during normal operations
   - ⚠️ JSON parsing takes > 500ms
   - ⚠️ Data aggregation blocks UI

3. **Energy:**
   - ⚠️ "High" energy impact during active use
   - ⚠️ Timer visible in energy log
   - ⚠️ Network polling while idle

4. **Network:**
   - ⚠️ Initial load > 2 MB
   - ⚠️ Multiple requests for same data
   - ⚠️ Unoptimized image uploads

---

## Part 7: Known Performance Areas

Based on the code review, these areas have been flagged for monitoring:

### 1. Timer-Based Updates (NewbornDashboardViewModel:36)

**Location:** `/Features/Newborn/ViewModels/NewbornDashboardViewModel.swift`

```swift
timer = Timer.publish(every: 60, on: .main, in: .common)
    .autoconnect()
    .sink { [weak self] _ in
        self?.updateStatus()
    }
```

**What to Check:**
- CPU spike every 60 seconds (should be minimal)
- Memory allocations during update (should reuse objects)
- Energy impact visible in Energy Log

**Expected:** < 1% CPU, < 100 KB allocations per update

---

### 2. Firestore Listeners (15+ Active)

**Locations:** Throughout NewbornManager, ToddlerManager, RecipesManager

**What to Check:**
- Network activity when listeners trigger
- CPU usage during document decoding
- Memory for cached listener data

**Expected:**
- Network: < 5 KB per update
- CPU: < 5% per listener callback
- Memory: < 50 MB for all cached data

---

### 3. Photo Upload Flow (FoodImageStorageService)

**Location:** `/Core/Services/FoodImageStorageService.swift`

**What to Check:**
- Memory spike when loading UIImage from PHAsset
- CPU usage during image compression
- Network usage during Firebase Storage upload
- Memory release after upload completes

**Expected:**
- Memory spike: 10-30 MB (then drops)
- CPU: < 50% during compression
- Upload: < 2 MB per photo
- Memory drops to baseline after upload

---

### 4. AI Service Calls (GeminiService)

**Location:** `/Core/Services/GeminiService.swift`

**What to Check:**
- CPU during JSON encoding/decoding
- Network request size
- Main thread blocking (should be async)
- Response parsing time

**Expected:**
- CPU: < 30% for < 1 second
- Request: < 20 KB
- Response: < 50 KB
- Parsing: < 500ms

---

### 5. Data Aggregation (DataAggregationService)

**Location:** `/Core/Services/DataAggregationService.swift`

**What to Check:**
- CPU usage during statistics calculation
- Memory for cached aggregations
- Time to compute daily/weekly summaries

**Expected:**
- CPU: < 40% for < 1 second
- Memory: < 10 MB cached data
- Calculation: < 500ms for 100 logs

---

## Part 8: Reporting Template

### Complete Performance Report

```
===============================================
TINYTASTESTRACKER PERFORMANCE BASELINE REPORT
===============================================

Date: February 15, 2026
Xcode Version: 15.2
Device: [iPhone 15 Pro / Simulator]
iOS Version: [17.x]
Build Configuration: Release
Test Duration: 1 hour

-----------------------------------------------
MEMORY PROFILING
-----------------------------------------------

Baseline Memory:
- App Launch: _____ MB
- After Login: _____ MB
- Dashboard: _____ MB

Peak Memory:
- Photo Upload: _____ MB
- AI Request: _____ MB
- Large Lists: _____ MB

Memory Issues:
[ ] No issues detected
[ ] Minor issues (see notes)
[ ] Critical issues (see notes)

Notes: _____________________________________

-----------------------------------------------
CPU PROFILING
-----------------------------------------------

CPU Usage:
- Idle: _____%
- Active Use: _____%
- AI Requests: _____% (_____ seconds)
- Data Aggregation: _____% (_____ seconds)

Main Thread Blocking:
[ ] No blocking detected
[ ] Minor blocking (< 1s)
[ ] Critical blocking (> 2s)

Hotspots:
1. _________________________________________
2. _________________________________________

Notes: _____________________________________

-----------------------------------------------
ENERGY PROFILING
-----------------------------------------------

Energy Impact:
- Overall: [ ] Low [ ] Medium [ ] High [ ] Very High
- Idle: [ ] Low [ ] Medium [ ] High
- Active: [ ] Low [ ] Medium [ ] High

Battery Estimate:
- 1 hour usage: ~_____% battery drain

Energy Issues:
[ ] No issues detected
[ ] Minor issues (see notes)
[ ] Critical issues (see notes)

Notes: _____________________________________

-----------------------------------------------
NETWORK PROFILING
-----------------------------------------------

Data Usage (2-minute test):
- Total: _____ KB
- Firestore: _____ KB
- Images: _____ KB
- AI: _____ KB

Efficiency:
[ ] Optimal (no redundant requests)
[ ] Good (minor optimizations possible)
[ ] Needs improvement (see notes)

Notes: _____________________________________

-----------------------------------------------
OVERALL ASSESSMENT
-----------------------------------------------

Performance Rating: [ ] Excellent [ ] Good [ ] Fair [ ] Poor

Ready for TestFlight: [ ] Yes [ ] No

Blocking Issues (Must Fix):
1. _________________________________________
2. _________________________________________

Nice-to-Have Optimizations:
1. _________________________________________
2. _________________________________________

-----------------------------------------------
ATTACHMENTS
-----------------------------------------------

[ ] Screenshots of Instruments traces
[ ] Exported .trace files
[ ] Screen recording of performance issues

===============================================
```

---

## Part 9: Next Steps

### If Performance is Good ✅

1. Save this report with Instruments traces
2. Proceed to TestFlight deployment
3. Monitor crash reports for performance-related issues
4. Re-profile after significant feature additions

### If Issues Found ⚠️

1. **For Critical Issues:**
   - Document specific issue with Instruments trace
   - Prioritize fix before TestFlight
   - Re-profile after fix to confirm

2. **For Moderate Issues:**
   - Add to backlog for optimization
   - Monitor in TestFlight analytics
   - Fix if users report problems

3. **Common Fixes:**
   - **Memory Leaks:** Add `[weak self]` to closures
   - **Main Thread Blocking:** Move work to `Task { }` or background queue
   - **Excessive Allocations:** Reuse objects instead of creating new ones
   - **Timer Overhead:** Use more efficient update mechanisms

---

## Part 10: Tools & Resources

### Xcode Instruments Templates

**Must Use:**
- ✅ **Allocations** - Memory usage and leaks
- ✅ **Time Profiler** - CPU usage and hotspots
- ✅ **Network** - Data usage and requests

**Optional (Advanced):**
- **Leaks** - Dedicated leak detection
- **Energy Log** - Battery impact (requires device)
- **Core Data** - Database profiling (if using Core Data)
- **Metal** - GPU performance (if using custom rendering)

### Keyboard Shortcuts

- **⌘I** - Profile app
- **⌘R** - Run app
- **⌘.** - Stop profiling
- **⌘<** - Edit Scheme

### Export Traces for Later Analysis

1. In Instruments, select **File → Save**
2. Save as `.trace` file
3. Reopen later with **File → Open**

### Continuous Profiling

Consider profiling:
- ✅ Before every TestFlight release
- ✅ After adding new features
- ✅ When users report "app is slow"
- ✅ After major iOS updates
- ✅ Quarterly performance reviews

---

## Summary

### What You'll Accomplish (1 hour)

✅ Establish memory baseline (no leaks)
✅ Identify CPU bottlenecks (if any)
✅ Verify battery impact is acceptable
✅ Confirm network usage is efficient
✅ Document baseline for future comparison
✅ Catch critical issues before TestFlight

### Key Takeaways

1. **Profile in Release mode** - Debug builds are slower
2. **Use physical device** - For accurate energy data
3. **Test realistic scenarios** - Simulate actual parent usage
4. **Document everything** - Baselines are useful for regression detection
5. **Fix critical issues first** - Not all optimizations are urgent

### Phase 1 Completion

After completing this profiling:
- ✅ SwiftLint CI/CD fixed
- ✅ Security testing guide created
- ✅ Performance baseline established

**You're ready for TestFlight deployment!** 🚀

---

**Last Updated:** February 15, 2026
**Status:** Ready for execution
**Estimated Time:** 1 hour
**Prerequisites:** Xcode 15.2+, test data prepared
