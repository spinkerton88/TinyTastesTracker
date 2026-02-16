# CloudKit Sync Guide

🔍 **Important Understanding**

Why you don't see schema in CloudKit Dashboard:
- **SwiftData manages its own CloudKit schema internally**
- This is **NORMAL** - you won't see "UserProfile" records in the dashboard
- SwiftData syncs automatically in the background
- You cannot query SwiftData's CloudKit records directly

How CloudKit Sync Actually Works:
1. SwiftData automatically syncs when iCloud is signed in
2. Data is encrypted end-to-end
3. Syncs happen in the background automatically
4. You can monitor status via **Settings > iCloud Sync Status View**

---

📋 **Next Steps - YOU NEED TO DO THESE**

1. **Open Xcode** and go to the `TinyTastesWidget` target
2. **Signing & Capabilities** tab
3. Verify the iCloud capability now shows:
    - Services: **CloudKit** ✓
    - Containers: **iCloud.tinytastestracker** ✓
4. **Clean and Rebuild**:
    - Product > Clean Build Folder (Shift+Cmd+K)
    - Product > Build (Cmd+B)
5. **Test on Device** (NOT Simulator):
    - Make sure you're signed into iCloud in Settings
    - Launch the app
    - Go to **Settings > iCloud Sync Status**
    - Should show "CloudKit Active" when signed in
6. **Test Share Profile**:
    - Go to **Settings > Family > Share Profile**
    - Should now open iOS share sheet with JSON file
    - Can share via AirDrop, Messages, etc.

⚠️ **CloudKit Will NOT Work In Simulator**

CloudKit sync only works on real devices with iCloud accounts. Simulator testing will show "iCloud Not Signed In".
