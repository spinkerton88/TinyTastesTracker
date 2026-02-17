# Tiny Tastes Tracker - AI Context Profile

**Version:** 1.0  
**Last Updated:** February 16, 2026  
**Purpose:** Quick reference for AI assistants to understand the complete project context

---

## 🎯 Project Overview

**Tiny Tastes Tracker** is an intelligent iOS baby tracking application that grows with your child from birth through toddlerhood, featuring AI-powered insights and personalized recommendations.

**Target Audience:** Parents of children aged 0-3 years  
**Platform:** iOS 17.0+  
**Tech Stack:** SwiftUI, Firebase (Firestore + Auth), Google Gemini AI  
**Development Status:** Production-ready, migrated from SwiftData to Firebase

---

## 🌟 Core Value Proposition

**"The intelligent baby tracking app that grows with your child"**

Unlike generic baby trackers, Tiny Tastes Tracker:
- **Adapts** to your child's developmental stage (Newborn → Explorer → Toddler)
- **Learns** from your data to provide personalized AI recommendations
- **Guides** parents through critical nutrition milestones
- **Simplifies** complex tasks like meal planning and pediatrician visits

---

## 🎨 Product Features by Mode

### 🌙 Newborn Mode (0-6 Months)

**Core Tracking:**
- Sleep sessions with quality ratings and Live Activities (Dynamic Island/Lock Screen)
- Feeding management (nursing sessions, bottle feeds with amounts)
- Diaper logs (wet/dirty patterns for health insights)
- Growth tracking (weight, height, head circumference)
- Medication logging
- Pumping sessions

**Smart Features:**
- AI-powered sleep predictions (next sleep window)
- Widgets for quick-glance feeding information
- Real-time sleep timer on Lock Screen

**Use Case:** New parents tracking basic health metrics, looking for patterns in sleep/feeding

---

### 🥄 Explorer Mode (6-12 Months)

**Core Tracking:**
- Food introduction tracker (200+ foods database)
- Reaction monitoring (allergies, preferences, dislikes)
- Category progress visualization (fruits, vegetables, proteins, etc.)
- First foods guidance (age-appropriate recommendations)

**Smart Features:**
- Allergen alerts and 2-hour monitoring prompts
- Milestone badges for food exploration achievements
- Visual progress tracking across food groups

**Use Case:** Parents introducing solids, monitoring for allergies, celebrating firsts

---

### 🌈 Toddler Mode (12+ Months)

**Core Tracking:**
- "Eat the Rainbow" color variety tracking
- Nutrition balance monitoring (Iron, Calcium, Vitamin C, Omega-3, Protein)
- Complete meal logging with portions
- Recipe management (save, scan via OCR, AI-generate)
- Weekly meal planning with automatic shopping lists

**Smart Features:**
- Barcode scanning for packaged foods (Open Food Facts API)
- Recipe OCR from photos/cookbooks
- AI-powered picky eater strategies
- Meal builder with nutritional insights
- Shopping list export to iOS Reminders

**Use Case:** Parents managing toddler nutrition, meal planning, dealing with picky eating

---

## 🤖 Sage AI Assistant

**Capabilities:**
- Context-aware guidance based on child's data (age, allergens, history)
- Voice chat for hands-free interaction
- Smart food recommendations and meal ideas
- Sleep pattern analysis and predictions
- Picky eater strategy suggestions
- Pediatrician visit preparation

**Technology:**
- Google Gemini API (text and vision models)
- Real-time voice streaming
- Conversation history (session-only, not persisted)
- Photo analysis for food identification

**Privacy:**
- Only sends necessary context (age, allergens, not child's name)
- No automatic data sharing (user-initiated only)
- Rate-limited (10/min, 100/hour, 1000/day)

---

## 🏗️ Technical Architecture

### Data Layer
**Backend:** Firebase Firestore (migrated from SwiftData in Feb 2026)
- Real-time sync across devices
- Offline-first architecture with persistence
- User authentication via Firebase Auth (Email/Password + Google)
- Multi-child support with profile switching

**Data Models (28 total):**
- **Newborn:** NursingLog, BottleFeedLog, DiaperLog, SleepLog, PumpingLog, MedicationLog, GrowthMeasurement, ActivityLog
- **Toddler:** MealLog, TriedFoodLog, CustomFood, NutrientGoals, Recipe, MealPlanEntry, ShoppingListItem
- **System:** UserProfile, ParentProfile, ChildProfile, Badge, Milestone, PediatricianSummary

### Application Layer
**Pattern:** Coordinator + Manager architecture
- `AppState` - Central coordinator delegating to domain managers
- `NewbornManager` - Sleep, feeding, diapers, bottles, growth
- `ToddlerManager` - Meals, nutrition, food logs
- `RecipeManager` - Recipes, meal plans, shopping lists
- `AIServiceManager` - Centralized AI interactions

**UI Framework:** SwiftUI with `@Observable` pattern

### Integration Layer
**Third-Party Services:**
1. **Google Gemini AI** - AI features, image analysis, voice chat
2. **Open Food Facts** - Nutrition data for packaged foods (barcode scanning)
3. **Apple EventKit** - Shopping list export to Reminders
4. **Firebase** - Authentication, database, offline sync

---

## 🔐 Privacy & Security

### Data Storage
- **Local-first:** All data stored on-device with Firestore offline persistence
- **Encrypted:** iOS file-level encryption + HTTPS/TLS for network
- **No tracking:** No analytics, no behavioral advertising
- **User control:** Full data export (JSON/CSV) and deletion capabilities

### AI Data Sharing
**What's sent to Gemini:**
- User questions/prompts
- Child's age and known allergens (for safety)
- Photos (when user explicitly shares for analysis)
- Conversation history (current session only)

**What's NOT sent:**
- Child's name
- Specific meal/sleep logs (unless user shares in prompt)
- Location data
- Any data without user initiation

### Compliance
- ✅ **COPPA Compliant** - Parents control all data
- ✅ **GDPR Compliant** - Data export, deletion, portability
- ✅ **App Store Privacy** - Full disclosure of data practices

---

## 🎯 Target User Personas

### 1. **First-Time Parent (Newborn Mode)**
- **Age:** 25-35
- **Pain Points:** Overwhelmed, sleep-deprived, tracking everything manually
- **Goals:** Understand baby's patterns, prepare for pediatrician visits
- **Key Features:** Sleep tracking, feeding logs, AI sleep predictions

### 2. **Organized Planner (Explorer Mode)**
- **Age:** 28-38
- **Pain Points:** Worried about allergies, wants structured approach to solids
- **Goals:** Safely introduce foods, track reactions, celebrate milestones
- **Key Features:** Food introduction tracker, allergen monitoring, progress visualization

### 3. **Nutrition-Conscious Parent (Toddler Mode)**
- **Age:** 30-40
- **Pain Points:** Picky eater, meal planning fatigue, nutritional balance concerns
- **Goals:** Ensure balanced diet, simplify meal planning, expand palate
- **Key Features:** Nutrition tracking, meal planning, AI recipe suggestions, picky eater strategies

---

## 🚀 Competitive Advantages

### vs. Generic Baby Trackers (Baby Tracker, Huckleberry)
- ✅ **Adaptive modes** that grow with child (not just newborn focus)
- ✅ **AI-powered insights** beyond basic charts
- ✅ **Nutrition-first approach** for toddler years
- ✅ **Meal planning integration** (not just tracking)

### vs. Nutrition Apps (MyFitnessPal, Yummly)
- ✅ **Child-specific** nutrition goals and recommendations
- ✅ **Developmental context** (age-appropriate foods)
- ✅ **Allergen safety** built-in
- ✅ **Picky eater strategies** from AI

### vs. Meal Planning Apps (Mealime, Plan to Eat)
- ✅ **Integrated tracking** (what they ate + what you planned)
- ✅ **Child nutrition focus** (not adult meal prep)
- ✅ **AI recipe adaptation** for toddler preferences
- ✅ **Shopping list auto-generation** from meal plans

---

## 📊 Key Metrics & Success Indicators

### User Engagement
- Daily active users tracking at least one log
- Average logs per user per day
- Feature adoption rates (Newborn → Explorer → Toddler progression)

### AI Usage
- Sage chat sessions per user per week
- Voice chat vs. text chat ratio
- Recipe generation requests
- Photo analysis usage

### Retention
- 7-day, 30-day, 90-day retention rates
- Churn points (when users stop using app)
- Feature stickiness (which features drive retention)

---

## 🛣️ Product Roadmap

### ✅ Completed (Current State)
- Multi-mode tracking (Newborn, Explorer, Toddler)
- Firebase migration (authentication, real-time sync, offline support)
- Sage AI assistant with voice chat
- Recipe management (OCR, AI generation, meal planning)
- Barcode scanning for nutrition data
- Multi-child support with profile switching
- Widgets and Live Activities
- Localization infrastructure (English base)

### 🚧 In Progress
- Pediatrician summary generation (AI-powered visit prep)
- Messy face photo gallery (link photos to food logs)
- Enhanced allergen monitoring notifications
- Translations (Spanish, French)

### 📅 Planned Features
- **TestFlight Deployment** - Beta testing program
- **iCloud Photo Sync** - Sync photos across devices
- **Family Collaboration** - Share profiles with partners/caregivers
- **HealthKit Integration** - Sync growth data with Apple Health
- **Shareable Milestone Cards** - Social media-ready achievements
- **Daycare Report Ingestion** - Parse and import daycare logs (PDF/image OCR)
- **Advanced Analytics** - Growth percentiles, nutrition trends
- **Expanded Food Database** - 500+ foods with cultural variety

---

## 💡 Marketing Angles

### Emotional Hooks
1. **"Never forget a first"** - Milestone tracking and celebration
2. **"Sleep when the baby sleeps... but know when that is"** - AI sleep predictions
3. **"From first foods to favorite foods"** - Journey through nutrition milestones
4. **"Your AI parenting partner, always on call"** - Sage assistant availability
5. **"Turn picky eaters into adventurous eaters"** - Toddler mode focus

### Feature-Based Messaging
1. **For New Parents:** "Track everything, understand patterns, prepare for doctor visits"
2. **For Allergy-Conscious Parents:** "Safely introduce foods with built-in allergen monitoring"
3. **For Busy Parents:** "AI-powered meal planning that actually works for toddlers"
4. **For Data-Driven Parents:** "Beautiful charts and insights from your baby's data"

### Differentiation
- **"The only baby app that grows with your child"** - Adaptive modes
- **"AI that knows your child"** - Personalized recommendations based on actual data
- **"From tracking to planning"** - Not just logs, but actionable meal plans
- **"Privacy-first parenting tech"** - Local data, no selling, full control

---

## 🎨 Design Philosophy

### Visual Identity
- **Clean, modern SwiftUI design** with iOS native patterns
- **Playful but professional** - Emojis for food categories, serious data visualization
- **Color-coded systems** - Rainbow tracking, nutrition categories
- **Adaptive UI** - Changes based on child's age/mode

### User Experience Principles
1. **Quick logging** - Most actions in 3 taps or less
2. **Contextual AI** - Sage appears when helpful, not intrusive
3. **Offline-first** - Works without internet (critical for new parents)
4. **Forgiving** - Easy to edit/delete logs, undo actions
5. **Celebratory** - Badges, milestones, positive reinforcement

---

## 🔧 Development Practices

### Code Quality
- **SwiftLint** and **SwiftFormat** for consistency
- **XcodeGen** for project management (project.yml)
- **Modular architecture** - Clear separation of concerns
- **Type-safe** - Minimal force-unwrapping, comprehensive error handling

### Testing Strategy
- Unit tests for managers and services
- UI tests for critical flows (onboarding, logging)
- Manual testing on physical devices (not just simulator)
- Firebase emulator for local development

### Security Measures
- API key obfuscation (XOR cipher + Base64)
- Rate limiting on AI requests
- Usage monitoring and anomaly detection
- Firestore security rules (user-owned data only)

---

## 📱 Platform Details

**Minimum Requirements:**
- iOS 17.0+
- iPhone (optimized for iPhone 14/15/16)
- iPad support (adaptive layouts)

**Key iOS Integrations:**
- **Live Activities** - Real-time sleep timer on Lock Screen/Dynamic Island
- **Widgets** - Home Screen widgets for last feed, next sleep
- **App Shortcuts** - Siri integration for quick logging
- **EventKit** - Shopping list export to Reminders
- **Camera/Photos** - Barcode scanning, meal photos, recipe OCR
- **VoiceOver** - Accessibility support for vision-impaired users

---

## 🌍 Localization Status

**Current:** English (US) - Base language  
**In Progress:** Spanish, French  
**Planned:** Mandarin, German, Portuguese

**Localization Scope:**
- All UI strings (45+ keys in Localizable.strings)
- Food database names (200+ foods)
- Allergen information
- Error messages and notifications
- AI prompt templates (for localized Sage responses)

---

## 📈 Business Model (Future Considerations)

**Current:** Free app (no monetization)

**Potential Models:**
1. **Freemium** - Basic tracking free, AI features premium ($4.99/month)
2. **One-Time Purchase** - $9.99 unlock all features
3. **Family Plan** - $7.99/month for unlimited children + family sharing
4. **Pediatrician Partnership** - White-label for medical practices

**No Plans For:**
- Advertising (privacy-first commitment)
- Data selling (never)
- Subscription for basic tracking (core features always free)

---

## 🎓 Educational Content Opportunities

### In-App Guides
- "Introduction to Solids: A 6-Month Timeline"
- "Understanding Allergen Introduction (Top 9)"
- "Balanced Toddler Nutrition: Beyond the Food Pyramid"
- "Reading Your Baby's Sleep Cues"

### Blog/Marketing Content
- "Why Tracking Matters: The Science of Baby Patterns"
- "AI in Parenting: How Machine Learning Helps New Parents"
- "The Rainbow Method: Teaching Toddlers to Eat Colorfully"
- "Meal Prep for Picky Eaters: 10 AI-Generated Recipes"

### Social Media
- **Instagram:** Milestone celebrations, messy face photos, recipe ideas
- **TikTok:** Quick tips, AI chat demos, meal planning hacks
- **Pinterest:** Printable growth charts, meal plan templates, food introduction guides
- **YouTube:** Feature tutorials, parent testimonials, nutrition deep-dives

---

## 🤝 Partnership Opportunities

### Potential Collaborators
1. **Pediatricians/Pediatric Practices** - Recommend app, integrate summaries
2. **Lactation Consultants** - Feeding tracking for breastfeeding support
3. **Nutritionists/Dietitians** - Toddler meal planning expertise
4. **Baby Food Brands** - Recipe partnerships (organic, allergen-free)
5. **Parenting Influencers** - Authentic reviews and demos

### Integration Opportunities
1. **HealthKit** - Sync growth data with Apple Health
2. **Google Fit** - Android version (future)
3. **Smart Scales** - Auto-import weight measurements
4. **Baby Monitors** - Import sleep data from Nanit, Owlet, etc.

---

## 🐛 Known Limitations & Future Improvements

### Current Limitations
1. **iOS Only** - No Android version (Firebase makes this easier in future)
2. **English-First** - Translations in progress
3. **Manual Logging** - No automatic tracking (requires user input)
4. **Photo Storage** - Large galleries may impact storage
5. **AI Costs** - Gemini API usage needs monitoring at scale

### Planned Improvements
1. **Smarter Defaults** - Learn from user patterns to pre-fill logs
2. **Predictive Logging** - "It's been 3 hours, time to feed?"
3. **Photo Compression** - Optimize storage without quality loss
4. **Batch Operations** - Edit/delete multiple logs at once
5. **Export Formats** - PDF reports, CSV data, shareable charts

---

## 📞 Support & Community

### User Support Channels
- In-app help documentation
- Email support (planned)
- FAQ section in Settings
- Video tutorials (planned)

### Community Building
- Private Facebook group for beta testers
- Discord server for power users
- Reddit community (r/TinyTastesTracker)
- User-generated recipe sharing (future feature)

---

## 🎯 Success Stories (Hypothetical Use Cases)

### Story 1: Sleep Pattern Discovery
*"After 2 weeks of tracking, Sage AI noticed my baby sleeps better after evening baths. I adjusted our routine and she's sleeping 30 minutes longer!"*

### Story 2: Allergy Identification
*"The allergen monitoring caught my son's egg sensitivity early. The 2-hour check-in prompts helped me document symptoms for our pediatrician."*

### Story 3: Picky Eater Breakthrough
*"The AI suggested serving broccoli with cheese sauce. My toddler who 'hates vegetables' now asks for 'trees with cheese' every night!"*

### Story 4: Pediatrician Visit Prep
*"I generated a 2-month summary before our checkup. The doctor was impressed with the data and we had a much more productive conversation."*

---

## 📚 Additional Resources

### Internal Documentation
- `README.md` - Developer setup and architecture overview
- `ROADMAP.md` - Feature implementation timeline
- `DATA_HANDLING.md` - Privacy and data flow documentation
- `FIREBASE_MIGRATION_PLAN.md` - Technical migration details
- `TESTFLIGHT_DEPLOYMENT_GUIDE.md` - Beta deployment process

### External References
- [Google Gemini API Docs](https://ai.google.dev/docs)
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Open Food Facts API](https://world.openfoodfacts.org/data)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## 🔑 Key Takeaways for AI Assistants

When discussing Tiny Tastes Tracker, remember:

1. **It's adaptive** - Not just a baby tracker, it grows through 3 distinct modes
2. **It's intelligent** - AI is core to the experience, not a gimmick
3. **It's privacy-first** - Local data, user control, no tracking/selling
4. **It's comprehensive** - From sleep tracking to meal planning to pediatrician prep
5. **It's modern** - SwiftUI, Firebase, latest iOS features (Live Activities, Widgets)
6. **It's in production** - Real app, real users (or ready for them), not a prototype

**Unique Selling Point:** The only baby app that combines newborn tracking, food introduction guidance, and toddler meal planning with AI-powered insights—all while respecting your privacy.

---

**End of Context Profile**  
*For questions or updates, refer to the project documentation in `/docs`*
