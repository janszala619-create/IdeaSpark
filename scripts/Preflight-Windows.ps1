param(
    [string]$ZipPath = "IdeaSpark-source.zip",
    [switch]$SkipZip
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Assert-FileExists {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Missing required file or directory: $Path"
    }
}

function Get-ProjectFiles {
    if (Get-Command rg -ErrorAction SilentlyContinue) {
        return @(rg --files)
    }

    return @(Get-ChildItem -Recurse -File | ForEach-Object {
        $_.FullName.Substring((Get-Location).Path.Length + 1)
    })
}

Write-Step "Checking required project files"
$requiredPaths = @(
    "IdeaSpark",
    "IdeaSpark.xcodeproj\project.pbxproj",
    "IdeaSpark.xcodeproj\xcshareddata\xcschemes\IdeaSpark.xcscheme",
    "IdeaSparkTests",
    "IdeaSpark\Resources\ideas.json",
    "Config\Debug.xcconfig",
    "Config\Release.xcconfig",
    ".github\workflows\ios-ci.yml",
    "README.md",
    "WINDOWS_TESTEN.md",
    "TESTFLIGHT_WINDOWS.md",
    "VERIFICATION.md"
)

foreach ($path in $requiredPaths) {
    Assert-FileExists $path
}
Write-Host "Required files are present."

Write-Step "Validating Xcode scheme XML"
[xml](Get-Content -Raw -LiteralPath "IdeaSpark.xcodeproj\xcshareddata\xcschemes\IdeaSpark.xcscheme") | Out-Null
Write-Host "Scheme XML is valid."

Write-Step "Validating local ideas JSON"
$ideas = Get-Content -Raw -LiteralPath "IdeaSpark\Resources\ideas.json" | ConvertFrom-Json
if ($ideas.Count -lt 20) {
    throw "Expected at least 20 local ideas, found $($ideas.Count)."
}

$requiredCategories = @(
    "webApp",
    "mobileApp",
    "artificialIntelligence",
    "game",
    "tool",
    "automation"
)
$requiredDifficulties = @("beginner", "intermediate", "advanced")
$categories = @($ideas | Select-Object -ExpandProperty category -Unique)
$difficulties = @($ideas | Select-Object -ExpandProperty difficulty -Unique)

foreach ($category in $requiredCategories) {
    if ($categories -notcontains $category) {
        throw "Missing idea category: $category"
    }
}

foreach ($difficulty in $requiredDifficulties) {
    if ($difficulties -notcontains $difficulty) {
        throw "Missing difficulty level: $difficulty"
    }
}

Write-Host "ideas=$($ideas.Count) categories=$($categories -join ',') difficulties=$($difficulties -join ',')"

Write-Step "Checking Swift file membership in Xcode project"
$project = Get-Content -Raw -LiteralPath "IdeaSpark.xcodeproj\project.pbxproj"
$swiftFiles = @(Get-ProjectFiles | Where-Object { $_ -like "*.swift" })
$missingSwiftFiles = @()

foreach ($swiftFile in $swiftFiles) {
    $fileName = Split-Path $swiftFile -Leaf
    if ($project -notmatch [regex]::Escape($fileName)) {
        $missingSwiftFiles += $swiftFile
    }
}

if ($missingSwiftFiles.Count -gt 0) {
    throw "Swift files are missing from the Xcode project: $($missingSwiftFiles -join ', ')"
}

Write-Host "swift_project_membership=all_present count=$($swiftFiles.Count)"

Write-Step "Checking Xcode project markers"
$requiredProjectMarkers = @(
    'productType = "com.apple.product-type.application";',
    'productType = "com.apple.product-type.bundle.unit-test";',
    'IdeaSpark.app',
    'IdeaSparkTests.xctest',
    'PRODUCT_BUNDLE_IDENTIFIER = com.example.IdeaSpark;',
    'PRODUCT_BUNDLE_IDENTIFIER = com.example.IdeaSparkTests;',
    'IPHONEOS_DEPLOYMENT_TARGET = 17.0;',
    'TEST_HOST = "$(BUILT_PRODUCTS_DIR)/IdeaSpark.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/IdeaSpark";',
    'ideas.json in Resources'
)

foreach ($marker in $requiredProjectMarkers) {
    if (-not $project.Contains($marker)) {
        throw "Xcode project is missing required marker: $marker"
    }
}

Write-Host "Xcode project markers are present."

Write-Step "Checking signing settings"
if ($project -match "CODE_SIGNING_ALLOWED\s*=\s*NO;") {
    throw "Project build settings disable code signing. Keep CODE_SIGNING_ALLOWED=NO only as a simulator CI command-line override."
}
Write-Host "Project build settings do not globally disable code signing."

Write-Step "Checking GitHub Actions workflow"
$workflow = Get-Content -Raw -LiteralPath ".github\workflows\ios-ci.yml"
$requiredWorkflowMarkers = @(
    "windows-preflight",
    "runs-on: windows-latest",
    "runs-on: macos-latest",
    "needs: windows-preflight",
    "xcodebuild build",
    "xcodebuild test",
    "CODE_SIGNING_ALLOWED=NO",
    "runtimeMajor",
    "SIMULATOR_RUNTIME",
    "iOS 17 or newer",
    "IdeaSpark-ci-results",
    "TestResults/build.log",
    "TestResults/test.log",
    "TestResults/IdeaSpark.xcresult"
)

foreach ($marker in $requiredWorkflowMarkers) {
    if (-not $workflow.Contains($marker)) {
        throw "GitHub Actions workflow is missing required marker: $marker"
    }
}

Write-Host "GitHub Actions workflow markers are present."

Write-Step "Checking UI accessibility and preview markers"
$uiSources = @(
    "IdeaSpark\Components\CategoryPicker.swift",
    "IdeaSpark\Components\IdeaCardView.swift",
    "IdeaSpark\Components\IdeaRowView.swift",
    "IdeaSpark\Features\Discover\DiscoverView.swift",
    "IdeaSpark\Features\Settings\SettingsView.swift"
) | ForEach-Object {
    Get-Content -Raw -LiteralPath $_
}
$uiSources = $uiSources -join "`n"
$requiredUIMarkers = @(
    '#Preview("Idea Card Light")',
    '#Preview("Idea Card Dark Dynamic Type")',
    '#Preview("Settings Light")',
    '#Preview("Settings Dark Dynamic Type")',
    'accessibilityIdentifier("discover.generateButton")',
    'accessibilityIdentifier("discover.sourcePicker")',
    'accessibilityIdentifier("filters.category")',
    'accessibilityIdentifier("filters.difficulty")',
    'accessibilityIdentifier("idea.card")',
    'accessibilityIdentifier("idea.favoriteButton")',
    'accessibilityIdentifier("idea.row")',
    'accessibilityIdentifier("settings.aiToggle")',
    'accessibilityIdentifier("settings.backendURL")',
    'accessibilityIdentifier("settings.hapticsToggle")'
)

foreach ($marker in $requiredUIMarkers) {
    if (-not ($uiSources -match [regex]::Escape($marker))) {
        throw "UI is missing required accessibility or preview marker: $marker"
    }
}

Write-Host "UI accessibility and preview markers are present."

Write-Step "Checking backend URL safety markers"
$backendSafetySources = @(
    "IdeaSpark\Services\AppConfiguration.swift",
    "IdeaSpark\Features\Settings\SettingsView.swift",
    "IdeaSparkTests\APIIdeaServiceTests.swift"
) | ForEach-Object {
    Get-Content -Raw -LiteralPath $_
}
$backendSafetySources = $backendSafetySources -join "`n"
$requiredBackendSafetyMarkers = @(
    'url.scheme?.lowercased() == "https"',
    '(url.user ?? "").isEmpty',
    'url.password == nil',
    'url.query == nil',
    'url.fragment == nil',
    'https://token@api.example.com',
    'https://api.example.com?token=abc',
    'GenerateIdeaPayload',
    'requestBodyData'
)

foreach ($marker in $requiredBackendSafetyMarkers) {
    if (-not ($backendSafetySources -match [regex]::Escape($marker))) {
        throw "Backend URL safety marker is missing: $marker"
    }
}

Write-Host "Backend URL safety markers are present."

Write-Step "Checking focused test coverage markers"
$testSources = @(
    "IdeaSparkTests\LocalIdeaServiceTests.swift",
    "IdeaSparkTests\APIIdeaServiceTests.swift",
    "IdeaSparkTests\PersistenceTests.swift"
) | ForEach-Object {
    Get-Content -Raw -LiteralPath $_
}
$testSources = $testSources -join "`n"
$requiredTestMarkers = @(
    "testRandomLocalIdeaSelectionReturnsAnIdea",
    "testCategoryFilterLimitsSelection",
    "testDifficultyFilterLimitsSelection",
    "testCombinedCategoryAndDifficultyFilterLimitsSelection",
    "testNoIdeasAvailableForUnmatchedFilters",
    "testAvoidsImmediateRepeatWhenAlternativesExist",
    "testDecodesBundledIdeasJSON",
    "testEmptyLocalIdeasJSONThrowsNoIdeasAvailable",
    "testInvalidLocalIdeasJSONThrowsDecodingFailed",
    "testDecodesAPIResponse",
    "testDecodingFailureIsMapped",
    "testServerErrorIsMapped",
    "testRequestTimeoutStatusIsMapped",
    "testClientErrorIsMappedToInvalidResponse",
    "testNetworkErrorIsMapped",
    "testInvalidBackendURLIsRejected",
    "testAppConfigurationAcceptsOnlyHTTPSBackendURLs",
    "testTimeoutBehavior",
    "testAIGenerationFallsBackToLocalIdeaWhenServiceFails",
    "testDisabledAIGenerationUsesLocalIdea",
    "testDuplicateFavoritesArePrevented",
    "testFavoriteToggleAddsThenRemovesIdea",
    "testRemoveAllClearsFavorites",
    "testHistoryIsCappedAtFiftyIdeas",
    "testHistoryReRecordingSameIdeaKeepsSingleEntry",
    "testHistoryLimitZeroClearsRecordedIdea",
    "testRemoveAllClearsHistory",
    "testFavoriteEntityRoundTripPreservesIdeaFields"
)

foreach ($marker in $requiredTestMarkers) {
    if (-not ($testSources -match [regex]::Escape($marker))) {
        throw "Test suite is missing required coverage marker: $marker"
    }
}

Write-Host "Focused XCTest coverage markers are present."

Write-Step "Scanning for obvious secret patterns"
$scanFiles = @(
    "README.md",
    "WINDOWS_TESTEN.md",
    "TESTFLIGHT_WINDOWS.md",
    "VERIFICATION.md",
    ".github\workflows\ios-ci.yml"
) + @(Get-ChildItem -Path "IdeaSpark", "Config", "IdeaSparkTests", "scripts" -Recurse -File | ForEach-Object { $_.FullName })

$secretPattern = "sk-[A-Za-z0-9]{20,}|OPENAI_API_KEY\s*=|bearer\s+[A-Za-z0-9._-]{20,}|api[_-]?key\s*[:=]\s*['""][^'""]{8,}['""]"
$secretHits = @()

foreach ($file in $scanFiles) {
    $matches = Select-String -LiteralPath $file -Pattern $secretPattern -CaseSensitive:$false -ErrorAction SilentlyContinue
    if ($matches) {
        $secretHits += $matches
    }
}

if ($secretHits.Count -gt 0) {
    $formattedHits = $secretHits | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line)" }
    throw "Potential secret patterns found:`n$($formattedHits -join "`n")"
}

Write-Host "No obvious secret patterns found."

if (-not $SkipZip) {
    Write-Step "Creating source ZIP"
    $zipItems = @(
        ".\IdeaSpark",
        ".\IdeaSpark.xcodeproj",
        ".\IdeaSparkTests",
        ".\Config",
        ".\.github",
        ".\scripts",
        ".\.gitignore",
        ".\README.md",
        ".\WINDOWS_TESTEN.md",
        ".\TESTFLIGHT_WINDOWS.md",
        ".\VERIFICATION.md"
    )
    Compress-Archive -Path $zipItems -DestinationPath $ZipPath -Force
    $zip = Get-Item -LiteralPath $ZipPath
    Write-Host "zip=$($zip.FullName) size=$($zip.Length)"
}

Write-Step "Done"
Write-Host "Preflight checks passed. Use GitHub Actions for the real Xcode build and simulator tests."
