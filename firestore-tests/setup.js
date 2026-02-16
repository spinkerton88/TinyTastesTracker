/**
 * Firestore Rules Testing Setup
 *
 * This file provides helper functions for testing Firestore security rules.
 */

import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';

// Global test environment
let testEnv;

/**
 * Initialize the test environment before all tests
 */
export async function setupTestEnvironment() {
  // Load the Firestore rules
  const rules = readFileSync('./firestore.rules', 'utf8');

  testEnv = await initializeTestEnvironment({
    projectId: 'tinytastestracker-test',
    firestore: {
      rules,
      host: 'localhost',
      port: 8080
    }
  });

  return testEnv;
}

/**
 * Clean up the test environment after all tests
 */
export async function teardownTestEnvironment() {
  if (testEnv) {
    await testEnv.cleanup();
  }
}

/**
 * Clear all Firestore data between tests
 */
export async function clearFirestoreData() {
  if (testEnv) {
    await testEnv.clearFirestore();
  }
}

/**
 * Get an authenticated context for a user
 */
export function getAuthenticatedContext(userId, email = `${userId}@test.com`) {
  if (!testEnv) {
    throw new Error('Test environment not initialized');
  }

  return testEnv.authenticatedContext(userId, {
    email: email
  });
}

/**
 * Get an unauthenticated context
 */
export function getUnauthenticatedContext() {
  if (!testEnv) {
    throw new Error('Test environment not initialized');
  }

  return testEnv.unauthenticatedContext();
}

/**
 * Assert that a Firestore operation succeeds
 */
export { assertSucceeds };

/**
 * Assert that a Firestore operation fails with permission denied
 */
export { assertFails };

/**
 * Test data factories
 */
export const TestData = {
  /**
   * Create a child profile document
   */
  childProfile(ownerId, overrides = {}) {
    return {
      ownerId,
      name: 'Test Baby',
      dateOfBirth: new Date('2025-01-01').toISOString(),
      gender: 'other',
      currentMode: 'explorer',
      sharedWith: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      ...overrides
    };
  },

  /**
   * Create a sleep log document
   */
  sleepLog(babyId, ownerId, overrides = {}) {
    return {
      babyId,
      ownerId,
      startTime: new Date().toISOString(),
      endTime: new Date(Date.now() + 7200000).toISOString(), // 2 hours later
      quality: 'good',
      timestamp: new Date().toISOString(),
      ...overrides
    };
  },

  /**
   * Create a nursing log document
   */
  nursingLog(babyId, ownerId, overrides = {}) {
    return {
      babyId,
      ownerId,
      startTime: new Date().toISOString(),
      duration: 1200, // 20 minutes
      side: 'left',
      timestamp: new Date().toISOString(),
      ...overrides
    };
  },

  /**
   * Create a profile invitation document
   */
  profileInvitation(childProfileId, invitedBy, overrides = {}) {
    return {
      childProfileId,
      invitedBy,
      invitedEmail: 'invitee@test.com',
      inviteCode: '123456',
      status: 'pending',
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 86400000).toISOString(), // 24 hours
      ...overrides
    };
  },

  /**
   * Create a meal log document
   */
  mealLog(childId, ownerId, overrides = {}) {
    return {
      childId,
      ownerId,
      mealType: 'lunch',
      foodsEaten: ['apple', 'banana'],
      timestamp: new Date().toISOString(),
      ...overrides
    };
  },

  /**
   * Create a recipe document
   */
  recipe(ownerId, overrides = {}) {
    return {
      ownerId,
      title: 'Test Recipe',
      ingredients: ['ingredient1', 'ingredient2'],
      instructions: 'Cook the food',
      sharedWith: [],
      createdAt: new Date().toISOString(),
      ...overrides
    };
  }
};
