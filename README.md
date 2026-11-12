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
2. Download the latest `AddonDetector.zip` file from the **Assets** dropdown.
3. Extract the `AddonDetector` folder into your WoW addons directory:
   ```text
   World of Warcraft\Interface\AddOns\AddonDetector
