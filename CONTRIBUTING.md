# Contributing to Tiny Tastes Tracker

Thank you for your interest in contributing to Tiny Tastes Tracker! This document provides guidelines and best practices for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)

---

## 🤝 Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what's best for the project and community
- Show empathy toward other contributors

---

## 🚀 Getting Started

### Prerequisites

1. **Install required tools:**
   ```bash
   brew install xcodegen
   brew install swiftlint
   brew install swiftformat
   ```

2. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/TinyTastesTracker.git
   cd TinyTastesTracker
   ```

3. **Set up the project:**
   ```bash
   xcodegen generate
   ```

4. **Configure API key:**
   ```bash
   cp TinyTastesTracker/Resources/GenerativeAI-Info.plist.example TinyTastesTracker/Resources/GenerativeAI-Info.plist
   # Edit GenerativeAI-Info.plist and add your Gemini API key
   ```

---

## 🔄 Development Workflow

### Branch Naming Convention

Create descriptive branch names:

```
feature/add-food-database-import
fix/crash-on-meal-logging
refactor/simplify-recipe-manager
docs/update-readme
test/add-nutrition-tests
chore/update-dependencies
```

### Development Process

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Write clean, well-documented code
   - Follow the code style guidelines
   - Add tests for new functionality
   - Update documentation as needed

3. **Run code quality tools:**
   ```bash
   # Auto-format code
   swiftformat .

   # Run linter
   swiftlint

   # Fix any warnings/errors
   swiftlint --fix
   ```

4. **Test your changes:**
   ```bash
   # Build the project
   xcodebuild -project TinyTastesTracker.xcodeproj -scheme TinyTastesTracker build

   # Run tests (when implemented)
   xcodebuild test -project TinyTastesTracker.xcodeproj -scheme TinyTastesTracker
   ```

5. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add food database import feature"
   ```

6. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**

---

## 🎨 Code Style Guidelines

### Swift Style

We use **SwiftLint** and **SwiftFormat** to enforce consistent code style.

#### Key Principles

1. **No Force Unwrapping:**
   ```swift
   // ❌ Bad
   let value = dictionary["key"]!

   // ✅ Good
   guard let value = dictionary["key"] else {
       return
   }
   ```

2. **Use Guard for Early Returns:**
   ```swift
   // ❌ Bad
   func process(data: Data?) {
       if let data = data {
           // Long processing logic
       }
   }

   // ✅ Good
   func process(data: Data?) {
       guard let data = data else {
           return
       }
       // Processing logic
   }
   ```

3. **Descriptive Naming:**
   ```swift
   // ❌ Bad
   let d = Date()
   func calc() { }

   // ✅ Good
   let currentDate = Date()
   func calculateNutrientBalance() { }
   ```

4. **Prefer Computed Properties:**
   ```swift
   // ✅ Good
   var isActive: Bool {
       status == .active
   }
   ```

5. **Use Type Inference:**
   ```swift
   // ❌ Bad
   let name: String = "John"

   // ✅ Good
   let name = "John"
   ```

### File Organization

```swift
//
//  FileName.swift
//  TinyTastesTracker
//

import Foundation
import SwiftUI

// MARK: - Main Type

struct MyView: View {
    // MARK: - Properties

    @State private var isActive = false

    // MARK: - Body

    var body: some View {
        // Implementation
    }

    // MARK: - Private Methods

    private func performAction() {
        // Implementation
    }
}

// MARK: - Supporting Types

struct SupportingModel {
    // Implementation
}
```

### Architecture Guidelines

1. **Coordinator Pattern:**
   - AppState coordinates domain managers
   - Each manager handles its specific domain

2. **Observable Pattern:**
   - Use `@Observable` for managers
   - Use `@State` for view-local state
   - Use `@Bindable` when passing observable objects

3. **SwiftData:**
   - Use ModelContext for persistence
   - Models should be simple data structures
   - Business logic belongs in managers

---

## 📝 Commit Message Guidelines

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **refactor**: Code refactoring
- **test**: Adding tests
- **chore**: Maintenance tasks
- **style**: Code style changes (formatting, etc.)
- **perf**: Performance improvements

### Examples

```
feat(toddler): add nutrient goal customization

Allow parents to customize weekly nutrient goals based on their
child's specific dietary needs.

Closes #123
```

```
fix(camera): resolve force unwrap crash in photo capture

Replace force unwrap with guard statement to safely handle
nil photoOutput.

Fixes #456
```

```
docs(readme): update setup instructions

Add detailed API key configuration steps and troubleshooting section.
```

### Rules

- Use imperative mood ("add" not "added")
- Keep subject line under 50 characters
- Capitalize subject line
- No period at end of subject
- Separate subject from body with blank line
- Wrap body at 72 characters
- Reference issues/PRs in footer

---

## 🔀 Pull Request Process

### Before Submitting

- [ ] Code builds without errors
- [ ] SwiftLint passes without warnings
- [ ] SwiftFormat applied
- [ ] All force unwraps removed
- [ ] Tests added for new functionality
- [ ] Documentation updated
- [ ] No API keys or secrets committed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings introduced
- [ ] Tests added/updated
```

### Review Process

1. **Automated Checks:**
   - Build must succeed
   - SwiftLint must pass
   - No force unwraps

2. **Code Review:**
   - At least one approval required
   - All comments addressed
   - No unresolved conversations

3. **Merge:**
   - Squash commits for cleaner history
   - Update changelog if applicable

---

## 🧪 Testing Guidelines

### Unit Tests

```swift
import XCTest
@testable import TinyTastesTracker

final class ToddlerManagerTests: XCTestCase {
    var manager: ToddlerManager!

    override func setUp() {
        super.setUp()
        manager = ToddlerManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testRainbowProgressCalculation() {
        // Given
        // ... setup test data

        // When
        let progress = manager.rainbowProgress

        // Then
        XCTAssertEqual(progress[.red], 3)
    }
}
```

### Testing Best Practices

1. **Test naming:** `test<MethodName>_<Scenario>_<ExpectedResult>`
2. **Arrange-Act-Assert:** Structure tests clearly
3. **Test one thing:** Each test should verify one behavior
4. **Mock dependencies:** Use protocols for testability
5. **Test edge cases:** Empty data, nil values, etc.

---

## 📚 Documentation Standards

### Inline Documentation

```swift
/// Calculates weekly nutrition summary for the child.
///
/// This method aggregates meal logs from the past 7 days and
/// tallies nutrient occurrences across all consumed foods.
///
/// - Returns: Dictionary mapping nutrients to occurrence count
/// - Note: Only considers meals logged within the last week
func calculateWeeklyNutrition() -> [Nutrient: Int] {
    // Implementation
}
```

### When to Document

- Public APIs and protocols
- Complex algorithms
- Non-obvious business logic
- Workarounds and edge cases
- Security-sensitive code

### What NOT to Document

- Self-explanatory code
- Simple getters/setters
- Obvious implementations

---

## 🐛 Reporting Bugs

### Bug Report Template

```markdown
**Describe the bug**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Tap on '...'
3. See error

**Expected behavior**
What should happen

**Screenshots**
If applicable

**Environment:**
- Device: [e.g. iPhone 15 Pro]
- iOS version: [e.g. 17.0]
- App version: [e.g. 1.0.0]

**Additional context**
Any other relevant information
```

---

## 💡 Suggesting Features

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
Clear description of the problem

**Describe the solution**
Detailed description of proposed solution

**Describe alternatives**
Other solutions considered

**Additional context**
Mockups, examples, related issues
```

---

## 🔒 Security

### Critical Security Rules

1. **Never Commit Secrets**
   - ❌ Never commit API keys, tokens, or credentials
   - ❌ Never commit `GenerativeAI-Info.plist` (only `.example` version)
   - ✅ Always use `.gitignore` exclusions
   - ✅ Review `git diff` before committing

2. **API Key Management**
   ```bash
   # ❌ BAD: Hardcoded API key
   let apiKey = "AIzaSyCmidsQpJ3lLgRCE0aAdhI3rmiB8lNQc5w"

   # ✅ GOOD: Use SecureAPIKeyManager
   if let apiKey = SecureAPIKeyManager.shared.getAPIKey() {
       // Use the key
   }
   ```

3. **Security Components**

   When making API calls, always integrate security components:

   ```swift
   // Use APIRateLimiter to prevent quota exhaustion
   try APIRateLimiter.shared.checkRateLimit()

   // Use APIUsageMonitor to track calls
   let result = try await APIUsageMonitor.shared.track(.textGeneration) {
       await geminiService.generateContent(prompt: prompt)
   }
   ```

4. **Data Handling**
   - Minimize data sent to external APIs
   - Sanitize user input before API calls
   - Never log sensitive data (API keys, user data)
   - Use `@Sendable` for concurrent code safety

5. **Code Review Requirements**
   - [ ] No hardcoded secrets or API keys
   - [ ] API calls use rate limiting
   - [ ] API calls are monitored
   - [ ] Sensitive data is not logged
   - [ ] User input is validated
   - [ ] Force unwraps removed (crash safety)

### Reporting Security Vulnerabilities

**DO NOT** create public issues for security vulnerabilities.

Instead:
1. Email security concerns privately to [your-email@example.com]
2. Include detailed description and reproduction steps
3. Allow 90 days for fix before public disclosure
4. Provide proof of concept if applicable

### Security Testing

Before submitting PRs that touch security-sensitive code:

```bash
# 1. Check for hardcoded secrets
grep -r "AIza" TinyTastesTracker/
grep -r "api_key" TinyTastesTracker/

# 2. Verify .gitignore is working
git status --ignored

# 3. Test rate limiting
# (Run rapid API calls and verify limits work)

# 4. Check usage monitoring
# (Verify APIUsageMonitor records calls correctly)
```

### Security Best Practices

- ✅ Use `guard let` instead of force unwraps
- ✅ Validate all user input
- ✅ Use `async/await` for safe concurrency
- ✅ Keep dependencies updated
- ✅ Follow principle of least privilege
- ✅ Review changes that touch authentication/API code
- ⚠️ Remember: Obfuscation ≠ Encryption
- ⚠️ Production apps MUST use backend proxy (see README)

### Security Resources

- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Apple Secure Coding Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/SecureCodingGuide/)
- [Swift Security Best Practices](https://swift.org/security/)

---

## 📞 Getting Help

- Review existing issues and PRs
- Check the documentation
- Ask questions in discussions
- Be patient and respectful

---

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

**Thank you for contributing to Tiny Tastes Tracker! 🙏**
