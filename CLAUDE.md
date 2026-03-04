# CLAUDE.md — mas-cli appExtVrsId Patcher

This file gives AI assistants the context needed to understand, navigate, and
contribute to this repository effectively.

---

## Project Overview

This is a **patched fork of [mas-cli](https://github.com/mas-cli/mas) v1.9.0**
maintained by [@handyandy87](https://github.com/handyandy87). It adds three
major capabilities on top of the upstream `mas` command-line tool:

| Capability | Flag | Description |
|---|---|---|
| Version override | `--ver <appExtVrsId>` | Pass a specific App Store external version ID to download a historical version of an app |
| Lookup only | `--lookup` | Resolve the version string for a given `--ver` ID without downloading anything |
| Package rescue | automatic | When the App Store install step fails after a successful download, automatically stage the `.pkg` from the App Store cache and extract it to `/Users/Shared/MASExtractedPkgs/` |

**Platform**: macOS 10.13+ only. The tool depends on private Apple frameworks
(`CommerceKit`, `StoreFoundation`) that are not available on other platforms.

---

## Repository Structure

```
.
├── Sources/
│   ├── mas/                        # Main application (Swift)
│   │   ├── MAS.swift               # @main entry point; preprocesses -ver alias
│   │   ├── Commands/               # One file per CLI subcommand (19 commands)
│   │   ├── AppStore/               # App Store integration layer
│   │   │   ├── Downloader.swift    # Top-level download orchestration
│   │   │   ├── SSPurchase.swift    # SSPurchase extension; builds buy parameters
│   │   │   ├── PurchaseDownloadObserver.swift  # CKDownloadQueueObserver; drives UI + rescue
│   │   │   ├── PkgRescuer.swift    # NEW: stages & extracts .pkg on install failure
│   │   │   ├── CKSoftwareMap+SoftwareMap.swift
│   │   │   ├── CKSoftwareProduct+SoftwareProduct.swift
│   │   │   ├── ISStoreAccount.swift
│   │   │   └── Storefront.swift
│   │   ├── Controllers/            # Protocol-based business logic
│   │   ├── Models/                 # Data types (AppID, SearchResult, SoftwareProduct)
│   │   ├── Errors/                 # MASError enum
│   │   ├── Formatters/             # Console output formatting
│   │   ├── Network/                # NetworkSession protocol + URLSession extension
│   │   └── Utilities/              # Finder, ISORegion, ProcessInfo helpers
│   └── PrivateFrameworks/          # Clang module maps + headers for private Apple frameworks
│       ├── CommerceKit/            # CKDownloadQueue, CKPurchaseController, CKSoftwareMap, …
│       └── StoreFoundation/        # SSPurchase, SSDownload, SSDownloadMetadata, …
├── Tests/
│   └── masTests/                   # Quick/Nimble BDD test suite (28 spec files)
│       └── JSON/                   # JSON fixtures for search and lookup endpoints
├── script/                         # Dev scripts (build, test, lint, format, bootstrap, …)
├── docs/
│   ├── style.md                    # Code style guide (authoritative)
│   └── sample.swift                # Annotated style examples
├── .github/workflows/              # CI: build-test, tag-pushed, codeql, release-published
├── Package.swift                   # Swift Package Manager manifest
├── .swiftlint.yml                  # SwiftLint rule configuration
├── .swiftformat / .swift-format    # Auto-formatter configs
├── Brewfile                        # Dev tool dependencies
└── changelog.md                    # Human-readable change history
```

---

## Core Modified Files

These are the files that differ meaningfully from upstream mas-cli v1.9.0:

### `Sources/mas/MAS.swift`
Custom `main(_:)` entry point that rewrites `-ver` → `--ver` in `CommandLine.arguments` before ArgumentParser runs. This allows the single-dash multi-character alias that ArgumentParser does not natively support.

### `Sources/mas/Commands/Install.swift`
Adds two new options to the `install` subcommand:
- `@Option --ver` (`appExtVrsId: Int = 0`) — passed down through the download stack to `SSPurchase.buyParameters`
- `@Flag --lookup` (`lookupOnly: Bool`) — skips the "already installed" check and signals the observer to cancel after reading the version

### `Sources/mas/AppStore/Downloader.swift`
Threads `appExtVrsId` and `lookupOnly` parameters through the three-layer download chain:
`downloadApps(withAppIDs:verifiedBy:…)` → `downloadApps(withAppIDs:…)` → `downloadApp(withAppID:…)`.
Network-error retry logic is suppressed in `lookupOnly` mode.

### `Sources/mas/AppStore/SSPurchase.swift`
Injects `appExtVrsId` into `SSPurchase.buyParameters` as the `appExtVrsId=<value>` query parameter that the App Store daemon uses to select the requested historical version.

### `Sources/mas/AppStore/PurchaseDownloadObserver.swift`
Drives three parallel concerns:
1. **Progress UI** — prints download/install phases and a progress bar.
2. **Lookup-only flow** — on `changedWithAddition` (or first `statusChangedFor` as fallback), reads `bundleVersion` + `title` from `SSDownloadMetadata`, prints `==> Version lookup: <title> (<version>)`, and immediately removes the download.
3. **Package rescue** — starts a `PkgRescuer` when a download is added; on failure calls `rescueAndExtract`, suppresses the download error if rescue succeeds, and interactively prompts the user to embed the receipt into the extracted `.app` bundle.

### `Sources/mas/AppStore/PkgRescuer.swift` *(new file)*
Polls the App Store Darwin user cache directory (`getconf DARWIN_USER_CACHE_DIR`) every 100 ms using a `DispatchSourceTimer` to hard-link the `.pkg` and `receipt` files to a staging area before they can disappear. On rescue:
1. Creates a uniquely named output folder under `/Users/Shared/MASExtractedPkgs/<appID>/<YYYYMMDD-HHmmss-AppName[-version]>/`
2. Copies the receipt alongside the extracted content
3. Extracts the `.pkg` with `xar -xf` then `ditto -x` for each `Payload` file
4. Returns paths for user-facing messages

---

## Development Workflows

### Prerequisites

```bash
brew bundle          # installs swiftlint, swiftformat, etc. from Brewfile
# or
script/bootstrap
```

### Build

```bash
script/build
# equivalent to:
swift build --configuration release
# output: .build/release/mas
```

### Test

```bash
script/test
# equivalent to:
swift test
```

Tests use **Quick** (BDD) and **Nimble** (matchers). Each spec file is named `*Spec.swift`. Mock objects live alongside specs (e.g., `MockAppLibrary`, `MockAppStoreSearcher`).

### Lint

```bash
script/lint         # runs SwiftLint, ShellCheck, yamllint, markdownlint
```

SwiftLint is configured in `.swiftlint.yml`. Most rules are set to `warning` severity. Fix warnings before committing.

### Format

```bash
script/format       # runs swiftformat + swift-format (auto-fixes)
```

Always run format before committing Swift changes.

### Clean

```bash
script/clean
```

---

## Code Conventions

Sourced from `docs/style.md` (authoritative) and `docs/sample.swift`.

### Swift

- **No force-unwraps** in production code (under `Sources/mas/`). Force-unwraps are *encouraged* in tests.
- Prefer `struct` over `class`. Default new classes to `final`.
- Prefer protocol conformance over class inheritance.
- **Line length**: 120 characters max.
- **Indentation**: 4 spaces (no tabs).
- **Immutability**: use `let` wherever possible.
- **Closures**: use trailing closure syntax.
- **Type inference**: let the compiler infer types when possible.
- **Acronyms**: follow the capitalisation of the first letter (e.g., `appID`, `JSON`, `url`).
- **Void**: use `()` for void arguments, `Void` for void return types.
- **Weak references**: strongify a weak reference once before using it multiple times in the same scope.
- **Computed properties**: place below stored properties, with a blank line above and below.
- **Access-control extensions**: group functions into separate `extension` blocks per access level.

### Async / Promises

The codebase uses **PromiseKit 8** throughout — not Swift's `async`/`await`. All asynchronous operations return `Promise<T>` or `Guarantee<T>`. PromiseKit is configured in `MAS.initialize()` to dispatch on `DispatchQueue.global()`.

### Error Handling

All domain errors are cases of `MASError` (`Sources/mas/Errors/MASError.swift`). Prefer throwing or rejecting with a `MASError` over `fatalError` in production paths.

### CLI Arguments

Commands are implemented as `ParsableCommand` structs nested inside the `MAS` struct. Each command:
- Declares `@Flag`, `@Option`, and `@Argument` properties for its interface.
- Implements `run()` for the real entry point and a testable `run(appLibrary:searcher:)` overload.

### Testing Patterns

- Spec files mirror the source layout: `Tests/masTests/Commands/InstallSpec.swift` tests `Sources/mas/Commands/Install.swift`.
- Use `describe` / `context` / `it` blocks (Quick DSL).
- Inject dependencies via the testable `run(appLibrary:searcher:)` overloads.
- JSON fixtures live in `Tests/masTests/JSON/` and are loaded by `Bundle+JSON`.

---

## Dependencies

| Package | Version | Role |
|---|---|---|
| `swift-argument-parser` | ≥ 1.5.0 | CLI parsing |
| `PromiseKit` | ≥ 8.1.2 | Async/Promise primitives |
| `Version` | ≥ 2.1.0 | Semantic version parsing & comparison |
| `Regex` | ≥ 2.1.1 | Regex helpers |
| `IsoCountryCodes` | ≥ 1.0.2 | ISO 3166 country code data |
| `Quick` | ≥ 5.0.1 | BDD test framework (test only) |
| `Nimble` | ≥ 10.0.0 | Matcher assertions (test only) |

**Private frameworks** (linked from `/System/Library/PrivateFrameworks`):
- `CommerceKit` — App Store download queue, purchase controller, software map
- `StoreFoundation` — `SSPurchase`, `SSDownload`, `ISStoreAccount`, etc.

Header stubs live in `Sources/PrivateFrameworks/` and are exposed via `-I` compiler flags in `Package.swift`.

---

## CI/CD

| Workflow | Trigger | Actions |
|---|---|---|
| `build-test.yml` | push / PR | bootstrap → build → test → lint on `macos-15` arm64 |
| `tag-pushed.yml` | version tag `v*.*.*` | validate SSH sig, build universal binary, create `.pkg`, bump Homebrew, draft release |
| `codeql.yml` | schedule | static security analysis |
| `release-published.yml` | release published | post-release automation |

---

## Key Behaviours to Know

1. **`-ver` alias**: `MAS.main(_:)` rewrites `-ver` to `--ver` before ArgumentParser parses args. Do not add a separate `@Option(name: .shortAndLong)` — this would conflict.

2. **`appExtVrsId` default**: The default is `0`. When `0` is passed in `SSPurchase.buyParameters`, the App Store daemon returns the current version, matching upstream behaviour.

3. **Polling interval**: `PkgRescuer` polls every 100 ms with a 50 ms leeway. The timer runs for up to 60 seconds and stops early once both `.pkg` and `receipt` are staged.

4. **Rescue output root**: `/Users/Shared/MASExtractedPkgs/` — world-writable location chosen so extraction works regardless of which user or sudo context runs `mas`.

5. **Receipt embedding**: Only offered when `isatty(stdin)` is true. Never forced. The receipt is copied into `<App>.app/Contents/_MASReceipt/receipt`.

6. **Lookup-only cancellation**: In `--lookup` mode, `PurchaseDownloadObserver` removes the download from `CKDownloadQueue` immediately after reading metadata. The resulting `.cancelled` status is treated as success (not an error).

7. **Retry logic**: `downloadApp` retries up to 3 times on `NSURLErrorDomain` failures. Retries are skipped entirely in `lookupOnly` mode.

---

## Useful Commands Cheat Sheet

```bash
# Build and run locally
swift build --configuration release
.build/release/mas install <appID>
.build/release/mas install <appID> --ver <appExtVrsId>
.build/release/mas install <appID> --ver <appExtVrsId> --lookup

# Run tests
swift test

# Lint everything
script/lint

# Auto-format Swift
script/format

# Clean build artifacts
script/clean

# View installed apps
.build/release/mas list

# Search for an app
.build/release/mas search <query>
```

---

## Out-of-Scope / Do Not Change

- **Do not** use `async`/`await`. The codebase is PromiseKit-based; mixing paradigms will cause subtle queue deadlocks.
- **Do not** add force-unwraps (`!`) in `Sources/mas/` production code.
- **Do not** link additional private Apple frameworks without updating both `Package.swift` and the corresponding header stubs in `Sources/PrivateFrameworks/`.
- **Do not** push directly to `master`. All changes go through feature branches and CI.
