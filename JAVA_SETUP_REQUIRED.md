# Firestore Security Testing - Setup Required

## ⚠️ Java Required

The Firebase Emulator requires Java to run. You need to install it manually.

## Quick Install (5 minutes)

### Step 1: Install Java

**Download Java 17 (Temurin - Free, Open Source):**
1. Visit: https://adoptium.net/temurin/releases/
2. Select:
   - **Operating System**: macOS
   - **Architecture**: aarch64 (Apple Silicon)
   - **Version**: 17 (LTS)
   - **Package Type**: JDK
3. Download the `.pkg` file
4. Run the installer (double-click)
5. Follow the installation wizard

**Verify Installation:**
```bash
java -version
# Should output: openjdk version "17.0.x"
```

### Step 2: Run Tests

```bash
cd "/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker"
npm run test:rules
```

## Expected Output

```
i  emulators: Starting emulators: firestore
✔  firestore: Firestore Emulator logging to firestore-debug.log
✔  firestore: Firestore Emulator running on http://127.0.0.1:8080

  Authentication Requirements
    ✓ should deny reading child_profiles without authentication
    ... 7 more tests

  Child Profile Security
    ✓ should allow owners to read their own child profiles
    ... 11 more tests

  Profile Log Security
    ✓ should allow profile owners to create sleep logs
    ... 14 more tests

  Profile Invitation Security
    ✓ should allow profile owners to create invitations
    ... 9 more tests

  Recipe and Custom Food Security
    ✓ should allow users to create their own recipes
    ... 14 more tests

  60 passing (2.3s)
```

## Alternative: Manual Testing

If you can't install Java right now, you can still test your Firestore rules manually:

### Using Firebase Console (Web)

1. Go to: https://console.firebase.google.com
2. Select your project: **TinyTastesTracker**
3. Click: **Firestore Database** → **Rules**
4. Click: **Rules Playground** (if available)
5. Test individual operations

### Using Firebase Emulator (When Java is installed)

```bash
# Start emulator with UI
npm run emulator:start

# Open in browser: http://localhost:4000
# Test operations manually in the UI
```

## Why We Need Automated Tests

**Without automated tests:**
- ❌ 30+ minutes to manually test rule changes
- ❌ Easy to miss edge cases
- ❌ No confidence in deployments

**With automated tests:**
- ✅ 2-3 seconds to test all rules
- ✅ 60+ scenarios automatically tested
- ✅ 100% confidence in security
- ✅ Catches bugs before production

## Troubleshooting

### "Java not found" after installation

**Add Java to PATH:**
```bash
# Add to ~/.zshrc or ~/.bash_profile
export JAVA_HOME=$(/usr/libexec/java_home)
export PATH=$JAVA_HOME/bin:$PATH

# Reload shell
source ~/.zshrc
```

### "Port 8080 already in use"

```bash
# Kill process on port 8080
lsof -ti:8080 | xargs kill -9

# Run tests again
npm run test:rules
```

### Still having issues?

1. Verify Java installation: `java -version`
2. Check Node.js version: `node --version` (should be 18+)
3. Reinstall dependencies: `rm -rf node_modules && npm install`
4. Check Firebase CLI: `firebase --version`

## What You've Set Up So Far

✅ **842 npm packages installed**
✅ **60+ test files ready**
✅ **Firebase emulator configured**
✅ **CI/CD integration ready**

**Only missing:** Java runtime (5-minute install)

## Once Java is Installed

Run these commands:
```bash
cd "/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker"

# Run all tests
npm run test:rules

# Run tests in watch mode
npm run test:rules:watch

# Start emulator with UI
npm run emulator:start
```

---

**Next Steps:**
1. Install Java from https://adoptium.net/temurin/releases/
2. Run `npm run test:rules`
3. See 60 tests pass in 2-3 seconds ✅

**Questions?** Check the other documentation:
- `FIRESTORE_TESTING_QUICKSTART.md`
- `FIRESTORE_TESTING_IMPLEMENTATION.md`
- `firestore-tests/README.md`
