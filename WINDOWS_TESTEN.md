# IdeaSpark auf Windows online testen

Du brauchst keinen eigenen Mac, um den Build und die Tests online zu pruefen. Fuer native iOS-Apps braucht der Build aber irgendwo macOS/Xcode. Das kann GitHub Actions online uebernehmen.

## Variante A: Online Build und Simulator-Tests mit GitHub Actions

1. Fuehre im Projektordner optional den Windows-Preflight aus:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\Preflight-Windows.ps1
   ```

   Das prueft die wichtigsten lokalen Dateien, Projekt-/CI-Marker, Testabdeckungs-Marker und aktualisiert `IdeaSpark-source.zip`.

2. Entpacke `IdeaSpark-source.zip`.
3. Erstelle ein GitHub-Repository.
4. Lade den entpackten Inhalt in das Repository hoch. Wichtig: Die Ordner `.github`, `IdeaSpark`, `IdeaSpark.xcodeproj`, `IdeaSparkTests`, `Config` und `scripts` muessen direkt im Repository liegen.
5. Oeffne in GitHub den Tab `Actions`.
6. Starte den Workflow `iOS CI` manuell oder pushe eine Aenderung.
7. Der Workflow startet zuerst einen Windows-Preflight. Wenn dieser Schritt rot ist, stimmen Dateien, JSON, Projektzuordnung, Testabdeckungs-Marker, Workflow-Marker oder Secret-Scan noch nicht.
8. Wenn der macOS-Job gruen ist, wurde die App online mit Xcode gebaut und die XCTest-Suite auf einem iPhone-Simulator mit iOS 17 oder neuer ausgefuehrt.
9. Wenn der macOS-Job rot ist, lade im fehlgeschlagenen Lauf das Artifact `IdeaSpark-ci-results` herunter. Darin liegen `build.log`, eventuell `test.log` und bei Testlaeufen `IdeaSpark.xcresult`.

Der Workflow liegt hier:

```text
.github/workflows/ios-ci.yml
```

## Variante B: Nur Dateien behalten und spaeter auf iPhone testen

Die Dateien sind vollstaendig im Projektordner und zusaetzlich als ZIP vorhanden:

```text
IdeaSpark-source.zip
```

Du kannst das ZIP weitergeben oder in einen Cloud-Mac-/CI-Dienst hochladen.

## Wichtig fuer echtes iPhone

Ein iPhone installiert keine beliebigen unsignierten iOS-App-Dateien. Fuer einen echten Test auf deinem iPhone brauchst du einen signierten Build. Uebliche Wege:

1. TestFlight ueber einen Apple Developer Account.
2. Ein Cloud-Mac-/CI-Dienst, der mit deinen Apple-Signing-Daten eine signierte IPA oder einen TestFlight-Upload erstellt.
3. Eine andere Person mit Mac und Xcode baut/signiert das Projekt fuer dein Geraet.

Ohne Apple-Signing kannst du den Quellcode erstellen und online im Simulator testen, aber nicht direkt wie bei Android eine unsignierte App-Datei auf dem iPhone installieren.

Mehr Details fuer den Weg von Windows zu TestFlight stehen in:

```text
TESTFLIGHT_WINDOWS.md
```
