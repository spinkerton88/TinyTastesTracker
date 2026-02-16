/**
 * Test Suite: Authentication Requirements
 *
 * Verifies that all Firestore operations require authentication
 */

import { describe, it, before, after, afterEach } from 'mocha';
import { expect } from 'chai';
import {
  setupTestEnvironment,
  teardownTestEnvironment,
  clearFirestoreData,
  getAuthenticatedContext,
  getUnauthenticatedContext,
  assertSucceeds,
  assertFails,
  TestData
} from './setup.js';

describe('Authentication Requirements', () => {
  before(async () => {
    await setupTestEnvironment();
  });

  after(async () => {
    await teardownTestEnvironment();
  });

  afterEach(async () => {
    await clearFirestoreData();
  });

  describe('Unauthenticated Access', () => {
    it('should deny reading child_profiles without authentication', async () => {
      const unauthedContext = getUnauthenticatedContext();
      const firestore = unauthedContext.firestore();

      await assertFails(
        firestore.collection('child_profiles').doc('profile1').get()
      );
    });

    it('should deny creating child_profiles without authentication', async () => {
      const unauthedContext = getUnauthenticatedContext();
      const firestore = unauthedContext.firestore();

      await assertFails(
        firestore.collection('child_profiles').doc('profile1').set(
          TestData.childProfile('user1')
        )
      );
    });

    it('should deny reading sleep_logs without authentication', async () => {
      const unauthedContext = getUnauthenticatedContext();
      const firestore = unauthedContext.firestore();

      await assertFails(
        firestore.collection('sleep_logs').doc('log1').get()
      );
    });

    it('should deny reading nursing_logs without authentication', async () => {
      const unauthedContext = getUnauthenticatedContext();
      const firestore = unauthedContext.firestore();

      await assertFails(
        firestore.collection('nursing_logs').doc('log1').get()
      );
    });

    it('should deny reading meal_logs without authentication', async () => {
      const unauthedContext = getUnauthenticatedContext();
      const firestore = unauthedContext.firestore();

      await assertFails(
        firestore.collection('meal_logs').doc('log1').get()
      );
    });

    it('should deny reading recipes without authentication', async () => {
      const unauthedContext = getUnauthenticatedContext();
      const firestore = unauthedContext.firestore();

      await assertFails(
        firestore.collection('recipes').doc('recipe1').get()
      );
    });
  });

  describe('Authenticated Access', () => {
    it('should allow authenticated users to read their own child profiles', async () => {
      const alice = getAuthenticatedContext('alice');

      // Create a profile as admin
      const adminContext = getAuthenticatedContext('alice');
      await adminContext.firestore()
        .collection('child_profiles')
        .doc('profile1')
        .set(TestData.childProfile('alice'));

      // Verify Alice can read it
      await assertSucceeds(
        alice.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .get()
      );
    });

    it('should allow authenticated users to create child profiles', async () => {
      const alice = getAuthenticatedContext('alice');

      await assertSucceeds(
        alice.firestore()
          .collection('child_profiles')
          .doc('profile1')
          .set(TestData.childProfile('alice'))
      );
    });
  });
});
