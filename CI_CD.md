# CI/CD Guide

This document describes the Continuous Integration and Continuous Deployment setup for Tiny Tastes Tracker.

## Table of Contents
- [Overview](#overview)
- [GitHub Actions Setup](#github-actions-setup)
- [Workflows](#workflows)
- [Code Coverage](#code-coverage)
- [Pre-commit Hooks](#pre-commit-hooks)
- [Release Process](#release-process)

## Overview

Tiny Tastes Tracker uses GitHub Actions for automated testing, quality checks, and releases.

### CI/CD Features

- ✅ Automated testing on every push/PR
- ✅ Code coverage reporting with Codecov
- ✅ SwiftLint & SwiftFormat checks
- ✅ Security scanning (API key detection)
- ✅ Automated releases on tags
- ✅ PR comments with test results
- ✅ Pre-commit hooks for local quality checks

## GitHub Actions Setup

### Prerequisites

1. **Repository Secrets**

   Add these secrets in GitHub Settings → Secrets:

   ```
   CODECOV_TOKEN=<your-codecov-token>
   DEVELOPMENT_TEAM=<your-team-id>  (optional, for signing)
   ```

2. **Branch Protection**

   Configure in Settings → Branches:
   - Require status checks before merging
   - Require branches to be up to date
   - Required checks:
     - `test` job from CI workflow
     - `lint` job from CI workflow
     - `security` job from CI workflow

3. **Codecov Integration**

   1. Sign up at [codecov.io](https://codecov.io)
   2. Connect your GitHub repository
   3. Copy the token to GitHub secrets as `CODECOV_TOKEN`

## Workflows

### CI Workflow

**File:** `.github/workflows/ci.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`

**Jobs:**

#### 1. Test Job
- Checkout code
- Setup Xcode 15.2
- Install dependencies (XcodeGen, SwiftLint)
- Generate Xcode project
- Build app
- Run unit tests with coverage
- Generate coverage reports
- Upload to Codecov
- Comment PR with results

#### 2. Lint Job
- Run SwiftLint (strict mode)
- Check SwiftFormat compliance

#### 3. Security Job
- Scan for hardcoded API keys
- Check for excessive force unwraps

**Duration:** ~10-15 minutes

### Release Workflow

**File:** `.github/workflows/release.yml`

**Triggers:**
- Push of version tags (e.g., `v1.0.0`)

**Steps:**
1. Run full test suite
2. Build release archive
3. Generate release notes
4. Create GitHub release
5. Upload build artifacts

**Usage:**
```bash
# Create and push a release tag
git tag v1.0.0
git push origin v1.0.0
```

## Code Coverage

### Codecov Configuration

**File:** `codecov.yml`

**Settings:**
- Target coverage: 60% overall
- Patch coverage: 70% for new code
- Threshold: 2% (won't fail if coverage drops <2%)

**Ignored Paths:**
- Test files
- Resources
- Generated files
- Widget extension

### Coverage Reports

#### In GitHub Actions

Coverage is automatically:
- Uploaded to Codecov
- Commented on PRs
- Displayed in workflow logs

#### Locally

Generate coverage report:
```bash
cd TinyTastesTracker
./scripts/generate_coverage.sh
```

View results:
- Terminal: `coverage.txt`
- JSON: `coverage.json`
- HTML: `coverage-html/index.html` (requires slather)

### Coverage Badges

Add to README.md:
```markdown
[![codecov](https://codecov.io/gh/USERNAME/TinyTastesTracker/branch/main/graph/badge.svg)](https://codecov.io/gh/USERNAME/TinyTastesTracker)
```

## Pre-commit Hooks

### Installation

```bash
cd TinyTastesTracker
./scripts/setup_git_hooks.sh
```

### What They Do

Pre-commit hooks run automatically before each commit:

1. **SwiftLint**
   - Lints staged Swift files
   - Fails commit if violations found
   - Run `swiftlint autocorrect` to fix

2. **SwiftFormat**
   - Checks code formatting
   - Fails commit if not formatted
   - Run `swiftformat .` to fix

3. **Secret Detection**
   - Scans for API keys
   - Blocks commit if found

4. **Force Unwrap Check**
   - Warns if >5 force unwraps in changes
   - Doesn't block commit

5. **TODO/FIXME Detection**
   - Lists new TODO comments
   - Doesn't block commit

### Bypassing Hooks

**Not recommended**, but possible:
```bash
git commit --no-verify
```

### Uninstalling

```bash
rm .git/hooks/pre-commit
```

## Release Process

### Version Numbering

Follow Semantic Versioning:
- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.1.1): Bug fixes

### Creating a Release

1. **Update Version**
   ```bash
   # Update version in project.yml or Info.plist
   vim TinyTastesTracker/Resources/Info.plist
   ```

2. **Update Changelog**
   ```bash
   # Add changes to CHANGELOG.md
   vim CHANGELOG.md
   ```

3. **Commit Changes**
   ```bash
   git add .
   git commit -m "chore: bump version to v1.0.0"
   git push origin main
   ```

4. **Create Tag**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

5. **GitHub Release**
   - Release workflow automatically creates GitHub release
   - Edit release notes if needed
   - Add additional assets if required

### Release Checklist

- [ ] All tests passing
- [ ] Coverage meets target (60%)
- [ ] SwiftLint warnings resolved
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version number updated
- [ ] Release notes prepared

## Monitoring

### Build Status

Check workflow status:
- Repository → Actions tab
- View logs for failed jobs
- Re-run failed workflows if needed

### Coverage Trends

Monitor in Codecov dashboard:
- Overall coverage percentage
- Coverage trends over time
- File-level coverage
- Uncovered lines

### Notifications

Configure in GitHub Settings → Notifications:
- Email on workflow failures
- Slack/Discord integration (optional)

## Troubleshooting

### Build Fails on CI but Works Locally

**Possible causes:**
- Different Xcode version
- Missing dependencies
- Environment differences

**Solutions:**
```bash
# Match Xcode version
DEVELOPER_DIR=/Applications/Xcode_15.2.app/Contents/Developer

# Clean and rebuild
xcodebuild clean
xcodebuild build -scheme TinyTastesTracker
```

### Coverage Upload Fails

**Check:**
- `CODECOV_TOKEN` secret is set
- Codecov service is operational
- Network connectivity

**Manual upload:**
```bash
bash <(curl -s https://codecov.io/bash) -t ${CODECOV_TOKEN}
```

### SwiftLint Fails in CI

**Common issues:**
- Different SwiftLint version
- New violations in staged code

**Fix:**
```bash
# Update SwiftLint
brew upgrade swiftlint

# Run locally first
swiftlint lint --strict
swiftlint autocorrect
```

### Test Timeout in CI

**Increase timeout:**
```yaml
# In workflow file
- name: Run Tests
  timeout-minutes: 20  # Increase from default 10
```

**Optimize tests:**
- Reduce UI test scope
- Use faster simulators
- Parallelize tests

## Advanced Configuration

### Custom Workflow

Create additional workflows:
```yaml
# .github/workflows/nightly.yml
name: Nightly Build

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  test:
    runs-on: macos-14
    steps:
      # ... steps here
```

### Matrix Builds

Test on multiple iOS versions:
```yaml
strategy:
  matrix:
    device: ['iPhone 15 Pro', 'iPhone 14', 'iPad Pro']
steps:
  - name: Test
    run: |
      xcodebuild test \
        -destination "platform=iOS Simulator,name=${{ matrix.device }}"
```

### Caching

Speed up builds with caching:
```yaml
- uses: actions/cache@v4
  with:
    path: ~/Library/Caches/org.swift.swiftpm
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
```

## Best Practices

1. **Keep Builds Fast**
   - Cache dependencies
   - Run tests in parallel
   - Use faster test schemes

2. **Fail Fast**
   - Run quick checks (lint) before slow tests
   - Break into separate jobs

3. **Meaningful Commits**
   - Use conventional commits
   - Include issue references
   - Keep commits atomic

4. **Monitor Coverage**
   - Don't obsess over 100%
   - Focus on critical paths
   - Test public APIs thoroughly

5. **Regular Updates**
   - Keep Xcode version current
   - Update dependencies monthly
   - Review and update workflows

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Codecov Documentation](https://docs.codecov.com)
- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)

## Support

For CI/CD issues:
1. Check workflow logs in GitHub Actions
2. Review this guide
3. Open an issue with logs attached
4. Contact the development team
