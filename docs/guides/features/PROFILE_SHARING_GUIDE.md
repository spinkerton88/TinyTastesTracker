# Tiny Tastes Tracker - Profile Sharing Guide

## Overview

Profile sharing is now live! Share child profiles with your partner, family members, or caregivers using simple invitation codes.

---

## How It Works

### For Profile Owners (Person Sharing)

1. **Go to Settings → Manage Children**
2. **Tap the menu (•••)** on the profile you want to share
3. **Select "Manage Sharing"**
4. **Tap "Invite Someone"**
5. **A 6-digit code is automatically generated**
6. **Share the code** via:
   - iMessage
   - WhatsApp
   - Email
   - Text message
   - In person
   - Any messaging app

The app provides two convenient options:
- **"Share via iMessage, WhatsApp, etc."** - Opens iOS share sheet with pre-filled message
- **"Copy Code"** - Copies just the code to your clipboard

### For Recipients (Person Accepting)

1. **Download Tiny Tastes Tracker** (if you haven't already)
2. **Create an account or sign in**
3. **Go to Settings → Family → Accept Invitation**
4. **Enter the 6-digit code** you received
5. **Tap Accept**

The profile will immediately appear in your profile list with a purple share badge.

---

## Features

### Real-Time Sync
- All changes sync instantly across all users who have access
- Add a meal log on one device, see it immediately on another
- Works like everyone is logged into the same account

### Owner Privileges
The original profile owner retains special privileges:
- **Can revoke access** from any shared user
- **Can delete the profile** (shared users cannot)
- **Can manage sharing settings**

### Shared User Capabilities
Shared users can:
- **View all profile data** (meals, sleep, diapers, growth, etc.)
- **Add new data** (log meals, mark foods as tried, etc.)
- **Edit existing data**
- **See who else has access** (in Manage Sharing view)
- **Remove themselves** from the profile at any time

---

## Managing Access

### View Who Has Access
1. **Go to Settings → Manage Children**
2. **Tap (•••) → Manage Sharing** on the profile
3. **See list of users** with access and pending invitations

### Revoke Access (Owner Only)
1. **Go to Manage Sharing** for the profile
2. **Find the user** in the "Shared With" section
3. **Tap "Remove"** next to their name
4. **Confirm** the action

The profile will immediately disappear from their account.

### Leave a Shared Profile (Shared User)
1. **Go to Manage Sharing** for the profile
2. **Tap "Leave Profile"** at the bottom
3. **Confirm** the action

You'll no longer have access to the profile.

---

## Invitation Details

### Invitation Codes
- **6 digits** for easy entry
- **Expire in 7 days**
- **Can be shared multiple times** (same code works for multiple people)

### Pending Invitations
- **View all pending invitations** in Manage Sharing
- **Copy the code** again if needed
- **See expiration date** for each invitation

### Invitation Status
- **Pending** - Code not yet used
- **Accepted** - Someone accepted and now has access
- **Expired** - Code is older than 7 days
- **Declined** - Recipient declined the invitation

---

## Common Scenarios

### Scenario 1: Share with Partner
**You and your spouse want to track your baby together.**

1. You create the profile on your account
2. Generate an invitation code
3. Text the code to your spouse
4. Your spouse enters the code in their account
5. Now you both see and edit the same data in real-time

### Scenario 2: Share with Grandparent (View-Only Usage)
**Your parent wants to see baby's progress but won't add data.**

1. Generate an invitation code
2. Send it to your parent via email or text
3. They accept and can now view everything
4. They have full edit access, but can choose to only view

Note: There's no "read-only" mode currently. All shared users have full edit access. Add a note to your invitation message if you prefer they only view.

### Scenario 3: Share with Daycare
**Your daycare provider will log meals and naps during the day.**

1. Generate an invitation code
2. Give the code to your daycare provider
3. They accept and log activities throughout the day
4. You see everything they log in real-time

### Scenario 4: Multiple Children
**You want to share only one child, not all.**

1. Go to Manage Sharing for **each specific profile**
2. Share invitations separately
3. Recipients only get access to profiles you explicitly share

You can share:
- All profiles with someone (send multiple codes)
- Just one profile (send one code)
- Different profiles with different people

---

## Firestore Setup (One-Time)

You need to update your Firestore security rules to enable shared access.

### Steps

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your Tiny Tastes Tracker project**
3. **Click Firestore Database** in the left sidebar
4. **Click the "Rules" tab** at the top
5. **Copy the content from**: `/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker/firestore.rules`
6. **Paste it into the Firebase Console rules editor**
7. **Click "Publish"**

### What This Does

The updated rules allow:
- **Profile owner** + **anyone in sharedWith array** can read/write profile data
- **Only owner** can delete profiles
- **Only owner** can modify sharing settings

Without this update, shared users won't be able to access the data even though the app allows it.

---

## Testing Checklist

### Test 1: Create and Share Invitation
- [ ] Create invitation code
- [ ] Share via iOS share sheet
- [ ] Copy code to clipboard

### Test 2: Accept Invitation
- [ ] Enter code on second account
- [ ] Profile appears with purple badge
- [ ] All data is visible

### Test 3: Real-Time Sync
- [ ] Add meal log on Device A
- [ ] See it appear on Device B immediately
- [ ] Edit data on Device B
- [ ] See changes on Device A

### Test 4: Owner Privileges
- [ ] Revoke access as owner
- [ ] Profile disappears from shared user's account
- [ ] Owner can still access profile

### Test 5: Shared User Actions
- [ ] Shared user can add data
- [ ] Shared user can edit data
- [ ] Shared user can view Manage Sharing (but not revoke owner)
- [ ] Shared user can leave profile

---

## Troubleshooting

### "Invalid invitation code" error
- Check that the code is exactly 6 digits
- Make sure the invitation hasn't expired (7 days)
- Try copying the code again from the sender

### Profile not appearing after accepting
- Check that Firestore rules are updated (see Firestore Setup above)
- Try force-quitting and reopening the app
- Check Firebase Console → Firestore → child_profiles → verify you're in the sharedWith array

### Can't see shared user's changes
- Make sure both users are online
- Pull to refresh the profile list
- Check that you're looking at the same profile (check profile name)

### "You don't have permission" errors
- Firestore rules may not be updated
- The owner may have revoked your access
- Try signing out and back in

---

## Security & Privacy

### Data Access
- **Shared users have full access** to all data for shared profiles only
- **They cannot access your account settings** or other profiles
- **They cannot change ownership** or delete the profile

### Revoking Access
- **Immediate effect** - user loses access instantly
- **No notification** - user doesn't get notified when revoked
- **Data stays** - any data they added remains in the profile

### Account Separation
- **Each user has their own account** and login
- **Sharing doesn't merge accounts** - just shares specific profiles
- **Each user can have their own profiles** + shared profiles

---

## Future Enhancements

Planned features for future versions:

- **Push notifications** when invitation is accepted
- **Activity log** showing who made what changes
- **Read-only sharing** for view-only access
- **Transfer ownership** to another user
- **Share multiple profiles** with one invitation
- **Deep links** for one-tap acceptance

---

## Questions?

**Q: Can shared users invite more people?**
A: No, only the owner can invite others.

**Q: What happens if the owner deletes their account?**
A: The profile and all its data are deleted. Shared users lose access.

**Q: Can I share one profile with multiple people?**
A: Yes! Send the same code to multiple people or generate new codes.

**Q: Is there a limit to how many people I can share with?**
A: No limit in the app, but Firestore costs scale with usage.

**Q: Can I see who added what data?**
A: Not in v1. Future versions may include activity logging.

**Q: What if I accidentally revoke someone?**
A: Generate a new invitation and send them the code again.

---

## Success! 🎉

Once you:
- ✅ Updated Firestore rules
- ✅ Tested invitation creation and acceptance
- ✅ Verified real-time sync

Your profile sharing feature is fully operational!

Enjoy tracking your little one's journey together with family and caregivers.
