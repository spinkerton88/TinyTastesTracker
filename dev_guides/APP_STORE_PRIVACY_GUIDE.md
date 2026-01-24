# App Store Privacy "Nutrition Label" Guide

This guide contains the exact answers you need to select in App Store Connect under **App Privacy**.

## 1. Data Collection
**Question:** Do you or your third-party partners collect data from this app?
**Answer:** **YES**

## 2. Data Types
Select the following data types:

| Data Type | Specific Data | Purpose |
| :--- | :--- | :--- |
| **Contact Info** | None | (We do not collect email/phone linked to identity) |
| **Health & Fitness** | Health; Fitness | App Functionality (Tracking meals/sleep) |
| **User Content** | Photos or Videos; Other User Content | App Functionality (Food photos, daily logs) |
| **Identifiers** | Device ID | App Functionality (CloudKit sync) |
| **Diagnostics** | Crash Data; Performance Data | Analytics (if you use them, otherwise No) |

## 3. Data Usage & Links
For each data type selected above, you must answer three questions:

---

### A. Health & Fitness
1.  **How is this data used?** -> **App Functionality**
2.  **Is this data linked to the user's identity?** -> **YES** (Linked via iCloud ID)
3.  **Is this data used for tracking purposes?** -> **NO**

### B. User Content (Photos/Logs)
1.  **How is this data used?** -> **App Functionality**
2.  **Is this data linked to the user's identity?** -> **YES**
3.  **Is this data used for tracking purposes?** -> **NO**

### C. Identifiers (Device ID)
1.  **How is this data used?** -> **App Functionality**
2.  **Is this data linked to the user's identity?** -> **YES**
3.  **Is this data used for tracking purposes?** -> **NO**

---

## 4. Privacy Links
When asked for URLs in App Store Connect:

*   **Privacy Policy URL:** `https://tinytastestracker.com` (or `https://[your-username].github.io/TinyTastesTracker/`)
*   **User Privacy Choices URL:** [Leave Blank] (Not required for this business model)

## 5. Age Rating (COPPA Compliance)
Since this app is for **Parents** but tracks **Children**, Apple has specific questions.

*   **Question:** Is your app made for kids?
*   **Answer:** **NO**. Select "This app is intended for use by parents/adults."
    *   *Why?* Apps "Made for Kids" have severe restrictions on third-party analytics and AI. Since your user is the *parent* logging the data, you categorize it as a tool for adults.

## 6. GDPR Compliance (International)
*   **Data Minimization:** We only collect what is needed for features.
*   **Right to Delete:** The app includes a "Delete All Data" button in Settings.
*   **Data Export:** The app includes an "Export Data" feature.
*   **Consent:** Users agree to Terms/Privacy Policy upon onboarding.
