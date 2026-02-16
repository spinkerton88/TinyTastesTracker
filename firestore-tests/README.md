# Automated Firestore Security Rules Testing

This directory contains automated security tests for Firebase Firestore security rules.

## Overview

These tests ensure that:
- Authentication is required for all operations
- Users can only access their own data
- Profile sharing works correctly
- Invitation system is secure
- Cross-user data isolation is maintained

## Test Structure

```
firestore-tests/
├── setup.js                      # Test environment setup and helpers
├── 01-authentication.test.js     # Authentication requirement tests
├── 02-child-profiles.test.js     # Profile ownership and sharing
├── 03-profile-logs.test.js       # Log access control
├── 04-invitations.test.js        # Invitation system security
└── 05-recipes-and-sharing.test.js # Recipe and custom food security
```

## Running Tests

### Prerequisites

```bash
# Install Node.js 18+ (if not already installed)
brew install node

# Install dependencies
npm install
```

### Run Tests Locally

```bash
# Run all tests with Firebase Emulator
npm run test:rules

# Start emulator manually (for debugging)
npm run emulator:start

# Run tests in watch mode (for development)
npm run test:rules:watch
```

### Run Tests in CI/CD

Tests automatically run in GitHub Actions on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`

## Test Coverage

### Collections Tested

✅ **child_profiles** - Owner + SharedWith access
✅ **profile_invitations** - Invitation system security
✅ **sleep_logs** - Profile-based access control
✅ **nursing_logs** - Profile-based access control
✅ **diaper_logs** - Profile-based access control
✅ **meal_logs** - Profile-based access control
✅ **recipes** - Owner + SharedWith access
✅ **custom_foods** - Owner + SharedWith access
✅ **meal_plan_entries** - Owner-only access
✅ **shopping_list_items** - Owner + SharedWith access

### Attack Vectors Tested

1. **Unauthenticated Access**
   - ❌ Reading without authentication
   - ❌ Writing without authentication
   - ❌ Deleting without authentication

2. **Unauthorized Access**
   - ❌ Reading other users' profiles
   - ❌ Reading other users' logs
   - ❌ Modifying other users' data
   - ❌ Deleting other users' data

3. **Privilege Escalation**
   - ❌ Shared users changing ownership
   - ❌ Shared users modifying sharing permissions
   - ❌ Non-owners creating invitations for others
   - ❌ Users modifying others' invitations

4. **Data Isolation**
   - ✅ Users can only access shared profiles
   - ✅ Logs are protected by profile access
   - ✅ Recipes follow sharing model
   - ✅ Cross-user data is isolated

5. **Invitation System**
   - ✅ Only inviters can cancel invitations
   - ✅ Anyone can accept/decline (with code)
   - ❌ Users can't create fake invitations
   - ❌ Users can't modify others' invitations

## Test Results Example

```bash
$ npm run test:rules

  Authentication Requirements
    Unauthenticated Access
      ✓ should deny reading child_profiles without authentication
      ✓ should deny creating child_profiles without authentication
      ✓ should deny reading sleep_logs without authentication
    Authenticated Access
      ✓ should allow authenticated users to read their own child profiles

  Child Profile Security
    Owner Access Control
      ✓ should allow owners to read their own child profiles
      ✓ should allow owners to update their own child profiles
      ✓ should deny non-owners from deleting child profiles
    Profile Sharing
      ✓ should allow shared users to read child profiles
      ✓ should deny shared users from changing ownership

  Profile Log Security
    Sleep Logs
      ✓ should allow profile owners to create sleep logs
      ✓ should allow shared users to read sleep logs
      ✓ should deny non-shared users from reading sleep logs

  Profile Invitation Security
    Creating Invitations
      ✓ should allow profile owners to create invitations
      ✓ should deny users from creating invitations for others
    Accepting/Declining Invitations
      ✓ should allow any user to mark invitation as accepted
      ✓ should deny non-inviter from updating other fields

  Recipe and Custom Food Security
    Recipe Ownership
      ✓ should allow users to create their own recipes
      ✓ should deny non-owners from deleting recipes
    Recipe Sharing
      ✓ should allow shared users to read recipes
      ✓ should deny non-shared users from reading recipes

  60 passing (2.3s)
```

## Adding New Tests

### 1. Create Test File

```javascript
import { describe, it, before, after, afterEach } from 'mocha';
import {
  setupTestEnvironment,
  teardownTestEnvironment,
  clearFirestoreData,
  getAuthenticatedContext,
  assertSucceeds,
  assertFails,
  TestData
} from './setup.js';

describe('My New Security Test', () => {
  before(async () => {
    await setupTestEnvironment();
  });

  after(async () => {
    await teardownTestEnvironment();
  });

  afterEach(async () => {
    await clearFirestoreData();
  });

  it('should test something', async () => {
    const alice = getAuthenticatedContext('alice');

    // Test logic here
    await assertSucceeds(
      alice.firestore().collection('test').doc('doc1').get()
    );
  });
});
```

### 2. Add Test Data Factory

If you need custom test data, add it to `setup.js`:

```javascript
export const TestData = {
  // ... existing factories

  myNewData(ownerId, overrides = {}) {
    return {
      ownerId,
      // ... default fields
      ...overrides
    };
  }
};
```

### 3. Run Tests

```bash
npm run test:rules
```

## Debugging Failed Tests

### View Emulator UI

```bash
npm run emulator:start
# Open http://localhost:4000 in browser
```

### Check Rules

The tests use the rules from `firestore.rules`. If tests fail:

1. Check the error message for rule violation
2. Open `firestore.rules` and find the relevant rule
3. Verify the rule logic matches expected behavior
4. Update rules if needed
5. Re-run tests

### Common Issues

**Tests fail with "permission denied"**
- Check that rules allow the operation
- Verify auth context is set up correctly
- Check that test data includes required fields (ownerId, babyId, etc.)

**Tests timeout**
- Ensure Firebase emulator is running
- Check emulator port (default: 8080)
- Increase timeout in test file

**Tests pass locally but fail in CI**
- Ensure all dependencies are in package.json
- Check Node.js version (requires 18+)
- Verify firebase.json configuration

## CI/CD Integration

### GitHub Actions Workflow

The tests automatically run in CI/CD via `.github/workflows/ci.yml`:

```yaml
firestore-rules:
  name: Test Firestore Security Rules
  runs-on: ubuntu-latest

  steps:
  - name: Checkout code
    uses: actions/checkout@v4

  - name: Setup Node.js
    uses: actions/setup-node@v4
    with:
      node-version: '18'
      cache: 'npm'

  - name: Install dependencies
    run: npm ci

  - name: Run Firestore Rules Tests
    run: npm run test:rules
```

### Test Results

Test results are uploaded as artifacts and visible in:
- GitHub Actions summary
- Pull request checks
- Test artifacts (downloadable)

## Security Best Practices

### 1. Test Every Collection

Ensure every Firestore collection has corresponding tests:
- Authentication requirements
- Owner-based access control
- Shared access (if applicable)
- Cross-user isolation

### 2. Test Attack Vectors

For each operation, test:
- ✅ Legitimate access (should succeed)
- ❌ Unauthenticated access (should fail)
- ❌ Unauthorized user access (should fail)
- ❌ Privilege escalation attempts (should fail)

### 3. Edge Cases

Test edge cases like:
- Expired invitations
- Removed users still in sharedWith array
- Deleted profiles with orphaned logs
- Multiple simultaneous operations

### 4. Regular Updates

Update tests when:
- Adding new collections
- Changing security rules
- Adding new sharing features
- Implementing new access patterns

## Performance

Tests typically run in **2-3 seconds** for the full suite (60+ tests).

To improve performance:
- Use `afterEach` instead of `after` for cleanup
- Clear only necessary data between tests
- Use parallel test execution when possible
- Mock heavy operations

## Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Rules Unit Testing](https://firebase.google.com/docs/rules/unit-tests)
- [Mocha Testing Framework](https://mochajs.org/)
- [Chai Assertion Library](https://www.chaijs.com/)

## Support

For issues or questions:
1. Check test output for specific error messages
2. Review firestore.rules for rule logic
3. Verify test data includes required fields
4. Check GitHub Actions logs for CI failures
5. Contact the development team

---

**Last Updated:** February 15, 2026
**Test Coverage:** 60+ tests across 5 test suites
**Execution Time:** ~2-3 seconds
