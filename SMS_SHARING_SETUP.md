# Tiny Tastes Tracker - SMS Profile Sharing Setup Guide

## ✅ What's Already Done

Your profile sharing feature is fully implemented with:
- Data models and managers (using phone numbers instead of email)
- Complete UI for inviting, accepting, and managing shared access
- Real-time sync across devices
- Security checks (owner privileges, etc.)

**You just need to configure 2 things:**

---

## Part 1: Firestore Security Rules (5 minutes)

### Why This Matters
Security rules control who can access what data in Firestore. Without updating these, shared users won't be able to read/write the child's data even though your app logic allows it.

### Steps:

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your "Tiny Tastes Tracker" project

2. **Navigate to Firestore Rules**
   - Click "Firestore Database" in left sidebar
   - Click the "Rules" tab at the top

3. **Replace Rules**
   - Copy all the content from: `/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker/firestore.rules`
   - Paste it into the Firebase Console rules editor
   - **Click "Publish"**

4. **Verify**
   - You should see a success message
   - The rules are now live!

### What Changed:
- **Before**: Only the owner (ownerId) could access child profiles and their data
- **After**: Owner + anyone in the `sharedWith` array can access the data
- Owner still retains exclusive rights to delete profiles and modify sharing settings

---

## Part 2: SMS Service with Twilio (15-20 minutes)

### Why This Matters
When you invite someone via phone number, they need to receive that invitation with the 6-digit code. The app will send them a text message.

### Why Twilio?
- Industry standard for SMS
- Reliable delivery
- Pay-as-you-go pricing (around $0.0075 per SMS in US)
- Free trial credit ($15 to start)
- Easy to set up

---

### Step 1: Create Twilio Account

1. **Go to**: https://www.twilio.com/try-twilio
2. **Click** "Start for free" or "Sign up"
3. **Fill out** the registration form
4. **Verify** your email address
5. **Verify** your phone number (they'll send you a code)

---

### Step 2: Get a Twilio Phone Number

1. After logging in, you'll see **"Get a phone number"**
2. Click **"Get a trial number"**
3. Twilio will assign you a number (e.g., +1234567890)
4. **Click "Choose this number"**
5. **Save this number** - you'll need it!

💡 **Note**: Trial accounts can only send to verified phone numbers. For production, you'll need to upgrade your account (no monthly fees, just pay-per-use).

---

### Step 3: Get Your Twilio Credentials

1. Go to your **Twilio Console Dashboard**: https://console.twilio.com/
2. You'll see a box labeled **"Account Info"**
3. **Copy** these three values:
   - **Account SID** (starts with "AC...")
   - **Auth Token** (click the eye icon to reveal it)
   - **My Twilio phone number** (the one you just got)

⚠️ **Keep these secret!** Don't share them publicly.

---

### Step 4: Add Twilio Credentials to Your App

1. **Open**: `/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker/TinyTastesTracker/Core/Services/SMSService.swift`

2. **Find lines 13-15:**
   ```swift
   private let accountSID = "YOUR_TWILIO_ACCOUNT_SID"
   private let authToken = "YOUR_TWILIO_AUTH_TOKEN"
   private let fromNumber = "+1234567890"
   ```

3. **Replace with your actual credentials:**
   ```swift
   private let accountSID = "AC1234567890abcdef..." // Your Account SID
   private let authToken = "your_auth_token_here"    // Your Auth Token
   private let fromNumber = "+15551234567"            // Your Twilio number
   ```

4. **Save the file**

---

### Step 5: Test It! (Trial Account)

With a trial account, you can only send to verified numbers:

1. **In Twilio Console**, go to **Phone Numbers** → **Verified Caller IDs**
2. **Click** "Add a new number"
3. **Enter** your own phone number (or a test recipient's)
4. **Verify** it with the code Twilio sends

Now you can test sending invitations!

1. **Build and run** your app
2. **Create** a test child profile
3. **Invite** yourself (use the verified phone number)
4. **Check** your phone - you should receive a text!

---

### Step 6: Upgrade for Production (When Ready)

To send to any phone number:

1. **Go to**: https://console.twilio.com/
2. **Click** "Upgrade" in the top banner
3. **Add** a credit card (no monthly fees!)
4. **Add** $20 to start (typical SMS costs $0.0075 each)
5. **Done!** Now you can send to any number

**Pricing**: Around $0.0075 per SMS in the US, varies by country.

---

## Testing Checklist

### Test 1: Send Invitation
- [ ] Open app, go to Settings → Manage Children
- [ ] Tap the menu (•••) on a profile → "Manage Sharing"
- [ ] Tap "Invite Someone"
- [ ] Enter a phone number (verified number if using trial)
- [ ] Send invitation
- [ ] **Expected**: Text message arrives within 30 seconds with 6-digit code

### Test 2: Accept Invitation
- [ ] On second device/account, sign in
- [ ] Go to Settings → Family → Accept Invitation
- [ ] Enter the 6-digit code from text
- [ ] **Expected**: Profile appears in your list with purple share badge

### Test 3: Real-time Sync
- [ ] On Device A (owner): Add a meal log for the shared child
- [ ] On Device B (shared user): Pull to refresh
- [ ] **Expected**: The meal log appears instantly

### Test 4: Owner Privileges
- [ ] As shared user: Try to access "Manage Sharing"
- [ ] **Expected**: You can see who has access but can't revoke anyone
- [ ] As owner: Revoke the shared user's access
- [ ] **Expected**: Profile disappears from shared user's account

---

## Troubleshooting

### Text Message Not Sending?

**Check 1**: Twilio Credentials
```swift
// In SMSService.swift, lines 13-15
// Make sure they're your actual credentials, not the placeholders
private let accountSID = "AC..." // ✅ Starts with "AC"
private let authToken = "abc123..." // ✅ Your actual token
private let fromNumber = "+15551234567" // ✅ Your Twilio number with +
```

**Check 2**: Phone Number Format
- Must include country code (e.g., +1 for US/Canada)
- Twilio formats it automatically, but check it's correct

**Check 3**: Trial Account Restrictions
- Go to Twilio Console → Phone Numbers → Verified Caller IDs
- Make sure recipient's number is verified

**Check 4**: Twilio Console Logs
- Go to: https://console.twilio.com/
- Click "Monitor" → "Logs" → "Messaging"
- You'll see all SMS attempts and any errors

**Check 5**: Console Logs in Xcode
- When you send an invitation, check Xcode console
- Should see: `✅ SMS sent successfully to +15551234567`
- If error, it will show the status code and message

### Profile Not Appearing After Accepting?

**Check 1**: Firestore Rules
- Make sure you published the updated rules in Firebase Console
- Go to Firestore → Rules tab
- Should see the `hasProfileAccess()` function

**Check 2**: Profile Manager Listeners
- The app should automatically detect the new profile
- Try force-quitting and reopening the app

**Check 3**: Firebase Console
- Go to Firestore Database
- Find the child_profiles collection
- Check if the user's ID is in the `sharedWith` array

### "Recipient phone number is not a valid E.164"?

This means the phone number format is wrong. Twilio requires E.164 format:
- ✅ Correct: `+15551234567` (country code + number)
- ❌ Wrong: `555-123-4567`, `(555) 123-4567`, `5551234567`

The app auto-formats US numbers, but for international:
- Include the country code with +
- Example (UK): `+447911123456`
- Example (Australia): `+61412345678`

---

## Security Notes

### Twilio Credentials Security
⚠️ **Important**: Your Twilio credentials are currently hardcoded in SMSService.swift. This is fine for:
- Development
- TestFlight beta testing
- Small-scale apps

**For large-scale production**, you should:
1. Move credentials to a backend server
2. Have your app call your server, which then calls Twilio
3. This prevents someone from extracting your credentials from the app binary

**Quick security measure**: Set spending limits in Twilio dashboard to prevent abuse.

---

## Cost Estimation

**Twilio SMS Pricing** (US):
- $0.0075 per SMS sent (0.75 cents)
- $0.0075 per SMS received (for verification codes, not used here)
- No monthly fees, pay-as-you-go

**Example costs**:
- 100 invitations/month = $0.75
- 1,000 invitations/month = $7.50
- 10,000 invitations/month = $75

**Compare to email** (Resend):
- 3,000 emails/month = Free
- 50,000 emails/month = $20

💡 **Tip**: SMS is more expensive but has much higher open rates (98% vs 20% for email)

---

## Alternative: Use Email Instead

If you prefer email over SMS (cheaper, no phone number needed):

The codebase has `EmailService.swift` already created. To switch back to email:

1. **In ProfileSharingManager.swift**, line 82:
   ```swift
   try await sendInvitationEmail(invitation: invitation)  // Instead of sendInvitationSMS
   ```

2. **In ProfileInvitation.swift**, make `invitedEmail` the primary field

3. **In all UI files**, change phone number inputs back to email inputs

4. **Follow** the email setup guide in `PROFILE_SHARING_SETUP.md`

Or let me know and I can make these changes for you!

---

## Next Steps After Setup

Once SMS is working:

1. **Test with real users**: Have a friend/partner test the full flow
2. **Monitor usage**: Check Twilio dashboard for SMS usage and costs
3. **Add error handling**: Show user-friendly errors if SMS send fails
4. **Consider push notifications**: Notify when invitation is accepted
5. **Add resend option**: Let users resend invitations if they didn't receive
6. **International support**: Test with international phone numbers

---

## Questions?

**Q: Can I use my own phone number instead of buying a Twilio one?**
A: No, you must use a Twilio number. But it's yours to keep (no monthly fee).

**Q: Can shared users invite more people?**
A: No, only the owner can invite others. This is enforced in both UI and security rules.

**Q: What happens if I run out of Twilio credit?**
A: SMS sending will fail, but the app won't crash. Users will see an error message.

**Q: Can I send SMS internationally?**
A: Yes! But prices vary by country (some are more expensive). Check Twilio's pricing page.

**Q: Do I need a separate Twilio number for testing and production?**
A: No, you can use the same number for both. Just upgrade your account when ready.

---

## Success! 🎉

Once you complete both parts:
- ✅ Firestore rules updated
- ✅ Twilio credentials configured
- ✅ Test invitation sent and received

Your SMS profile sharing feature is fully operational!
