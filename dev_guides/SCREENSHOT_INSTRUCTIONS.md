# How to Capture App Store Screenshots

This guide provides step-by-step instructions for manually capturing the 5 key screens defined in our [SCREENSHOT_PLAN.md](file:///Users/seanpinkerton/Documents/Personal/Tiny%20Tastes%20Tracker%20AI/TinyTastesTracker/dev_guides/SCREENSHOT_PLAN.md).

## Prerequisites
1.  Open your project in **Xcode**.
2.  Run the app on a **Simulator** (e.g., iPhone 15 Pro Max).
3.  Ensure you have some sample data logged (or use the "Demo Mode" in Settings if available) so the screens look populated.

---

## The 5 Screens & How to Find Them

### 1. The Dashboard (Tracking)
*   **Goal:** Show the main activity feed.
*   **Navigation:**
    1.  Tap the **"Tracking"** tab (List icon) in the bottom bar.
    2.  Ensure some logs (feeds, sleep, or diapers) are visible.
*   **Capture:** Press `Cmd + S` in the Simulator.

### 2. Food Tracking (100 Foods)
*   **Goal:** Show the "100 Foods Challenge" or food list.
*   **Navigation:**
    1.  Go to **Profile** -> **Application Mode** and select **Explorer**.
    2.  Tap the **"Foods"** tab (Fork/Knife icon).
*   **Capture:** Press `Cmd + S` in the Simulator.

### 3. Sage AI (Chat)
*   **Goal:** Show a helpful AI conversation.
*   **Navigation:**
    1.  Tap the **Sage Icon** (usually a floating leaf or in the overlay).
    2.  Type a sample question like *"Is avocado a good first food?"* to show a response.
*   **Capture:** Press `Cmd + S` in the Simulator.

### 4. Messy Face Gallery
*   **Goal:** Show the colorful photo grid.
*   **Navigation:**
    1.  Ensure you are in **Explorer** mode.
    2.  This view is often found within the **Foods** detail or a specific **Gallery** link in the Explorer tracking tab.
    3.  *Path:* **Foods Tab** -> Search for a food with a photo -> Tap it to see the gallery.
*   **Capture:** Press `Cmd + S` in the Simulator.

### 5. Pediatrician Report
*   **Goal:** Show growth charts or summary data.
*   **Navigation:**
    1.  Tap the **"Profile"** tab.
    2.  Navgiate to **"Health Summary"** or **"Pediatrician Report"**.
*   **Capture:** Press `Cmd + S` in the Simulator.

---

## Pro Tips for Better Screenshots
*   **Clean Status Bar:** In the Simulator menu, go to **Device** -> **Trigger Side Button** (or use `xcrun simctl status_bar` in terminal) to ensure the time shows 9:41 and the battery is full.
*   **Save Location:** By default, Simulator screenshots are saved to your **Desktop**.
*   **Dark Mode:** Consider taking a few in Dark Mode (`Cmd + Shift + A`) to see which looks punchier for the App Store!
