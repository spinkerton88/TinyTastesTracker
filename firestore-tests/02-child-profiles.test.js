/**
 * Test Suite: Child Profile Security
 *
 * Verifies owner-based access control and profile sharing
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

describe('Child Profile Security', () => {
  before(async () => {
    await setupTestEnvironment();
  });

  after(async () => {
    await teardownTestEnvironment();
  });

  afterEach(async () => {
    await clearFirestoreData();
  });

  describe('Owner Access Control', () => {
    it('should allow owners to read their own child profiles', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create profile
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice'));

      // Verify read access
      await assertSucceeds(
        alice.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .get()
      );
    });

    it('should allow owners to update their own child profiles', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create profile
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice'));

      // Update profile
      await assertSucceeds(
        alice.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .update({ name: 'Updated Baby Name' })
      );
    });

    it('should allow owners to delete their own child profiles', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create profile
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice'));

      // Delete profile
      await assertSucceeds(
        alice.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .delete()
      );
    });

    it('should deny non-owners from deleting child profiles', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice'));

      // Bob tries to delete (should fail)
      await assertFails(
        bob.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .delete()
      );
    });
  });

  describe('Profile Sharing', () => {
    it('should allow shared users to read child profiles', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile and shares with Bob
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice', { sharedWith: ['bob'] }));

      // Bob should be able to read
      await assertSucceeds(
        bob.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .get()
      );
    });

    it('should allow shared users to update child profiles (but not ownership)', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile and shares with Bob
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice', { sharedWith: ['bob'] }));

      // Bob should be able to update (but not ownership fields)
      await assertSucceeds(
        bob.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .update({ name: 'Updated Name' })
      );
    });

    it('should deny shared users from changing ownership', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile and shares with Bob
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice', { sharedWith: ['bob'] }));

      // Bob tries to change ownership (should fail)
      await assertFails(
        bob.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .update({ ownerId: 'bob' })
      );
    });

    it('should deny non-shared users from reading child profiles', async () => {
      const alice = getAuthenticatedContext('alice');
      const charlie = getAuthenticatedContext('charlie');

      // Alice creates profile shared with Bob (not Charlie)
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice', { sharedWith: ['bob'] }));

      // Charlie should NOT be able to read
      await assertFails(
        charlie.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .get()
      );
    });

    it('should allow users to add themselves to sharedWith (invitation acceptance)', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates profile without sharing
      await alice.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice'));

      // Bob adds himself to sharedWith (simulating invitation acceptance)
      await assertSucceeds(
        bob.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .update({ sharedWith: ['bob'] })
      );
    });
  });

  describe('Cross-User Data Isolation', () => {
    it('should prevent users from accessing other users\' profiles', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates her profile
      await alice.firestore()
        .collection('child_profiles')
        .doc('alice-profile')
        .set(TestData.childProfile('alice'));

      // Bob creates his profile
      await bob.firestore()
        .collection('child_profiles')
        .doc('bob-profile')
        .set(TestData.childProfile('bob'));

      // Alice should NOT be able to read Bob's profile
      await assertFails(
        alice.firestore()
          .collection('child_profiles')
          .doc('bob-profile')
          .get()
      );

      // Bob should NOT be able to read Alice's profile
      await assertFails(
        bob.firestore()
          .collection('child_profiles')
          .doc('alice-profile')
          .get()
      );
    });
  });
});
