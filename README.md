# AddonDetector

**Author:** Copper  
**Client Version:** World of Warcraft 3.3.5a (`Interface: 30300`)

**AddonDetector** is a lightweight, strictly read-only diagnostic utility for World of Warcraft 3.3.5a. When mystery bars, stray icons, or overlapping frames clutter your screen, AddonDetector tells you exactly which addon owns the UI element under your mouse cursor—including specific **WeakAuras** aura names.

---

## Features

* **Live Cursor Detection:** Identifies any addon frame, panel, or click-through HUD element directly beneath your cursor.
* **Overlapping Frame Support:** If multiple addons are stacked in the same spot, all of their names are listed alphabetically in the detector window.
* **WeakAuras Aura Identification:** When hovering over a WeakAura, AddonDetector inspects the region hierarchy to display the exact aura name (`WeakAuras: <Aura Name>`) while ignoring invisible group bounding boxes.
* **Strictly Non-Intrusive:** Operates in 100% read-only mode. It never hooks, alters, or interacts with other addons.
* **Zero Background Overhead:** Scanning only runs while the window is open and **Check** is active. Clicking **Stop** or closing the window completely unhooks the scanner.
* **Draggable Minimap Button:** Includes a spyglass minimap button that remembers its position across sessions.

---

## Installation

### Method 1: Download from Releases (Recommended)
1. Look at the right-hand sidebar of this GitHub page and click on **Releases**.
2. Download the latest `AddonDetector.zip` file from the **Assets** section.
3. Extract the `AddonDetector` folder into your WoW addons directory:
   `World of Warcraft\Interface\AddOns\AddonDetector`
4. Restart World of Warcraft or type `/reload` in-game.

### Method 2: Download via the Green "Code" Button
1. At the top right of this repository page, click the green **`<> Code`** button.
2. Click **Download ZIP** at the bottom of the dropdown menu.
3. Open the downloaded `.zip` file and extract the folder into your `World of Warcraft\Interface\AddOns\` directory.
4. **Important:** Rename the extracted folder from `AddonDetector-main` (or `AddonDetector-master`) to **`AddonDetector`** so the game client can load it properly:
   `World of Warcraft\Interface\AddOns\AddonDetector`
5. Restart World of Warcraft or type `/reload` in-game.

---

## How to Use

1. **Open the Detector Window:**
   * **Left-Click** the spyglass button on your minimap (**Left-Drag** to move it around the minimap ring), **OR**
   * Type `/ad` or `/addondetector` in chat.
2. **Start Scanning:**
   * Click the **Check** button inside the AddonDetector window.
   * Move your mouse cursor over any UI panel, bar, icon, or WeakAura on your screen. The window will dynamically list every addon detected under your cursor.
3. **Stop Scanning:**
   * Click the **Stop** button to pause detection while keeping the window open, or click the **`X`** button in the top-right corner to close the window and automatically stop scanning.

---

## Slash Commands

* `/ad` — Toggle the AddonDetector window open or closed.
* `/addondetector` — Toggle the AddonDetector window open or closed.
