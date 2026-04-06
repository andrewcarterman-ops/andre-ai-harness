# Visual Studio Build Tools - Installationsanleitung

## WICHTIG: Diese Komponenten MÜSSEN ausgewählt werden:

### Workloads (Hauptkategorien):
☑️ **Desktop-Entwicklung mit C++**
   - Enthält: MSVC, Windows SDK, CMake

### Einzelne Komponenten (Optional aber empfohlen):
☑️ MSVC v143 - VS 2022 C++ x64/x86 Build Tools
☑️ Windows 11 SDK (oder Windows 10 SDK)
☑️ C++ CMake Tools für Windows

## Installationsschritte:

1. **vs_buildtools.exe** starten
2. Auf **"Weiter"** klicken
3. Bei **Workloads**: ☑️ "Desktop-Entwicklung mit C++" ankreuzen
4. Rechts unten auf **"Installieren"** klicken
5. **Warten** (dauert 10-20 Minuten je nach Internet)
6. **Neustart** der Shell/Terminal nach Installation

## Nach der Installation testen:

In PowerShell:
```powershell
# Prüfen ob link.exe gefunden wird
where.exe link

# Oder:
cmd /c where link

# Sollte ausgeben:
# C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\...\bin\Hostx64\x64\link.exe
```

## Falls link.exe nicht gefunden wird:

**Option A: Visual Studio Developer Command Prompt verwenden**
- Startmenü → "Developer Command Prompt for VS 2022" oder "x64 Native Tools Command Prompt"
- In diesem Terminal: `cargo check`

**Option B: Environment Variables setzen**
```powershell
# Pfad anpassen je nach Installationsversion:
$env:PATH = "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.43.34808\bin\Hostx64\x64;$env:PATH"
```

**Option C: Rust auf GNU-Toolchain umstellen**
```powershell
# Statt MSVC, MinGW verwenden:
rustup default stable-x86_64-pc-windows-gnu
```
(Dann brauchst du aber MinGW installiert)

## Empfehlung:

**Option A ist am einfachsten**: Developer Command Prompt verwenden!
