#!/bin/bash
# generate_coverage.sh
# Generate code coverage report for Tiny Tastes Tracker

set -e

SCHEME="TinyTastesTracker"
DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
DERIVED_DATA="./DerivedData"
RESULT_BUNDLE="./TestResults.xcresult"

echo "🧪 Running tests with code coverage..."

# Clean previous results
rm -rf "$DERIVED_DATA" "$RESULT_BUNDLE"

# Generate Xcode project if needed
if [ ! -f "TinyTastesTracker.xcodeproj/project.pbxproj" ]; then
    echo "📦 Generating Xcode project..."
    xcodegen generate
fi

# Run tests with coverage
xcodebuild test \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    | xcpretty

echo ""
echo "📊 Generating coverage reports..."

# Generate JSON coverage report
xcrun xccov view --report --json "$RESULT_BUNDLE" > coverage.json

# Generate human-readable coverage report
xcrun xccov view --report "$RESULT_BUNDLE" > coverage.txt

# Generate HTML coverage report (if slather is installed)
if command -v slather &> /dev/null; then
    echo "📄 Generating HTML report with slather..."
    slather coverage \
        --scheme "$SCHEME" \
        --html \
        --output-directory ./coverage-html \
        --binary-basename TinyTastesTracker \
        TinyTastesTracker.xcodeproj

    echo "✅ HTML report generated at: ./coverage-html/index.html"
    open ./coverage-html/index.html 2>/dev/null || true
fi

# Display coverage summary
echo ""
echo "📊 Coverage Summary:"
echo "===================="
cat coverage.txt

# Extract overall coverage percentage
COVERAGE=$(grep "TinyTastesTracker.app" coverage.txt | head -1 | awk '{print $4}' | sed 's/%//')

echo ""
if (( $(echo "$COVERAGE >= 60" | bc -l) )); then
    echo "✅ Coverage is above target: ${COVERAGE}%"
else
    echo "⚠️  Coverage is below target (60%): ${COVERAGE}%"
fi

echo ""
echo "📁 Reports generated:"
echo "  - JSON: coverage.json"
echo "  - Text: coverage.txt"
if [ -d "./coverage-html" ]; then
    echo "  - HTML: coverage-html/index.html"
fi
echo "  - Xcode: $RESULT_BUNDLE"
