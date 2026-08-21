#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode("Mouse", "Window")
global IsRunning := false

; Hotkey F8: Start Auto-Dialing
F8::
{
    global IsRunning
    IsRunning := true
    
    ; Default fallback list of phone numbers
    PhoneNumbers := ["5042182934", "8018200774", "5805176632"]
    
    ; Load from numbers.txt if present in the same folder
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

    ToolTip("Auto-Dialer Started. Press F9 to Pause, ESC to Stop.")
    Sleep(2000)
    ToolTip()

    while (IsRunning)
    {
        ; Create a shuffled copy of numbers for alternating order
        ShuffledNumbers := []
        for num in PhoneNumbers
            ShuffledNumbers.Push(num)
        
        Loop ShuffledNumbers.Length {
            i := Random(1, ShuffledNumbers.Length)
            j := Random(1, ShuffledNumbers.Length)
            temp := ShuffledNumbers[i]
            ShuffledNumbers[i] := ShuffledNumbers[j]
            ShuffledNumbers[j] := temp
        }

        for index, number in ShuffledNumbers
        {
            if (!IsRunning) {
                ToolTip()
                return
            }

            ; Ensure RingCentral or Acenturi is active
            if WinExist("Acenturi")
                WinActivate("Acenturi")
            else if WinExist("RingCentral")
                WinActivate("RingCentral")
            else if WinExist("ahk_exe RingCentral.exe")
                WinActivate("ahk_exe RingCentral.exe")

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

            ; Focus Input Box and Paste Phone Number
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

            ; Ring Countdown (Random 10 to 30 seconds)
            RingTimeSeconds := Random(10, 30)
            Loop RingTimeSeconds
            {
                if (!IsRunning) {
                    ToolTip()
                    return
                }
                remaining := RingTimeSeconds - A_Index + 1
                ToolTip("Calling (" . index . "/" . ShuffledNumbers.Length . "): " . number . "`nRinging: " . RingTimeSeconds . "s (Cancel in " . remaining . "s)")
                Sleep(1000)
            }

            ; Hang Up Call
            ToolTip("Hanging up...")
            if WinExist("Acenturi")
                WinActivate("Acenturi")
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

; Hotkey F9: Pause or Resume
F9::
{
    global IsRunning
    IsRunning := !IsRunning
    if (IsRunning)
        ToolTip("Auto-Dialer RESUMED")
    else
        ToolTip("Auto-Dialer PAUSED")
    SetTimer(() => ToolTip(), -2000)
}

; Hotkey ESC: Emergency Stop
Esc::
{
    global IsRunning
    IsRunning := false
    ToolTip("Auto-Dialer STOPPED")
    SetTimer(() => ToolTip(), -2000)
    ExitApp()
}
