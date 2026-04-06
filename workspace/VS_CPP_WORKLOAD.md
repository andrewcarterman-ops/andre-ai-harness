# Visual Studio - C++ Workload hinzufügen

## Schritt-für-Schritt:

### 1. Visual Studio Installer öffnen
- Startmenü → "Visual Studio Installer" oder
- `C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe`

### 2. Auf "Ändern" klicken
Sollte ein Button "Ändern" oder "Modify" bei deiner Installation sein.

### 3. Workloads auswählen
☑️ **Desktop-Entwicklung mit C++** 
   (Haken setzen!)

### 4. Rechts Details prüfen
Diese sollten angehakt sein:
- ☑️ MSVC v143 - VS 2022 C++ x64/x86 Build Tools (Latest)
- ☑️ Windows 11 SDK (10.0.22621.0)

### 5. "Ändern" klicken
Warten bis Installation fertig ist (5-10 Minuten)

### 6. NEU STARTEN
Terminal/PowerShell komplett schließen und neu öffnen!

## Danach testen:

```powershell
# In NEUEM Terminal:
$env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"
cd ~/.openclaw/workspace/crates/tool-registry
cargo check
```

Sollte jetzt funktionieren!
