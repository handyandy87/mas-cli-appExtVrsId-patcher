# Changelog

## [mas-1.9.0-handyandy87-ver-rescue] - 2026-02-03

This release extends MAS 1.9.0 with two main capabilities added:

1) A runtime `--ver` override for the `appExtVrsId` parameter used during App Store purchase/download initiation.  
2) An automatic “rescue + extract” workflow that stages the App Store cached `.pkg` + receipt during download and, on post-download failure, extracts the package to `/Users/Shared/MASExtractedPkgs` and optionally embeds the Mac App Store receipt into the extracted app bundle.

### Added
- **`--ver` option** (optional) to override the App Store `appExtVrsId` parameter.
  - Default remains `0` when not provided.
  - Also supports a multi-character alias after the app id: `-ver` (via argument preprocessing).
  - Examples:
    - `mas install 424389933 --ver 867747287`
    - `mas install 424389933 -ver 867747287`

- **Automatic package rescue + extraction on post-download failure**
  - If a download attempt occurs and the install fails afterward (including errors like: `The installation could not be started`), MAS will attempt to:
    - Stage the `.pkg` and receipt from the App Store cache into:
      - `/Users/Shared/MASExtractedPkgs/.staging/<appID>/`
    - Extract the staged `.pkg` into:
      - `/Users/Shared/MASExtractedPkgs/<appID>/<YYYYMMDD-HHMMSS>-<AppName>[-<bundleVersion>]/`
    - Preserve the `Applications/` folder structure produced by the package (e.g., `Applications/<App>.app`).

- **Optional Mac App Store receipt embedding prompt**
  - After a successful rescue extraction, MAS prompts:
    - “Would you like to copy the Mac App Store receipt into the extracted app bundle? [Y/N]”
  - If **Y**, it copies the receipt (does not move it):
    - Source: `<output>/<appID>-receipt`
    - Destination: `<App>.app/Contents/_MASReceipt/receipt`

### Changed
- **Extraction mechanism**
  - Uses `xar` to unpack `.pkg` archives (XAR format), then `ditto -x` to unpack `Payload` into the output directory.
  - This replaces the more complex `pkgutil --expand` directory staging flow and reduces extraction fragility.

- **Output folder naming**
  - Output includes app name and timestamp, and includes `bundleVersion` when available:
    - `<YYYYMMDD-HHMMSS>-<AppName>-<bundleVersion>` (if available)
    - `<YYYYMMDD-HHMMSS>-<AppName>` (if not)

### Fixed
- Improved resilience against post-download failure timing by staging `.pkg`/receipt during download (best-effort) so that temporary cache cleanup is less likely to delete needed artifacts before extraction.

### Known limitations
- Rescue depends on the `.pkg` and receipt being present/visible in the App Store cache during the download window.
  - Cache root is derived from:
    - `getconf DARWIN_USER_CACHE_DIR`
  - The implementation monitors expected per-app subfolders under that cache dir (e.g., `com.apple.AppStore/<appID>/`), which can vary by macOS version.
- Some packages may not yield a single `.app` at a predictable path (e.g., multi-component installs). The extraction still preserves the package’s structure so the user can locate installed artifacts.

### Usage
- Standard install (unchanged behavior):
  - `mas install <appID>`
- Install with `appExtVrsId` override:
  - `mas install <appID> --ver <appExtVrsId>`
  - `mas install <appID> -ver <appExtVrsId>`
- On post-download failure, MAS will:
  - Print status messages indicating rescue/extraction
  - Print the final extracted output path under `/Users/Shared/MASExtractedPkgs`
  - Offer to copy the Mac App Store receipt into the extracted app bundle

### Implementation notes (file summary)

#### Modified
- `Sources/mas/MAS.swift`
  - Adds argument preprocessing so `-ver` is translated to `--ver` before parsing.
- `Sources/mas/Commands/Install.swift`
- `Sources/mas/Commands/Purchase.swift`
- `Sources/mas/Commands/Lucky.swift`
- `Sources/mas/Commands/Upgrade.swift`
  - Adds `--ver` option (default `0`) and passes it into the downloader.
- `Sources/mas/AppStore/Downloader.swift`
  - Threads `appExtVrsId` through download orchestration so the override reaches the purchase/download initiation.
- `Sources/mas/AppStore/SSPurchase.swift`
  - Accepts `appExtVrsId` and injects it into the request parameters (replacing the prior hard-coded default usage).
- `Sources/mas/AppStore/PurchaseDownloadObserver.swift`
  - Starts/coordinates staging (best-effort) during download.
  - On failure after a download attempt, triggers rescue extraction and prompts for optional receipt embedding.

#### Added
- `Sources/mas/AppStore/PkgRescuer.swift`
  - Implements:
    - Cache discovery using `getconf DARWIN_USER_CACHE_DIR`
    - Staging of `.pkg` and `receipt` into `/Users/Shared/MASExtractedPkgs/.staging/<appID>/`
    - Extraction using `xar` + `ditto`
    - Output folder creation and receipt copying
    - Optional receipt embedding into `<App>.app/Contents/_MASReceipt/receipt`

#### Generated / metadata
- `Sources/mas/Package.swift`
  - Regenerated build metadata file.
