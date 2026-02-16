# Security Rules Functional Testing Guide
**TinyTastesTracker - Firebase Firestore Rules Verification**

**Date:** February 15, 2026
**Purpose:** Verify that deployed Firestore security rules (258 lines) protect user data correctly
**Estimated Time:** 2-3 hours
**Status:** ✅ Rules deployed (Feb 8, 2026), needs functional testing

---

## Prerequisites

- ✅ Firestore rules deployed to production (verified Feb 8)
- ✅ Firebase Console access
- ✅ TinyTastesTracker app installed on test device/simulator
- ✅ Two test accounts prepared

---

## Test Accounts Setup (15 minutes)

### Account 1: Alice (Primary Owner)
1. Open Firebase Console → Authentication
2. Create test account:
   - **Email:** `alice-test@tinytastes.com`
   - **Password:** `TestPassword123!`
3. Note User UID: `_________________` (fill in after creation)

### Account 2: Bob (Non-owner / Shared User)
1. Create second test account:
   - **Email:** `bob-test@tinytastes.com`
   - **Password:** `TestPassword123!`
2. Note User UID: `_________________` (fill in after creation)

---

## Test Suite 1: Authentication Requirements (15 minutes)

### Test 1.1: Unauthenticated Access Denial ❌
**Expected:** All operations should fail without authentication

1. Sign out of app completely
2. Attempt to access any data
3. **Expected Result:** Access denied, redirected to login

**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

---

## Test Suite 2: Owner Access Control (30 minutes)

### Test 2.1: Owner Can Create Child Profile ✅
**User:** Alice

1. Sign in as Alice
2. Navigate to Profile Creation
3. Create child profile:
   - **Name:** "Test Baby Alice"
   - **Date of Birth:** January 1, 2026
   - **Gender:** Other
4. Save profile

**Expected Result:** Profile created successfully
**Status:** [ ] Pass [ ] Fail
**Profile ID:** _________________
**Notes:** _______________________________________________

### Test 2.2: Owner Can Read Own Profile ✅
**User:** Alice

1. Navigate to profile list
2. View "Test Baby Alice" profile
3. Verify all data is visible

**Expected Result:** Full access to profile data
**Status:** [ ] Pass [ ] Fail

### Test 2.3: Owner Can Update Own Profile ✅
**User:** Alice

1. Edit "Test Baby Alice" profile
2. Change name to "Test Baby Alice Updated"
3. Save changes

**Expected Result:** Changes saved successfully
**Status:** [ ] Pass [ ] Fail

### Test 2.4: Owner Can Delete Own Profile ✅
**User:** Alice

1. Navigate to profile settings
2. Select "Delete Profile"
3. Confirm deletion

**Expected Result:** Profile deleted (test on duplicate profile, not main test profile)
**Status:** [ ] Pass [ ] Fail

---

## Test Suite 3: Unauthorized Access Denial (45 minutes)

### Test 3.1: Non-owner Cannot Read Other User's Profile ❌
**Users:** Alice (owner), Bob (non-owner)

**Setup:**
1. Alice creates child profile "Test Baby Alice"
2. Note the Profile ID: _________________
3. Sign out
4. Sign in as Bob

**Test:**
1. Attempt to manually navigate to Alice's profile (if possible via deep link or Firebase Console)
2. Or: Use Firebase Console Firestore viewer to check Bob's access

**Expected Result:** Access denied, Bob cannot see Alice's profile
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 3.2: Non-owner Cannot Access Other User's Logs ❌
**Users:** Alice (owner), Bob (non-owner)

**Setup:**
1. As Alice, create nursing log for "Test Baby Alice"
2. As Alice, create sleep log
3. Sign out
4. Sign in as Bob

**Test:**
1. Navigate to newborn tracking
2. Attempt to view logs

**Expected Result:** Bob sees no logs (only his own data if any)
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 3.3: Non-owner Cannot Delete Other User's Data ❌
**Users:** Alice (owner), Bob (non-owner)

**Setup:**
1. As Alice, create data (logs, recipes, etc.)
2. Sign out
3. Sign in as Bob

**Test:**
1. Attempt to access deletion features
2. Verify Bob cannot delete Alice's data

**Expected Result:** Deletion operations fail or unavailable
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

---

## Test Suite 4: Profile Sharing & Invitations (60 minutes)

### Test 4.1: Owner Can Create Invitation ✅
**User:** Alice

1. Sign in as Alice
2. Navigate to Profile Sharing (Settings → Family Sharing)
3. Select "Test Baby Alice" profile
4. Click "Invite User"
5. Enter Bob's email: `bob-test@tinytastes.com`
6. Generate invitation code

**Expected Result:** 6-digit invitation code generated
**Invitation Code:** __ __ __ __ __ __
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 4.2: Invitee Can Accept Invitation ✅
**User:** Bob

1. Sign out, sign in as Bob
2. Navigate to Profile Sharing
3. Select "Accept Invitation"
4. Enter 6-digit code from Test 4.1
5. Accept invitation

**Expected Result:** Invitation accepted, profile access granted
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 4.3: Shared User Can Read Shared Profile ✅
**User:** Bob (now has shared access)

1. As Bob, navigate to profile list
2. Verify "Test Baby Alice" appears in shared profiles
3. Open profile
4. View details

**Expected Result:** Bob can read Alice's shared profile
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 4.4: Shared User Can Update Shared Profile Data ✅
**User:** Bob (shared access)

1. As Bob, open "Test Baby Alice" profile
2. Navigate to Newborn tracking
3. Add a nursing log
4. Add a sleep log

**Expected Result:** Bob can create logs for shared profile
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 4.5: Shared User Cannot Change Ownership ❌
**User:** Bob (shared access)

1. As Bob, open "Test Baby Alice" profile
2. Attempt to access profile ownership settings (if visible)
3. Attempt to remove Alice as owner
4. Attempt to transfer ownership to Bob

**Expected Result:** Bob cannot modify ownership or sharing permissions
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 4.6: Shared User Cannot Delete Profile ❌
**User:** Bob (shared access)

1. As Bob, open "Test Baby Alice" profile
2. Navigate to profile settings
3. Look for "Delete Profile" option

**Expected Result:** Delete option unavailable or operation fails
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 4.7: Owner Can Revoke Shared Access ✅
**User:** Alice (owner)

1. Sign out, sign in as Alice
2. Navigate to Family Sharing for "Test Baby Alice"
3. View list of shared users (should include Bob)
4. Select Bob
5. Click "Revoke Access"
6. Confirm

**Expected Result:** Bob's access revoked
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 4.8: Revoked User Cannot Access Profile ❌
**User:** Bob (access revoked)

1. Sign out, sign in as Bob
2. Navigate to profile list
3. Verify "Test Baby Alice" is no longer accessible

**Expected Result:** Bob cannot see or access Alice's profile
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

---

## Test Suite 5: Recipe & Custom Food Sharing (30 minutes)

### Test 5.1: Owner Can Create Recipe ✅
**User:** Alice

1. Sign in as Alice
2. Navigate to Recipes
3. Create new recipe: "Test Recipe Alice"
4. Save

**Expected Result:** Recipe created successfully
**Status:** [ ] Pass [ ] Fail

### Test 5.2: Non-shared User Cannot Read Recipe ❌
**Users:** Alice (owner), Bob (non-shared)

1. As Alice, create private recipe
2. Sign out, sign in as Bob
3. Navigate to Recipes
4. Search for Alice's recipe

**Expected Result:** Bob cannot see Alice's private recipe
**Status:** [ ] Pass [ ] Fail

### Test 5.3: Shared Recipe Access Works ✅
**Setup:** Alice shares profile with Bob (use previous invitation)

1. As Alice, create recipe for "Test Baby Alice"
2. Sign out, sign in as Bob
3. Navigate to Recipes
4. View recipes for shared profile

**Expected Result:** Bob can see recipes for shared profile
**Status:** [ ] Pass [ ] Fail

---

## Test Suite 6: Edge Cases & Security (20 minutes)

### Test 6.1: Expired Invitation Handling
**Test:** Create invitation, wait for expiration (or manually expire in Firestore Console)

**Expected Result:** Expired invitation cannot be accepted
**Status:** [ ] Pass [ ] Fail
**Notes:** _______________________________________________

### Test 6.2: Invalid Invitation Code ❌
**Test:** Attempt to accept invitation with wrong code

1. As Bob, navigate to Accept Invitation
2. Enter invalid code: "999999"
3. Submit

**Expected Result:** Error message, invitation not accepted
**Status:** [ ] Pass [ ] Fail

### Test 6.3: Cross-Profile Data Isolation ❌
**Test:** Ensure logs from one profile don't appear in another

1. Alice creates Profile A with logs
2. Alice creates Profile B with different logs
3. Switch between profiles
4. Verify logs don't mix

**Expected Result:** Each profile's data is isolated
**Status:** [ ] Pass [ ] Fail

---

## Test Summary

### Results Overview

| Test Suite | Tests | Passed | Failed | Notes |
|------------|-------|--------|--------|-------|
| Authentication | 1 | [ ] | [ ] | |
| Owner Access | 4 | [ ] | [ ] | |
| Unauthorized Access | 3 | [ ] | [ ] | |
| Profile Sharing | 8 | [ ] | [ ] | |
| Recipe Sharing | 3 | [ ] | [ ] | |
| Edge Cases | 3 | [ ] | [ ] | |
| **Total** | **22** | **__** | **__** | |

### Critical Issues Found

1. _______________________________________________
2. _______________________________________________
3. _______________________________________________

### Security Vulnerabilities Discovered

1. _______________________________________________
2. _______________________________________________

### Recommendations

1. _______________________________________________
2. _______________________________________________

---

## Firestore Console Verification (Optional)

### Manual Database Inspection

1. Open Firebase Console → Firestore Database
2. Navigate to collections:
   - `child_profiles` - verify ownerId fields
   - `sleep_logs` - verify babyId and access
   - `nursing_logs` - verify babyId and access
   - `profile_invitations` - verify invitation data
3. Check that:
   - All documents have proper ownerId/babyId fields
   - sharedWith arrays are correct
   - No orphaned data

### Security Rules Simulator (Optional)

1. Firebase Console → Firestore → Rules
2. Click "Rules Playground"
3. Test individual operations:
   - Read as authenticated user
   - Read as different user
   - Write as owner
   - Write as non-owner

---

## Sign-off

**Tester Name:** _________________
**Date Completed:** _________________
**Overall Result:** [ ] All tests passed [ ] Issues found (see above)
**Ready for TestFlight:** [ ] Yes [ ] No (requires fixes)

---

## Next Steps

### If All Tests Pass ✅
1. Document passing results
2. Proceed to TestFlight deployment
3. Schedule follow-up security audit post-launch

### If Tests Fail ❌
1. Document specific failures
2. Review Firestore rules (firestore.rules)
3. Make necessary corrections
4. Re-deploy rules: `firebase deploy --only firestore:rules`
5. Re-run failed tests
6. Repeat until all tests pass

---

**Last Updated:** February 15, 2026
**Rules Version:** 2 (258 lines)
**Rules Deployment Date:** February 8, 2026
