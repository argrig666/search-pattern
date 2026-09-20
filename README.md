# RadSearch (Radiology Search Pattern Assistant)

> An ergonomic, low-cognitive-load, distraction-free search pattern checklist for radiologists on Windows PACS diagnostic workstations.

[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue.svg)](https://www.autohotkey.com/v2/)
[![Language](https://img.shields.io/badge/language-AutoHotkey%20v2-green.svg)](https://www.autohotkey.com/v2/)
[![Database](https://img.shields.io/badge/studies-107%20exams-orange.svg)](search_patterns.txt)

---

## 📖 Quick Links & Documentation

- **[PROJECT_GUIDE.md](PROJECT_GUIDE.md)**: **Authoritative Project Manual & Architecture Guide**
  - Clinical rationale, cognitive ergonomics, and satisfaction-of-search prevention.
  - Complete data pipeline (`search pattern.pdf` ➔ `build_search_patterns.py` ➔ `search_patterns.txt` ➔ `generate_script.py` ➔ `RadSearch_ProgressiveAccordion.ahk`).
  - Cross-machine synchronization instructions (Git, portable USB, cloud drive, SMB).
  - Operational playbook and invariants for developers and AI agents.
- **[README_RadSearch.md](README_RadSearch.md)**: **End-User Quick Reference & Cheatsheet**
  - Single-key drill-down tables (`N` ➔ `C` ➔ `H` = CT Head).
  - Keyboard shortcuts (`Ctrl + Alt + Space`, `F1`, `F2`, `F3`, `F4`).
  - Nuance PowerMic, Philips SpeechMike, and foot pedal configuration.

---

## ⚡ Quick Start on Windows

### Option 1: Standard (AutoHotkey v2 Installed)
1. Install [AutoHotkey v2](https://www.autohotkey.com/v2/).
2. Double-click [`RadSearch_ProgressiveAccordion.ahk`](RadSearch_ProgressiveAccordion.ahk) (or run [`Run_RadSearch.bat`](Run_RadSearch.bat)).

### Option 2: Zero-Install Portable (No Admin Rights Needed)
1. Download portable AutoHotkey v2 from [autohotkey.com/download/ahk-v2.zip](https://www.autohotkey.com/download/ahk-v2.zip).
2. Extract `AutoHotkey64.exe` directly into this folder.
3. Double-click [`Run_RadSearch.bat`](Run_RadSearch.bat).

---

## 🔄 Synchronizing Across Machines

To keep this repository and runtime updated across your development boxes and reading stations:

```bash
# Push updates from development machine:
git add .
git commit -m "Update search patterns"
git push origin main

# Pull updates on Windows PACS workstation:
git pull origin main
# (or double-click sync_and_run.bat)
```

See [PROJECT_GUIDE.md](PROJECT_GUIDE.md#5-multi-machine-synchronization-guide) for full multi-machine setup instructions.
