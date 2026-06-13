# IdeaSpark Verifikationsstatus

Stand: 2026-06-14, Windows-Workspace.

## Lokal auf Windows ausgefuehrt

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Preflight-Windows.ps1
```

Ergebnis: bestanden.

Geprueft wurden:

- erforderliche Projektdateien
- Xcode-Scheme-XML
- `ideas.json` mit 22 Ideen
- alle sechs Kategorien und alle drei Schwierigkeitsgrade
- Swift-Dateimitgliedschaft im Xcode-Projekt
- Xcode-Projektmarker fuer App- und Test-Target
- Signing-Einstellung ohne globales `CODE_SIGNING_ALLOWED=NO`
- GitHub-Actions-Workflowmarker
- iPhone-Simulator-Auswahl mit iOS 17 oder neuer
- UI-Accessibility- und Light/Dark-Preview-Marker
- Backend-URL-Sicherheitsmarker ohne eingebettete Zugangsdaten, Query oder Fragment
- fokussierte XCTest-Abdeckungsmarker inklusive Favoriten-/Verlauf-Persistence
- offensichtliche Secret-/API-Key-Muster
- ZIP-Erstellung als `IdeaSpark-source.zip`

## Lokal nicht moeglich

Dieser Windows-Host hat keine lokale Apple-Toolchain:

- `xcodebuild` nicht gefunden
- `xcrun` nicht gefunden
- `swift` nicht gefunden

Der MCP-Versuch mit Projekt `IdeaSpark.xcodeproj`, Scheme `IdeaSpark` und iPhone-15-Simulator wurde gestartet, scheitert aber ebenfalls an der fehlenden Toolchain:

```text
build_run_sim: spawn xcodebuild ENOENT
test_sim: spawn xcrun ENOENT
```

## Noch zur vollstaendigen Zielerfuellung offen

Die vollstaendige Zielverifikation braucht macOS/Xcode:

```bash
xcodebuild build \
  -project IdeaSpark.xcodeproj \
  -scheme IdeaSpark \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  CODE_SIGNING_ALLOWED=NO

xcodebuild test \
  -project IdeaSpark.xcodeproj \
  -scheme IdeaSpark \
  -configuration Debug \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  CODE_SIGNING_ALLOWED=NO
```

Alternativ kann der enthaltene GitHub-Actions-Workflow `iOS CI` diese Schritte online auf einem gehosteten macOS-Runner ausfuehren.
