# CloudKit Family Sharing - Testing Guide

## Overview
This guide explains how to test the CloudKit Family Sharing feature that allows two parents with **different iCloud accounts** to share and sync the same baby profile in real-time.

## Prerequisites

### Required:
- ✅ Two iOS devices (iPhone, iPad, etc.)
- ✅ Two different iCloud accounts (e.g., mom@icloud.com and dad@icloud.com)
- ✅ Both devices signed into their respective iCloud accounts
- ✅ Both devices have iCloud Drive enabled
- ✅ Both devices connected to the internet

### App Requirements:
- ✅ TinyTastesTracker installed on both devices
- ✅ Same app bundle ID and CloudKit container
- ✅ Both devices running the latest build

---

## Test Scenario: Mom Shares Profile with Dad

### Device 1 - Mom's iPhone (Owner)

#### Step 1: Create Profile
1. Launch app on Mom's iPhone
2. Complete onboarding
3. Create a baby profile (e.g., "Emma")
4. Add some data:
   - Log a feeding
   - Try a new food
   - Add an allergy

#### Step 2: Share the Profile
1. Go to **Settings**
2. Tap **Family**
3. Tap **Share Profile**
4. Wait for UICloudSharingController to appear
5. Tap **Add People**
6. Enter Dad's iCloud email (dad@icloud.com)
7. Choose permission: **Can Make Changes** (Read/Write)
8. Tap **Send**

#### Step 3: Verify Share Created
1. Go to **Settings > Family > Manage Sharing**
2. Should see "Emma" under "Profiles You're Sharing"
3. Tap "Manage" to see Dad as a participant

---

### Device 2 - Dad's iPhone (Participant)

#### Step 1: Receive Invitation
Dad will receive a notification:
- **Push Notification**: "Someone shared a profile with you"
- **OR** Email: Invitation from iCloud

#### Step 2: Accept Invitation

**Option A: From Notification**
1. Tap the notification
2. App opens to share invitation
3. Tap **Accept**

**Option B: From App**
1. Launch TinyTastesTracker
2. Go to **Settings > Family > Manage Sharing**
3. See invitation under "Pending Invitations"
4. Tap **Accept**

#### Step 3: Access Shared Profile
1. After accepting, Emma's profile appears in the app
2. All data from Mom's device is visible
3. Dad can now:
   - ✅ View all feedings, foods, recipes
   - ✅ Add new logs
   - ✅ Edit existing data
   - ✅ Changes sync back to Mom's device

---

## Testing Real-Time Sync

### Test 1: Add Data on Mom's Device
1. Mom logs a new feeding
2. Wait 10-30 seconds
3. **Expected**: Dad's device shows the new feeding
4. If not visible, pull-to-refresh

### Test 2: Add Data on Dad's Device
1. Dad tries a new food
2. Wait 10-30 seconds
3. **Expected**: Mom's device shows the new food
4. If not visible, pull-to-refresh

### Test 3: Edit Data on Both Devices
1. Mom edits a recipe
2. Dad edits the same recipe at the same time
3. **Expected**: CloudKit handles conflict resolution
4. Last write wins (most recent change)

---

## Testing Permissions

### Read/Write (Can Make Changes)
- ✅ Can view all data
- ✅ Can add new logs
- ✅ Can edit existing data
- ✅ Can delete data
- ❌ Cannot change sharing settings
- ❌ Cannot remove participants

### Read-Only (Can View)
- ✅ Can view all data
- ❌ Cannot add logs
- ❌ Cannot edit data
- ❌ Cannot delete data

**To Test:**
1. Mom changes Dad's permission to "Can View Only"
2. Dad tries to add a feeding
3. **Expected**: Should see "Read-Only Access" error

---

## Testing Participant Management

### Mom's Device (Owner)

#### View Participants:
1. Settings > Family > Manage Sharing
2. Tap "Manage" on Emma's profile
3. Should see:
   - Mom (Owner)
   - Dad (Can Make Changes)

#### Remove Participant:
1. In Participants view
2. Swipe left on Dad
3. Tap "Remove Access"
4. **Expected**: Dad loses access immediately

#### Stop Sharing:
1. Settings > Family > Manage Sharing
2. Swipe left on Emma's profile
3. Tap "Stop Sharing"
4. Confirm
5. **Expected**: All participants lose access

### Dad's Device (Participant)

#### View Own Access:
1. Settings > Family > Manage Sharing
2. Should see Emma under "Shared With You"
3. Cannot manage other participants

---

## Troubleshooting

### Share Not Appearing
**Problem**: Dad doesn't receive the invitation

**Solutions**:
1. Check Dad's email for iCloud invitation
2. Settings > Family > Manage Sharing > Pull to refresh
3. Ensure both devices are online
4. Check iCloud account is correct
5. Wait up to 5 minutes for propagation

### Data Not Syncing
**Problem**: Changes on one device don't appear on the other

**Solutions**:
1. Check iCloud Sync Status in both apps
2. Ensure both devices are online
3. Pull-to-refresh in the app
4. Force close and reopen both apps
5. Wait up to 60 seconds for sync

### Share Creation Fails
**Problem**: "Failed to create share" error

**Solutions**:
1. Ensure profile has been synced to CloudKit first
2. Check Settings > iCloud Sync Status shows "Active"
3. Sign out and back into iCloud
4. Delete and reinstall app
5. Check Xcode console for detailed error

### Record Not Found Error
**Problem**: "Could not find the profile in CloudKit"

**Cause**: Profile hasn't been uploaded to CloudKit yet

**Solution**:
1. Wait 1-2 minutes after creating profile
2. Check Settings > iCloud Sync Status
3. Add some data to trigger a sync
4. Try sharing again

---

## Testing Multiple Profiles

### Scenario: Multiple Children
1. Mom has two profiles: Emma and Noah
2. Mom shares Emma with Dad
3. Mom shares Noah with Grandma
4. **Expected**:
   - Dad only sees Emma
   - Grandma only sees Noah
   - Mom sees both

**To Test:**
1. Create second profile on Mom's device
2. Share each with different people
3. Verify isolation on participant devices

---

## Known Limitations

### Current Implementation:
- ✅ Share entire profile (baby + all data)
- ✅ Real-time sync between devices
- ✅ Manage participants
- ✅ Change permissions
- ❌ Cannot share individual meals/logs (all or nothing)
- ❌ Cannot merge two separate profiles
- ❌ Offline changes queue for later sync

### Future Enhancements:
- Granular sharing (share only specific features)
- Conflict resolution UI
- Offline mode with sync queue
- Share history/audit log

---

## Success Criteria

The CloudKit sharing feature is working correctly when:

✅ **Share Creation**
- Mom can share profile with Dad's email
- UICloudSharingController appears properly
- Share is created in CloudKit

✅ **Invitation**
- Dad receives notification/email
- Dad can accept invitation
- Shared profile appears in Dad's app

✅ **Real-Time Sync**
- Changes on Mom's device appear on Dad's (within 60s)
- Changes on Dad's device appear on Mom's (within 60s)
- Data persists across app restarts

✅ **Permissions**
- Read/Write allows full editing
- Read-Only prevents changes
- Owner can manage participants

✅ **Participant Management**
- Can view all participants
- Can remove participants
- Can stop sharing entirely

---

## Debugging

### Check Xcode Console for:
```
✅ Successfully created share
✅ Share saved successfully
✅ CloudKit container initialized
✅ Successfully created ModelContainer with CloudKit sync enabled
```

### Red Flags:
```
❌ Failed to create share
❌ Record not found
❌ Using IN-MEMORY storage
❌ CloudKit not configured
```

---

## Quick Test Checklist

Before releasing:
- [ ] Two devices, different iCloud accounts
- [ ] Create profile on Device 1
- [ ] Share profile with Device 2's iCloud email
- [ ] Device 2 receives and accepts invitation
- [ ] Add data on Device 1 → appears on Device 2
- [ ] Add data on Device 2 → appears on Device 1
- [ ] Change permission to Read-Only → Device 2 can't edit
- [ ] Remove participant → Device 2 loses access
- [ ] Stop sharing → All participants lose access

---

**Ready to test!** Follow the steps above and report any issues.
