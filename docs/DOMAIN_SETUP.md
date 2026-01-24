# Custom Domain Setup Guide

## 1. Purchase Your Domain
You need a "Domain Registrar" to buy the name `tinytastestracker.com`.

**Recommended Registrars:**
*   **Cloudflare**: Highly recommended. No markup pricing (cheapest), free SSL, enterprise-grade speed/security.
*   **Namecheap**: specific, easy to use, great support.
*   **PorkaBun**: Fun brand, often very cheap, good interface.

**Action:** Go to one of these sites, search for `tinytastestracker.com`, and buy it (~$10-15/year).

## 2. Configure DNS Records
Once purchased, you need to point the domain to GitHub authentication.

1.  Log in to your registrar (e.g., Cloudflare dashboard).
2.  Go to **DNS Settings**.
3.  Add the following **A Records** (points the "naked" domain `tinytastestracker.com`):
    *   **Type**: `A` | **Name**: `@` | **Value**: `185.199.108.153`
    *   **Type**: `A` | **Name**: `@` | **Value**: `185.199.109.153`
    *   **Type**: `A` | **Name**: `@` | **Value**: `185.199.110.153`
    *   **Type**: `A` | **Name**: `@` | **Value**: `185.199.111.153`
4.  Add a **CNAME Record** (points `www.tinytastestracker.com`):
    *   **Type**: `CNAME`
    *   **Name**: `www`
    *   **Value**: `[your-github-username].github.io` (e.g., `seanpinkerton.github.io`)
    *   *Note: Do not include the /repository-name part.*

## 3. Configure GitHub Pages
1.  Go to your GitHub Repository > **Settings**.
2.  Click **Pages** (sidebar).
3.  Scroll down to **Custom domain**.
4.  Enter: `tinytastestracker.com`
5.  Click **Save**.
6.  GitHub will check the DNS. Once green, perform step 7.
7.  Check the box **"Enforce HTTPS"** (Critical for security).

## 4. Verify
Visit `https://tinytastestracker.com`. It should load your privacy policy.

## 5. Set Up Email (Optional but Recommended)
most registrars (like Cloudflare or Namecheap) offer **Email Forwarding** for free.
1.  In your registrar settings, look for "Email Routing" or "Redirect Email".
2.  Create a custom address: `support@tinytastestracker.com`.
3.  Forward it to your personal email (e.g., `sean... @gmail.com`).
4.  Now you can legitimate use `support@tinytastestracker.com` in the App Store!
