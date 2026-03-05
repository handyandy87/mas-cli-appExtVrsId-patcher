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

## 🗂️ mas-legacyapps — Legacy App Installer

Need to restore a full suite of Pro or productivity apps for an older macOS release? **`mas-legacyapps`** is a companion tool built on top of this patcher. It bundles App External Version ID data for every supported macOS release and walks you through a set of interactive menus — or accepts flags to run fully automated.

**Supported macOS releases:** High Sierra · Mojave · Catalina · Monterey

**Apps covered:** Final Cut Pro, Compressor, Motion, Logic Pro, MainStage, GarageBand, Keynote, Numbers, Pages, iMovie, Xcode

```console
$ mas-legacyapps --os catalina --category pro --all --yes
```

It can also be run fully non-interactively for scripted or automated use:

```bash
# Install all Pro Apps for Catalina, no prompts, no delay
mas-legacyapps --os catalina --category pro --all --yes --delay 0

# Install everything for Monterey including Xcode
mas-legacyapps --os monterey --category all --xcode --all --yes
```

→ **[handyandy87/mas-legacyapps](https://github.com/handyandy87/mas-legacyapps)**

---

## 🔧 Build from source

```shell
swift build -c release
```

Output binary: `.build/x86_64-apple-macosx/release/mas`

Or open the project root in Xcode.

---

## 📄 License

MIT — see [LICENSE](LICENSE).

Original mas by [@argon](https://github.com/argon). This fork by [@handyandy87](https://github.com/handyandy87).
