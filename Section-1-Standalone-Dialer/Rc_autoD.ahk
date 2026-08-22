#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode("Mouse", "Window")
global IsRunning := false

; ----------------------------------------------------
; Press F8 to START Auto-Dialer
; ----------------------------------------------------
F8::
{
    global IsRunning
    IsRunning := true
    
    ; Built-in list of all 15 numbers
    PhoneNumbers := [
        "5042182934", "8018200774", "5805176632", "9312574089",
        "4058157187", "4053236683", "2147141817", "2103095957",
        "5042773882", "5042922446", "5048770800", "5049050927",
        "5043288946", "8562067364", "5048863679", "2142508835",
	"4053862508", "8164130021", "3078779403", "8014510710",
	"4063436000", "6105340516", "6109670327", "4848625703",
	"7172282197", "8043638522", "5409421629", "7653986105",
	"8124420945", "8047219531", "2153822861", "6823012386"
    ]

    ToolTip("🚀 Auto-Dialer STARTED! Starting in 2 seconds...")
    Sleep(2000)

    while (IsRunning)
    {
        for index, number in PhoneNumbers
        {
            if (!IsRunning) {
                ToolTip()
                return
            }

            ; 1. Activate RingCentral Window
            if WinExist("ahk_exe RingCentral.exe")
                WinActivate("ahk_exe RingCentral.exe")
            else if WinExist("RingCentral")
                WinActivate("RingCentral")

            Sleep(400)
            WinGetPos(&X, &Y, &W, &H, "A")

            ; Calculate Button Coordinates
            inputBoxX := Integer(W * 0.50)
            inputBoxY := Integer(H * 0.38)
            redHangupX := Integer(W * 0.60)
            redHangupY := Integer(H * 0.90)

            ; --- STEP 1: FORCE HANGUP ANY PREVIOUS CALL FIRST ---
            Click(redHangupX, redHangupY) ; Click Red Circle
            Sleep(200)
            Send("^+h") ; Hangup shortcut
            Sleep(200)
            Send("!h")
            Sleep(300)

            ; --- STEP 2: FOCUS INPUT BOX BEFORE CTRL+A ---
            Click(inputBoxX, inputBoxY) ; Click "Enter a name or number"
            Sleep(300)

            ; --- STEP 3: PASTE PHONE NUMBER ---
            A_Clipboard := number
            Sleep(100)
            Send("^a")   ; Select text in input box
            Sleep(100)
            Send("{BS}") ; Clear box
            Sleep(100)
            Send("^v")   ; Paste number
            Sleep(400)

            ; --- STEP 4: DIAL NUMBER ---
            Send("{Enter}")
            Sleep(300)
            Send("{Enter}")

            ; --- STEP 5: LIVE COUNTDOWN (10-30s) ---
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

            ; --- STEP 6: HANG UP CALL ---
            ToolTip("🛑 Hanging up call...")
            Click(redHangupX, redHangupY) ; Click Big Red Circle
            Sleep(300)
            Send("^+h") ; Shortcut Hangup
            Sleep(200)
            Send("!h")
            Sleep(1000)
            ToolTip()

            ; Pause 2 seconds before next call
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