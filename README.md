# 📞 RingCentral & CRM Auto-Dialer Automation

An open-source, lightweight automation toolkit for **RingCentral / Ascenturi Softphone** and **CRM portals (Planet ALTIG)** using **AutoHotkey v2** and **JavaScript**.

> ⚖️ **License:** MIT License (Open Source) — No sensitive user data, PII, credentials, or proprietary API keys are included.

---

## 📑 Table of Contents
- [Section 1: Standalone RingCentral Auto-Dialer](#section-1-standalone-ringcentral-auto-dialer)
- [Section 2: CRM-Synced Auto-Dialer & Screen-Pop Suite](#section-2-crm-synced-auto-dialer--screen-pop-suite)
- [Hotkey Controls](#-hotkey-controls)
- [License](#-license)

---

## Section 1: Standalone RingCentral Auto-Dialer

A standalone AutoHotkey v2 script designed to rapidly dial through a list of phone numbers on RingCentral / Ascenturi softphone without requiring CRM synchronization.

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
