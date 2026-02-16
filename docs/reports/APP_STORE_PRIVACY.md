# App Store Privacy Documentation

**Last Updated:** January 12, 2026  
**Purpose:** Answers for App Store Connect Privacy Questionnaire

## Overview

This document provides pre-filled answers for the App Store Connect privacy questionnaire. Use these answers when submitting Tiny Tastes Tracker to the App Store.

---

## Privacy Nutrition Labels

### Data Collection Summary

**Does your app collect data?** YES

**Data Types Collected:**

#### 1. Health & Fitness
- **What:** Meal logs, sleep logs, diaper logs, bottle logs, growth measurements
- **Purpose:** App Functionality
- **Linked to User:** NO (data is local, not linked to identity)
- **Used for Tracking:** NO

#### 2. Photos or Videos
- **What:** Meal photos, recipe photos, child profile photos
- **Purpose:** App Functionality
- **Linked to User:** NO (stored locally)
- **Used for Tracking:** NO

#### 3. User Content
- **What:** Recipes, meal plans, notes, AI chat messages
- **Purpose:** App Functionality
- **Linked to User:** NO (stored locally)
- **Used for Tracking:** NO

#### 4. Other Data
- **What:** Child's name, date of birth, allergens
- **Purpose:** App Functionality
- **Linked to User:** NO (stored locally)
- **Used for Tracking:** NO

---

## Detailed Privacy Questionnaire Answers

### Section 1: Data Collection

**Q: Does this app collect data from users?**  
A: **YES**

**Q: What types of data does this app collect?**  
A: Select the following:
- [x] Health & Fitness
- [x] Photos or Videos
- [x] User Content
- [x] Other Data Types

---

### Section 2: Health & Fitness Data

**Q: What health and fitness data does your app collect?**  
A: 
- Nutrition (meal logs, food intake)
- Sleep (sleep duration, quality)
- Other health data (diaper logs, bottle feeding, growth measurements)

**Q: How is this data used?**  
A: 
- [x] App Functionality (tracking baby's health and development)
- [ ] Analytics (NO)
- [ ] Product Personalization (NO - personalization is local, not server-based)
- [ ] Advertising (NO)
- [ ] Other Purposes (NO)

**Q: Is this data linked to the user's identity?**  
A: **NO**
- Data is stored locally on the device
- No user account or authentication
- No server-side storage
- Cannot be traced back to a specific user

**Q: Is this data used to track the user?**  
A: **NO**
- No cross-app tracking
- No cross-site tracking
- No advertising tracking

---

### Section 3: Photos or Videos

**Q: What photos or videos does your app collect?**  
A: Photos of meals, recipes, and child profile pictures

**Q: How is this data used?**  
A:
- [x] App Functionality (display in meal logs, recipes, profiles)
- [ ] Analytics (NO)
- [ ] Product Personalization (NO)
- [ ] Advertising (NO)
- [ ] Other Purposes (NO)

**Q: Is this data linked to the user's identity?**  
A: **NO**
- Photos are stored locally on the device
- No server-side storage (except when user explicitly uses AI analysis)
- When sent to Google Gemini for analysis, photos are not linked to user identity

**Q: Is this data used to track the user?**  
A: **NO**

---

### Section 4: User Content

**Q: What user content does your app collect?**  
A:
- Recipes (titles, ingredients, instructions)
- Meal plans
- Notes and observations
- AI chat messages

**Q: How is this data used?**  
A:
- [x] App Functionality (store and display user-created content)
- [ ] Analytics (NO)
- [ ] Product Personalization (NO)
- [ ] Advertising (NO)
- [ ] Other Purposes (NO)

**Q: Is this data linked to the user's identity?**  
A: **NO**
- Content is stored locally
- AI chat messages are sent to Google Gemini but not linked to user identity
- No user accounts or authentication

**Q: Is this data used to track the user?**  
A: **NO**

---

### Section 5: Other Data Types

**Q: What other data does your app collect?**  
A:
- Child's name
- Child's date of birth
- Child's gender
- Allergen information

**Q: How is this data used?**  
A:
- [x] App Functionality (personalize recommendations based on child's age)
- [ ] Analytics (NO)
- [ ] Product Personalization (NO - personalization is local)
- [ ] Advertising (NO)
- [ ] Other Purposes (NO)

**Q: Is this data linked to the user's identity?**  
A: **NO**
- Data is stored locally
- Child's name is never sent to external services
- Only age and allergens are sent to AI (for safety), not linked to identity

**Q: Is this data used to track the user?**  
A: **NO**

---

### Section 6: Data Usage

**Q: Does your app use data for tracking purposes?**  
A: **NO**

**Q: Does your app or third-party partners use data for tracking purposes?**  
A: **NO**

**Explanation:**
- We do not track users across apps or websites
- We do not use data for advertising
- We do not share data with data brokers
- Google Gemini AI processes data for app functionality only, not for tracking

---

### Section 7: Third-Party SDKs

**Q: Does your app use third-party SDKs?**  
A: **YES**

**Q: Which third-party SDKs does your app use?**  
A:
1. **Google Gemini AI SDK** (`GoogleGenerativeAI`)
   - Purpose: AI-powered recommendations and food analysis
   - Data shared: User questions, child's age/allergens, photos (when user initiates analysis)
   - Privacy policy: https://policies.google.com/privacy
   - Tracking: NO

**Q: Do these SDKs collect data?**  
A: **YES** (Google Gemini AI processes data sent by the app)

**Q: What data do these SDKs collect?**  
A:
- User-generated content (questions, photos for analysis)
- Child's age and allergen information (for context)

**Q: Is this data linked to the user's identity?**  
A: **NO**
- No user accounts or authentication
- Data is processed anonymously by Google Gemini API

**Q: Is this data used for tracking?**  
A: **NO**

---

### Section 8: Data Retention and Deletion

**Q: How long do you retain user data?**  
A:
- **Local data:** Retained until user deletes it or deletes the app
- **Third-party data (Google Gemini):** Retained per Google's API terms (~30 days)

**Q: Can users request deletion of their data?**  
A: **YES**
- Users can delete specific data types (meal logs, sleep logs, etc.)
- Users can delete all data via Settings → Privacy & Data → Delete All Data
- Deleting the app removes all local data

**Q: Can users request a copy of their data?**  
A: **YES**
- Users can export all data in JSON or CSV format
- Export available via Settings → Privacy & Data → Export All Data

---

### Section 9: Data Security

**Q: How do you protect user data?**  
A:
- **Local storage:** Data is stored in iOS's encrypted SwiftData database
- **Device security:** Protected by device passcode/biometric authentication
- **Network security:** All API calls use HTTPS/TLS encryption
- **API key protection:** Gemini API key is obfuscated with rate limiting and usage monitoring
- **No central server:** No backend server collecting user data

**Q: Do you encrypt data in transit?**  
A: **YES** (HTTPS/TLS for all network requests)

**Q: Do you encrypt data at rest?**  
A: **YES** (iOS file-level encryption)

---

### Section 10: Children's Privacy

**Q: Is your app directed at children under 13?**  
A: **NO**

**Explanation:**
- The app is designed for parents and caregivers (ages 18+)
- Parents provide information about their children
- We do not knowingly collect data directly from children under 13
- COPPA compliance: Parents have full control over their child's data

**Q: Does your app comply with COPPA?**  
A: **YES**
- App is for parental use only
- No direct data collection from children
- Parents can delete all data about their child
- Privacy policy clearly states data practices

---

### Section 11: International Privacy Laws

**Q: Does your app comply with GDPR?**  
A: **YES**

**GDPR Rights Supported:**
- [x] Right to Access (users can view all data in the app)
- [x] Right to Rectification (users can edit data)
- [x] Right to Erasure (users can delete data)
- [x] Right to Data Portability (users can export data)
- [x] Right to Restrict Processing (users can avoid AI features)
- [x] Right to Object (users can contact us)

**Q: Where is user data stored?**  
A:
- **Local data:** On the user's device (in their country)
- **Third-party processing:** Google Gemini API (may be processed in the US)
- **Compliance:** Google complies with EU-US Data Privacy Framework

---

## Privacy Policy URL

**Q: What is the URL of your privacy policy?**  
A: **[TO BE FILLED]**

**Before App Store submission:**
1. Host PRIVACY_POLICY.md on a public website
2. Ensure it's accessible without authentication
3. Use a permanent URL (e.g., https://tinytastestracker.com/privacy)
4. Enter the URL in App Store Connect

**Temporary options:**
- GitHub Pages (free)
- Netlify/Vercel (free)
- Your own website

---

## App Privacy Report (iOS 15+)

iOS 15+ includes an App Privacy Report that shows users:
- Which permissions your app has used
- Which domains your app has contacted
- How often

**Domains Tiny Tastes Tracker contacts:**
- `generativelanguage.googleapis.com` (Google Gemini AI)
- `world.openfoodfacts.org` (Open Food Facts API)

**Permissions used:**
- Camera (for barcode scanning and photos)
- Photo Library (for uploading photos)
- Reminders (optional, for shopping list export)

**Recommendation:** Test the App Privacy Report before submission to ensure it shows expected behavior.

---

## Common Mistakes to Avoid

### ❌ Incorrect Answers

1. **"Data is linked to user identity"**
   - WRONG if you don't have user accounts
   - Tiny Tastes Tracker stores data locally, not linked to identity

2. **"Data is used for tracking"**
   - WRONG if you don't do cross-app/cross-site tracking
   - Tiny Tastes Tracker does not track users

3. **"No third-party SDKs"**
   - WRONG - we use Google Gemini AI SDK
   - Must disclose all third-party SDKs

4. **"No data collection"**
   - WRONG - we collect health data, photos, user content
   - Must disclose all data collection

### ✅ Correct Approach

- Be transparent about all data collection
- Clearly state data is stored locally (not linked to identity)
- Disclose third-party SDKs (Google Gemini AI)
- Emphasize no tracking or advertising
- Provide clear data deletion and export options

---

## Pre-Submission Checklist

Before submitting to App Store:

- [ ] Privacy policy hosted on public URL
- [ ] Privacy policy URL added to App Store Connect
- [ ] All privacy questionnaire answers reviewed
- [ ] Third-party SDKs disclosed (Google Gemini AI)
- [ ] Data collection purposes clearly stated
- [ ] "No tracking" confirmed
- [ ] COPPA compliance verified
- [ ] GDPR compliance verified
- [ ] Data deletion feature tested
- [ ] Data export feature tested
- [ ] App Privacy Report reviewed
- [ ] Screenshots don't show real child data (use demo data)

---

## Updates and Maintenance

**When to update privacy labels:**
- Adding new data collection
- Adding new third-party SDKs
- Changing data usage purposes
- Adding tracking or advertising
- Changing data retention policies

**How to update:**
1. Update PRIVACY_POLICY.md
2. Update this document (APP_STORE_PRIVACY.md)
3. Submit app update with new privacy labels
4. Apple reviews changes before approval

---

## Resources

- [App Store Privacy Guidelines](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Privacy Nutrition Labels](https://developer.apple.com/app-store/app-privacy-details/)
- [COPPA Compliance](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)
- [GDPR Overview](https://gdpr.eu/)
- [Google Gemini API Privacy](https://ai.google.dev/terms)

---

**Last Updated:** January 12, 2026  
**Next Review:** Before App Store submission  
**Maintainer:** Development Team
