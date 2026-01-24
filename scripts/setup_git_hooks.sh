#!/bin/bash
# setup_git_hooks.sh
# Install git hooks for Tiny Tastes Tracker

echo "🔧 Setting up git hooks for Tiny Tastes Tracker..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Run 'git init' first."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
if [ -f "scripts/pre-commit" ]; then
    cp scripts/pre-commit .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
else
    echo "❌ Error: scripts/pre-commit not found"
    exit 1
fi

# Check for required tools
echo ""
echo "🔍 Checking for required tools..."

if command -v swiftlint &> /dev/null; then
    echo "✅ SwiftLint is installed"
else
    echo "⚠️  SwiftLint is NOT installed"
    echo "   Install it with: brew install swiftlint"
fi

if command -v swiftformat &> /dev/null; then
    echo "✅ SwiftFormat is installed"
else
    echo "⚠️  SwiftFormat is NOT installed"
    echo "   Install it with: brew install swiftformat"
fi

if command -v xcodegen &> /dev/null; then
    echo "✅ XcodeGen is installed"
else
    echo "⚠️  XcodeGen is NOT installed"
    echo "   Install it with: brew install xcodegen"
fi

echo ""
echo "🎉 Git hooks setup complete!"
echo ""
echo "The pre-commit hook will now run automatically before each commit to:"
echo "  • Run SwiftLint on staged files"
echo "  • Check formatting with SwiftFormat"
echo "  • Check for hardcoded secrets"
echo "  • Warn about force unwraps"
echo ""
echo "To bypass the hook (not recommended), use: git commit --no-verify"
