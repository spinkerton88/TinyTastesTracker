# Voice Chat WebSocket Implementation Guide

**Status**: Voice Chat Temporarily Disabled
**Reason**: Cloudflare Worker doesn't support WebSocket connections
**Date**: 2026-01-24

---

## Current Status

✅ **Working Features**:
- Text-based Sage AI Chat (HTTP POST)
- Recipe Generation (HTTP POST)
- Flavor Pairings (HTTP POST)
- Sleep Predictions (HTTP POST)
- All other AI features (HTTP POST)

❌ **Not Working**:
- Voice Chat (requires WebSocket)

## Why Voice Chat Doesn't Work

Your Cloudflare Worker backend successfully handles HTTP requests but cannot handle WebSocket connections. Gemini Live API requires bidirectional WebSocket streaming for real-time voice chat.

### Cloudflare Worker Limitations

```javascript
// Your current worker handles HTTP:
export default {
  async fetch(request) {
    // ✅ Works for regular API calls
    const response = await fetch(GEMINI_API, {
      method: 'POST',
      body: request.body
    })
    return response
  }
}

// But WebSocket requires:
// ❌ Upgrade: websocket header
// ❌ Bidirectional streaming
// ❌ Persistent connection
```

**Cloudflare Worker Free Tier**: No WebSocket support
**Cloudflare Worker Paid Plan**: Requires Durable Objects ($5/month minimum)

---

## Solutions for Production

### Option 1: Enable Cloudflare Durable Objects (Recommended)

**Cost**: $5/month minimum
**Complexity**: Medium
**Best For**: Production deployment

#### Step 1: Upgrade Cloudflare Plan

1. Go to Cloudflare Dashboard
2. Navigate to Workers & Pages
3. Upgrade to **Workers Paid** plan ($5/month)

#### Step 2: Create Durable Object for WebSocket

```javascript
// worker.js
export class WebSocketHandler {
  constructor(state, env) {
    this.state = state
    this.env = env
  }

  async fetch(request) {
    const upgradeHeader = request.headers.get('Upgrade')

    if (!upgradeHeader || upgradeHeader !== 'websocket') {
      return new Response('Expected WebSocket', { status: 426 })
    }

    // Accept WebSocket connection
    const pair = new WebSocketPair()
    const [client, server] = Object.values(pair)

    // Handle WebSocket connection
    this.handleSession(server, request)

    return new Response(null, {
      status: 101,
      webSocket: client,
    })
  }

  async handleSession(websocket, request) {
    websocket.accept()

    // Connect to Gemini Live API
    const geminiWs = new WebSocket(
      'wss://generativelanguage.googleapis.com/ws/v1beta/models/gemini-2.0-flash-exp:generateContent',
      {
        headers: {
          'Authorization': `Bearer ${this.env.GEMINI_API_KEY}`
        }
      }
    )

    // Forward messages: Client <-> Gemini
    websocket.addEventListener('message', (event) => {
      geminiWs.send(event.data)
    })

    geminiWs.addEventListener('message', (event) => {
      websocket.send(event.data)
    })

    websocket.addEventListener('close', () => {
      geminiWs.close()
    })
  }
}

// Main worker
export default {
  async fetch(request, env) {
    const url = new URL(request.url)

    // WebSocket endpoint
    if (url.pathname.startsWith('/ws/')) {
      const id = env.WEBSOCKET_HANDLER.idFromName('global')
      const obj = env.WEBSOCKET_HANDLER.get(id)
      return obj.fetch(request)
    }

    // Regular HTTP endpoints
    return handleHTTPRequest(request, env)
  }
}
```

#### Step 3: Configure wrangler.toml

```toml
name = "tiny-tastes-gemini-proxy"
main = "src/worker.js"
compatibility_date = "2024-01-01"

[durable_objects]
bindings = [
  { name = "WEBSOCKET_HANDLER", class_name = "WebSocketHandler" }
]

[[migrations]]
tag = "v1"
new_classes = ["WebSocketHandler"]

[vars]
# Environment variables (set via `wrangler secret put`)
```

#### Step 4: Deploy

```bash
# Set API key
wrangler secret put GEMINI_API_KEY

# Deploy
wrangler deploy
```

---

### Option 2: Use Different Backend (Alternative)

If you don't want to pay for Cloudflare, use a different WebSocket-capable backend:

#### A. Railway.app (Free Tier)

**Cost**: Free (with $5/month credit)
**Setup**: Deploy Node.js WebSocket server

```javascript
// server.js
const express = require('express')
const WebSocket = require('ws')

const app = express()
const server = app.listen(process.env.PORT || 3000)

const wss = new WebSocket.Server({ server, path: '/ws/gemini' })

wss.on('connection', (ws) => {
  // Connect to Gemini Live API
  const geminiWs = new WebSocket(
    'wss://generativelanguage.googleapis.com/...',
    {
      headers: { 'Authorization': `Bearer ${process.env.GEMINI_API_KEY}` }
    }
  )

  // Proxy messages
  ws.on('message', (data) => geminiWs.send(data))
  geminiWs.on('message', (data) => ws.send(data))
})
```

Deploy to Railway: `railway up`

#### B. Render.com (Free Tier)

Similar to Railway, deploy a WebSocket server for free.

#### C. Fly.io (Free Tier)

Supports WebSocket natively, good for hobby projects.

---

### Option 3: Direct Gemini API (Not Recommended)

**Security Risk**: API key exposed in client app

```swift
// ⚠️ NOT RECOMMENDED FOR PRODUCTION
let apiKey = "YOUR_GEMINI_API_KEY_EXPOSED_TO_USERS"
```

**Why this is bad**:
- Anyone can decompile your app and steal the API key
- No rate limiting or cost control
- Violates API key security best practices

Only use this for development/testing, never in production.

---

## Current Workaround (Temporary)

Voice chat button is **disabled** in `SageView.swift` (lines 186-199):

```swift
// TEMPORARILY DISABLED: Voice chat requires WebSocket support
// TODO: Re-enable after adding Cloudflare Durable Objects
/*
SageOptionButton(
    title: "Voice Chat",
    subtitle: "Talk to Sage hands-free",
    icon: "mic.fill",
    color: .green
) {
    showingVoiceChat = true
}
*/
```

**To re-enable**: Uncomment lines 188-199 after WebSocket backend is ready.

---

## Testing WebSocket Backend

Once you've set up WebSocket support, test it:

### 1. Test with `wscat` (CLI tool)

```bash
npm install -g wscat

# Test connection
wscat -c "wss://your-worker.workers.dev/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent"

# Should see: Connected
# Send test message:
> {"setup": {"model": "models/gemini-2.0-flash-exp"}}
```

### 2. Test in Xcode Console

After deploying:
1. Uncomment voice chat button in SageView.swift
2. Rebuild app
3. Open voice chat
4. Check Xcode console for:
   ```
   🔌 Connecting to WebSocket: wss://...
   ✅ Connected to Gemini Live
   ```

### 3. Monitor Cloudflare Logs

```bash
wrangler tail
```

Watch for WebSocket upgrade requests and connections.

---

## Cost Comparison

| Solution | Monthly Cost | Setup Time | Reliability |
|----------|-------------|------------|-------------|
| Cloudflare Durable Objects | $5 minimum | 2-3 hours | ⭐⭐⭐⭐⭐ |
| Railway.app | Free ($5 credit) | 1-2 hours | ⭐⭐⭐⭐ |
| Render.com | Free | 1-2 hours | ⭐⭐⭐⭐ |
| Fly.io | Free (hobby tier) | 1-2 hours | ⭐⭐⭐⭐ |
| Direct API (insecure) | $0 | 5 minutes | ❌ Not recommended |

---

## Recommended Next Steps

### For Development (Now)
✅ **Voice chat is disabled** - app works perfectly with text-based Sage

### For Production (Before Launch)

Choose one:

1. **Best Option**: Upgrade to Cloudflare Workers Paid + Durable Objects
   - Same infrastructure as existing HTTP endpoints
   - Minimal code changes
   - Professional solution

2. **Free Alternative**: Deploy WebSocket server to Railway/Render
   - Separate backend for WebSocket only
   - Keep Cloudflare Worker for HTTP endpoints
   - Free tier suitable for testing

3. **Quick Test**: Use direct Gemini API temporarily
   - Add API key to app (for testing ONLY)
   - Test voice chat functionality
   - Replace with proper backend before launch

---

## Re-enabling Voice Chat

Once WebSocket backend is ready:

### 1. Uncomment Voice Chat Button

In `SageView.swift` lines 186-199:

```swift
// Remove /* and */ comments
SageOptionButton(
    title: "Voice Chat",
    subtitle: "Talk to Sage hands-free",
    icon: "mic.fill",
    color: .green
) {
    showingVoiceChat = true
}
.accessibilityLabel(AccessibilityIdentifiers.Sage.voiceChatButton)
.accessibilityHint("Opens voice chat with Sage")
```

### 2. Update Backend URL (if changed)

In `GenerativeAI-Info.plist`:
```xml
<key>BACKEND_URL</key>
<string>https://your-new-websocket-backend.com</string>
```

### 3. Test Thoroughly

- Test on multiple devices
- Test network failures
- Test long conversations
- Monitor crash reports

---

## Support

**Questions?** Check:
- [Cloudflare Durable Objects Docs](https://developers.cloudflare.com/durable-objects/)
- [Gemini Live API Docs](https://ai.google.dev/gemini-api/docs/live)
- `SAGE_VOICE_CHAT_FIXES.md` for crash fixes

**Current Status**: Voice chat disabled, all other features working perfectly ✅
