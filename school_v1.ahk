#Requires AutoHotkey v2.0

global presets := Map()
global currentWeapon := ""
global schoolNormal := 0
global schoolCtrl := 0
global schoolProne := 0
global schoolDelay := 0
global patternStrength := 50
global scriptRunning := false
global dotVisible := false
global iniFile := A_ScriptDir "\school_presets.ini"
global dotColorChoice := "Red", dotSizeInput := "5", chkDot := 0  ; Default color and size
global boostActive := false
global originalValues := {}  ; Stores original strengths when boosted
global currentHotkey
currentHotkey := IniRead(A_ScriptDir "\school_keys.ini", "Hotkeys", "RedDotToggle", "F9")
initialHotkeyDisplay := FormatHotkeyText(currentHotkey)
global boostHotkey := IniRead(A_ScriptDir "\school_keys.ini", "Hotkeys", "BoostToggle", "F10")
Hotkey(boostHotkey, ToggleBoostKey, "On")



Hotkey(currentHotkey, ToggleRedDotKey, "On")

TraySetIcon(A_ScriptDir . "\icon.ico") ; Set the icon

LoadPresetsFromINI()
currentWeapon := GetFirstPresetName()

global myGui := Gui("+AlwaysOnTop +MinimizeBox +Caption +SysMenu", "SCHOOL Settings")
myGui.Add("Text",, "Weapon Preset:")
dropdown := myGui.Add("DropDownList", "vWeaponChoice w150")

myGui.Add("Text",, "Stand Strength:")
txtNormal := myGui.Add("Edit", "w100")
myGui.Add("Text",, "Crouch Strength:")
txtCtrl := myGui.Add("Edit", "w100")
myGui.Add("Text",, "Prone Strength:")
txtProne := myGui.Add("Edit", "w100")
myGui.Add("Text",, "Delay (ms):")
txtDelay := myGui.Add("Edit", "w100")
boostCheckbox := myGui.Add("Checkbox", "x10 y+10 vBoostStrength", "x5 Strength Boost (3x Scope)")
myGui.Add("Text", "x10 y+10", "Pattern Strength (1–1000):")
boostCheckbox.OnEvent("Click", (*) => ToggleBoost(boostCheckbox.Value))


slider := myGui.Add("Slider", "x20 y+10 w200 vPatternSlider Range1-1000 TickInterval100 ToolTip")
slider.Value := patternStrength
sliderInput := myGui.Add("Edit", "x225 y285 w60", String(patternStrength))

; Checkbox for showing red dot outside the settings window
chkDot := myGui.Add("Checkbox", "x280 y240", "Show Red Dot")
chkDot.OnEvent("Click", (*) => ToggleDot(chkDot.Value))

btnX := 500
btnY := 60
btnW := 100
btnH := 30
btnSpacing := 10

btnPanel := myGui.Add("GroupBox", "x220 y20 w160 h215", "Main Controls")

btnStart := myGui.Add("Button", "x230 yp+25 w140", "▶️ Start")
btnStop := myGui.Add("Button", "x230 y+5 w140", "⛔ Stop")
btnSave := myGui.Add("Button", "x230 y+10 w140", "💾 Save Preset")
btnAdd := myGui.Add("Button", "x230 y+10 w140", "➕ Add Preset")
btnDelete := myGui.Add("Button", "x230 y+10 w140", "🗑️ Delete")
btnSettings := myGui.Add("Button", "x230 y+10 w140", "⚙️ Settings")

btnSettings.OnEvent("Click", (*) => OpenSettingsWindow())

dropdown.OnEvent("Change", LoadPreset)
slider.OnEvent("Change", SliderChanged)
sliderInput.OnEvent("Change", SliderInputChanged)

SliderChanged(*) {
    sliderInput.Text := String(slider.Value)
}

SliderInputChanged(*) {
    val := Round(Number(sliderInput.Text))
    if val >= 1 && val <= 1000 {
        slider.Value := val
    }
}

btnSave.OnEvent("Click", (*) => (SavePreset(), BringGuiToFront()))
btnAdd.OnEvent("Click", (*) => (AddPreset(), BringGuiToFront()))
btnDelete.OnEvent("Click", (*) => (DeletePreset(), BringGuiToFront()))
btnStart.OnEvent("Click", (*) => (StartScript(), BringGuiToFront()))
btnStop.OnEvent("Click", (*) => (StopScript(), BringGuiToFront()))

global hudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +LastFound")
hudGui.BackColor := "Black"
hudGui.SetFont("s6.2 Bold")
weaponText := hudGui.Add("Text", "w200 h20 BackgroundTrans cWhite vWeaponText", "")
statusText := hudGui.Add("Text", "w200 h20 BackgroundTrans cGreen vStatusText", "")
screenW := A_ScreenWidth
hudGui.Show("x" screenW - 220 " y10 NoActivate")
WinSetTransparent(180, "ahk_id " hudGui.Hwnd)

OpenSettingsWindow() {
    global settingsGui

    if IsSet(settingsGui) {
        settingsGui.Show()
        return
    }

    settingsGui := Gui("+AlwaysOnTop +ToolWindow", "Settings")
    settingsGui.Add("Button", "w200", "🎯 Hotkeys").OnEvent("Click", (*) => OpenHotkeysWindow())
    settingsGui.Show("w220 h80")
}


OpenHotkeysWindow() {
    global hotkeysGui, currentHotkey, boostHotkey

    if IsSet(hotkeysGui) {
        hotkeysGui.Show()
        return
    }

    hotkeysGui := Gui("+AlwaysOnTop +ToolWindow", "Configure Hotkeys")

    ; Red Dot Hotkey
    hotkeysGui.Add("Text",, "🎯 Red Dot Toggle:")
    btnSetRedDot := hotkeysGui.Add("Button", "w180", "Press Red Dot Hotkey")
    redDotDisplay := hotkeysGui.Add("Text", "vHotkeyDisplay w180", "Current: " FormatHotkeyText(currentHotkey))

    ; Boost Hotkey
    hotkeysGui.Add("Text", "y+10", "⚡ x5 Strength Boost:")
    btnSetBoost := hotkeysGui.Add("Button", "w180", "Press Boost Hotkey")
    boostDisplay := hotkeysGui.Add("Text", "vBoostHotkeyDisplay w180", "Current: " FormatHotkeyText(boostHotkey))

    ; Save + OK
    btnSave := hotkeysGui.Add("Button", "x20 y+15 w80", "💾 Save")
    btnOK := hotkeysGui.Add("Button", "x120 yp w80", "OK")

    ; Events
    btnSetRedDot.OnEvent("Click", (*) => PickHotkey_Compatible(redDotDisplay))
    btnSetBoost.OnEvent("Click", (*) => PickBoostHotkey(boostDisplay))
    btnSave.OnEvent("Click", (*) => (SaveCurrentHotkey(), SaveBoostHotkey()))
    btnOK.OnEvent("Click", (*) => hotkeysGui.Hide())

    hotkeysGui.Show("w220 h240")
}
PickBoostHotkey(displayCtrl) {
    global boostHotkey

    MsgBoxAlwaysOnTop("After you click OK, press your Boost Hotkey (e.g., Alt+1, XButton1, etc.)")

    ; Wait until no keys are pressed
    Loop {
        Sleep(50)
        if !GetKeyState("Shift") && !GetKeyState("Ctrl") && !GetKeyState("Alt")
            break
    }

    keyPressed := ""
    modifiers := ""
    disallowed := Map("Ctrl", true, "Alt", true, "Shift", true, "LControl", true, "RControl", true, "LAlt", true, "RAlt", true, "LShift", true, "RShift", true)

    Loop {
        for key in GetAllKeys() {
            if GetKeyState(key, "P") {
                if disallowed.Has(key)
                    continue

                keyPressed := key
                break
            }
        }
        if keyPressed != ""
            break
        Sleep(10)
    }

    ; Build modifier string
    if GetKeyState("Ctrl", "P")
        modifiers .= "^"
    if GetKeyState("Alt", "P")
        modifiers .= "!"
    if GetKeyState("Shift", "P")
        modifiers .= "+"

    newHotkey := modifiers keyPressed

    try Hotkey(boostHotkey, "Off")
    boostHotkey := newHotkey
    Hotkey(boostHotkey, ToggleBoostKey, "On")

    displayCtrl.Text := "Current: " FormatHotkeyText(boostHotkey)
    IniWrite(boostHotkey, A_ScriptDir "\school_keys.ini", "Hotkeys", "BoostToggle")
    MsgBoxAlwaysOnTop("✅ Boost hotkey set to: " boostHotkey)
}


SaveCurrentHotkey() {
    global currentHotkey
    IniWrite(currentHotkey, A_ScriptDir "\school_keys.ini", "Hotkeys", "RedDotToggle")
    MsgBoxAlwaysOnTop("✅ Hotkey saved: " currentHotkey)
}

SaveBoostHotkey() {
    global boostHotkey
    IniWrite(boostHotkey, A_ScriptDir "\school_keys.ini", "Hotkeys", "BoostToggle")
    MsgBoxAlwaysOnTop("✅ Boost hotkey saved: " boostHotkey)
}

MsgBoxAlwaysOnTop(text, title := "Set Hotkey") {
    SetTimer(EnsureTopmostMsgBox, -50)
    return MsgBox(text, title)
}

EnsureTopmostMsgBox(*) {
    hWnd := WinExist("ahk_class #32770")
    if hWnd
        DllCall("SetWindowPos", "Ptr", hWnd, "Ptr", -1, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0003)
}

PickHotkey_Compatible(displayCtrl) {
    global currentHotkey

    MsgBoxAlwaysOnTop("After you click OK, press your new hotkey (e.g., Ctrl+1, Alt+F, etc.)")

    ; Wait for clean state before detecting
    Loop {
        Sleep(50)
        if !GetKeyState("Shift") && !GetKeyState("Ctrl") && !GetKeyState("Alt")
            break
    }

    keyPressed := ""
    modifiers := ""
    disallowed := Map("Ctrl", true, "Alt", true, "Shift", true, "LControl", true, "RControl", true, "LAlt", true, "RAlt", true, "LShift", true, "RShift", true)

    Loop {
        for key in GetAllKeys() {
            if GetKeyState(key, "P") {
                ; Skip if only a modifier is pressed
                if disallowed.Has(key)
                    continue

                keyPressed := key
                break
            }
        }
        if keyPressed != ""
            break
        Sleep(10)
    }

    ; Detect what modifiers were held at the moment the key was pressed
    if GetKeyState("Ctrl", "P")
        modifiers .= "^"
    if GetKeyState("Alt", "P")
        modifiers .= "!"
    if GetKeyState("Shift", "P")
        modifiers .= "+"

    fullHotkey := modifiers keyPressed

    ; Update current hotkey
    try Hotkey(currentHotkey, "Off")
    currentHotkey := fullHotkey
    Hotkey(currentHotkey, ToggleRedDotKey, "On")

    ; Show in GUI and save to INI
    displayCtrl.Text := "Current: " FormatHotkeyText(currentHotkey)
    IniWrite(currentHotkey, A_ScriptDir "\school_keys.ini", "Hotkeys", "RedDotToggle")
    MsgBoxAlwaysOnTop("✅ Hotkey set to: " currentHotkey)
}


GetAllKeys() {
    static keys := [
        "A","B","C","D","E","F","G","H","I","J","K","L","M",
        "N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "1","2","3","4","5","6","7","8","9","0",
        "F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
        "Insert","Delete","Home","End","PgUp","PgDn",
        "Up","Down","Left","Right",
        "Tab","Enter","Space","Escape","Backspace",
        "XButton1", "XButton2", "LButton", "RButton", "MButton", "WheelUp", "WheelDown"
    ]
    return keys
}

FormatHotkeyText(hotkey) {
    display := ""
    if InStr(hotkey, "^")
        display .= "Ctrl + "
    if InStr(hotkey, "!")
        display .= "Alt + "
    if InStr(hotkey, "+")
        display .= "Shift + "

    ; Remove modifiers from key name
    keyOnly := RegExReplace(hotkey, "[\^\!\+]")

    return display keyOnly
}

ToggleRedDotKey(*) {
    global dotVisible
    dotVisible := !dotVisible
    ToggleDot(dotVisible)
}

ToggleBoostKey(*) {
    global boostCheckbox
    boostCheckbox.Value := !boostCheckbox.Value
    ToggleBoost(boostCheckbox.Value)
}


UpdateHUD() {
    global weaponText, statusText, currentWeapon
    global scriptRunning, boostActive

    weaponText.Text := "Weapon: " currentWeapon

    recoilText := "Recoil: " (scriptRunning ? "ON" : "OFF")

    if boostActive
        recoilText .= "    ➕ x5 Boost (3x Scope)"

    statusText.Text := recoilText
    statusText.SetFont("c" (scriptRunning ? "Green" : "Red"))
}

PopupInput(prompt, title := "Input") {
    global myGui
    myGui.Opt("-AlwaysOnTop")
    Sleep(100)
    result := ""
    try {
        result := InputBox(prompt, title)
        WinActivate("ahk_class #32770")
    }
    Sleep(100)
    myGui.Opt("+AlwaysOnTop")
    myGui.Show()
    return result
}

PopupMsg(text, title := "Message", type := 0) {
    global myGui
    myGui.Opt("-AlwaysOnTop")
    Sleep(100)
    result := MsgBox(text, title, type)
    Sleep(100)
    myGui.Opt("+AlwaysOnTop")
    myGui.Show()
    return result
}

LoadPresetsFromINI() {
    global presets, iniFile
    if !FileExist(iniFile) {
        MsgBox("INI file does not exist: " iniFile)  ; Debugging message to confirm the file exists.
        return
    }
    sections := IniRead(iniFile)
    Loop Parse, sections, "`n", "`r" {
        section := A_LoopField
        if section = ""
            continue
        presets[section] := {
            normal: IniRead(iniFile, section, "normal", 0),
            ctrl:   IniRead(iniFile, section, "ctrl", 0),
            prone:  IniRead(iniFile, section, "prone", 0),
            delay:  IniRead(iniFile, section, "delay", 10),
            strength: IniRead(iniFile, section, "strength", 50)
        }
    }
}

SavePresetsToINI() {
    global presets, iniFile
    if FileExist(iniFile)
        FileDelete iniFile
    for name, data in presets {
        IniWrite(data.normal, iniFile, name, "normal")
        IniWrite(data.ctrl, iniFile, name, "ctrl")
        IniWrite(data.prone, iniFile, name, "prone")
        IniWrite(data.delay, iniFile, name, "delay")
        IniWrite(data.strength, iniFile, name, "strength")
    }
}

UpdateDropdown() {
    global dropdown, presets, currentWeapon
    dropdown.Delete()
    i := 1
    for k in presets {
        dropdown.Add([k])  ; ✅ wrap in array as required
        if k = currentWeapon
            dropdown.Value := i
        i++
    }
}

ToggleBoost(state) {
    global schoolNormal, schoolCtrl, schoolProne, txtNormal, txtCtrl, txtProne
    global slider, sliderInput
    global originalValues, boostActive, patternStrength

    if state {
        originalValues := {
            normal: schoolNormal,
            ctrl: schoolCtrl,
            prone: schoolProne,
            strength: patternStrength
        }

        ; Apply x5 to recoil strengths
        schoolNormal := originalValues.normal * 5
        schoolCtrl := originalValues.ctrl * 5
        schoolProne := originalValues.prone * 5

        ; Apply x2.33 to pattern strength
        patternStrength := Round(originalValues.strength * 2.5)

        boostActive := true
    } else {
        if originalValues.HasOwnProp("normal") {
            schoolNormal := originalValues.normal
            schoolCtrl := originalValues.ctrl
            schoolProne := originalValues.prone
            patternStrength := originalValues.strength
        }
        boostActive := false
    }

    ; Update GUI fields
    txtNormal.Text := schoolNormal
    txtCtrl.Text := schoolCtrl
    txtProne.Text := schoolProne

    slider.Value := patternStrength
    sliderInput.Text := String(patternStrength)

    UpdateHUD()
}

LoadPreset(*) {
    global currentWeapon
    global schoolNormal, schoolCtrl, schoolProne, schoolDelay, patternStrength
    global txtNormal, txtCtrl, txtProne, txtDelay, slider, sliderInput
    global presets

    selected := dropdown.Text
    if !presets.Has(selected)
        return

    currentWeapon := selected
    preset := presets[selected]

    schoolNormal := preset.normal
    schoolCtrl := preset.ctrl
    schoolProne := preset.HasOwnProp("prone") ? preset.prone : 0
    schoolDelay := preset.delay
    patternStrength := preset.strength

    txtNormal.Text := schoolNormal
    txtCtrl.Text := schoolCtrl
    txtProne.Text := schoolProne
    txtDelay.Text := schoolDelay
    slider.Value := patternStrength
    sliderInput.Text := String(patternStrength)

    UpdateHUD()
}

SavePreset() {
    global currentWeapon, schoolNormal, schoolCtrl, schoolProne, schoolDelay, patternStrength, presets
    if !IsNumber(txtNormal.Text) || !IsNumber(txtCtrl.Text) || !IsNumber(txtDelay.Text) || !IsNumber(txtProne.Text) {
        PopupMsg("Please enter valid numbers in all fields.", "Error", 48)
        return
    }
    schoolNormal := Round(Number(txtNormal.Text))
    schoolCtrl := Round(Number(txtCtrl.Text))
    schoolProne := Round(Number(txtProne.Text))
    schoolDelay := Round(Number(txtDelay.Text))
    patternStrength := slider.Value
    presets[currentWeapon] := {
        normal: schoolNormal,
        ctrl: schoolCtrl,
        prone: schoolProne,
        delay: schoolDelay,
        strength: patternStrength
    }
    SavePresetsToINI()
    PopupMsg("Preset saved!", "Success")
    UpdateHUD()
}

AddPreset() {
    global presets, dropdown
    input := PopupInput("Enter new weapon name:", "Add Weapon")
    if !IsObject(input) || input.Value = "" || input.Result != "OK"
        return

    name := input.Value . ""  ; Force to string

    if presets.Has(name) {
        PopupMsg("That preset already exists.", "Warning", 48)
        return
    }

    presets[name] := { normal: 0, ctrl: 0, prone: 0, delay: 10, strength: 50 }
    SavePresetsToINI()
    UpdateDropdown()
    dropdown.Text := name
    LoadPreset()
}

DeletePreset() {
    global presets, dropdown, currentWeapon
    if presets.Count <= 1 {
        PopupMsg("Cannot delete the only preset!", "Warning", 48)
        return
    }
    confirm := PopupMsg("Delete '" currentWeapon "'?", "Confirm Delete", 4)
    if confirm = "Yes" {
        presets.Delete(currentWeapon)
        SavePresetsToINI()
        currentWeapon := GetFirstPresetName()
        UpdateDropdown()
        dropdown.Text := currentWeapon
        LoadPreset()
    }
}

StartScript() {
    global scriptRunning
    scriptRunning := true
    TrayTip("SCHOOL", "Script Enabled (F8 to toggle off)")
    UpdateHUD()
}

StopScript() {
    global scriptRunning
    scriptRunning := false
    TrayTip("SCHOOL", "Script Disabled")
    UpdateHUD()
}

ToggleDot(state := false) {
    global dotGui, dotVisible, chkDot

    ; Ensure dotGui is created if not already
    if !IsSet(dotGui) {
        dotGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    }

    ; Fixed size for red dot
    size := 5  ; Fixed size for the red dot

    ; Set the background color of the red dot
    dotGui.BackColor := "Red"  
    dotGui.Opt("+LastFound")
    hwnd := WinExist()

    ; Create circular region
    hRgn := DllCall("CreateEllipticRgn", "Int", 0, "Int", 0, "Int", size, "Int", size, "Ptr")
    DllCall("SetWindowRgn", "Ptr", hwnd, "Ptr", hRgn, "Int", true)

    centerX := (A_ScreenWidth // 2) - (size // 2)
    centerY := (A_ScreenHeight // 2) - (size // 2)

    if (state) {
        dotGui.Show("x" centerX " y" centerY " w" size " h" size " NoActivate")
        dotVisible := true
        chkDot.Value := 1  ; Set checkbox to checked
    } else {
        dotGui.Hide()
        dotVisible := false
        chkDot.Value := 0  ; Set checkbox to unchecked
    }
}

BringGuiToFront() {
    global myGui
    myGui.Opt("-AlwaysOnTop")
    Sleep(150)
    myGui.Opt("+AlwaysOnTop")
    myGui.Show()
}

~*LButton:: {
    global scriptRunning
    if !scriptRunning
        return

    ; Determine current strength based on stance
    base := GetKeyState("z", "P") ? schoolProne
         : GetKeyState("Ctrl", "P") ? schoolCtrl
         : schoolNormal

    ; Start recoil loop for full-auto weapons
    grow := 0.0
    while GetKeyState("LButton", "P") && GetKeyState("RButton", "P") {
        grow += (patternStrength / 1000) ** 2
        step := Round(base + grow)
        if step > 1000
            step := 1000
        DllCall("mouse_event", "UInt", 0x01, "Int", 0, "Int", step, "UInt", 0)
        Sleep(schoolDelay)
    }
}

F8:: {
    global scriptRunning
    scriptRunning := !scriptRunning
    TrayTip("SCHOOL", scriptRunning ? "Script Enabled" : "Script Disabled")
    UpdateHUD()
}

F10:: {
    global boostCheckbox
    boostCheckbox.Value := !boostCheckbox.Value
    ToggleBoost(boostCheckbox.Value)
}

UpdateDropdown()
if currentWeapon != "" {
    dropdown.Text := currentWeapon
    LoadPreset()
}

GetFirstPresetName() {
    global presets
    for k in presets
        return k
    return ""
}



sliderInput.Text := String(slider.Value)

; Add the label off-screen initially
bottomLabel := myGui.Add("Text", "x170 y460 cGray", "Powered by FDCaffeine")

; Show the GUI first
myGui.Show("w392 h350")

; Measure GUI and label size
myGui.GetClientPos(,, &winW, &winH)
bottomLabel.GetPos(,, &labelW, &labelH)

; Calculate centered position
x := (winW - labelW) // 2
y := winH - labelH - 10  ; 10 px from bottom

; Move the label into place
bottomLabel.Move(x, y)