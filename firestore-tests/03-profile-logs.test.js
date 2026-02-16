/**
 * Test Suite: Profile Log Security (Sleep, Nursing, Diaper, etc.)
 *
 * Verifies that logs are properly protected by profile access control
 */

import { describe, it, before, after, afterEach } from 'mocha';
import { expect } from 'chai';
import {
  setupTestEnvironment,
  teardownTestEnvironment,
  clearFirestoreData,
  getAuthenticatedContext,
  assertSucceeds,
  assertFails,
  TestData
} from './setup.js';

describe('Profile Log Security', () => {
  before(async () => {
    await setupTestEnvironment();
  });

  after(async () => {
    await teardownTestEnvironment();
  });

  afterEach(async () => {
    await clearFirestoreData();
  });

  describe('Sleep Logs', () => {
    it('should allow profile owners to create sleep logs', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create profile first
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      // Create sleep log
      await assertSucceeds(
        alice.firestore()
          .collection('sleep_logs')
          .doc('log1')
          .set(TestData.sleepLog('baby1', 'alice'))
      );
    });

    it('should allow profile owners to read sleep logs', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create profile and log
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      await alice.firestore()
        .collection('sleep_logs')
        .doc('log1')
        .set(TestData.sleepLog('baby1', 'alice'));

      // Read sleep log
      await assertSucceeds(
        alice.firestore()
          .collection('sleep_logs')
          .doc('log1')
          .get()
      );
    });

    it('should allow shared users to read sleep logs', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile and shares with Bob
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice', { sharedWith: ['bob'] }));

      await alice.firestore()
        .collection('sleep_logs')
        .doc('log1')
        .set(TestData.sleepLog('baby1', 'alice'));

      // Bob should be able to read
      await assertSucceeds(
        bob.firestore()
          .collection('sleep_logs')
          .doc('log1')
          .get()
      );
    });

    it('should deny non-shared users from reading sleep logs', async () => {
      const alice = getAuthenticatedContext('alice');
      const charlie = getAuthenticatedContext('charlie');

      // Alice creates profile and log
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      await alice.firestore()
        .collection('sleep_logs')
        .doc('log1')
        .set(TestData.sleepLog('baby1', 'alice'));

      // Charlie should NOT be able to read
      await assertFails(
        charlie.firestore()
          .collection('sleep_logs')
          .doc('log1')
          .get()
      );
    });
  });

  describe('Nursing Logs', () => {
    it('should allow profile owners to create nursing logs', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create profile first
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      // Create nursing log
      await assertSucceeds(
        alice.firestore()
          .collection('nursing_logs')
          .doc('log1')
          .set(TestData.nursingLog('baby1', 'alice'))
      );
    });

    it('should deny non-owners from reading nursing logs', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile and nursing log
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      await alice.firestore()
        .collection('nursing_logs')
        .doc('log1')
        .set(TestData.nursingLog('baby1', 'alice'));

      // Bob should NOT be able to read (not shared)
      await assertFails(
        bob.firestore()
          .collection('nursing_logs')
          .doc('log1')
          .get()
      );
    });
  });

  describe('Meal Logs', () => {
    it('should allow profile owners to create meal logs', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create profile first
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      // Create meal log
      await assertSucceeds(
        alice.firestore()
          .collection('meal_logs')
          .doc('log1')
          .set(TestData.mealLog('baby1', 'alice'))
      );
    });

    it('should allow shared users to write meal logs', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile and shares with Bob
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice', { sharedWith: ['bob'] }));

      // Bob should be able to create meal logs
      await assertSucceeds(
        bob.firestore()
          .collection('meal_logs')
          .doc('log1')
          .set(TestData.mealLog('baby1', 'alice'))
      );
    });
  });

  describe('Cross-Profile Log Isolation', () => {
    it('should prevent reading logs from different profiles', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates her profile and log
      await alice.firestore()
        .collection('child_profiles')
        .doc('alice-baby')
        .set(TestData.childProfile('alice'));

      await alice.firestore()
        .collection('sleep_logs')
        .doc('alice-log')
        .set(TestData.sleepLog('alice-baby', 'alice'));

      // Bob creates his profile and log
      await bob.firestore()
        .collection('child_profiles')
        .doc('bob-baby')
        .set(TestData.childProfile('bob'));

      await bob.firestore()
        .collection('sleep_logs')
        .doc('bob-log')
        .set(TestData.sleepLog('bob-baby', 'bob'));

      // Alice should NOT read Bob's log
      await assertFails(
        alice.firestore()
          .collection('sleep_logs')
          .doc('bob-log')
          .get()
      );

      // Bob should NOT read Alice's log
      await assertFails(
        bob.firestore()
          .collection('sleep_logs')
          .doc('alice-log')
          .get()
      );
    });
  });
});
