# IdeaSpark

IdeaSpark is a native iOS 17 SwiftUI MVP for discovering software project ideas. It generates ideas from a bundled local dataset, stores favorites and history with SwiftData, and can optionally call a configurable backend endpoint for AI-generated ideas.

## Architecture

- `IdeaSpark/App`: app entry point, tab shell, and root SwiftData container.
- `IdeaSpark/Models`: `ProjectIdea`, `IdeaCategory`, `DifficultyLevel`, loading state, and generation errors.
- `IdeaSpark/Services`: local JSON generation, URLSession-backed API generation, app configuration, and haptics.
- `IdeaSpark/Persistence`: SwiftData entities and small store helpers for favorites and capped history.
- `IdeaSpark/Features`: Discover, Favorites, History, and Settings screens.
- `IdeaSpark/Components`: reusable cards, rows, badges, pickers, detail, and empty states.
- `IdeaSpark/Resources/ideas.json`: 22 local example ideas across all required categories.
- `IdeaSparkTests`: focused XCTest coverage for generation, filters, decoding, API failures/timeouts, duplicate favorites, and history capping.

The app intentionally keeps the architecture feature-oriented and small: SwiftUI owns UI state, services own generation/networking, and SwiftData helpers own persistence rules.

## Run

1. Open `IdeaSpark.xcodeproj` in Xcode 15 or newer.
2. Select the `IdeaSpark` scheme.
3. Choose an iPhone simulator running iOS 17 or newer.
4. Build and run.

The app is fully usable without a backend because local idea generation is the default source.

## Windows and Online Testing

You do not need a local Mac just to check whether the project compiles and the tests pass. Push this folder to GitHub and run the included workflow:

```text
.github/workflows/ios-ci.yml
```

The workflow uses a hosted macOS runner, selects an available iPhone simulator running iOS 17 or newer, builds the `IdeaSpark` scheme, and runs the XCTest suite.
It first runs the same Windows preflight checks in a `windows-latest` job, then uploads `IdeaSpark-ci-results` with build/test logs and any generated `.xcresult` bundle.
The project itself does not globally disable code signing; the CI passes `CODE_SIGNING_ALLOWED=NO` only for unsigned simulator builds.

Before uploading from Windows, you can run the local preflight script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Preflight-Windows.ps1
```

It validates the project files, local ideas JSON, Xcode scheme XML, Swift project membership, Xcode/CI markers, focused XCTest coverage markers, obvious secret patterns, and refreshes `IdeaSpark-source.zip`.

Installing the app on a real iPhone is a separate distribution step. Native iOS apps need Apple code signing. The usual path without owning a Mac is:

1. Run the GitHub Actions workflow to verify build and tests.
2. Use an Apple Developer account plus TestFlight or another cloud macOS signing service to create and distribute a signed build.
3. Install the beta from the TestFlight app on your iPhone.

Without Apple signing, the source files can be created and shared, but iOS will not install an arbitrary unsigned app package on your iPhone.

See `TESTFLIGHT_WINDOWS.md` for the recommended Windows-to-iPhone testing path.
See `VERIFICATION.md` for the latest local Windows verification evidence and the remaining macOS/Xcode gate.
See `AI_BACKEND_VERCEL.md` for the Vercel/OpenAI backend used by the optional AI idea generation setting.

## Backend Configuration

The iOS app never stores AI provider secrets. It only sends requests to your own backend:

```text
POST /api/generate-idea
```

This repository includes a Vercel-compatible backend at `api/generate-idea.js`.
Deploy it from GitHub, set `OPENAI_API_KEY` as a Vercel environment variable, then enter the deployed Vercel base URL in the IdeaSpark Settings tab.

Configure the base URL in one of two places:

- Build config: `Config/Debug.xcconfig` and `Config/Release.xcconfig` set `IDEASPARK_API_BASE_URL`.
- Runtime development setting: Settings tab -> Backend-URL.

The API service requires HTTPS, rejects backend URLs with embedded credentials, query strings, or fragments, and maps server, network, decoding, invalid response, and timeout failures to user-friendly fallback behavior.

## Tests

Run the `IdeaSparkTests` test target from Xcode. The current tests cover:

- random local idea selection
- category filtering
- difficulty filtering
- avoiding immediate repeats when alternatives exist
- decoding bundled local JSON
- handling empty or malformed local JSON
- decoding API responses
- mapping malformed API JSON
- mapping API server errors
- mapping API timeout and client-error status codes
- mapping API network errors
- rejecting non-HTTPS backend URLs
- rejecting backend URLs with embedded credentials or URL parameters
- timeout behavior
- falling back to local ideas when AI generation fails or is disabled
- duplicate favorite prevention
- favorite toggle and clear-all behavior
- capping history to 50 items
- history duplicate replacement and clear-all behavior
- persistence entity round-tripping

## Verification Status

Local artifact checks passed in this workspace:

- shared Xcode scheme XML is valid
- `ideas.json` parses with 22 ideas
- all six categories and all three difficulty levels are represented
- all Swift files are referenced by `IdeaSpark.xcodeproj`
- light/dark Dynamic Type previews and key accessibility identifiers are present
- backend URL safety markers are present
- focused XCTest coverage markers are present
- no obvious API key or secret patterns were found

Simulator build/run and XCTest execution still need to be completed on a machine where `xcodebuild` and `xcrun` are available.
