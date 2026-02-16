# Tiny Tastes Tracker - Profile Sharing Setup Guide

## ✅ What's Already Done

Your profile sharing feature is fully implemented with:
- Data models and managers
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

## Part 2: Email Service (15 minutes)

### Why This Matters
When you invite someone via email, they need to receive that invitation with the 6-digit code. Right now, the app just prints to console. We need a real email service.

### Option 1: Resend (Recommended - Easiest)

**Why Resend?**
- 3,000 free emails/month (plenty for your app)
- Simple API, no complex setup
- Great deliverability (emails won't go to spam)
- Modern, developer-friendly

#### Step 1: Sign Up for Resend

1. Go to: https://resend.com/
2. Click "Start Building" or "Sign Up"
3. Create account with your email
4. Verify your email address

#### Step 2: Get API Key

1. In Resend dashboard, click **"API Keys"** in sidebar
2. Click **"Create API Key"**
3. Name it: `TinyTastesTracker`
4. Permission: **"Sending access"**
5. Click **"Add"**
6. **Copy the API key** (starts with `re_...`)
   - ⚠️ Save this somewhere safe - you won't see it again!

#### Step 3: Add API Key to Your App

1. Open: `/Users/seanpinkerton/Documents/Personal/Tiny Tastes Tracker AI/TinyTastesTracker/TinyTastesTracker/Core/Services/EmailService.swift`

2. Find line 14:
   ```swift
   private let apiKey = "YOUR_RESEND_API_KEY_HERE"
   ```

3. Replace with your actual key:
   ```swift
   private let apiKey = "re_abc123xyz..." // Your actual Resend key
   ```

4. Save the file

#### Step 4: Update "From" Email (Optional for now)

The emails currently send from: `noreply@resend.dev`

This works for testing, but for production:

1. In Resend dashboard, go to **"Domains"**
2. Click **"Add Domain"**
3. Enter your domain (e.g., `tinytastestracker.com`)
4. Add the DNS records Resend provides to your domain registrar
5. After verification, update line 59 in EmailService.swift:
   ```swift
   "from": "Tiny Tastes Tracker <noreply@yourdomain.com>"
   ```

For now, keep `noreply@resend.dev` - it works fine for development and testing!

#### Step 5: Test It!

1. Build and run your app
2. Create a test child profile
3. Invite yourself (use a different email than your login)
4. Check your email - you should receive a beautifully formatted invitation!

---

## Testing Checklist

### Test 1: Send Invitation
- [ ] Open app, go to Settings → Manage Children
- [ ] Tap the menu (•••) on a profile → "Manage Sharing"
- [ ] Tap "Invite Someone"
- [ ] Enter an email address
- [ ] Send invitation
- [ ] **Expected**: Email arrives within 1 minute with 6-digit code

### Test 2: Accept Invitation
- [ ] On second device/account, sign in with the invited email
- [ ] Go to Settings → Family → Accept Invitation
- [ ] Enter the 6-digit code from email
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

## Alternative: Option 2 - Firebase Cloud Functions

If you prefer serverless (no API key in app):

### Pros:
- More secure (no API key in client code)
- Automatic scaling
- Can add more complex logic later

### Cons:
- More setup required
- Need to deploy functions
- Requires Firebase Blaze plan (pay-as-you-go, but has free tier)

**Let me know if you want instructions for this approach instead!**

---

## Security Notes

### API Key Security
⚠️ **Important**: The Resend API key is currently hardcoded in EmailService.swift. This is fine for:
- Development
- TestFlight beta testing
- Apps distributed to a limited audience

**For production App Store release, you should:**
1. Move the API key to a backend server
2. Have your app call your server, which then calls Resend
3. Or use Firebase Cloud Functions (Option 2 above)

### Why This Matters:
Someone could extract the API key from your app binary and use it to send emails from your account.

**Quick fix for now**: Set rate limits in Resend dashboard to prevent abuse.

---

## Troubleshooting

### Email Not Sending?

**Check 1**: API Key
```swift
// In EmailService.swift, line 14
// Make sure it's your actual key, not the placeholder
private let apiKey = "re_abc123xyz..." // ✅ Good
private let apiKey = "YOUR_RESEND_API_KEY_HERE" // ❌ Bad
```

**Check 2**: Console Logs
- When you send an invitation, check Xcode console
- Should see: `✅ Email sent successfully to email@example.com`
- If error, it will show the status code and message

**Check 3**: Resend Dashboard
- Go to Resend dashboard → Logs
- You should see the email send attempt and status

**Check 4**: Spam Folder
- Check recipient's spam folder
- Emails from `resend.dev` domain might be flagged

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

### Build Errors?

If you get build errors after adding EmailService.swift:

1. Clean build folder: Cmd+Shift+K in Xcode
2. Rebuild: Cmd+B
3. If still failing, close Xcode and delete:
   - `/Users/seanpinkerton/Library/Developer/Xcode/DerivedData/TinyTastesTracker-*`
4. Reopen project and build

---

## Next Steps After Setup

Once emails are working:

1. **Test with real users**: Have a friend/partner test the full flow
2. **Monitor usage**: Check Resend dashboard for email send stats
3. **Add error handling**: Show user-friendly errors if email send fails
4. **Consider push notifications**: Notify when invitation is accepted
5. **Add email templates**: Create templates for other scenarios (invitation accepted, access revoked, etc.)

---

## Questions?

Common scenarios:

**Q: Can I change the email design?**
A: Yes! Edit the `EmailTemplates.invitationEmail()` function in EmailService.swift. It's just HTML/CSS.

**Q: What if I want to send from my own domain?**
A: Verify your domain in Resend, then update line 59 in EmailService.swift with your domain.

**Q: Can shared users invite more people?**
A: No, only the owner can invite others. This is enforced in both UI and security rules.

**Q: How do I revoke someone's access?**
A: Owner goes to Manage Sharing → tap Remove next to the user's name.

**Q: What happens to data if I revoke access?**
A: The shared user loses access immediately. The data stays intact and belongs to the owner.

---

## Success! 🎉

Once you complete both parts:
- ✅ Firestore rules updated
- ✅ Resend API key configured
- ✅ Test invitation sent and received

Your profile sharing feature is fully operational!
