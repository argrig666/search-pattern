#Requires AutoHotkey v2.0+
#SingleInstance Force

; ==============================================================================
; RadSearch - Progressive Accordion Search Pattern GUI for Radiology
; Optimized for Windows PACS Workstations with Single-Keypress Navigation
; ==============================================================================

; Global Configuration & State
global AppTitle := "RadSearch | Search Pattern"
global ScriptVersion := "1.2"
global DataFilePath := A_ScriptDir . "\search_patterns.txt"

; Visual Palette (Radiology Dark-Room Ergonomics)
global COLOR_BG := "181A1F"           ; Deep dark slate/charcoal (reading-room safe)
global COLOR_PANEL := "21252B"        ; Slightly elevated dark panel
global COLOR_BORDER := "3E4451"       ; Subtle divider color
global COLOR_TEXT_ACTIVE := "D8DEE9"  ; Crisp, soft off-white
global COLOR_TEXT_MUTED := "5C6370"   ; Muted slate (greyed out completed items)
global COLOR_ACCENT := "61AFEF"       ; Soft medical cyan for active drawers / keys
global COLOR_DONE := "98C379"         ; Soft sage green for completed tally

; Win32 Custom Draw Colors (BGR Format)
global BGR_MUTED := 0x70635C          ; BGR for COLOR_TEXT_MUTED
global BGR_ACTIVE := 0xEFB261         ; BGR for COLOR_ACCENT
global BGR_TEXT := 0xE9DED8           ; BGR for COLOR_TEXT_ACTIVE
global BGR_DONE := 0x79C398           ; BGR for COLOR_DONE

; Global Navigation State Machine
global CurrentViewMode := "Catalog"   ; "Catalog" or "Checklist"
global CatalogNavLevel := 0           ; 0 = Section, 1 = Modality, 2 = Study
global ActiveSection := ""
global ActiveModality := ""

; Lookup Maps for Single-Keypress Navigation
global SectionKeyToName := Map(
    "b", "BODY",
    "r", "BREAST",
    "h", "CARDIAC",
    "c", "CHEST",
    "m", "MSK",
    "n", "NEURO",
    "x", "NUCLEAR MEDICINE",
    "p", "PEDIATRIC",
    "v", "PERIPHERAL VASCULAR",
    "u", "ULTRASOUND",
    "w", "WORKFLOW OPTIMIZATION"
)
global SectionNameToKey := Map(
    "BODY", "b",
    "BREAST", "r",
    "CARDIAC", "h",
    "CHEST", "c",
    "MSK", "m",
    "NEURO", "n",
    "NUCLEAR MEDICINE", "x",
    "PEDIATRIC", "p",
    "PERIPHERAL VASCULAR", "v",
    "ULTRASOUND", "u",
    "WORKFLOW OPTIMIZATION", "w"
)
global ModalityKeyMap := Map(
    "BODY", Map("c", "CT", "f", "FLUOROSCOPY", "m", "MRI", "r", "RADIOGRAPH"),
    "BREAST", Map("m", "MAMMOGRAPHY & US", "r", "MRI"),
    "CARDIAC", Map("c", "CT", "m", "MRI"),
    "CHEST", Map("c", "CT", "m", "MRI", "r", "RADIOGRAPH"),
    "MSK", Map("m", "MRI", "r", "RADIOGRAPH"),
    "NEURO", Map("c", "CT", "m", "MRI", "r", "RADIOGRAPH"),
    "NUCLEAR MEDICINE", Map("c", "COMMON & EMERGENT", "g", "GENERAL NM", "p", "PET/CT"),
    "PEDIATRIC", Map("c", "CT", "f", "FLUOROSCOPY", "m", "MRI", "r", "RADIOGRAPH", "u", "ULTRASOUND"),
    "PERIPHERAL VASCULAR", Map("c", "CT"),
    "ULTRASOUND", Map("b", "BODY & GENERAL US", "t", "TRANSPLANT US", "v", "VASCULAR US"),
    "WORKFLOW OPTIMIZATION", Map("c", "CONSULTATION", "i", "INTERPRETIVE SKILLS")
)
global StudyKeyMap := Map(
    "CHEST|RADIOGRAPH", Map("c", "CHEST RADIOGRAPH"),
    "CHEST|CT", Map("c", "CT CHEST", "p", "CTA PE (CT ANGIOGRAM FOR PULMONARY EMBOLUS)"),
    "CHEST|MRI", Map("c", "MRI CHEST"),
    "BODY|RADIOGRAPH", Map("a", "ABDOMINAL RADIOGRAPH"),
    "BODY|FLUOROSCOPY", Map("e", "FLUOROSCOPIC ESOPHAGRAM", "u", "FLUOROSCOPIC UPPER GI STUDY"),
    "BODY|CT", Map("c", "CT CHEST ABDOMEN PELVIS", "a", "CT ABDOMEN PELVIS (CT AP)", "t", "TAILORING SEARCH PATTERN TO INDICATION", "h", "HOW TO TRIAGE A CT CHEST ABDOMEN PELVIS", "v", "THE VALUE OF NON-CONTRAST STUDIES"),
    "BODY|MRI", Map("a", "MRI ABDOMEN (GENERAL APPROACH)", "p", "MRI PELVIS (GENERAL APPROACH)", "r", "MRI PELVIS (PROSTATE)"),
    "NEURO|RADIOGRAPH", Map("s", "SKULL RADIOGRAPH", "c", "CERVICAL SPINE RADIOGRAPH", "t", "THORACIC SPINE RADIOGRAPH", "l", "LUMBAR SPINE RADIOGRAPH"),
    "NEURO|CT", Map("h", "CT HEAD", "t", "CT TEMPORAL BONES", "n", "CT SOFT TISSUE NECK", "c", "CT CERVICAL SPINE", "o", "CT THORACIC SPINE", "l", "CT LUMBAR SPINE", "a", "CTA HEAD AND NECK"),
    "NEURO|MRI", Map("b", "MRI BRAIN", "f", "MRI BRAIN FOR SEIZURE FOCUS", "o", "MRI ORBITS", "i", "MRI INTERNAL AUDITORY CANALS (MRI IAC)", "p", "MRI OF THE SELLA AND PITUITARY GLAND", "n", "MRI NECK", "c", "MRI CERVICAL SPINE", "t", "MRI THORACIC SPINE", "l", "MRI LUMBAR SPINE", "s", "MRI TOTAL SPINE"),
    "MSK|RADIOGRAPH", Map("c", "CONSIDERATIONS FOR ALL MSK RADIOGRAPHS", "s", "SHOULDER RADIOGRAPH", "e", "ELBOW RADIOGRAPH", "w", "WRIST/HAND RADIOGRAPH", "p", "PELVIS/HIP RADIOGRAPH", "k", "KNEE RADIOGRAPH", "a", "ANKLE RADIOGRAPH", "f", "FOOT RADIOGRAPH"),
    "MSK|MRI", Map("s", "MRI SHOULDER", "e", "MRI ELBOW", "w", "MRI WRIST", "h", "MRI HIP AND PELVIS", "k", "MRI KNEE", "a", "MRI ANKLE", "i", "MSK MRI EXAMS FOR INFECTION"),
    "CARDIAC|CT", Map("c", "CTA CORONARY", "a", "CTA AORTA (DISSECTION STUDY)"),
    "CARDIAC|MRI", Map("h", "MRI HEART (GENERAL APPROACH)", "s", "MRI HEART - CONSIDERATIONS FOR SPECIFIC INDICATIONS"),
    "PERIPHERAL VASCULAR|CT", Map("l", "CTA ILIOFEMORAL RUNOFF AND LOWER EXTREMITIES", "u", "CTA OF THE UPPER EXTREMITY"),
    "ULTRASOUND|BODY & GENERAL US", Map("g", "GENERAL APPROACHES TO ULTRASOUND", "a", "US ABDOMEN", "x", "US APPENDIX", "r", "US RENAL AND RETROPERITONEUM", "p", "US PELVIS AND TRANSVAGINAL", "f", "US FIRST TRIMESTER PREGNANCY", "s", "US SCROTUM", "t", "US THYROID"),
    "ULTRASOUND|TRANSPLANT US", Map("l", "US LIVER TRANSPLANT", "r", "US RENAL TRANSPLANT"),
    "ULTRASOUND|VASCULAR US", Map("d", "US LOWER EXTREMITY FOR DVT", "a", "US EXTREMITY ARTERIAL DOPPLER", "h", "US HEMODIALYSIS ACCESS", "c", "US CAROTID", "t", "US TRANSCRANIAL DOPPLER (TCD)", "l", "US LIVER DOPPLER", "r", "US RENAL DOPPLER"),
    "NUCLEAR MEDICINE|COMMON & EMERGENT", Map("v", "V/Q SCAN", "g", "GI BLEEDING STUDY", "h", "HIDA (HEPATOBILIARY SCINTIGRAPHY)", "b", "BRAIN DEATH STUDY"),
    "NUCLEAR MEDICINE|GENERAL NM", Map("b", "BONE SCAN", "3", "THREE PHASE BONE SCAN", "g", "GALLBLADDER EJECTION FRACTION STUDY", "e", "GASTRIC EMPTYING STUDY", "i", "I-123 IODINE UPTAKE TEST", "p", "PARATHYROID IMAGING WITH TC99-SESTAMIBI", "w", "COMBINED SULFUR COLLOID AND TAGGED WBC SCAN"),
    "NUCLEAR MEDICINE|PET/CT", Map("f", "F18 FDG PET/CT WHOLE BODY", "g", "GALLIUM-68 DOTATATE PET/CT", "a", "FLUCICLOVINE F18 (AXUMIN) PET/CT"),
    "PEDIATRIC|CT", Map("c", "NOTES ON CT CHEST IN PEDIATRIC PATIENTS"),
    "PEDIATRIC|FLUOROSCOPY", Map("v", "FLUOROSCOPIC UPPER GI FOR MIDGUT VOLVULUS", "e", "PEDIATRIC CONTRAST ENEMA"),
    "PEDIATRIC|MRI", Map("e", "MR ENTEROGRAPHY", "u", "MR UROGRAM"),
    "PEDIATRIC|RADIOGRAPH", Map("c", "NEONATAL CHEST RADIOGRAPH", "a", "NEONATAL ABDOMINAL RADIOGRAPH", "s", "SCOLIOSIS SERIES (XR SCOLIOSIS)"),
    "PEDIATRIC|ULTRASOUND", Map("m", "US ABDOMEN FOR COMPLICATIONS OF MALROTATION", "i", "US FOR INTUSSUSCEPTION", "p", "US FOR PYLORIC STENOSIS", "r", "US RENAL AND RETROPERITONEUM", "h", "US NEONATAL HEAD", "s", "US NEONATAL SPINE", "d", "US HIPS FOR HIP DYSPLASIA"),
    "BREAST|MAMMOGRAPHY & US", Map("m", "MAMMOGRAM AND BREAST TOMOSYNTHESIS", "u", "US BREAST"),
    "BREAST|MRI", Map("b", "MRI BREAST", "i", "MRI BREAST FOR IMPLANT EVALUATION"),
    "WORKFLOW OPTIMIZATION|CONSULTATION", Map("s", "STEPS TOWARD PROVIDING A HIGHER LEVEL OF CARE:", "f", "SOME RULES OF THUMB FOR WHEN TO FOLLOW CASES", "c", "SUGGESTIONS FOR CONSTANT IMPROVEMENT"),
    "WORKFLOW OPTIMIZATION|INTERPRETIVE SKILLS", Map("b", "MANAGING BREAKS IN THE SEARCH PATTERN", "f", "FINAL CHECKS: THINGS TO CONSIDER FOR EVERY STUDY", "p", "SOME RULES OF THUMB ON WHEN TO PROVIDE PRELIMINARY REPORTS")
)

; Global State Containers
global AllStudies := []
global CatalogStudyMap := Map()       ; Map[catalogItemHwnd] => study object
global SecNodeMap := Map()            ; Map[sectionName] => itemHwnd
global ModNodeMap := Map()            ; Map[section|modality] => itemHwnd
global CurrentStudy := ""
global NodeDataMap := Map()           ; Map[itemHwnd] => {Num, RawText, IsDrawer, TotalChildren, CheckedChildren, IsChecked}
global CheckedItemMap := Map()        ; Map[itemHwnd] => bool
global TopLevelStationList := []      ; List of top-level station itemHwnds in current study
global TotalStudyLeafCount := 0
global CheckedStudyLeafCount := 0
global IsAlwaysOnTop := true

; Windows Theme & Extended Styles
global DWMWA_USE_IMMERSIVE_DARK_MODE := 20
global TVS_CHECKBOXES := 0x0100
global TVS_FULLROWSELECT := 0x1000
global NM_CUSTOMDRAW := -12
global CDDS_PREPAINT := 0x00000001
global CDDS_ITEMPREPAINT := 0x00010001
global CDRF_DODEFAULT := 0x00000000
global CDRF_NEWFONT := 0x00000002
global CDRF_NOTIFYITEMDRAW := 0x00000020

; ------------------------------------------------------------------------------
; Initialize GUI Window (Sleek, Minimalist, High-DPI Legible)
; ------------------------------------------------------------------------------
MainGui := Gui("+Resize +MinSize380x480 +AlwaysOnTop", AppTitle)
MainGui.BackColor := COLOR_BG
MainGui.SetFont("s11 c" . COLOR_TEXT_ACTIVE, "Segoe UI")

; Catalog Mode Controls:
; 1. Sleek Breadcrumb HUD (Prominent single-key prompts)
TxtBreadcrumb := MainGui.Add("Text", "x12 y10 w350 h24 c" . COLOR_ACCENT . " +0x200", "Keys: [B]ody [C]hest [N]euro [M]sk [H]eart [U]s [P]eds [R]Breast [X]Nuc")
TxtBreadcrumb.SetFont("s11 bold")

; 2. Compact Always-On-Top Pin Toggle Button
BtnPin := MainGui.Add("Button", "x370 y10 w32 h24 +Flat", "📌")

; 3. Clean Search Input (Optional instant filter)
EditSearch := MainGui.Add("Edit", "x12 y38 w390 h26 c" . COLOR_TEXT_ACTIVE . " Background" . COLOR_PANEL)
EditSearch.ToolTip := "Type to filter studies, or press single keys directly (e.g. N -> C -> H)"

; 4. Catalog TreeView (Generous line height, readable font)
TVCatalog := MainGui.Add("TreeView", "x12 y70 w390 h580 Background" . COLOR_PANEL . " c" . COLOR_TEXT_ACTIVE . " +0x1000 +Buttons -Lines")
TVCatalog.SetFont("s12", "Segoe UI")

; Checklist Mode Controls:
; 1. Prominent Study Title Header
TxtStudyTitle := MainGui.Add("Text", "x12 y10 w225 h26 +Hidden c" . COLOR_ACCENT . " +0x200", "Select a Study")
TxtStudyTitle.SetFont("s13 bold")

; 2. Minimalist Action Buttons (Checklist Mode)
BtnBackCatalog := MainGui.Add("Button", "x245 y10 w74 h24 +Hidden +Flat", "⌫ Catalog")
BtnBackCatalog.SetFont("s9")
BtnReset := MainGui.Add("Button", "x325 y10 w48 h24 +Hidden +Flat", "↺ Reset")
BtnReset.SetFont("s9")

; 3. Modern Slim Accent Progress Bar
PrgStatus := MainGui.Add("Progress", "x12 y38 w390 h4 +Hidden c" . COLOR_ACCENT . " Background" . COLOR_PANEL . " +Smooth", 0)

; 4. Progress Tally Display
TxtProgress := MainGui.Add("Text", "x12 y44 w390 h18 +Hidden c" . COLOR_TEXT_MUTED, "0 / 0 completed (0%)")
TxtProgress.SetFont("s10")

; 5. Checklist TreeView (All items expanded and immediately available to gaze!)
TVChecklist := MainGui.Add("TreeView", "x12 y66 w390 h584 +Hidden +Checked +0x1000 Background" . COLOR_PANEL . " c" . COLOR_TEXT_ACTIVE . " +Buttons -Lines")
TVChecklist.SetFont("s12", "Segoe UI")

; Status / Hotkey Hint Footer (Minimalist)
TxtFooter := MainGui.Add("Text", "x12 y656 w390 h18 c" . COLOR_TEXT_MUTED . " +0x200", "Keys: [N]=Neuro ➔ [C]=CT ➔ [H]=Head  |  ⌫=Back  |  📌=Pin")
TxtFooter.SetFont("s9")

; ------------------------------------------------------------------------------
; Apply Windows Dark Mode & Event Message Hooks
; ------------------------------------------------------------------------------
ApplyDarkTheme(MainGui.Hwnd, TVCatalog.Hwnd)
ApplyDarkTheme(MainGui.Hwnd, TVChecklist.Hwnd)

; Set comfortable row height (30px) for high-contrast legibility
SendMessage(0x111B, 30, 0, TVCatalog.Hwnd)
SendMessage(0x111B, 30, 0, TVChecklist.Hwnd)

; Register CustomDraw and Mouse-Up Hook
OnMessage(0x004E, OnWmNotifyCustomDraw)
OnMessage(0x0202, OnWmLButtonUp)

; ------------------------------------------------------------------------------
; Event Handlers
; ------------------------------------------------------------------------------
BtnBackCatalog.OnEvent("Click", (*) => SwitchToView("Catalog"))
BtnReset.OnEvent("Click", (*) => ResetCurrentStudyChecks())
BtnPin.OnEvent("Click", (*) => ToggleAlwaysOnTop())

EditSearch.OnEvent("Change", OnSearchChange)

; Catalog Tree Events: Mouse Selection & Double-Click
TVCatalog.OnEvent("DoubleClick", OnCatalogDoubleClick)
TVCatalog.OnEvent("ItemSelect", OnCatalogItemSelect)

; Checklist Tree Events
TVChecklist.OnEvent("ItemCheck", OnChecklistItemChecked)
TVChecklist.OnEvent("ItemSelect", OnChecklistItemSelect)
TVChecklist.OnEvent("ItemExpand", OnChecklistItemExpand)

MainGui.OnEvent("Size", OnGuiResize)
MainGui.OnEvent("Close", CleanExit)

; Load Database
LoadSearchPatternDatabase()

; Build Catalog Tree & Show Window
PopulateCatalogTree()
SwitchToView("Catalog")
MainGui.Show("w420 h700")

; ==============================================================================
; Single-Keypress Hierarchical Navigation Engine
; ==============================================================================

ControlHasFocus(ctrl) {
    try return ctrl.Focused
    return false
}

HandleCatalogKey(k) {
    global CatalogNavLevel, ActiveSection, ActiveModality
    global SectionKeyToName, ModalityKeyMap, StudyKeyMap
    global SecNodeMap, ModNodeMap, TVCatalog, AllStudies

    k := StrLower(k)

    ; LEVEL 0: Selecting Section
    if (CatalogNavLevel == 0) {
        if SectionKeyToName.Has(k) {
            SelectCatalogSection(SectionKeyToName[k])
            return
        }
    }

    ; LEVEL 1: Selecting Modality under ActiveSection
    else if (CatalogNavLevel == 1) {
        if (ModalityKeyMap.Has(ActiveSection) && ModalityKeyMap[ActiveSection].Has(k)) {
            SelectCatalogModality(ModalityKeyMap[ActiveSection][k])
            return
        }
        ; Forgiveness rule: If pressed key matches another section, switch section directly
        else if SectionKeyToName.Has(k) {
            SelectCatalogSection(SectionKeyToName[k])
            return
        }
    }

    ; LEVEL 2: Selecting Study under ActiveSection > ActiveModality
    else if (CatalogNavLevel == 2) {
        comboKey := ActiveSection . "|" . ActiveModality
        if (StudyKeyMap.Has(comboKey) && StudyKeyMap[comboKey].Has(k)) {
            studyTitle := StudyKeyMap[comboKey][k]
            for s in AllStudies {
                if (s.Section == ActiveSection && s.Modality == ActiveModality && s.Title == studyTitle) {
                    LoadStudyAndShowChecklist(s)
                    return
                }
            }
        }
        ; Forgiveness rule: If pressed key matches another modality in current section
        else if (ModalityKeyMap.Has(ActiveSection) && ModalityKeyMap[ActiveSection].Has(k)) {
            SelectCatalogModality(ModalityKeyMap[ActiveSection][k])
            return
        }
        ; Forgiveness rule: If pressed key matches another section
        else if SectionKeyToName.Has(k) {
            SelectCatalogSection(SectionKeyToName[k])
            return
        }
    }
}

SelectCatalogSection(secName) {
    global CatalogNavLevel, ActiveSection, ActiveModality
    global SecNodeMap, TVCatalog

    ; Collapse other sections
    for name, sHwnd in SecNodeMap {
        if (name != secName)
            TVCatalog.Modify(sHwnd, "-Expand")
    }

    ActiveSection := secName
    ActiveModality := ""
    CatalogNavLevel := 1

    if SecNodeMap.Has(secName) {
        sHwnd := SecNodeMap[secName]
        TVCatalog.Modify(sHwnd, "Expand")
        TVCatalog.Modify(sHwnd, "Select Vis")
    }

    UpdateCatalogBreadcrumb()
}

SelectCatalogModality(modName) {
    global CatalogNavLevel, ActiveSection, ActiveModality
    global ModNodeMap, TVCatalog

    ; Collapse other modalities in this section
    for key, mHwnd in ModNodeMap {
        if InStr(key, ActiveSection . "|") && (key != ActiveSection . "|" . modName)
            TVCatalog.Modify(mHwnd, "-Expand")
    }

    ActiveModality := modName
    CatalogNavLevel := 2

    modKey := ActiveSection . "|" . modName
    if ModNodeMap.Has(modKey) {
        mHwnd := ModNodeMap[modKey]
        TVCatalog.Modify(mHwnd, "Expand")
        TVCatalog.Modify(mHwnd, "Select Vis")
    }

    UpdateCatalogBreadcrumb()
}

HandleCatalogBack() {
    global CatalogNavLevel, ActiveSection, ActiveModality
    global SecNodeMap, ModNodeMap, TVCatalog

    if (CatalogNavLevel == 2) {
        modKey := ActiveSection . "|" . ActiveModality
        if ModNodeMap.Has(modKey)
            TVCatalog.Modify(ModNodeMap[modKey], "-Expand")
        ActiveModality := ""
        CatalogNavLevel := 1
        UpdateCatalogBreadcrumb()
    } else if (CatalogNavLevel == 1) {
        if SecNodeMap.Has(ActiveSection)
            TVCatalog.Modify(SecNodeMap[ActiveSection], "-Expand")
        ActiveSection := ""
        CatalogNavLevel := 0
        UpdateCatalogBreadcrumb()
    }
}

UpdateCatalogBreadcrumb() {
    global CatalogNavLevel, ActiveSection, ActiveModality
    global TxtBreadcrumb, TxtFooter, ModalityKeyMap, StudyKeyMap

    if (CatalogNavLevel == 0) {
        TxtBreadcrumb.Text := "Keys: [B]ody [C]hest [N]euro [M]sk [H]eart [U]s [P]eds [R]Breast [X]Nuc"
        TxtFooter.Text := "Press Key: [N]=Neuro ➔ [C]=CT ➔ [H]=Head  |  ⌫=Back"
    } else if (CatalogNavLevel == 1) {
        opts := ""
        if ModalityKeyMap.Has(ActiveSection) {
            for k, m in ModalityKeyMap[ActiveSection]
                opts .= "[" . StrUpper(k) . "] " . m . "  "
        }
        TxtBreadcrumb.Text := ActiveSection . " ➔ " . opts
        TxtFooter.Text := "Press Modality Key  |  ⌫ Back to Sections"
    } else if (CatalogNavLevel == 2) {
        opts := ""
        comboKey := ActiveSection . "|" . ActiveModality
        if StudyKeyMap.Has(comboKey) {
            for k, st in StudyKeyMap[comboKey] {
                shortTitle := RegExReplace(st, "^(CT|CTA|MRI|MR|US|FLUOROSCOPIC)\s+", "")
                if (StrLen(shortTitle) > 10)
                    shortTitle := SubStr(shortTitle, 1, 9) . ".."
                opts .= "[" . StrUpper(k) . "]" . shortTitle . " "
            }
        }
        TxtBreadcrumb.Text := ActiveSection . ">" . ActiveModality . " ➔ " . opts
        TxtFooter.Text := "Press Study Key to Open  |  ⌫ Back to Modalities"
    }
}

; ==============================================================================
; Functions: Data Parsing & Catalog Setup
; ==============================================================================

LoadSearchPatternDatabase() {
    global AllStudies, DataFilePath
    if !FileExist(DataFilePath) {
        if FileExist(A_WorkingDir . "\search_patterns.txt")
            DataFilePath := A_WorkingDir . "\search_patterns.txt"
        else {
            selected := FileSelect(1, A_ScriptDir, "Select search_patterns.txt", "Text Documents (*.txt)")
            if (selected = "") {
                MsgBox("Database file 'search_patterns.txt' not found.`nExiting application.", AppTitle, 0x10)
                ExitApp()
            }
            DataFilePath := selected
        }
    }

    content := FileRead(DataFilePath, "UTF-8")
    AllStudies := []
    curStudy := ""

    Loop Parse, content, "`n", "`r" {
        line := Trim(A_LoopField)
        if (line = "")
            continue

        ; Header line: SECTION > MODALITY > TITLE
        parts := StrSplit(line, " > ")
        if (parts.Length == 3 && !RegExMatch(parts[1], "^\d")) {
            curStudy := {
                Section: Trim(parts[1]),
                Modality: Trim(parts[2]),
                Title: Trim(parts[3]),
                Items: []
            }
            AllStudies.Push(curStudy)
            continue
        }

        ; Item line: digits.digits [optional dot] text
        if (IsObject(curStudy) && RegExMatch(line, "^(\d+(?:\.\d+)*)\.?\s*(.*)", &m)) {
            curStudy.Items.Push({
                Num: m[1],
                Text: Trim(m[2])
            })
        }
    }
}

PopulateCatalogTree(filterQuery := "") {
    global TVCatalog, AllStudies, CatalogStudyMap, SecNodeMap, ModNodeMap
    global SectionNameToKey, ModalityKeyMap, StudyKeyMap

    TVCatalog.Delete()
    CatalogStudyMap.Clear()
    SecNodeMap.Clear()
    ModNodeMap.Clear()

    filterQuery := Trim(StrLower(filterQuery))

    for study in AllStudies {
        fullSearchStr := StrLower(study.Section . " " . study.Modality . " " . study.Title)
        if (filterQuery != "" && !InStr(fullSearchStr, filterQuery))
            continue

        ; Ensure Section node exists
        if !SecNodeMap.Has(study.Section) {
            secKey := SectionNameToKey.Has(study.Section) ? StrUpper(SectionNameToKey[study.Section]) : "?"
            sLabel := "[" . secKey . "] 📁 " . study.Section
            sNode := TVCatalog.Add(sLabel, 0, (filterQuery != "" ? "Expand" : ""))
            SecNodeMap[study.Section] := sNode
        }
        sNode := SecNodeMap[study.Section]

        ; Ensure Modality node exists under Section
        modCombo := study.Section . "|" . study.Modality
        if !ModNodeMap.Has(modCombo) {
            modKey := "?"
            if (ModalityKeyMap.Has(study.Section)) {
                for mk, mv in ModalityKeyMap[study.Section] {
                    if (mv == study.Modality) {
                        modKey := StrUpper(mk)
                        break
                    }
                }
            }
            mLabel := "[" . modKey . "] 📂 " . study.Modality
            mNode := TVCatalog.Add(mLabel, sNode, (filterQuery != "" ? "Expand" : ""))
            ModNodeMap[modCombo] := mNode
        }
        mNode := ModNodeMap[modCombo]

        ; Find study key
        stKey := "?"
        if StudyKeyMap.Has(modCombo) {
            for sk, sv in StudyKeyMap[modCombo] {
                if (sv == study.Title) {
                    stKey := StrUpper(sk)
                    break
                }
            }
        }
        stLabel := "[" . stKey . "] 📄 " . study.Title
        stNode := TVCatalog.Add(stLabel, mNode)
        CatalogStudyMap[stNode] := study
    }
    SendMessage(0x111B, 30, 0, TVCatalog.Hwnd)
}

OnSearchChange(ctrl, *) {
    query := ctrl.Value
    PopulateCatalogTree(query)
}

OnWmLButtonUp(wParam, lParam, msg, hwnd) {
    global TVCatalog
    try {
        if (hwnd == TVCatalog.Hwnd) {
            SetTimer(CheckCatalogSelectionAndLoad, -20)
        }
    }
}

OnCatalogDoubleClick(tv, itemHwnd) {
    global CatalogStudyMap
    if (itemHwnd != 0 && CatalogStudyMap.Has(itemHwnd)) {
        LoadStudyAndShowChecklist(CatalogStudyMap[itemHwnd])
    }
}

OnCatalogItemSelect(tv, itemHwnd) {
    global CatalogStudyMap, SecNodeMap, ModNodeMap
    global ActiveSection, ActiveModality, CatalogNavLevel

    if (itemHwnd == 0)
        return

    if CatalogStudyMap.Has(itemHwnd) {
        study := CatalogStudyMap[itemHwnd]
        LoadStudyAndShowChecklist(study)
        return
    }

    for secName, sHwnd in SecNodeMap {
        if (sHwnd == itemHwnd) {
            ActiveSection := secName
            ActiveModality := ""
            CatalogNavLevel := 1
            UpdateCatalogBreadcrumb()
            return
        }
    }

    for comboKey, mHwnd in ModNodeMap {
        if (mHwnd == itemHwnd) {
            parts := StrSplit(comboKey, "|")
            ActiveSection := parts[1]
            ActiveModality := parts[2]
            CatalogNavLevel := 2
            UpdateCatalogBreadcrumb()
            return
        }
    }
}

CheckCatalogSelectionAndLoad() {
    global TVCatalog, CatalogStudyMap
    try {
        selected := TVCatalog.GetSelection()
        if (selected != 0 && CatalogStudyMap.Has(selected)) {
            LoadStudyAndShowChecklist(CatalogStudyMap[selected])
        }
    }
}

OpenSelectedCatalogStudy() {
    global TVCatalog, CatalogStudyMap, SecNodeMap, ModNodeMap
    selected := TVCatalog.GetSelection()
    if (selected != 0) {
        if CatalogStudyMap.Has(selected) {
            LoadStudyAndShowChecklist(CatalogStudyMap[selected])
            return
        }
        for secName, sHwnd in SecNodeMap {
            if (sHwnd == selected) {
                SelectCatalogSection(secName)
                return
            }
        }
        for modCombo, mHwnd in ModNodeMap {
            if (mHwnd == selected) {
                parts := StrSplit(modCombo, "|")
                SelectCatalogModality(parts[2])
                return
            }
        }
    }
}

LoadStudyAndShowChecklist(study) {
    global CurrentStudy
    CurrentStudy := study
    LoadStudyIntoChecklist(study)
    SwitchToView("Checklist")
}

; ==============================================================================
; Progressive Accordion Checklist Engine
; ==============================================================================

LoadStudyIntoChecklist(study) {
    global TVChecklist, TxtStudyTitle, NodeDataMap, CheckedItemMap
    global TopLevelStationList, TotalStudyLeafCount, CheckedStudyLeafCount

    TVChecklist.Delete()
    NodeDataMap.Clear()
    CheckedItemMap.Clear()
    TopLevelStationList := []
    TotalStudyLeafCount := 0
    CheckedStudyLeafCount := 0

    TxtStudyTitle.Text := study.Title
    TxtStudyTitle.ToolTip := study.Section . " > " . study.Modality . " > " . study.Title

    numToHwnd := Map()
    allNodeHwnds := []

    ; First Pass: Insert All Nodes and Resolve Ancestor Hierarchy
    for item in study.Items {
        num := item.Num
        rawText := item.Text

        parentHwnd := 0
        if InStr(num, ".") {
            pNum := SubStr(num, 1, InStr(num, ".", , -1) - 1)
            while (pNum != "") {
                if numToHwnd.Has(pNum) {
                    parentHwnd := numToHwnd[pNum]
                    break
                }
                if InStr(pNum, ".")
                    pNum := SubStr(pNum, 1, InStr(pNum, ".", , -1) - 1)
                else
                    pNum := ""
            }
        }

        displayStr := num . ". " . rawText
        nodeHwnd := TVChecklist.Add(displayStr, parentHwnd)
        numToHwnd[num] := nodeHwnd
        allNodeHwnds.Push(nodeHwnd)

        NodeDataMap[nodeHwnd] := {
            Num: num,
            RawText: rawText,
            IsDrawer: false,
            IsExpanded: true,
            TotalChildren: 0,
            CheckedChildren: 0,
            IsChecked: false
        }
    }

    ; Second Pass: Identify Drawers, Count Leaves, Build Sequential Stations
    for nodeHwnd in allNodeHwnds {
        data := NodeDataMap[nodeHwnd]
        firstChild := TVChecklist.GetChild(nodeHwnd)
        parentHwnd := TVChecklist.GetParent(nodeHwnd)

        if (firstChild != 0) {
            data.IsDrawer := true
            if (parentHwnd == 0) {
                TopLevelStationList.Push(nodeHwnd)
            }
        } else {
            TotalStudyLeafCount++
            if (parentHwnd == 0) {
                TopLevelStationList.Push(nodeHwnd)
            } else {
                pHwnd := parentHwnd
                while (pHwnd != 0) {
                    if NodeDataMap.Has(pHwnd)
                        NodeDataMap[pHwnd].TotalChildren++
                    pHwnd := TVChecklist.GetParent(pHwnd)
                }
            }
        }
    }

    ; Third Pass: Format Drawer Headers with Sequential Tallies
    for nodeHwnd in allNodeHwnds {
        data := NodeDataMap[nodeHwnd]
        if (data.IsDrawer) {
            newLabel := "▾ " . data.Num . ". " . data.RawText . " (0/" . data.TotalChildren . ")"
            TVChecklist.Modify(nodeHwnd, "", newLabel)
        }
    }

    ; Fourth Pass: Expand ALL Stations & Drawers (Entire pattern available to gaze)
    for nodeHwnd in allNodeHwnds {
        if (NodeDataMap[nodeHwnd].IsDrawer) {
            TVChecklist.Modify(nodeHwnd, "Expand")
            NodeDataMap[nodeHwnd].IsExpanded := true
        }
    }

    ; Select the first checkable item at the top
    if (TopLevelStationList.Length > 0) {
        firstStation := TopLevelStationList[1]
        firstLeaf := NodeDataMap[firstStation].IsDrawer ? FindFirstCheckableLeaf(firstStation) : firstStation
        if (firstLeaf != 0)
            TVChecklist.Modify(firstLeaf, "Select Vis")
    }

    ; Re-apply comfortable row height for checklist
    SendMessage(0x111B, 30, 0, TVChecklist.Hwnd)

    UpdateProgressDisplay()
}

ExpandDrawer(drawerHwnd) {
    global TVChecklist, NodeDataMap
    TVChecklist.Modify(drawerHwnd, "Expand")
    if NodeDataMap.Has(drawerHwnd) {
        NodeDataMap[drawerHwnd].IsExpanded := true
        UpdateDrawerHeaderFormat(drawerHwnd, true)
    }
}

UpdateDrawerHeaderFormat(drawerHwnd, isExpanded) {
    global TVChecklist, NodeDataMap
    if !NodeDataMap.Has(drawerHwnd)
        return

    data := NodeDataMap[drawerHwnd]
    isCompleted := (data.TotalChildren > 0 && data.CheckedChildren >= data.TotalChildren)

    glyph := isCompleted ? "✔ " : (isExpanded ? "▾ " : "▸ ")
    newText := glyph . data.Num . ". " . data.RawText . " (" . data.CheckedChildren . "/" . data.TotalChildren . ")"
    TVChecklist.Modify(drawerHwnd, "", newText)
}

; ------------------------------------------------------------------------------
; Checklist Event Handling & Auto-Advance Logic
; ------------------------------------------------------------------------------

OnChecklistItemChecked(tv, itemHwnd, isChecked) {
    global NodeDataMap, CheckedItemMap, CheckedStudyLeafCount

    if !NodeDataMap.Has(itemHwnd)
        return

    itemData := NodeDataMap[itemHwnd]

    if (itemData.IsDrawer) {
        if (isChecked)
            tv.Modify(itemHwnd, "-Check")
        return
    }

    itemData.IsChecked := isChecked
    CheckedItemMap[itemHwnd] := isChecked

    delta := isChecked ? 1 : -1
    CheckedStudyLeafCount += delta

    baseText := itemData.Num . ". " . itemData.RawText
    newText := isChecked ? ("✔ " . baseText) : baseText
    tv.Modify(itemHwnd, "", newText)

    pHwnd := tv.GetParent(itemHwnd)
    while (pHwnd != 0) {
        if NodeDataMap.Has(pHwnd) {
            pData := NodeDataMap[pHwnd]
            pData.CheckedChildren += delta
            UpdateDrawerHeaderFormat(pHwnd, true)
        }
        pHwnd := tv.GetParent(pHwnd)
    }

    UpdateProgressDisplay()

    DllCall("user32\InvalidateRect", "ptr", tv.Hwnd, "ptr", 0, "int", 1)
}

FindNextStation(currentStationHwnd) {
    global TopLevelStationList
    for idx, sHwnd in TopLevelStationList {
        if (sHwnd == currentStationHwnd) {
            if (idx < TopLevelStationList.Length)
                return TopLevelStationList[idx + 1]
            break
        }
    }
    return 0
}

FindFirstCheckableLeaf(parentNodeHwnd) {
    global TVChecklist, NodeDataMap
    child := TVChecklist.GetChild(parentNodeHwnd)
    while (child != 0) {
        if NodeDataMap.Has(child) {
            if (!NodeDataMap[child].IsDrawer && !NodeDataMap[child].IsChecked)
                return child
            if (NodeDataMap[child].IsDrawer) {
                subLeaf := FindFirstCheckableLeaf(child)
                if (subLeaf != 0)
                    return subLeaf
            }
        }
        child := TVChecklist.GetNext(child)
    }
    return 0
}

OnChecklistItemSelect(tv, itemHwnd) {
    ; Selection indicates focus; all items are already visible to gaze
}

OnChecklistItemExpand(tv, itemHwnd, isExpanded) {
    global NodeDataMap
    if NodeDataMap.Has(itemHwnd) {
        NodeDataMap[itemHwnd].IsExpanded := isExpanded
        UpdateDrawerHeaderFormat(itemHwnd, isExpanded)
    }
}

UpdateProgressDisplay() {
    global PrgStatus, TxtProgress, TotalStudyLeafCount, CheckedStudyLeafCount
    if (TotalStudyLeafCount == 0) {
        PrgStatus.Value := 0
        TxtProgress.Text := "0 / 0 completed (0%)"
        return
    }

    pct := Round((CheckedStudyLeafCount / TotalStudyLeafCount) * 100)
    PrgStatus.Value := pct
    TxtProgress.Text := CheckedStudyLeafCount . " / " . TotalStudyLeafCount . " completed (" . pct . "%)"
}

ResetCurrentStudyChecks() {
    global CurrentStudy
    if (IsObject(CurrentStudy)) {
        LoadStudyIntoChecklist(CurrentStudy)
    }
}

; ==============================================================================
; View Management (Catalog vs Checklist)
; ==============================================================================

SwitchToView(viewMode) {
    global TVCatalog, TVChecklist, EditSearch, TxtStudyTitle, TxtBreadcrumb
    global PrgStatus, TxtProgress, BtnBackCatalog, BtnReset, CurrentViewMode, TxtFooter
    global CatalogNavLevel, ActiveSection, ActiveModality

    CurrentViewMode := viewMode

    if (viewMode = "Catalog") {
        TVChecklist.Visible := false
        TxtStudyTitle.Visible := false
        PrgStatus.Visible := false
        TxtProgress.Visible := false
        BtnBackCatalog.Visible := false
        BtnReset.Visible := false

        TxtBreadcrumb.Visible := true
        EditSearch.Visible := true
        TVCatalog.Visible := true

        UpdateCatalogBreadcrumb()
        TVCatalog.Focus()
    } else {
        TxtBreadcrumb.Visible := false
        EditSearch.Visible := false
        TVCatalog.Visible := false

        TxtStudyTitle.Visible := true
        PrgStatus.Visible := true
        TxtProgress.Visible := true
        BtnBackCatalog.Visible := true
        BtnReset.Visible := true
        TVChecklist.Visible := true

        TxtFooter.Text := "Space / Mic: Check & Advance  |  ⌫ Catalog  |  F2 Reset  |  📌 F4"
        TVChecklist.Redraw()
        TVChecklist.Focus()
    }
}

ToggleAlwaysOnTop() {
    global MainGui, IsAlwaysOnTop, BtnPin
    IsAlwaysOnTop := !IsAlwaysOnTop
    if (IsAlwaysOnTop) {
        MainGui.Opt("+AlwaysOnTop")
        BtnPin.Text := "📌"
    } else {
        MainGui.Opt("-AlwaysOnTop")
        BtnPin.Text := "📍"
    }
}

OnGuiResize(guiObj, minMax, width, height) {
    if (minMax == -1 || width < 100 || height < 100)
        return
    pad := 12
    w := width - (pad * 2)

    ; Top Row Controls
    TxtBreadcrumb.Move(pad, 10, w - 36, 24)
    BtnPin.Move(width - pad - 32, 10, 32, 24)

    TxtStudyTitle.Move(pad, 10, w - 165, 26)
    BtnBackCatalog.Move(width - pad - 160, 10, 74, 24)
    BtnReset.Move(width - pad - 82, 10, 48, 24)

    ; Search & Progress Rows
    EditSearch.Move(pad, 38, w, 26)
    PrgStatus.Move(pad, 38, w, 4)
    TxtProgress.Move(pad, 44, w, 18)

    ; TreeViews
    tvCatalogHeight := height - 70 - 28
    tvChecklistHeight := height - 66 - 28

    TVCatalog.Move(pad, 70, w, tvCatalogHeight)
    TVChecklist.Move(pad, 66, w, tvChecklistHeight)

    ; Footer
    TxtFooter.Move(pad, height - 22, w, 18)
}

CleanExit(*) {
    OnMessage(0x004E, OnWmNotifyCustomDraw, 0)
    OnMessage(0x0202, OnWmLButtonUp, 0)
    try MainGui.Hide()
    ExitApp()
}

; ==============================================================================
; Win32 CustomDraw: Native Dark-Mode & Grayed-Out Checked Items
; ==============================================================================

ApplyDarkTheme(guiHwnd, tvHwnd) {
    val := 1
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", guiHwnd, "int", DWMWA_USE_IMMERSIVE_DARK_MODE, "int*", &val, "int", 4)
    DllCall("uxtheme\SetWindowTheme", "ptr", tvHwnd, "wstr", "DarkMode_Explorer", "ptr", 0)
    SendMessage(0x111D, 0, 0x2B2521, tvHwnd)
    SendMessage(0x111E, 0, BGR_TEXT, tvHwnd)
}

OnWmNotifyCustomDraw(wParam, lParam, msg, hwnd) {
    global TVChecklist, CheckedItemMap, NodeDataMap
    global NM_CUSTOMDRAW, CDDS_PREPAINT, CDDS_ITEMPREPAINT
    global CDRF_DODEFAULT, CDRF_NEWFONT, CDRF_NOTIFYITEMDRAW
    global BGR_MUTED, BGR_ACTIVE, BGR_TEXT, BGR_DONE

    try {
        if (!IsSet(TVChecklist) || !TVChecklist || !DllCall("user32\IsWindow", "ptr", TVChecklist.Hwnd))
            return CDRF_DODEFAULT

        hdrHwnd := NumGet(lParam, 0, "UPtr")
        if (hdrHwnd != TVChecklist.Hwnd)
            return CDRF_DODEFAULT

        code := NumGet(lParam, A_PtrSize * 2, "Int")
        if (code != NM_CUSTOMDRAW)
            return CDRF_DODEFAULT

        dwDrawStage := NumGet(lParam, A_PtrSize * 3, "UInt")

        if (dwDrawStage == CDDS_PREPAINT)
            return CDRF_NOTIFYITEMDRAW

        if (dwDrawStage == CDDS_ITEMPREPAINT) {
            itemHwnd := NumGet(lParam, (A_PtrSize == 8 ? 56 : 36), "UPtr")
            clrTextOffset := (A_PtrSize == 8 ? 80 : 48)

            if NodeDataMap.Has(itemHwnd) {
                data := NodeDataMap[itemHwnd]
                targetColor := BGR_TEXT

                if (data.IsDrawer) {
                    if (data.TotalChildren > 0 && data.CheckedChildren >= data.TotalChildren) {
                        targetColor := BGR_DONE
                    } else if (data.HasOwnProp("IsExpanded") && data.IsExpanded) {
                        targetColor := BGR_ACTIVE
                    } else {
                        targetColor := BGR_TEXT
                    }
                } else if (data.IsChecked) {
                    targetColor := BGR_MUTED
                } else {
                    targetColor := BGR_TEXT
                }

                NumPut("UInt", targetColor, lParam, clrTextOffset)
                return CDRF_NEWFONT
            }
            return CDRF_DODEFAULT
        }
    } catch {
        return CDRF_DODEFAULT
    }
    return CDRF_DODEFAULT
}

; ==============================================================================
; Keyboard Shortcuts & Single-Keypress Mappings
; ==============================================================================

#HotIf WinActive("ahk_id " . MainGui.Hwnd)

; F1: Jump directly to Checklist
F1::SwitchToView("Checklist")

; F2: Reset current study for next patient
F2::ResetCurrentStudyChecks()

; F3 or Ctrl+O: Back to Catalog
F3::SwitchToView("Catalog")
^o::SwitchToView("Catalog")

; Ctrl+F: Focus Search Box
^f::{
    SwitchToView("Catalog")
    EditSearch.Focus()
}

; Esc: Minimize/Hide HUD (or if in EditSearch, return to tree)
Esc::{
    if (ControlHasFocus(EditSearch))
        TVCatalog.Focus()
    else
        MainGui.Minimize()
}

#HotIf

; Checklist-Specific Keyboard Controls
#HotIf WinActive("ahk_id " . MainGui.Hwnd) && (CurrentViewMode == "Checklist")

; Space or Enter: Check active item and automatically advance
$Space::AdvanceChecklist()
$Enter::AdvanceChecklist()

; Backspace in Checklist returns to Catalog
$Backspace::SwitchToView("Catalog")

#HotIf

; Catalog Single-Key Navigation Mode (Active when Catalog is visible and not typing in search box)
#HotIf WinActive("ahk_id " . MainGui.Hwnd) && (CurrentViewMode == "Catalog") && !ControlHasFocus(EditSearch)

$Enter::OpenSelectedCatalogStudy()
$Space::OpenSelectedCatalogStudy()
$Backspace::HandleCatalogBack()
$Left::HandleCatalogBack()

$a::HandleCatalogKey("a")
$b::HandleCatalogKey("b")
$c::HandleCatalogKey("c")
$d::HandleCatalogKey("d")
$e::HandleCatalogKey("e")
$f::HandleCatalogKey("f")
$g::HandleCatalogKey("g")
$h::HandleCatalogKey("h")
$i::HandleCatalogKey("i")
$j::HandleCatalogKey("j")
$k::HandleCatalogKey("k")
$l::HandleCatalogKey("l")
$m::HandleCatalogKey("m")
$n::HandleCatalogKey("n")
$o::HandleCatalogKey("o")
$p::HandleCatalogKey("p")
$q::HandleCatalogKey("q")
$r::HandleCatalogKey("r")
$s::HandleCatalogKey("s")
$t::HandleCatalogKey("t")
$u::HandleCatalogKey("u")
$v::HandleCatalogKey("v")
$w::HandleCatalogKey("w")
$x::HandleCatalogKey("x")
$y::HandleCatalogKey("y")
$z::HandleCatalogKey("z")
$1::HandleCatalogKey("1")
$2::HandleCatalogKey("2")
$3::HandleCatalogKey("3")
$4::HandleCatalogKey("4")
$5::HandleCatalogKey("5")
$6::HandleCatalogKey("6")
$7::HandleCatalogKey("7")
$8::HandleCatalogKey("8")
$9::HandleCatalogKey("9")
$0::HandleCatalogKey("0")

#HotIf

AdvanceChecklist() {
    global TVChecklist, NodeDataMap, TopLevelStationList

    focused := TVChecklist.GetSelection()
    if (focused == 0) {
        if (TopLevelStationList.Length > 0) {
            firstStation := TopLevelStationList[1]
            if (NodeDataMap[firstStation].IsDrawer) {
                leaf := FindFirstCheckableLeaf(firstStation)
                if (leaf != 0)
                    TVChecklist.Modify(leaf, "Select Vis")
            } else {
                TVChecklist.Modify(firstStation, "Select Vis")
            }
        }
        return
    }

    if NodeDataMap.Has(focused) {
        data := NodeDataMap[focused]
        if (data.IsDrawer) {
            ExpandDrawer(focused)
            firstLeaf := FindFirstCheckableLeaf(focused)
            if (firstLeaf != 0)
                TVChecklist.Modify(firstLeaf, "Select Vis")
            return
        }

        isNowChecked := !data.IsChecked
        TVChecklist.Modify(focused, isNowChecked ? "Check" : "-Check")
        OnChecklistItemChecked(TVChecklist, focused, isNowChecked)

        if (isNowChecked) {
            nextLeaf := FindNextCheckableItem(focused)
            if (nextLeaf != 0)
                TVChecklist.Modify(nextLeaf, "Select Vis")
        }
    }
}

FindNextCheckableItem(currentLeafHwnd) {
    global TVChecklist, NodeDataMap
    sibling := TVChecklist.GetNext(currentLeafHwnd)
    while (sibling != 0) {
        if (NodeDataMap.Has(sibling) && !NodeDataMap[sibling].IsDrawer && !NodeDataMap[sibling].IsChecked)
            return sibling
        sibling := TVChecklist.GetNext(sibling)
    }

    parentDrawer := TVChecklist.GetParent(currentLeafHwnd)
    while (parentDrawer != 0) {
        nextStation := FindNextStation(parentDrawer)
        while (nextStation != 0) {
            if NodeDataMap.Has(nextStation) {
                if (NodeDataMap[nextStation].IsDrawer) {
                    leaf := FindFirstCheckableLeaf(nextStation)
                    if (leaf != 0)
                        return leaf
                } else if (!NodeDataMap[nextStation].IsChecked) {
                    return nextStation
                }
            }
            nextStation := FindNextStation(nextStation)
        }
        parentDrawer := TVChecklist.GetParent(parentDrawer)
    }
    return 0
}

; Optional Background Global Hotkey (Zero-Focus Theft for PACS Integration)
^!Space::
{
    AdvanceChecklist()
}
