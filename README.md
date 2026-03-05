# mas — appExtVrsId patcher

A patched version of [mas-cli](https://github.com/mas-cli/mas) (v1.9.0) that adds three capabilities on top of the standard `mas install` command:

- **`--ver <appExtVrsId>`** — install a specific historical version of a Mac App Store app by passing its App External ID
- **`--lookup`** — resolve an App External ID to its version string without downloading anything
- **Package rescue + extraction** — when an install fails after a successful download, automatically stage and extract the `.pkg` so you still get the app

> ⚠️ Tested on macOS Mojave through Ventura. Built against mas 1.9.0.

---

## 🪪 Finding App IDs

Each Mac App Store app has an integer **App Item ID**. `mas search` and `mas list` can find these, or extract one from the store URL:

```
https://apps.apple.com/us/app/logic-pro/id634148309
                                                 ↑
                                          App Item ID: 634148309
```

For **App External IDs** (version-specific identifiers used by `--ver` and `--lookup`), see the companion repo:
→ [handyandy87/Pro-Apps-App-External-IDs](https://github.com/handyandy87/Pro-Apps-App-External-IDs)

> If you already have a system `mas` installed, invoke this build by its full path — Terminal will otherwise resolve the system version first.

---

## ⬇️ Installing a specific version

```console
$ mas install 634148309 --ver 16404831
==> Downloading Logic Pro (10.0.3)
==> Downloaded Logic Pro (10.0.3)
==> Installing Logic Pro (10.0.3)
==> Installed Logic Pro (10.0.3)
```

Use `--force` to reinstall even if the app is already present:

```console
$ mas install 634148309 --ver 16404831 --force
```

---

## 🔍 Looking up a version without downloading

`--lookup` contacts Apple's servers, reads the version string from CommerceKit metadata, cancels the download immediately, and exits. Nothing is written to disk.

```console
$ mas install 634148309 --ver 16404831 --lookup
==> Version lookup: Logic Pro (10.0.3)
```

This is useful for resolving unknown App External IDs to their version strings in bulk — see the [mas-ver-lookup.sh](https://github.com/handyandy87/Pro-Apps-App-External-IDs) script in the companion repo.

**How it works:** The Mac App Store daemon (`storedownloadd`) populates download metadata — including `bundleVersion` — before any bytes are transferred. `--lookup` intercepts this metadata in the `CKDownloadQueueObserver` callback, prints the version, and calls `removeDownload` to cancel cleanly. If the `changedWithAddition` callback is skipped for very old IDs, a fallback in `statusChangedFor` catches it instead.

---

## 🛟 Package rescue + extraction

When the Mac App Store download succeeds but the install step fails (e.g. due to Gatekeeper, receipt validation, or OS version restrictions), you'd normally lose the downloaded package. This build rescues it automatically.

**Trigger error:**
```console
Error: Download failed: The installation could not be started.
```

**What happens:**

1. The in-flight `.pkg` and receipt are staged from the App Store cache to:
   ```
   /Users/Shared/MASExtractedPkgs/.staging/<app-id>/
   ```

2. The `.pkg` is extracted to:
   ```
   /Users/Shared/MASExtractedPkgs/<app-id>/<YYYYMMDD-HHMMSS>-<AppName>[-<version>]/
   ```

3. The receipt is copied alongside as `<app-id>-receipt`.

4. You're prompted whether to embed the receipt into the extracted app bundle:
   ```console
   Would you like to copy the Mac App Store receipt into the extracted app bundle? [Y/N]
   ```
   Answering `Y` copies the receipt to `<AppName>.app/Contents/_MASReceipt/receipt`.

5. Copy the extracted `.app` to `/Applications` to complete installation.

**Example output:**
```console
==> Install failed. Attempting to rescue and extract the downloaded package…
==> Rescue complete. Extracted to:
    /Users/Shared/MASExtractedPkgs/424389933/20260203-091512-Final Cut Pro-10.7.1/
==> Extracted app: …/Applications/Final Cut Pro.app
==> Copy the extracted app into /Applications to install it.
Would you like to copy the Mac App Store receipt into the extracted app bundle? [Y/N]
```

---

## 🔧 Build from source

```shell
swift build -c release
```

Output binary: `.build/x86_64-apple-macosx/release/mas`

Or open the project root in Xcode.

---

## 🗂️ mas-legacyapps — batch restore for last-compatible versions

`mas-legacyapps` is a companion command-line tool, written in Swift, that builds on this patcher to automate the most common use case: **restoring the last version of Apple's Pro and productivity apps that is compatible with a given macOS release**.

Rather than looking up individual App External IDs and running `mas install --ver` for each app, `mas-legacyapps` presents a short interactive menu, then downloads and installs every selected app in sequence — handling rate limiting, skipping unpurchased apps, and automatically rescuing extracted `.pkg` files when Gatekeeper blocks the install step.

**Supported macOS targets:** High Sierra (10.13), Mojave (10.14), Catalina (10.15), Monterey (12.0)

**Apps covered:** Final Cut Pro, Compressor, Motion, Logic Pro, MainStage, GarageBand, Keynote, Numbers, Pages, iMovie, Xcode

### Example session

```
╔═══════════════════════════════════════════════════════════════════╗
║         mas-legacyapps — Apple Pro & Productivity Apps            ║
╚═══════════════════════════════════════════════════════════════════╝

Select a macOS version:

  1.    High Sierra (10.13)         10 Pro, 4 iWork
  2.    Mojave (10.14)              10 Pro, 4 iWork + Xcode
  3.    Catalina (10.15)            10 Pro, 4 iWork + Xcode
  4.    Monterey (12.0)             10 Pro, 4 iWork + Xcode

Enter a number (or 'q' to quit): 3

What would you like to install for Catalina (10.15)?

  1.    Pro Apps            Final Cut Pro, Compressor, Motion, Logic Pro, MainStage, GarageBand
  2.    iWork & Media       Keynote, Numbers, Pages, iMovie
  3.    All                 Pro Apps + iWork & Media

  (Xcode will be offered separately regardless of your choice.)

Enter a number (or 'q' to quit): 3

Xcode 12.4 is available (~11 GB).
Include it? [y/N]: n

  Catalina (10.15) — 10/10 selected  •  ~11.6 GB
  ...
  [✓] Keynote          11.1        ~0.3 GB
  ...

Proceed? [Y/n]: y

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
==> [1/10] Keynote  11.1
==> Downloading Keynote (11.1)
...
```

It can also be run fully non-interactively for scripted or automated use:

```bash
# Install all Pro Apps for Catalina, no prompts, no delay
mas-legacyapps --os catalina --category pro --all --yes --delay 0

# Install everything for Monterey including Xcode
mas-legacyapps --os monterey --category all --xcode --all --yes
```

### Where to get it

The source lives in this repository under [`standalone/mas-legacyapps/`](standalone/mas-legacyapps/). Build and install with:

```bash
cd standalone/mas-legacyapps
swift build --configuration release
sudo cp .build/release/mas-legacyapps /usr/local/bin/
```

Or use the convenience scripts:

```bash
script/build     # build only
script/install   # build + copy to /usr/local/bin
```

The tool is also distributed as part of the [handyandy87/Pro-Apps-App-External-IDs](https://github.com/handyandy87/Pro-Apps-App-External-IDs) companion repository, which contains the full App External ID dataset it draws on.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

Original mas by [@argon](https://github.com/argon). This fork by [@handyandy87](https://github.com/handyandy87).
