# Quick Start Guide: Firestore Security Rules Testing

This guide will help you set up and run automated Firestore security rules testing in under 5 minutes.

## Step 1: Install Dependencies (2 minutes)

```bash
cd TinyTastesTracker

# Install Node.js packages
npm install

# Install Firebase CLI globally
npm install -g firebase-tools
```

## Step 2: Run Tests Locally (1 minute)

```bash
# Run all security tests
npm run test:rules
```

You should see output like:

```
🔥  Setting up Firebase Emulator...
✓  Firestore Emulator running on http://localhost:8080

  Authentication Requirements
    ✓ should deny reading child_profiles without authentication
    ✓ should allow authenticated users to read their own profiles

  Child Profile Security
    ✓ should allow owners to read their own child profiles
    ✓ should deny non-owners from deleting child profiles

  ... 56 more tests ...

  60 passing (2.3s)

🎉  All tests passed!
```

## Step 3: View Test Details (Optional)

```bash
# Start emulator with UI for debugging
npm run emulator:start

# Open in browser: http://localhost:4000
```

## Step 4: Run in Watch Mode (For Development)

```bash
# Tests automatically re-run on file changes
npm run test:rules:watch
```

## What Gets Tested?

### ✅ Security Coverage (60+ tests)

1. **Authentication** - All operations require auth
2. **Owner Access** - Users can only access their own data
3. **Profile Sharing** - Shared users have limited permissions
4. **Invitations** - Invitation system is secure
5. **Cross-User Isolation** - Users can't access each other's data
6. **Attack Vectors** - Common security vulnerabilities tested

### Test Results Breakdown

| Test Suite | Tests | Coverage |
|------------|-------|----------|
| Authentication | 8 | Unauthenticated access denied ✅ |
| Child Profiles | 12 | Owner/shared access control ✅ |
| Profile Logs | 15 | Sleep, nursing, meal logs ✅ |
| Invitations | 10 | Invitation system security ✅ |
| Recipes | 15 | Recipe and custom food sharing ✅ |
| **Total** | **60** | **All attack vectors covered** ✅ |

## Troubleshooting

### Issue: `npm: command not found`

**Solution:** Install Node.js

```bash
# macOS
brew install node

# Verify installation
node --version  # Should show v18.0.0 or higher
npm --version
```

### Issue: Tests timeout or fail to start

**Solution:** Check emulator port

```bash
# Kill any process using port 8080
lsof -ti:8080 | xargs kill -9

# Run tests again
npm run test:rules
```

### Issue: "Firebase project not initialized"

**Solution:** Tests use emulator, no real Firebase project needed! Tests run offline against your local `firestore.rules` file.

### Issue: Tests fail with "permission denied"

**Solution:** This might be expected! The tests verify rules work correctly:
- ✅ Green checkmark = Access properly denied (security working!)
- ❌ Red X = Access improperly allowed (security bug!)

Check the specific test to see if it's testing denial or approval.

## CI/CD Integration

Tests automatically run on GitHub Actions:

```yaml
# Already configured in .github/workflows/ci.yml
firestore-rules:
  name: Test Firestore Security Rules
  runs-on: ubuntu-latest
  # ... runs on every push and PR
```

View results in:
- GitHub Actions tab
- Pull request checks
- Test artifacts (downloadable)

## Adding Your First Test

Create `firestore-tests/06-my-test.test.js`:

```javascript
import { describe, it, before, after, afterEach } from 'mocha';
import {
  setupTestEnvironment,
  teardownTestEnvironment,
  clearFirestoreData,
  getAuthenticatedContext,
  assertSucceeds,
  assertFails
} from './setup.js';

describe('My Custom Security Test', () => {
  before(async () => {
    await setupTestEnvironment();
  });

  after(async () => {
    await teardownTestEnvironment();
  });

  afterEach(async () => {
    await clearFirestoreData();
  });

  it('should test my feature', async () => {
    const alice = getAuthenticatedContext('alice');

    // Test that Alice can create a document
    await assertSucceeds(
      alice.firestore()
        .collection('my_collection')
        .doc('doc1')
        .set({ ownerId: 'alice', data: 'test' })
    );

    // Test that Alice can read it
    await assertSucceeds(
      alice.firestore()
        .collection('my_collection')
        .doc('doc1')
        .get()
    );
  });
});
```

Run your new test:

```bash
npm run test:rules
```

## Common Test Patterns

### Test: User Can Access Own Data

```javascript
it('should allow owners to read their data', async () => {
  const alice = getAuthenticatedContext('alice');

  // Create data as Alice
  await alice.firestore()
    .collection('profiles')
    .doc('profile1')
    .set({ ownerId: 'alice', name: 'Test' });

  // Alice should be able to read it
  await assertSucceeds(
    alice.firestore()
      .collection('profiles')
      .doc('profile1')
      .get()
  );
});
```

### Test: User Cannot Access Other User's Data

```javascript
it('should deny reading other users\' data', async () => {
  const alice = getAuthenticatedContext('alice');
  const bob = getAuthenticatedContext('bob');

  // Alice creates her profile
  await alice.firestore()
    .collection('profiles')
    .doc('alice-profile')
    .set({ ownerId: 'alice' });

  // Bob should NOT be able to read it
  await assertFails(
    bob.firestore()
      .collection('profiles')
      .doc('alice-profile')
      .get()
  );
});
```

### Test: Shared Access Works

```javascript
it('should allow shared users to read', async () => {
  const alice = getAuthenticatedContext('alice');
  const bob = getAuthenticatedContext('bob');

  // Alice creates and shares with Bob
  await alice.firestore()
    .collection('profiles')
    .doc('profile1')
    .set({
      ownerId: 'alice',
      sharedWith: ['bob']
    });

  // Bob should be able to read
  await assertSucceeds(
    bob.firestore()
      .collection('profiles')
      .doc('profile1')
      .get()
  );
});
```

## Performance Tips

**Tests run in ~2-3 seconds** for 60+ tests. To keep them fast:

1. Use `clearFirestoreData()` between tests (not full emulator restart)
2. Don't add unnecessary delays or sleeps
3. Reuse test environment setup
4. Run specific test file during development:

```bash
# Run only one test file
npx mocha --require @babel/register firestore-tests/02-child-profiles.test.js
```

## Next Steps

- ✅ Review test output to understand security coverage
- ✅ Add tests for any custom collections you've added
- ✅ Run tests before deploying rule changes
- ✅ Monitor CI/CD test results in pull requests
- ✅ Update tests when adding new features

## Getting Help

**Test failing?**
1. Read the error message - it tells you which rule failed
2. Check `firestore.rules` for the relevant collection
3. Verify test data includes required fields (ownerId, babyId, etc.)
4. Use emulator UI to inspect data: http://localhost:4000

**Need to test a specific scenario?**
1. Look at existing tests for similar patterns
2. Copy a test file and modify for your use case
3. Use `TestData` factories in `setup.js` for consistent test data

**Want to contribute?**
1. Add tests for edge cases you discover
2. Improve test coverage for new features
3. Document any security issues found
4. Share test patterns that work well

---

**Ready to deploy?** Run tests one more time:

```bash
npm run test:rules

# If all tests pass:
# ✅ Your Firestore rules are production-ready!
```

**Questions?** Check `firestore-tests/README.md` for detailed documentation.
