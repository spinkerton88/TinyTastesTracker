# App Store Screenshot Plan

## Required Device Sizes
To cover all App Store requirements, we need screenshots for:
1.  **iPhone 6.7" Display** (iPhone 15 Pro Max, 14 Pro Max)
    *   *Also used for 6.5" in most cases, but technically distinct.*
2.  **iPhone 5.5" Display** (iPhone 8 Plus)
    *   *Required for older device support.*
3.  **iPad Pro (12.9" Display)** (6th Gen & 2nd Gen)
    *   *Required if iPad app is enabled.*

## Shot List & Marketing Copy

We will capture 5 key screens. For each, we'll strip the device status bar (clean look) and add marketing text above/below the phone.

### 1. The Dashboard
*   **Screen:** Home/Dashboard View (Newborn or Explorer mode)
*   **Caption:** "Track Every Moment"
*   **Sub-caption:** Sleep, feeds, diapers, and growth in one place.

### 2. Food Tracking
*   **Screen:** Food Search/Log View (showing "Avocado" or colorful food list)
*   **Caption:** "100+ First Foods"
*   **Sub-caption:** Log reactions, textures, and favorites instantly.

### 3. Sage AI
*   **Screen:** Sage Chat View (showing a Q&A about allergens or recipes)
*   **Caption:** "Your AI Pediatric Nutritionist"
*   **Sub-caption:** Instant answers for all your feeding questions.

### 4. Messy Face Gallery
*   **Screen:** Photo Grid or Single Photo Detail
*   **Caption:** "Capture the Messy Moments"
*   **Sub-caption:** Build a timeline of your baby's food journey.

### 5. Pediatrician Report
*   **Screen:** Summary/Report View
*   **Caption:** "Doctor-Ready Reports"
*   **Sub-caption:** Visualize growth and patterns for check-ups.

## Execution Strategy
**Option A: Automated (Recommended)**
We write a Swift UI Test that navigates to these screens and saves screenshots automatically using `fastlane snapshot`. This ensures perfect status bars (9:41 AM) and consistent data.

**Option B: Manual**
You run the Simulator for each device size, navigate to the screen, press `Cmd+S`, and we design them manually.

## Design Template (Mental Model)
[ TARGET CAPTION ]
[ SUB CAPTION ]
    _______
   |       |
   | PHONE |
   |_______|
