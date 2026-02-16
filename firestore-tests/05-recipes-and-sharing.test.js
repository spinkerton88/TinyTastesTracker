/**
 * Test Suite: Recipe and Custom Food Security
 *
 * Verifies that recipes and custom foods follow sharing model
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

describe('Recipe and Custom Food Security', () => {
  before(async () => {
    await setupTestEnvironment();
  });

  after(async () => {
    await teardownTestEnvironment();
  });

  afterEach(async () => {
    await clearFirestoreData();
  });

  describe('Recipe Ownership', () => {
    it('should allow users to create their own recipes', async () => {
      const alice = getAuthenticatedContext('alice');

      await assertSucceeds(
        alice.firestore()
          .collection('recipes')
          .doc('recipe1')
          .set(TestData.recipe('alice'))
      );
    });

    it('should allow owners to read their own recipes', async () => {
      const alice = getAuthenticatedContext('alice');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice'));

      await assertSucceeds(
        alice.firestore()
          .collection('recipes')
          .doc('recipe1')
          .get()
      );
    });

    it('should allow owners to update their own recipes', async () => {
      const alice = getAuthenticatedContext('alice');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice'));

      await assertSucceeds(
        alice.firestore()
          .collection('recipes')
          .doc('recipe1')
          .update({ title: 'Updated Recipe' })
      );
    });

    it('should allow owners to delete their own recipes', async () => {
      const alice = getAuthenticatedContext('alice');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice'));

      await assertSucceeds(
        alice.firestore()
          .collection('recipes')
          .doc('recipe1')
          .delete()
      );
    });

    it('should deny non-owners from deleting recipes', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice'));

      await assertFails(
        bob.firestore()
          .collection('recipes')
          .doc('recipe1')
          .delete()
      );
    });
  });

  describe('Recipe Sharing', () => {
    it('should allow shared users to read recipes', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice', { sharedWith: ['bob'] }));

      await assertSucceeds(
        bob.firestore()
          .collection('recipes')
          .doc('recipe1')
          .get()
      );
    });

    it('should allow shared users to update recipes', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice', { sharedWith: ['bob'] }));

      await assertSucceeds(
        bob.firestore()
          .collection('recipes')
          .doc('recipe1')
          .update({ title: 'Bob Updated This' })
      );
    });

    it('should deny non-shared users from reading recipes', async () => {
      const alice = getAuthenticatedContext('alice');
      const charlie = getAuthenticatedContext('charlie');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice', { sharedWith: ['bob'] })); // Not Charlie

      await assertFails(
        charlie.firestore()
          .collection('recipes')
          .doc('recipe1')
          .get()
      );
    });

    it('should allow users to add themselves to sharedWith', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      await alice.firestore()
        .collection('recipes')
        .doc('recipe1')
        .set(TestData.recipe('alice'));

      // Bob adds himself (simulating invitation acceptance)
      await assertSucceeds(
        bob.firestore()
          .collection('recipes')
          .doc('recipe1')
          .update({ sharedWith: ['bob'] })
      );
    });
  });

  describe('Owner-Only Collections', () => {
    it('should allow owners to create meal plan entries', async () => {
      const alice = getAuthenticatedContext('alice');

      await assertSucceeds(
        alice.firestore()
          .collection('meal_plan_entries')
          .doc('entry1')
          .set({
            ownerId: 'alice',
            date: new Date().toISOString(),
            mealType: 'lunch',
            recipeId: 'recipe1'
          })
      );
    });

    it('should deny non-owners from reading meal plan entries', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      await alice.firestore()
        .collection('meal_plan_entries')
        .doc('entry1')
        .set({
          ownerId: 'alice',
          date: new Date().toISOString(),
          mealType: 'lunch',
          recipeId: 'recipe1'
        });

      await assertFails(
        bob.firestore()
          .collection('meal_plan_entries')
          .doc('entry1')
          .get()
      );
    });
  });

  describe('Cross-User Recipe Isolation', () => {
    it('should prevent users from accessing each other\'s private recipes', async () => {
      const alice = getAuthenticatedContext('alice');
      const bob = getAuthenticatedContext('bob');

      // Alice creates her recipe
      await alice.firestore()
        .collection('recipes')
        .doc('alice-recipe')
        .set(TestData.recipe('alice'));

      // Bob creates his recipe
      await bob.firestore()
        .collection('recipes')
        .doc('bob-recipe')
        .set(TestData.recipe('bob'));

      // Alice should NOT read Bob's recipe
      await assertFails(
        alice.firestore()
          .collection('recipes')
          .doc('bob-recipe')
          .get()
      );

      // Bob should NOT read Alice's recipe
      await assertFails(
        bob.firestore()
          .collection('recipes')
          .doc('alice-recipe')
          .get()
      );
    });
  });
});
