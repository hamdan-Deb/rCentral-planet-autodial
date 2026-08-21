# RingCentral and CRM Auto-Dialer Automation Suite

An open-source, lightweight automation toolkit for RingCentral Softphone and web-based CRM portals (such as Planet) using AutoHotkey v2 and JavaScript.

> **Open Source Disclosure:** Licensed under the MIT License. No sensitive user data, PII, credentials, or API keys are included in this project.

---

## Project Structure

```text
ringcentral-crm-autodialer/
├── Section-1-Standalone-Dialer/
│   └── standalone_autodialer.ahk
├── Section-2-CRM-Synced-Suite/
│   ├── browser_scraper.js
│   └── crm_synced_autodialer.ahk
├── .gitignore
├── LICENSE
└── README.md
```

---

## Section 1: Standalone RingCentral Auto-Dialer

A standalone AutoHotkey v2 script designed to rapidly dial through a list of phone numbers on RingCentral Softphone without requiring CRM synchronization.

### Key Features

* **Alternating and Shuffled Dialing:** Prevents repetitive patterns by shuffling number order on each cycle.
* **Dynamic Call Durations:** Randomly rings between 10 to 30 seconds per call before hanging up.
* **No-Hold Protection:** Avoids keypresses that accidentally toggle active calls on Hold.
* **On-Screen Countdown Tooltip:** Provides a live visual display showing the current dialing status and cancellation countdown.

### Usage Instructions

1. Install **AutoHotkey v2** on your Windows machine.
2. Place `standalone_autodialer.ahk` and your `numbers.txt` file (one 10-digit number per line) in the same folder.
3. Double-click `standalone_autodialer.ahk` to launch the script.
4. Focus your RingCentral application and press **F8** to begin dialing.

---

## Section 2: CRM-Synced Auto-Dialer and Screen-Pop Suite

A complete two-part pipeline that extracts lead details from a browser CRM, maps phone numbers to unique customer `LeadId` profile URLs, and automatically opens the exact customer profile in Chrome when RingCentral begins dialing.

### Architecture Overview

```text
[Planet Web CRM]
        |
        v
(Browser Console Scraper)
Extracts LeadId URLs and Phone Numbers
        |
        +-----------------------+
        v                       v
  numbers.txt            lead_map.json
(Phone List)            (Phone -> LeadId URL)
        |                       |
        +-----------+-----------+
                    v
          [AutoHotkey v2 Script]
                    |
        +-----------+-----------+
        v                       v
[RingCentral Dials]   [Chrome Auto-Pops]
   (Outbound Call)    (Exact Customer Profile)
```

### Component Details

1. **`browser_scraper.js`**
   Executes in the browser Developer Console (`F12`). It scans lead list DOM elements, fetches lead detail pages in controlled batches to prevent `504 Gateway Timeout` errors, and exports `numbers.txt` and `lead_map.json` in top-to-bottom order.

2. **`crm_synced_autodialer.ahk`**
   Reads `numbers.txt` and `lead_map.json`. When **F8** is pressed, it activates RingCentral to place the call and simultaneously launches the matching customer profile URL in Chrome.

### Setup Procedure

1. Open the **Lead Inbox** page in your browser CRM.
2. Open Developer Tools (`F12`), navigate to the **Console** tab, paste `browser_scraper.js`, and press **Enter**.
3. Move the generated `numbers.txt` and `lead_map.json` files into the `Section-2-CRM-Synced-Suite` folder alongside `crm_synced_autodialer.ahk`.
4. Double-click `crm_synced_autodialer.ahk` to launch the script.
5. Focus RingCentral and press **F8** to initiate the automated dialing and screen-pop sequence.

---

## Hotkey Controls Reference

| Hotkey  | Action            | Function                                         |
| ------- | ----------------- | ------------------------------------------------ |
| **F8**  | Start Auto-Dialer | Begins auto-dialing and screen-pop execution.    |
| **F9**  | Pause / Resume    | Pauses script execution when a customer answers. |
| **ESC** | Emergency Stop    | Immediately terminates script execution.         |

---

## License

This project is licensed under the **MIT License**. See the [`LICENSE`](LICENSE) file for details.
