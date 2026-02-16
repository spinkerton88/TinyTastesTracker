/**
 * Test Suite: Profile Invitation Security
 *
 * Verifies that the invitation system is properly secured
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

describe('Profile Invitation Security', () => {
  before(async () => {
    await setupTestEnvironment();
  });

  after(async () => {
    await teardownTestEnvironment();
  });

  afterEach(async () => {
    await clearFirestoreData();
  });

  describe('Creating Invitations', () => {
    it('should allow profile owners to create invitations', async () => {
      const alice = getAuthenticatedContext('alice');

      // Alice creates her profile
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      // Alice creates invitation
      await assertSucceeds(
        alice.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .set(TestData.profileInvitation('baby1', 'alice'))
      );
    });

    it('should deny users from creating invitations for others', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates her profile
      await alice.firestore()
        .collection('child_profiles')
        .doc('baby1')
        .set(TestData.childProfile('alice'));

      // Bob tries to create invitation for Alice's profile (should fail)
      await assertFails(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .set(TestData.profileInvitation('baby1', 'alice')) // invitedBy should be bob's ID
      );
    });

    it('should require invitedBy to match auth.uid', async () => {
      const bob = getAuthenticatedContext('bob');

      // Bob tries to create invitation but claims it's from Alice
      await assertFails(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .set(TestData.profileInvitation('baby1', 'alice')) // Wrong invitedBy
      );
    });
  });

  describe('Reading Invitations', () => {
    it('should allow authenticated users to read invitations (for code lookup)', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates invitation
      await alice.firestore()
        .collection('profile_invitations')
        .doc('invite1')
        .set(TestData.profileInvitation('baby1', 'alice'));

      // Bob should be able to read (needed for 6-digit code lookup)
      await assertSucceeds(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .get()
      );
    });
  });

  describe('Accepting/Declining Invitations', () => {
    it('should allow any user to mark invitation as accepted', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates invitation
      await alice.firestore()
        .collection('profile_invitations')
        .doc('invite1')
        .set(TestData.profileInvitation('baby1', 'alice', {
          invitedEmail: 'bob@test.com'
        }));

      // Bob accepts the invitation
      await assertSucceeds(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .update({ status: 'accepted' })
      );
    });

    it('should allow any user to mark invitation as declined', async () => {
      const alice = getAuthenticatedContext('alice');
      const charlie = getAuthenticatedContext('charlie');

      // Alice creates invitation
      await alice.firestore()
        .collection('profile_invitations')
        .doc('invite1')
        .set(TestData.profileInvitation('baby1', 'alice'));

      // Charlie declines the invitation
      await assertSucceeds(
        charlie.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .update({ status: 'declined' })
      );
    });

    it('should deny non-inviter from updating other fields', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates invitation
      await alice.firestore()
        .collection('profile_invitations')
        .doc('invite1')
        .set(TestData.profileInvitation('baby1', 'alice'));

      // Bob tries to change the invite code (should fail)
      await assertFails(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .update({ inviteCode: '999999' })
      );
    });
  });

  describe('Deleting Invitations', () => {
    it('should allow inviter to delete (cancel) invitations', async () => {
      const alice = getAuthenticatedContext('alice');

      // Alice creates invitation
      await alice.firestore()
        .collection('profile_invitations')
        .doc('invite1')
        .set(TestData.profileInvitation('baby1', 'alice'));

      // Alice deletes (cancels) the invitation
      await assertSucceeds(
        alice.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .delete()
      );
    });

    it('should deny non-inviters from deleting invitations', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates invitation
      await alice.firestore()
        .collection('profile_invitations')
        .doc('invite1')
        .set(TestData.profileInvitation('baby1', 'alice'));

      // Bob tries to delete (should fail)
      await assertFails(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .delete()
      );
    });
  });

  describe('Edge Cases', () => {
    it('should handle expired invitations gracefully', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates an expired invitation
      const yesterday = new Date(Date.now() - 86400000).toISOString();
      await alice.firestore()
        .collection('profile_invitations')
        .doc('invite1')
        .set(TestData.profileInvitation('baby1', 'alice', {
          expiresAt: yesterday
        }));

      // Bob should still be able to read it (expiration is enforced in app logic)
      await assertSucceeds(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .get()
      );

      // But shouldn't be able to update non-status fields
      await assertFails(
        bob.firestore()
          .collection('profile_invitations')
          .doc('invite1')
          .update({ inviteCode: '888888' })
      );
    });
  });
});
