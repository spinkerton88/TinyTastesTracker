# Sage Voice Chat Bug Fixes

**Date**: 2026-01-24
**Status**: ✅ Fixed
**Build**: Successful

## Issues Fixed

### 1. EXC_BAD_ACCESS Crash in AudioPlayer ❌ → ✅

**Problem**:
- App crashed with `EXC_BAD_ACCESS (code=1, address=0x68682950c68690)` in `AudioPlayer.error()`
- Occurred when AVAudioPlayerDelegate methods were called on a deallocated object
- Crash happened in `AudioPlayer.swift:58-59` when creating a new player without cleaning up the old one

**Root Cause**:
```swift
// OLD CODE - CAUSED CRASH
audioPlayer = try AVAudioPlayer(data: audioData)  // New player created
audioPlayer?.delegate = self                      // Delegate set
// But old player still had delegate pointing to self!
```

When a new `AVAudioPlayer` was created, the old instance's delegate wasn't cleared. If the old player tried to call delegate methods (like `audioPlayerDidFinishPlaying`), it would crash.

**Fix Applied**:
```swift
// NEW CODE - PREVENTS CRASH
if let oldPlayer = audioPlayer {
    oldPlayer.delegate = nil  // ✅ Clear old delegate
    oldPlayer.stop()          // ✅ Stop old player
}

audioPlayer = try AVAudioPlayer(data: audioData)
audioPlayer?.delegate = self
```

**Files Changed**:
- `AudioPlayer.swift:58-62` - Added delegate cleanup in `processQueue()`
- `AudioPlayer.swift:82` - Added delegate cleanup in `stop()`

---

### 2. "Bad Response from Server" Error ❌ → ✅

**Problem**:
- Voice chat showed generic error: "There was a bad response from the server"
- No details about what actually went wrong
- Hard to diagnose connection issues

**Root Cause**:
- WebSocket connection errors weren't being handled with specific messages
- Error was shown as generic localized description
- Connection state errors weren't being monitored in real-time

**Fix Applied**:

**A. Better Error Messages in GeminiLiveService**:
```swift
// OLD CODE
case .failure(let error):
    connectionState = .error(error.localizedDescription)

// NEW CODE - SPECIFIC ERROR MESSAGES
case .failure(let error):
    let errorMsg: String
    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet:
            errorMsg = "No internet connection"
        case .timedOut:
            errorMsg = "Connection timed out"
        case .cannotConnectToHost:
            errorMsg = "Cannot connect to server"
        case .networkConnectionLost:
            errorMsg = "Network connection lost"
        default:
            errorMsg = "Network error: \(urlError.localizedDescription)"
        }
    } else {
        errorMsg = "WebSocket error: \(error.localizedDescription)"
    }
    connectionState = .error(errorMsg)
```

**B. Real-time Error Monitoring in VoiceChatView**:
```swift
.onChange(of: geminiLive.connectionState) { _, newState in
    if case .error(let message) = newState {
        errorMessage = message
        showError = true
    }
}
```

**C. Debug Logging**:
- Added `print()` statements for connection status
- `🔌 Connecting to WebSocket: [URL]`
- `✅ Connected to Gemini Live`
- `❌ [Specific error message]`

**Files Changed**:
- `GeminiLiveService.swift:59-96` - Added error handling in `connect()`
- `GeminiLiveService.swift:164-199` - Improved error messages in `receiveMessages()`
- `VoiceChatView.swift:129-135` - Added connection state monitoring

---

## Testing Checklist

### AudioPlayer Crash Fix
- [ ] Open Sage Voice Chat
- [ ] Start speaking (tap mic)
- [ ] Speak for 5-10 seconds
- [ ] Wait for Sage to respond
- [ ] **Expected**: No crash, audio plays smoothly
- [ ] **Old behavior**: App crashed with EXC_BAD_ACCESS

### Error Message Improvements
- [ ] Turn off WiFi/Cellular
- [ ] Open Sage Voice Chat
- [ ] **Expected**: Shows "No internet connection"
- [ ] **Old behavior**: "There was a bad response from the server"

- [ ] Turn on WiFi/Cellular
- [ ] If backend is down, **Expected**: "Cannot connect to server"
- [ ] **Old behavior**: Generic error

### Connection Stability
- [ ] Open Sage Voice Chat
- [ ] Verify status shows "Connecting..." then "Tap mic to talk"
- [ ] Check Xcode console for:
  ```
  🔌 Connecting to WebSocket: wss://...
  ✅ Connected to Gemini Live
  ```

---

## Common Errors & Solutions

### "No internet connection"
**Cause**: Device is offline
**Solution**: Enable WiFi or Cellular data

### "Connection timed out"
**Cause**: Network is slow or unstable
**Solution**: Check network speed, try again in better location

### "Cannot connect to server"
**Cause**: Backend proxy is down or unreachable
**Solution**:
1. Check backend URL in `GenerativeAI-Info.plist`
2. Verify Cloudflare Worker is running
3. Test backend endpoint: `https://tiny-tastes-gemini-proxy.tiny-tastes-gemini-proxy.workers.dev`

### "WebSocket error: [message]"
**Cause**: WebSocket protocol error
**Solution**:
1. Check backend supports WebSocket connections
2. Verify `/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent` endpoint
3. Check if backend requires authentication

---

## Backend Configuration

**Current Backend URL**:
```
https://tiny-tastes-gemini-proxy.tiny-tastes-gemini-proxy.workers.dev
```

**Converted to WebSocket**:
```
wss://tiny-tastes-gemini-proxy.tiny-tastes-gemini-proxy.workers.dev/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent
```

**Configuration File**: `GenerativeAI-Info.plist`
```xml
<key>BACKEND_URL</key>
<string>https://tiny-tastes-gemini-proxy.tiny-tastes-gemini-proxy.workers.dev</string>
```

---

## Debugging Guide

### Enable Detailed Logging

**1. Console Logs**:
```bash
# In Xcode, filter console by:
"🔌"  # Connection attempts
"✅"  # Success messages
"❌"  # Error messages
```

**2. Network Debugging**:
- Enable Network Link Conditioner in Settings
- Test with "100% Loss" (no internet)
- Test with "Very Bad Network" (slow connection)

**3. WebSocket Inspector**:
- Use Charles Proxy or Proxyman to inspect WebSocket traffic
- Verify setup message is sent correctly
- Check for server responses

### Common Issues

**Issue**: App still shows generic error
**Fix**: Make sure you're running the latest build (clean + rebuild)

**Issue**: Audio still crashes
**Fix**:
1. Check you're on the latest build
2. Clean derived data: `Cmd + Shift + K`
3. Clean build folder: `Cmd + Option + Shift + K`
4. Rebuild project

**Issue**: Connection never completes
**Fix**:
1. Check Xcode console for error messages
2. Verify backend URL is accessible via browser
3. Check if Cloudflare Worker is active
4. Ensure WebSocket endpoint exists

---

## Future Improvements

### Suggested Enhancements:
1. **Retry Logic**: Auto-retry connection on failure
2. **Connection Quality Indicator**: Show signal strength
3. **Offline Mode**: Queue messages for later
4. **Better UX**: Show specific error actions (e.g., "Open Settings" for internet)
5. **Health Check**: Ping backend before connecting

### Known Limitations:
- WebSocket requires persistent internet connection
- No automatic reconnection on network change
- Audio queue may have slight delays on slow networks

---

## Technical Details

### AudioPlayer Thread Safety
- All `@Published` properties updated on main thread
- AVAudioPlayerDelegate callbacks can come from any thread
- Fixed race condition with proper delegate cleanup

### WebSocket Lifecycle
1. Convert HTTPS → WSS
2. Create URLSessionWebSocketTask
3. Send setup message with system instruction
4. Start receiving messages loop
5. Handle errors with specific messages

### Error State Flow
```
GeminiLiveService.connectionState (.error)
    ↓
VoiceChatView.onChange observer
    ↓
Set errorMessage + showError = true
    ↓
Alert displayed to user
```

---

## Build Info

**Build Date**: 2026-01-24
**Xcode Version**: Latest
**iOS Target**: iOS 17.0+
**Status**: ✅ BUILD SUCCEEDED

---

**Ready for Testing** 🚀
