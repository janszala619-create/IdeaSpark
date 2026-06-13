# IdeaSpark auf einem echten iPhone testen

Diese Datei beschreibt den realistischen Weg, wenn du auf Windows arbeitest und keinen eigenen Mac verwenden moechtest.

## Was schon vorbereitet ist

- Der Quellcode liegt als natives iOS-17-SwiftUI-Projekt vor.
- `.github/workflows/ios-ci.yml` kann online auf macOS bauen und die Tests im iPhone-Simulator ausfuehren.
- Das Xcode-Projekt deaktiviert Code Signing nicht global.
- API-Secrets werden nicht in der App gespeichert.

## Was fuer ein echtes iPhone zusaetzlich noetig ist

iOS installiert keine unsignierten App-Dateien. Fuer dein echtes iPhone brauchst du deshalb:

1. Einen Apple Developer Account.
2. Eine App-ID beziehungsweise ein Bundle Identifier in Apple Developer / App Store Connect.
3. Code Signing ueber Apple-Zertifikate und Provisioning Profiles oder ueber Xcode Cloud.
4. Einen Upload zu App Store Connect.
5. TestFlight zum Installieren auf deinem iPhone.

Apple beschreibt TestFlight als Beta-Verteilung fuer Apps und App Clips. Builds koennen in App Store Connect hochgeladen und Testern zugewiesen werden. Xcode Cloud kann Build, Tests und TestFlight-Verteilung in Apples Infrastruktur verbinden.

Offizielle Einstiege:

- TestFlight: https://developer.apple.com/testflight/
- TestFlight Overview in App Store Connect Help: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
- Xcode Cloud: https://developer.apple.com/documentation/Xcode/Xcode-Cloud/
- Xcode Cloud Overview: https://developer.apple.com/xcode-cloud/

## Empfohlener Ablauf ohne eigenen Mac

1. Fuehre lokal auf Windows aus:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\Preflight-Windows.ps1
   ```

2. Lade den entpackten Inhalt von `IdeaSpark-source.zip` in ein GitHub-Repository.
3. Starte in GitHub Actions den Workflow `iOS CI`.
4. Wenn `iOS CI` gruen ist, ist der Simulator-Build/Test online bestanden.
5. Richte danach App Store Connect und TestFlight ein.
6. Nutze Xcode Cloud oder einen vertrauenswuerdigen Cloud-macOS-Dienst fuer den signierten Archive-/Upload-Schritt.
7. Installiere die App ueber die TestFlight-App auf deinem iPhone.

## Was du nicht tun solltest

- Keine Apple-Zertifikate, Provisioning Profiles oder App-Store-Connect-API-Keys in das Repository committen.
- Keine AI-Provider-API-Keys in die iOS-App schreiben.
- Keine zufaelligen IPA-Dateien aus unbekannten Diensten auf deinem Apple Account signieren lassen.

## Warum es keinen fertigen TestFlight-Workflow gibt

Ein TestFlight-Upload braucht Apple-spezifische Signing-Daten. Diese Daten sind persoenlich und muessen sicher als GitHub Secrets oder in Xcode Cloud hinterlegt werden. Ohne deine Apple-Team-ID, App-ID, Zertifikate und Profile waere ein automatischer Workflow nur scheinbar fertig und wuerde beim ersten Upload scheitern.

Sobald diese Daten vorhanden sind, kann ein separater Release-Workflow ergaenzt werden. Der aktuelle `iOS CI` Workflow bleibt bewusst auf Build und Simulator-Tests ohne Secrets beschraenkt.
