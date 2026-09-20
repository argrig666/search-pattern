# RadSearch - Progressive Accordion Search Pattern for PACS Workstations

An ergonomic, low-cognitive-load search pattern checklist for radiologists, implemented in **AutoHotkey v2**.

---

## 🌟 Key Features

1. **Fully Expanded, Gaze-Available Search Pattern:**
   - When entering a study, **every station and sub-item is immediately expanded**, presenting the complete search pattern to the radiologist's gaze to establish an immediate mental model.
   - Checked items are instantly **greyed out** (muted dark slate `#5C6370`) and tagged with `✔`.
   - Stations **never auto-collapse**, keeping the entire anatomical structure visible at all times.
   - Station headers clearly display progress (e.g. `▾ 1. SCOUT & BONES (2/4)` and turn soft sage green `✔ 1. SCOUT & BONES (4/4)` when complete).

2. **Minimalist, High-DPI Typography & Ergonomics:**
   - **Large, crystal-clear 12pt font** (`Segoe UI`) with generous **30px line height** for effortless reading at diagnostic viewing distances.
   - Bulky buttons removed in favor of clean, flat, modern controls that maximize screen real estate.
   - Native Windows 10/11 dark mode palette (`#181A1F` / `#21252B`) preserves dark-adaptation for subtle contrast perception on diagnostic PACS monitors.
   - Ultra-slim accent progress bar + completion tally.

3. **Single-Keypress Hierarchical Drill-Down (Zero Typing Required):**
   - Jump through the study catalog using single, conflict-free keystrokes:
     - **Level 1 (Section):** `[N]` Neuro, `[B]` Body, `[C]` Chest, `[M]` MSK, `[H]` Cardiac, `[U]` US, `[P]` Peds, `[R]` Breast, `[X]` Nuc Med, `[V]` Periph Vasc, `[W]` Workflow.
     - **Level 2 (Modality):** e.g., in Neuro: `[C]` CT, `[M]` MRI, `[R]` Radiograph.
     - **Level 3 (Study):** e.g., in Neuro > CT: `[H]` Head, `[T]` Temporal, `[N]` Neck, `[C]` C-Spine, `[O]` Thoracic, `[L]` L-Spine, `[A]` CTA Head/Neck.
   - **Example:** Press `N` ➔ `C` ➔ `H` to immediately open **CT HEAD**.
   - **Dynamic Breadcrumb HUD:** A live status bar at the top displays currently available single keys at every level.
   - **Forgiving Navigation:** Press `Backspace` or `Left Arrow` to step back a level. Pressing any section key at any time immediately switches to that section.

4. **Complete 113-Study Hierarchical Database:**
   - Automatically loads all 113 studies and 5,800+ checklist items directly from `search_patterns.txt`.
   - Browse via hierarchical catalog with mouse or keyboard, or type in the fuzzy search box (`Ctrl + F`).
   - Single-click or double-click any study item to open it immediately.

5. **Zero-Focus-Theft Dictation & PACS Integration:**
   - Pressing the **Global Hotkey** (`Ctrl + Alt + Space`, or mapped to `F12` / dictation microphone button) checks off the current item and advances **without stealing window focus from PACS**.

---

## ⚡ Single-Key Drill-Down Quick Reference

### Level 1: Sections
| Key | Section | Key | Section |
| :---: | :--- | :---: | :--- |
| **`B`** | BODY | **`X`** | NUCLEAR MEDICINE |
| **`C`** | CHEST | **`P`** | PEDIATRIC |
| **`N`** | NEURO | **`V`** | PERIPHERAL VASCULAR |
| **`M`** | MSK | **`U`** | ULTRASOUND |
| **`H`** | CARDIAC (HEART) | **`W`** | WORKFLOW OPTIMIZATION |
| **`R`** | BREAST | | |

### Level 2: Modalities (Context-Aware)
| Section | Keys & Modalities |
| :--- | :--- |
| **NEURO** | `[C]` CT &emsp; `[M]` MRI &emsp; `[R]` Radiograph |
| **BODY** | `[C]` CT &emsp; `[M]` MRI &emsp; `[R]` Radiograph &emsp; `[F]` Fluoroscopy |
| **CHEST** | `[C]` CT &emsp; `[M]` MRI &emsp; `[R]` Radiograph |
| **MSK** | `[M]` MRI &emsp; `[R]` Radiograph |
| **CARDIAC** | `[C]` CT &emsp; `[M]` MRI |
| **ULTRASOUND** | `[B]` Body/General &emsp; `[V]` Vascular &emsp; `[T]` Transplant |
| **PEDIATRIC** | `[C]` CT &emsp; `[M]` MRI &emsp; `[R]` Radiograph &emsp; `[U]` Ultrasound &emsp; `[F]` Fluoroscopy |
| **BREAST** | `[M]` Mammography/US &emsp; `[R]` MRI |
| **NUCLEAR** | `[C]` Common/Emergent &emsp; `[G]` General NM &emsp; `[P]` PET/CT |

### Rapid Workflow Examples:
- **`N` ➔ `C` ➔ `H`** = CT Head
- **`B` ➔ `C` ➔ `A`** = CT Abdomen/Pelvis
- **`C` ➔ `R` ➔ `C`** = Chest Radiograph
- **`C` ➔ `C` ➔ `P`** = CTA PE (Pulmonary Embolism)
- **`M` ➔ `R` ➔ `K`** = Knee Radiograph
- **`M` ➔ `M` ➔ `S`** = MRI Shoulder
- **`U` ➔ `B` ➔ `A`** = Ultrasound Abdomen
- **`⌫` (Backspace)** = Step back up one level (or back to Catalog from Checklist)

---

## ⌨️ Hotkey Cheatsheet

| Shortcut | Action | Where |
| :--- | :--- | :--- |
| **`Single Keys`** (`a`-`z`) | Instant section ➔ modality ➔ study drill-down | Catalog Mode |
| **`Backspace`** / **`Left`** | Step back one level (Study ➔ Modality ➔ Section) | Catalog Mode |
| **`Backspace`** | Return to Catalog from Checklist | Checklist Mode |
| **`Space`** or **`Enter`** | Check focused item & auto-advance to next station | Checklist Mode |
| **`Enter`** | Open highlighted study or expand highlighted node | Catalog Mode |
| **`F1`** | Switch view directly to **Checklist** | RadSearch Window |
| **`F2`** | **Reset** all checks (clears checklist for next patient) | RadSearch Window |
| **`F3`** or **`Ctrl + O`** | Open **Catalog** / Study Switcher | RadSearch Window |
| **`Ctrl + F`** | Jump to Study Fuzzy Search / Filter Box | RadSearch Window |
| **`F4`** (or Pin button) | Toggle **Always-On-Top** | RadSearch Window |
| **`Esc`** | Minimize / Hide HUD | RadSearch Window |
| **`Ctrl + Alt + Space`** | **Global Background Check & Advance** (Zero-focus theft from PACS) | **Anywhere** (PACS, PowerScribe) |

---

## 🚀 How to Run on Windows

1. Ensure **AutoHotkey v2** is installed ([download from autohotkey.com](https://www.autohotkey.com/v2/)).
2. Place both files in the same folder:
   - `RadSearch_ProgressiveAccordion.ahk`
   - `search_patterns.txt`
3. Double-click `RadSearch_ProgressiveAccordion.ahk`.

---

## 🎙️ Dictation Mic & Foot Pedal Mapping

To advance the search pattern while scrolling with your mouse in PACS, map a button on your **Philips SpeechMike**, **Nuance PowerMic**, or **Foot Pedal** to trigger the global hotkey:

In your existing AutoHotkey script or mic configuration, map a button to send:
```autohotkey
Send "^!{Space}"   ; Triggers Ctrl+Alt+Space in RadSearch
```
Or edit the bottom of `RadSearch_ProgressiveAccordion.ahk` to use any preferred key (e.g., `F12::AdvanceChecklist()`).
