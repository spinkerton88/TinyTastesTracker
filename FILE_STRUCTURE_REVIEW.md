# Project File Structure Review

This document analyzes the current file structure of `TinyTastesTracker` and provides recommendations to improve organization, reduce clutter, and follow standard practices.

## 🚨 Critical Issues (Immediate Action Recommended)

### 1. Remove Redundant Nested Folder
**Path:** `TinyTastesTracker/TinyTastesTracker/TinyTastesTracker`
- **Issue:** This folder appears to be a mistake (likely a drag-and-drop error or bad clone). It contains incomplete `Features` and `Shared` folders that are essentially stale duplicates of the main code.
- **Recommendation:** **DELETE** this entire folder.
- **Why:** It causes confusion and potential import errors if Xcode accidentally references files inside it.

### 2. Clean Up Root Directory Clutter
**Path:** `TinyTastesTracker/` (Root)
- **Issue:** There are over 40 Markdown (`.md`) files in the root directory. This makes it hard to find the actual `README.md` or project configuration files.
- **Recommendation:** Create a `docs/` directory and move these files into organized subfolders (e.g., `docs/plans`, `docs/guides`, `docs/reports`).
- **Why:** Keeps the root directory clean and makes documentation easier to browse.

### 3. Remove Temporary Log Files
**Path:** `TinyTastesTracker/*.log`, `TinyTastesTracker/*.txt`
- **Issue:** Files like `build_log.txt`, `onboarding_test_log.txt`, and `local_test_log.txt` are large and unnecessary for the repository.
- **Recommendation:** **DELETE** all these files. Your `.gitignore` already excludes `*.log`, so these are likely local clutter.
- **Why:** Reduces disk usage and visual noise.

---

## 📂 Proposed New Structure

```text
TinyTastesTracker/
├── .github/                 # GitHub Actions & Templates
├── App/                     # Main App Entry Points (TinyTastesTrackerApp.swift)
├── AppShortcuts/            # App Intents & Shortcuts
├── Assets.xcassets/         # Images & Colors
├── Core/                    # Core Business Logic (Models, Services, Managers)
├── Features/                # Feature Modules (Toddler, Newborn, etc.)
├── Resources/               # Plists, Strings, JSONs
├── Shared/                  # Shared UI Components & Utilities
├── UI/                      # Global UI Systems (Theme, Design System)
├── scripts/                 # Utility Scripts (Python, Shell)
├── docs/                    # [NEW] Moved Documentation
│   ├── plans/               # MIGRATION_PLAN.md, FEATURE_TASKS.md
│   ├── guides/              # CONTIBUTING.md, SETUP.md
│   └── reports/             # assessments, analysis
└── TinyTastesTracker.xcodeproj
```

---

## ✅ Action Plan (Step-by-Step)

### Step 1: Delete Redundant Folder
```bash
rm -rf "TinyTastesTracker/TinyTastesTracker/TinyTastesTracker"
```

### Step 2: Delete Log & Txt Files
```bash
find . -maxdepth 1 -name "*.log" -delete
find . -maxdepth 1 -name "*.txt" -delete
```

### Step 3: Organize Documentation
```bash
mkdir -p docs/plans docs/guides docs/reports docs/legacy

# Move Plans
mv *PLAN.md docs/plans/
mv *TASKS.md docs/plans/
mv *ROADMAP.md docs/plans/

# Move Guides
mv *GUIDE.md docs/guides/
mv *SETUP.md docs/guides/
mv *HOWTO.md docs/guides/

# Move Reports/Analysis
mv *ANALYSIS.md docs/reports/
mv *ASSESSMENT.md docs/reports/
mv *REPORT.md docs/reports/
mv *REVIEW.md docs/reports/

# Keep Critical Files in Root
# Keep: README.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md
```

### Step 4: Verify Xcode Project
After these changes, open `TinyTastesTracker.xcodeproj` to ensure no file references were broken (mainly relevant if you deleted source code, but since we are deleting the *duplicate* folder, it should be fine).
