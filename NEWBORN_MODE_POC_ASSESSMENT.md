# Assessment of Newborn Mode (POC Website)

**Source:** [https://tiny-tastes-tracker-app.vercel.app](https://tiny-tastes-tracker-app.vercel.app)
**Date:** January 14, 2026

## 1. Overview
This document outlines the features and user interface of the "Newborn Mode" observed on the Proof of Concept (POC) website. The goal is to verify the intended features and design for the iOS application's Newborn mode.

## 2. Navigation Flow
**Access Path:**
1.  Explorer Mode (Default) -> Profile Tab.
2.  Select "App Experience Mode".
3.  Change to "Newborn".
4.  Click "Save Profile".

**Immediate UI Changes:**
-   **Theme:** Transitions from the default teal/green (Explorer) to a **Rose/Indigo** color palette, indicating a distinct mode.
-   **Navigation:** The bottom tab bar updates to show mode-specific tabs.

## 3. Feature Breakdown by Tab

### A. Log Tab (Home Dashboard)
The primary dashboard focuses on immediate care and status tracking.
-   **Baby Status Widget:** Displays current state (e.g., "Awake") and date/time.
-   **Quick Stats:**
    -   *Next Feed:* Prediction or countdown.
    -   *Last Fed:* Timestamp.
    -   *Last Diaper:* Timestamp.
-   **Quick Action Buttons:** Large, accessible buttons for frequent actions:
    -   **Feed** (Bottle/Breast icon)
    -   **Diaper** (Diaper icon)
    -   **Sleep** (Moon icon)
    -   **Meds** (Pill icon)
-   **Activity Log:** Chronological list of today's events (e.g., "Fed 4oz", "Wet Diaper").

### B. Is it Normal? Tab
A dedicated safety and reassurance section.
-   **Daily Safety Check:**
    -   Tracks 24-hour totals for **Wet Diapers**, **Dirty Diapers**, and **Total Intake**.
    -   Likely compares against standard medical guidelines for newborns.
-   **Nursing Duration Chart:** Bar chart comparing today's nursing time vs. yesterday.
-   **"Is This Normal?" Button:** An AI-powered interaction point (Sage) to provide research-backed reassurance or flag potential issues based on the logs.

### C. Sleep & Growth Tab
Combines growth tracking with sleep predictability.
-   **Sleep View:**
    -   **The Sleep Sweet Spot:** A prominent feature predicting the next optimal nap window to prevent overtiredness.
    -   *Action:* "Predict Next Nap" button.
-   **Growth View:**
    -   **Gender Toggle:** Boy/Girl selector.
    -   **Measurements:** Input fields for **Weight** and **Height**.
    -   **Growth Chart:** Visualizes the baby's growth percentiles over time (likely WHO or CDC standards).

### D. Learn Tab
Educational and AI assistant hub.
-   **Sage Live:** A hands-free **Voice Assistant** feature.
    -   *Use Case:* "Hands full with baby? Just ask Sage."
-   **Research Lab (Ask Sage):** Text-based chat interface for developmental questions.

### E. Profile Tab
Standard settings with mode-specific styling.
-   Displays Baby's Name, Birthday, and Allergies.
-   Allows switching back to other modes (Explorer, Toddler).

## 4. Key Improvements for iOS App
Based on this POC assessment, the following features should be verified or prioritized in the iOS app roadmap:

1.  **Sleep Sweet Spot Algorithm:** The current iOS app roadmap mentions this as a "Feature Gap" (Item #13). The POC demonstrates a clear UI implementation for this ("Predict Next Nap" button).
2.  **"Is it Normal?" Safety Checks:** Ensure the iOS app has the logic to calculate 24h totals and trigger alerts/reassurance, not just simple logging.
3.  **Sage Live (Voice Mode):** The POC emphasizes "Hands Free" interaction. Verify the iOS implementations of `VoiceChat` align with this (auto-listening, audio playback).
4.  **Distinct Theming:** Confirm the iOS app correctly applies the Rose/Indigo theme when switching to Newborn mode, matching the POC's visual cue.
