# 🍼 Tiny Tastes Tracker

**The intelligent baby tracking app that grows with your child**

Tiny Tastes Tracker is a comprehensive iOS application designed to help parents track their child's journey from birth through toddlerhood, with AI-powered insights and personalized recommendations.

![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)

---

## ✨ Features

### 🌙 Newborn Mode (0-6 Months)
- **Sleep Tracking**: Log sleep sessions with quality ratings
- **Feeding Management**: Track nursing sessions, bottle feeds with amounts
- **Diaper Logs**: Monitor wet/dirty diapers for health insights
- **Growth Tracking**: Record weight, height, and head circumference
- **Live Activities**: Real-time sleep timer on Dynamic Island/Lock Screen
- **Widgets**: Quick-glance feeding information

### 🥄 Explorer Mode (6-12 Months)
- **Food Introduction**: Track 200+ foods your baby tries
- **Reaction Monitoring**: Log allergies, preferences, and reactions
- **Category Progress**: View progress across food groups
- **First Foods Guidance**: Age-appropriate food recommendations
- **Milestone Badges**: Celebrate food exploration achievements

### 🌈 Toddler Mode (12+ Months)
- **Eat the Rainbow**: Track color variety in meals
- **Nutrition Balance**: Monitor critical nutrients (Iron, Calcium, Vitamin C, Omega-3, Protein)
- **Meal Builder**: Plan and log complete meals
- **Recipe Management**: Save, scan (OCR), and AI-generate recipes
- **Weekly Meal Plans**: Organize meals with automatic shopping lists
- **Picky Eater Strategies**: AI-powered techniques to expand palates

### 🤖 Sage AI Assistant
- **Context-Aware Guidance**: Personalized advice based on your child's data
- **Voice Chat**: Ask questions hands-free while caring for your baby
- **Smart Recommendations**: Food suggestions, meal ideas, and strategies
- **Sleep Predictions**: AI-powered next sleep window predictions

---

## 🚀 Getting Started

### Prerequisites

- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0+
- **macOS**: Sonoma (14.0) or later
- **XcodeGen**: For project file generation
- **Google Gemini API Key**: Required for AI features

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd TinyTastesTracker
   ```

2. **Install XcodeGen** (if not already installed)
   ```bash
   brew install xcodegen
   ```

3. **Set up API Key** (IMPORTANT: Security)

   ⚠️ **Never commit your API key to version control!**

   a. Copy the example plist:
   ```bash
   cp TinyTastesTracker/Resources/GenerativeAI-Info.plist.example TinyTastesTracker/Resources/GenerativeAI-Info.plist
   ```

   b. Edit `GenerativeAI-Info.plist` and replace `YOUR_API_KEY_HERE` with your actual Gemini API key:
   ```xml
   <key>API_KEY</key>
   <string>YOUR_ACTUAL_GEMINI_API_KEY</string>
   ```

   c. The `.gitignore` is configured to exclude this file from commits

4. **Generate Xcode project**
   ```bash
   xcodegen generate
   ```

5. **Open the project**
   ```bash
   open TinyTastesTracker.xcodeproj
   ```

6. **Set your Development Team**
   - In Xcode, select the project in the navigator
   - Under "Signing & Capabilities", select your team
   - Or set `DEVELOPMENT_TEAM` environment variable

7. **Build and run**
   - Select a simulator or device
   - Press `Cmd+R` to build and run

---

## 🏗️ Architecture

### Tech Stack
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **AI Integration**: Google Gemini API (via generative-ai-swift SDK)
- **Image Processing**: Vision framework (OCR)
- **Audio**: AVFoundation (voice chat)
- **Project Management**: XcodeGen (project.yml)

### Project Structure

```
TinyTastesTracker/
├── App/                          # App lifecycle and main views
│   ├── TinyTastesTrackerApp.swift
│   └── ContentView.swift
├── Core/
│   ├── Managers/                 # Domain-specific business logic
│   │   ├── AppState.swift        # Coordinator pattern
│   │   ├── NewbornManager.swift  # Sleep, feeding, diapers
│   │   ├── ToddlerManager.swift  # Meals, nutrition tracking
│   │   ├── RecipeManager.swift   # Recipes, meal plans, shopping
│   │   └── AIServiceManager.swift# AI service coordination
│   ├── Models/                   # SwiftData models
│   ├── Services/                 # API clients and utilities
│   │   ├── GeminiService.swift
│   │   ├── GeminiLiveService.swift
│   │   ├── RecipeOCRService.swift
│   │   └── OpenFoodFactsService.swift
│   └── Utilities/
├── Features/                     # Feature modules
│   ├── Newborn/
│   ├── Explorer/
│   ├── Toddler/
│   ├── Sage/
│   └── Profile/
├── UI/                          # Reusable components
│   ├── Components/
│   ├── Charts/
│   └── Sheets/
└── Resources/                   # Assets, plists
```

### Design Patterns

#### Coordinator Pattern
`AppState` acts as a coordinator, delegating to domain-specific managers:
- **NewbornManager**: Handles sleep, nursing, diapers, bottles, growth
- **ToddlerManager**: Manages meals, nutrition, food logs
- **RecipeManager**: Recipes, meal plans, shopping lists
- **AIServiceManager**: Centralizes all AI interactions

This provides:
- ✅ Separation of concerns
- ✅ Better testability
- ✅ Easier maintenance
- ✅ Clear domain boundaries

#### Observable Pattern
All managers use `@Observable` macro for SwiftUI reactivity.

#### Repository Pattern
Managers handle data persistence through SwiftData's ModelContext.

---

## 🔐 Security Best Practices

### ⚠️ CRITICAL: API Key Security

**IMPORTANT SECURITY WARNING:**
API keys embedded in iOS apps can **ALWAYS** be extracted by determined attackers using tools like class-dump, Hopper, or runtime inspection. The security measures implemented in this project provide **basic obfuscation only** and are NOT a complete security solution.

#### Current Implementation

This project implements **three layers of API security**:

1. **SecureAPIKeyManager** (`Core/Security/SecureAPIKeyManager.swift`)
   - XOR cipher + Base64 encoding + key splitting
   - ⚠️ This is **obfuscation, NOT encryption**
   - Prevents casual inspection but not determined attackers
   - Suitable for development/personal use only

2. **APIRateLimiter** (`Core/Security/APIRateLimiter.swift`)
   - Multi-tier rate limiting (10/min, 100/hour, 1000/day)
   - Prevents quota exhaustion from bugs or abuse
   - Configurable limits with retry-after guidance
   - Persists across app launches

3. **APIUsageMonitor** (`Core/Security/APIUsageMonitor.swift`)
   - Tracks all API calls with timestamps and metrics
   - Detects anomalies (suspicious frequency, failure rates)
   - Provides usage statistics and reports
   - Helps identify abuse or bugs

#### For Development

The current setup is sufficient for:
- Personal use applications
- Development and testing
- Prototypes and MVPs
- Apps with low API usage

**Development Setup:**
```bash
# Create API key configuration file
cp TinyTastesTracker/Resources/GenerativeAI-Info.plist.example TinyTastesTracker/Resources/GenerativeAI-Info.plist

# Edit the file and add your API key
# The .gitignore is configured to prevent commits
```

#### For Production: Use a Backend Proxy

**For production apps, you MUST implement a backend proxy service:**

```
Mobile App → Your Backend API → Gemini API
            (with auth)        (with your API key)
```

**Benefits:**
- ✅ API key never embedded in app binary
- ✅ User authentication and authorization
- ✅ Server-side rate limiting and abuse prevention
- ✅ Cost control and monitoring
- ✅ Ability to revoke access without app updates
- ✅ Analytics and usage tracking
- ✅ Request validation and sanitization

**Example Backend Implementation:**
```python
# Example Flask backend (simplified)
@app.route('/api/generate', methods=['POST'])
@require_auth  # Verify user token
@rate_limit(max_calls=100, period=3600)  # Server-side limiting
def generate_content():
    user_prompt = request.json.get('prompt')

    # Validate and sanitize input
    if not is_valid_prompt(user_prompt):
        return jsonify({'error': 'Invalid prompt'}), 400

    # Call Gemini API with server's API key
    result = gemini_client.generate(prompt=user_prompt)

    # Log usage for billing/monitoring
    log_api_usage(user_id=current_user.id, tokens=result.tokens)

    return jsonify(result.data)
```

### Data Privacy

- ✅ All baby data stored locally using SwiftData
- ✅ No analytics or tracking by default
- ✅ Health data never leaves device except in AI queries
- ✅ Gemini API calls contain minimal necessary data
- ✅ No cloud sync (all data stays on device)
- ⚠️ AI queries may contain sensitive data (review prompts)

### Security Checklist

#### Before Development
- [x] API key stored in `.plist` excluded from git
- [x] `.gitignore` configured correctly
- [x] Rate limiting implemented
- [x] Usage monitoring enabled
- [ ] Review what data is sent to AI service

#### Before Production Release
- [ ] **CRITICAL: Implement backend API proxy**
- [ ] **CRITICAL: Revoke and regenerate all API keys**
- [ ] Never use embedded API keys in production
- [ ] Implement user authentication
- [ ] Add biometric authentication option
- [ ] Enable App Transport Security (ATS)
- [ ] Add certificate pinning
- [ ] Implement request signing
- [ ] Add jailbreak detection (optional)
- [ ] Review all third-party dependencies
- [ ] Conduct security audit
- [ ] Set up monitoring and alerting

#### Ongoing Security
- [ ] Monitor API usage for anomalies
- [ ] Rotate API keys periodically
- [ ] Review rate limits based on usage patterns
- [ ] Update dependencies for security patches
- [ ] Monitor for unusual user activity
- [ ] Keep security measures up to date

### Threat Model

**What we protect against:**
- ✅ Accidental API key commits to git
- ✅ Casual binary inspection
- ✅ Quota exhaustion from bugs
- ✅ Excessive API usage detection
- ✅ Basic reverse engineering

**What we DON'T protect against:**
- ❌ Determined attackers with reverse engineering tools
- ❌ Runtime code injection
- ❌ Jailbroken device inspection
- ❌ Man-in-the-middle attacks (without additional measures)
- ❌ API key extraction from memory dumps

**For production, implement:**
- Backend proxy service (eliminates embedded keys)
- User authentication and authorization
- Certificate pinning
- Request signing with device attestation
- Server-side validation and rate limiting

### Additional Resources

- [OWASP Mobile Security Testing Guide](https://owasp.org/www-project-mobile-security-testing-guide/)
- [Apple Security Best Practices](https://developer.apple.com/documentation/security)
- [API Security Best Practices](https://owasp.org/www-project-api-security/)
- [Gemini API Security](https://ai.google.dev/docs/oauth)

### Privacy Compliance
- ✅ **Privacy Policy Available**: See [PRIVACY_POLICY.md](PRIVACY_POLICY.md)
- ✅ **Data Handling Documentation**: See [DATA_HANDLING.md](DATA_HANDLING.md)
- ✅ **App Store Privacy**: See [APP_STORE_PRIVACY.md](APP_STORE_PRIVACY.md)
- ✅ **COPPA Compliant**: Parents have full control over child data
- ✅ **GDPR Compliant**: Data export and deletion features available


---

## 🧪 Testing

### Current Status
⚠️ Testing infrastructure not yet implemented (see Assessment.md)

### Recommended Testing Strategy

```swift
// Unit Tests to Implement
TinyTastesTrackerTests/
├── Managers/
│   ├── NewbornManagerTests.swift
│   ├── ToddlerManagerTests.swift
│   ├── RecipeManagerTests.swift
│   └── AIServiceManagerTests.swift
├── Services/
│   ├── GeminiServiceTests.swift (with mocks)
│   └── RecipeOCRServiceTests.swift
└── Models/
    └── DataModelTests.swift

// UI Tests
TinyTastesTrackerUITests/
├── OnboardingFlowTests.swift
├── MealLoggingTests.swift
└── RecipeScanningTests.swift
```

### Running Tests (Once Implemented)
```bash
# Run all tests
xcodebuild test -project TinyTastesTracker.xcodeproj -scheme TinyTastesTracker -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test suite
xcodebuild test -project TinyTastesTracker.xcodeproj -scheme TinyTastesTracker -only-testing:TinyTastesTrackerTests/ToddlerManagerTests
```

---

## 📝 Development Workflow

### Code Style
We use **SwiftLint** and **SwiftFormat** for consistent code style.

```bash
# Install SwiftLint
brew install swiftlint

# Install SwiftFormat
brew install swiftformat

# Run linting
swiftlint

# Auto-fix formatting
swiftformat .
```

### Git Workflow
1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "feat: add feature"`
3. Run linting: `swiftlint` and `swiftformat .`
4. Push and create pull request

### Commit Message Convention
```
feat: Add new feature
fix: Fix bug
docs: Update documentation
refactor: Refactor code
test: Add tests
chore: Update dependencies
```

### Before Committing
- [ ] Run SwiftLint and fix warnings
- [ ] Run SwiftFormat
- [ ] Remove any force-unwraps (`!`)
- [ ] Test on simulator
- [ ] Update documentation if needed

---

## 🛠️ Common Tasks

### Adding a New Food to Database
Edit `Core/Utilities/Constants.swift`:
```swift
FoodItem(
    id: "food_name",
    name: "Food Name",
    emoji: "🥑",
    category: .vegetables,
    color: .green,
    allergens: [.avocado],
    nutrients: [.protein, .iron],
    // ...
)
```

### Adding New SwiftData Model
1. Create model in `Core/Models/`
2. Add to `SharedModelContainer.swift`
3. Update relevant manager's `loadData()` method
4. Update AppState delegation if needed

### Modifying Xcode Project
1. Edit `project.yml`
2. Run `xcodegen generate`
3. Clean build folder: `Cmd+Shift+K`
4. Rebuild project

---

## 🐛 Troubleshooting

### Build Errors

**"Cannot find 'NewbornManager' in scope"**
- Solution: Run `xcodegen generate` to update project file

**"Signing requires a development team"**
- Solution: Set your team in Signing & Capabilities or set `DEVELOPMENT_TEAM` environment variable

**"API key not found"**
- Solution: Ensure `GenerativeAI-Info.plist` exists with valid API_KEY

### Runtime Issues

**"AI features not working"**
- Check API key is valid
- Verify network connection
- Check Xcode console for error messages

**"App crashes on launch"**
- Check for SwiftData migration issues
- Verify all required resources are included
- Reset simulator: Device → Erase All Content and Settings

---

## 📚 Additional Resources

### Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Vision Framework Guide](https://developer.apple.com/documentation/vision)

### Project References
- `ASSESSMENT.md` - Technical assessment and enhancement roadmap
- `COMPETITOR_ANALYSIS.md` - Competitive landscape analysis
- `project.yml` - XcodeGen project configuration

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Follow the code style guidelines (SwiftLint/SwiftFormat)
4. Write tests for new features
5. Update documentation
6. Submit a pull request

### Code Review Checklist
- [ ] Code follows Swift style guidelines
- [ ] No force-unwraps (`!`) used
- [ ] SwiftLint passes without warnings
- [ ] Tests added for new functionality
- [ ] Documentation updated
- [ ] No hardcoded secrets or API keys
- [ ] Performance considerations addressed

---

## 📄 License

[Add your license here]

---

## 🙏 Acknowledgments

- **Google Gemini AI** - AI-powered insights and recommendations
- **Open Food Facts** - Nutritional data API
- **Apple Vision Framework** - OCR capabilities
- **SwiftUI Community** - UI patterns and components

---

## 📞 Support

For issues, questions, or feedback:
- Create an issue in the repository
- Email: [your-email@example.com]
- Documentation: See `ASSESSMENT.md` for technical details

---

## 🗺️ Roadmap

See `ASSESSMENT.md` for detailed feature roadmap and enhancement plans.

### Upcoming Features
- [ ] Testing infrastructure (Unit + UI tests)
- [ ] Error handling improvements
- [x] Data export/backup functionality
- [ ] iCloud sync
- [ ] HealthKit integration
- [x] Multi-child support
- [ ] Shareable milestone cards
- [ ] Family collaboration features

---

**Built with ❤️ for parents everywhere**
