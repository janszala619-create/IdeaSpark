# IdeaSpark KI-Backend mit Vercel

Dieses Repo enthaelt ein kleines Vercel-Backend fuer die KI-Funktion der iOS-App:

```text
POST /api/generate-idea
```

Die iPhone-App sendet Kategorie und Schwierigkeit an diesen Endpunkt. Das Backend ruft OpenAI serverseitig auf und gibt ein `ProjectIdea`-JSON zurueck, das die App direkt decodieren kann.

## Warum ein Backend?

Der OpenAI API-Key darf nicht in die iOS-App. Eine App kann leicht ausgelesen werden. Der Key gehoert deshalb als Secret in Vercel.

## Vercel einrichten

1. Oeffne [vercel.com](https://vercel.com/) und melde dich mit GitHub an.
2. Waehle **Add New... -> Project**.
3. Importiere dein GitHub-Repo `janszala619-create/IdeaSpark`.
4. Vercel erkennt das API-Verzeichnis automatisch.
5. Oeffne im Vercel-Projekt **Settings -> Environment Variables**.
6. Lege diese Variablen an:

```text
OPENAI_API_KEY=dein_openai_api_key
OPENAI_MODEL=gpt-5.2
```

`OPENAI_MODEL` ist optional. Wenn du es nicht setzt, nutzt das Backend `gpt-5.2`.

7. Klicke **Deploy**.
8. Kopiere danach die Vercel-Domain, zum Beispiel:

```text
https://ideaspark-deinname.vercel.app
```

## In der iPhone-App nutzen

1. Oeffne IdeaSpark auf dem iPhone.
2. Gehe zu **Einstellungen**.
3. Aktiviere **AI-Ideen aktivieren**.
4. Trage als Backend-URL deine Vercel-Domain ein, zum Beispiel:

```text
https://ideaspark-deinname.vercel.app
```

Wichtig: Nur die Basis-URL eintragen, nicht `/api/generate-idea`.

5. Gehe zu **Entdecken**.
6. Waehle bei Quelle **AI**.
7. Tippe auf **Neue Idee generieren**.

## Lokal testen

Auf Windows kannst du die Backend-Logik ohne echten OpenAI-Aufruf testen:

```powershell
npm test
```

Ein echter lokaler End-to-End-Test braucht eine gesetzte `OPENAI_API_KEY`-Variable und einen lokalen Vercel/Node-Server. Fuer dein iPhone ist der Vercel-Deploy der einfachere Weg, weil die App eine HTTPS-URL erwartet.

## Request und Response

Die App sendet:

```json
{
  "category": "webApp",
  "difficulty": "beginner"
}
```

Beide Felder duerfen auch fehlen. Das Backend waehlt dann passende Werte.

Die App erwartet:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "BuildBuddy",
  "summary": "Ein kleines Werkzeug, das Checklisten fuer App-Releases generiert.",
  "category": "tool",
  "difficulty": "intermediate",
  "features": ["Release-Checkliste", "Export", "Statusanzeige"],
  "extensionIdea": "Team-Freigaben und GitHub-Integration ergaenzen.",
  "isAIGenerated": true
}
```

Erlaubte Kategorien:

```text
webApp, mobileApp, artificialIntelligence, game, tool, automation
```

Erlaubte Schwierigkeiten:

```text
beginner, intermediate, advanced
```
