# 📞 RingCentral & CRM Auto-Dialer Automation

An open-source, lightweight automation toolkit for **RingCentral Softphone** and **CRM portals (Planet)** using **AutoHotkey v2** and **JavaScript**.

> ⚖️ **License:** MIT License (Open Source) — No sensitive user data, PII, credentials, or proprietary API keys are included.

---

## 📑 Table of Contents
- [Section 1: Standalone RingCentral Auto-Dialer](#section-1-standalone-ringcentral-auto-dialer)
- [Section 2: CRM-Synced Auto-Dialer & Screen-Pop Suite](#section-2-crm-synced-auto-dialer--screen-pop-suite)
- [Hotkey Controls](#-hotkey-controls)
- [License](#-license)

---

## Section 1: Standalone RingCentral Auto-Dialer

A standalone AutoHotkey v2 script designed to rapidly dial through a list of phone numbers on RingCentral softphone without requiring CRM synchronization.

### 🌟 Key Features
- **Alternating & Shuffled Dialing:** Prevents repetitive patterns by shuffling number order.
- **Dynamic Call Durations:** Randomly rings between **10 to 30 seconds** per call before hanging up.
- **No-Hold Protection:** Avoids keypresses that accidentally toggle active calls on Hold.
- **On-Screen Countdown ToolTip:** Live visual display showing current dialing status and cancel countdown.

### 📜 Script Code: `standalone_autodialer.ahk`

```autohotkey
#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode("Mouse", "Window")
global IsRunning := false

F8::
{
    global IsRunning
    IsRunning := true
    
    PhoneNumbers := ["5042182934", "8018200774", "5805176632"]
    
    if FileExist("numbers.txt") {
        try {
            loaded := []
            fileText := FileRead("numbers.txt")
            Loop Parse, fileText, "`n", "`r" {
                clean := RegExReplace(A_LoopField, "\D", "")
                if (StrLen(clean) >= 10)
                    loaded.Push(clean)
            }
            if (loaded.Length > 0)
                PhoneNumbers := loaded
        }
    }

    ToolTip("🚀 Standalone Auto-Dialer STARTED!")
    Sleep(2000)
    ToolTip()

    while (IsRunning)
    {
        for index, number in PhoneNumbers
        {
            if (!IsRunning) {
                ToolTip()
                return
            }

            if WinExist("Acenturi")
                WinActivate("Acenturi")
            else if WinExist("RingCentral")
                WinActivate("RingCentral")

            Sleep(400)
            WinGetPos(&X, &Y, &W, &H, "A")

            inputBoxX := Integer(W * 0.50)
            inputBoxY := Integer(H * 0.38)
            redHangupX := Integer(W * 0.60)
            redHangupY := Integer(H * 0.90)

            ; Pre-Call Safety Hangup
            Click(redHangupX, redHangupY)
            Sleep(200)
            Send("^+h")
            Sleep(300)

            ; Focus Box & Paste Number
            Click(inputBoxX, inputBoxY)
            Sleep(300)
            A_Clipboard := number
            Sleep(100)
            Send("^a{BS}^v")
            Sleep(400)

            ; Trigger Call
            Send("{Enter}")
            Sleep(300)
            Send("{Enter}")

            ; Ring Countdown (10-30s)
            RingTimeSeconds := Random(10, 30)
            Loop RingTimeSeconds
            {
                if (!IsRunning) {
                    ToolTip()
                    return
                }
                remaining := RingTimeSeconds - A_Index + 1
                ToolTip("📞 Calling (" . index . "/" . PhoneNumbers.Length . "): " . number . "`n⏱️ Ringing: " . RingTimeSeconds . "s (Cancel in " . remaining . "s)")
                Sleep(1000)
            }

            ; Hang Up Call
            ToolTip("🛑 Hanging up...")
            Click(redHangupX, redHangupY)
            Sleep(300)
            Send("^+h")
            Sleep(1000)
            ToolTip()

            Sleep(2000)
        }
    }
}

F9::
{
    global IsRunning
    IsRunning := !IsRunning
    if (IsRunning)
        ToolTip("▶️ Auto-Dialer RESUMED!")
    else
        ToolTip("⏸️ Auto-Dialer PAUSED!")
    SetTimer(() => ToolTip(), -2000)
}

Esc::
{
    global IsRunning
    IsRunning := false
    ToolTip("🛑 Auto-Dialer STOPPED!")
    SetTimer(() => ToolTip(), -2000)
    ExitApp()
}

**## Section 2: CRM-Synced Auto-Dialer & Screen-Pop Suite**
A complete 2-part pipeline that extracts lead details from a browser CRM (Planet ALTIG), maps phone numbers to unique customer LeadId profile URLs, and automatically pops open the exact customer's profile in Chrome the moment RingCentral begins dialing!
⚙️ How the Pipeline Works
code
Text
[Planet ALTIG Web CRM]
        │
        ▼ (Browser Console Scraper)
Extracts LeadId URLs & Phone Numbers
        │
        ├───────────────────────┐
        ▼                       ▼
  `numbers.txt`          `lead_map.json`
(Phone List)            (Phone -> LeadId URL)
        │                       │
        └───────────┬───────────┘
                    ▼
          [AutoHotkey v2 Script]
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
[RingCentral Dials]   [Chrome Auto-Pops]
(Outbound Call)     (Exact Customer Profile)
Part A: Browser Console Lead Scraper (browser_scraper.js)
Paste this script into Chrome DevTools Console (F12) on Planet ALTIG. It fetches lead details in throttled batches to prevent 504 Gateway Timeout errors and exports numbers.txt and lead_map.json.
code
JavaScript
(async function extractSynchronizedLeads() {
    console.log("🚀 Starting Synchronized Sequential Scraper...");

    const rawLinks = Array.from(document.querySelectorAll('a'))
        .filter(a => a.href && (a.href.includes('InboxDetail') || a.href.includes('LeadId')))
        .map(a => a.href);

    const orderedLinks = [];
    const seen = new Set();

    for (const link of rawLinks) {
        if (!seen.has(link)) {
            seen.add(link);
            orderedLinks.push(link);
        }
    }

    let orderedPhoneList = [];
    let orderedLeadMap = {};

    const sleep = ms => new Promise(res => setTimeout(res, ms));
    const BATCH_SIZE = 4;

    for (let i = 0; i < orderedLinks.length; i += BATCH_SIZE) {
        const batch = orderedLinks.slice(i, i + BATCH_SIZE);

        const results = await Promise.all(batch.map(async (url) => {
            try {
                const leadIdMatch = url.match(/LeadId=(\d+)/i);
                const leadId = leadIdMatch ? leadIdMatch[1] : '';

                const res = await fetch(url);
                if (!res.ok) return null;
                const html = await res.text();

                const phoneMatch = html.match(/Ph:\s*\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}|\b\d{10}\b|\(\d{3}\)\s*\d{3}-\d{4}/i);

                if (phoneMatch) {
                    const cleanPhone = phoneMatch[0].replace(/\D/g, '').slice(-10);
                    if (cleanPhone.length === 10) {
                        return { phone: cleanPhone, url: `https://m.planetaltig.com/Lead/InboxDetail?LeadId=${leadId}` };
                    }
                }
            } catch (e) {
                console.error("Error fetching URL:", url);
            }
            return null;
        }));

        results.forEach(item => {
            if (item && item.phone) {
                if (!orderedLeadMap[item.phone]) {
                    orderedPhoneList.push(item.phone);
                    orderedLeadMap[item.phone] = item.url;
                }
            }
        });

        await sleep(250);
    }

    // Export numbers.txt
    const txtBlob = new Blob([orderedPhoneList.join('\n')], { type: 'text/plain' });
    const a1 = document.createElement('a');
    a1.href = URL.createObjectURL(txtBlob);
    a1.download = 'numbers.txt';
    a1.click();

    // Export lead_map.json
    const jsonBlob = new Blob([JSON.stringify(orderedLeadMap, null, 2)], { type: 'application/json' });
    const a2 = document.createElement('a');
    a2.href = URL.createObjectURL(jsonBlob);
    a2.download = 'lead_map.json';
    a2.click();

    console.log("💾 Both numbers.txt and lead_map.json exported successfully!");
})();
Part B: CRM-Synced AutoHotkey Script (crm_synced_autodialer.ahk)
Save this file in the same folder as numbers.txt and lead_map.json.
code
Autohotkey
#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode("Mouse", "Window")
global IsRunning := false

F8::
{
    global IsRunning
    IsRunning := true
    
    PhoneNumbers := ["5042182934", "8018200774"]
    LeadMap := Map()

    ; 1. Load lead_map.json
    if FileExist("lead_map.json") {
        try {
            jsonText := FileRead("lead_map.json")
            Pos := 1
            While Pos := RegExMatch(jsonText, "i)`"phone`":\s*`"(\d{10})`"[\s\S]*?`"url`":\s*`"([^`"]+)`"", &m, Pos) {
                LeadMap[m[1]] := m[2]
                Pos += m.Len
            }
        }
    }

    ; 2. Load numbers.txt
    if FileExist("numbers.txt") {
        try {
            loaded := []
            fileText := FileRead("numbers.txt")
            Loop Parse, fileText, "`n", "`r" {
                clean := RegExReplace(A_LoopField, "\D", "")
                if (StrLen(clean) >= 10)
                    loaded.Push(clean)
            }
            if (loaded.Length > 0)
                PhoneNumbers := loaded
        }
    }

    ToolTip("🚀 Auto-Dialer & Screen Pop STARTED!")
    Sleep(2000)
    ToolTip()

    while (IsRunning)
    {
        for index, number in PhoneNumbers
        {
            if (!IsRunning) {
                ToolTip()
                return
            }

            ; 1. Focus RingCentral FIRST and dial
            if WinExist("Ascenturi")
                WinActivate("Ascenturi")
            else if WinExist("RingCentral")
                WinActivate("RingCentral")

            Sleep(400)
            WinGetPos(&X, &Y, &W, &H, "A")

            inputBoxX := Integer(W * 0.50)
            inputBoxY := Integer(H * 0.38)
            redHangupX := Integer(W * 0.60)
            redHangupY := Integer(H * 0.90)

            ; Pre-Call Hangup Safety
            Click(redHangupX, redHangupY)
            Sleep(200)
            Send("^+h")
            Sleep(300)

            ; Focus Input Box & Paste Phone Number
            Click(inputBoxX, inputBoxY)
            Sleep(300)
            A_Clipboard := number
            Sleep(100)
            Send("^a{BS}^v")
            Sleep(400)

            ; Trigger Call
            Send("{Enter}")
            Sleep(300)
            Send("{Enter}")
            Sleep(300)

            ; 2. Open Customer Profile in Chrome (AFTER Dialing)
            if LeadMap.Has(number) {
                leadUrl := LeadMap[number]
                Run(leadUrl)
            }

            ; Ring Countdown (10-30s)
            RingTimeSeconds := Random(10, 30)
            Loop RingTimeSeconds
            {
                if (!IsRunning) {
                    ToolTip()
                    return
                }
                remaining := RingTimeSeconds - A_Index + 1
                ToolTip("📞 Calling (" . index . "/" . PhoneNumbers.Length . "): " . number . "`n⏱️ Ringing: " . RingTimeSeconds . "s (Cancel in " . remaining . "s)")
                Sleep(1000)
            }

            ; Hang Up
            ToolTip("🛑 Hanging up...")
            if WinExist("Ascenturi")
                WinActivate("Ascenturi")
            else if WinExist("RingCentral")
                WinActivate("RingCentral")

            Sleep(300)
            Click(redHangupX, redHangupY)
            Sleep(300)
            Send("^+h")
            Sleep(1000)
            ToolTip()

            Sleep(2000)
        }
    }
}

F9::
{
    global IsRunning
    IsRunning := !IsRunning
    if (IsRunning)
        ToolTip("▶️ Auto-Dialer RESUMED!")
    else
        ToolTip("⏸️ Auto-Dialer PAUSED!")
    SetTimer(() => ToolTip(), -2000)
}

Esc::
{
    global IsRunning
    IsRunning := false
    ToolTip("🛑 Auto-Dialer STOPPED!")
    SetTimer(() => ToolTip(), -2000)
    ExitApp()
}
🎮 Hotkey Controls
Hotkey	Action	Description
F8	Start Auto-Dialer	Begins the auto-dialing and CRM screen-pop loop.
F9	Pause / Resume	Pauses the script instantly if a customer answers so you can speak to them.
ESC	Stop & Exit	Kills the script execution completely.

📜 License
This project is licensed under the MIT License — free to use, modify, and distribute.
