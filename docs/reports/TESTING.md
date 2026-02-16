# Testing Guide

This document describes the testing infrastructure for Tiny Tastes Tracker and how to run tests.

## Table of Contents
- [Overview](#overview)
- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Code Coverage](#code-coverage)
- [Writing Tests](#writing-tests)
- [CI/CD Integration](#cicd-integration)

## Overview

Tiny Tastes Tracker has a comprehensive testing infrastructure with:
- **220+ tests** covering unit, integration, and UI tests
- **50-60% code coverage** of core business logic
- **Automated CI/CD** with GitHub Actions
- **Code coverage reporting** with Codecov
- **Pre-commit hooks** for quality checks

### Test Statistics

| Category | Tests | Lines | Coverage |
|----------|-------|-------|----------|
| Models | 24 | ~300 | Complete |
| Managers | 105 | ~1,140 | Complete |
| AI Integration | 25+ | ~390 | Complete |
| Persistence | 30+ | ~700 | Complete |
| UI Tests | 40+ | ~970 | Complete |
| **TOTAL** | **220+** | **~3,730** | **50-60%** |

## Test Structure

```
TinyTastesTracker/
├── TinyTastesTrackerTests/           # Unit & Integration Tests
│   ├── Models/                        # Model tests
│   │   ├── GroceryCategoryTests.swift
│   │   ├── UserProfileTests.swift
│   │   └── ShoppingListItemTests.swift
│   ├── Managers/                      # Business logic tests
│   │   ├── RecipeManagerTests.swift
│   │   ├── NewbornManagerTests.swift
│   │   └── ToddlerManagerTests.swift
│   ├── Services/                      # Service integration tests
│   │   └── GeminiServiceIntegrationTests.swift
│   ├── Persistence/                   # SwiftData tests
│   │   └── SwiftDataPersistenceTests.swift
│   └── Helpers/                       # Test utilities
│       └── MockGeminiService.swift
└── TinyTastesTrackerUITests/         # UI Tests
    ├── OnboardingUITests.swift
    ├── FoodTrackingUITests.swift
    ├── MealPlanningUITests.swift
    └── NewbornTrackingUITests.swift
```

## Running Tests

### Using Xcode

1. **Open Project**
   ```bash
   cd TinyTastesTracker
   xcodegen generate
   open TinyTastesTracker.xcodeproj
   ```

2. **Run All Tests**
   - Press `Cmd + U` to run all tests
   - Or: Product → Test

3. **Run Specific Test Suite**
   - Click the test diamond next to any test class or method
   - Or: Right-click → Run "[TestName]"

4. **Run Unit Tests Only**
   - Select `TinyTastesTrackerTests` scheme
   - Press `Cmd + U`

5. **Run UI Tests Only**
   - Select `TinyTastesTrackerUITests` scheme
   - Press `Cmd + U`

### Using Command Line

#### Run All Tests
```bash
cd TinyTastesTracker
xcodebuild test \
  -scheme TinyTastesTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  | xcpretty
```

#### Run Unit Tests Only
```bash
xcodebuild test \
  -scheme TinyTastesTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:TinyTastesTrackerTests \
  | xcpretty
```

#### Run UI Tests Only
```bash
xcodebuild test \
  -scheme TinyTastesTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:TinyTastesTrackerUITests \
  | xcpretty
```

#### Run Specific Test Class
```bash
xcodebuild test \
  -scheme TinyTastesTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:TinyTastesTrackerTests/RecipeManagerTests \
  | xcpretty
```

## Code Coverage

### Generate Coverage Report (Script)

```bash
cd TinyTastesTracker
./scripts/generate_coverage.sh
```

This script will:
- Run all tests with coverage enabled
- Generate JSON, text, and HTML reports
- Display coverage summary in terminal
- Open HTML report in browser (if slather is installed)

### Generate Coverage Report (Manual)

```bash
# Run tests with coverage
xcodebuild test \
  -scheme TinyTastesTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath ./TestResults.xcresult

# Generate coverage report
xcrun xccov view --report ./TestResults.xcresult
```

### View Coverage in Xcode

1. Run tests with coverage (Cmd + U)
2. Open Report Navigator (Cmd + 9)
3. Select latest test result
4. Click "Coverage" tab
5. Browse coverage by file

### Coverage Targets

- **Overall Target:** 60%
- **Core Business Logic:** 70%
- **New Code (PR):** 70%

## Writing Tests

### Unit Test Example

```swift
import XCTest
import SwiftData
@testable import TinyTastesTracker

final class MyManagerTests: XCTestCase {
    var manager: MyManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        manager = MyManager()

        // Setup in-memory SwiftData container
        let schema = Schema([MyModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() {
        manager = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }

    func testMyFeature() {
        // Given
        let item = MyModel(name: "Test")

        // When
        manager.save(item, context: modelContext)

        // Then
        XCTAssertEqual(manager.items.count, 1)
        XCTAssertEqual(manager.items.first?.name, "Test")
    }
}
```

### UI Test Example

```swift
import XCTest

final class MyFeatureUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testUserFlow() throws {
        // Arrange
        let button = app.buttons["myButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))

        // Act
        button.tap()

        // Assert
        let result = app.staticTexts["resultLabel"]
        XCTAssertTrue(result.waitForExistence(timeout: 3))
        XCTAssertEqual(result.label, "Expected Result")
    }
}
```

### Best Practices

1. **Test Naming**
   - Use descriptive names: `testSaveRecipeAddsToList`
   - Follow pattern: `test[UnitOfWork][Scenario][ExpectedBehavior]`

2. **Setup/Teardown**
   - Always clean up resources in `tearDown()`
   - Use in-memory databases for persistence tests

3. **Assertions**
   - Use specific assertions: `XCTAssertEqual` vs `XCTAssertTrue`
   - Include failure messages: `XCTAssertTrue(value, "Value should be true")`

4. **Async Testing**
   ```swift
   func testAsyncOperation() async throws {
       let result = try await manager.fetchData()
       XCTAssertNotNil(result)
   }
   ```

5. **UI Testing**
   - Use accessibility identifiers
   - Wait for elements: `element.waitForExistence(timeout: 5)`
   - Test critical user flows only

6. **Avoid**
   - Force unwraps (`!`)
   - Hardcoded waits (`sleep()`)
   - Testing implementation details
   - Flaky tests

## CI/CD Integration

### GitHub Actions

Tests run automatically on:
- Every push to `main` or `develop`
- Every pull request
- Every release tag (`v*.*.*`)

### Workflows

**CI Workflow** (`.github/workflows/ci.yml`)
- Runs on: Push, Pull Request
- Steps:
  1. Checkout code
  2. Generate Xcode project
  3. Run SwiftLint
  4. Build app
  5. Run unit tests
  6. Generate coverage
  7. Upload to Codecov
  8. Comment PR with coverage

**Release Workflow** (`.github/workflows/release.yml`)
- Runs on: Tag push (`v*.*.*`)
- Steps:
  1. Run all tests
  2. Build archive
  3. Create GitHub release
  4. Upload artifacts

### Local Pre-commit Checks

Install git hooks:
```bash
cd TinyTastesTracker
./scripts/setup_git_hooks.sh
```

The pre-commit hook runs:
- SwiftLint on staged files
- SwiftFormat checks
- Secret detection
- Force unwrap warnings

To bypass (not recommended):
```bash
git commit --no-verify
```

## Troubleshooting

### Tests Fail with "Simulator Not Found"

```bash
# List available simulators
xcrun simctl list devices

# Use an available device
xcodebuild test \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### SwiftData Tests Fail

- Ensure using `isStoredInMemoryOnly: true`
- Check proper setUp/tearDown
- Verify schema includes all models

### UI Tests Timeout

- Increase timeout: `element.waitForExistence(timeout: 10)`
- Check accessibility identifiers
- Ensure app launches correctly

### Coverage Not Generated

- Enable coverage in scheme settings
- Use `-enableCodeCoverage YES` flag
- Check Xcode version (15.2+)

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [UI Testing Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
- [SwiftData Testing](https://developer.apple.com/documentation/swiftdata)
- [GitHub Actions for iOS](https://docs.github.com/en/actions/guides/building-and-testing-swift)

## Contact

For questions or issues with tests, please:
- Open an issue in the repository
- Contact the development team
- Review CONTRIBUTING.md
