# mas

A command-line interface for the Mac App Store. Designed for scripting & automation.


## This contains a patched version of MAS to accept a "--ver" argument for the appExtVrsId (aka App External ID)


⚠️ MAS Version 1.9.0 is used in this patch. I've tested it as working with versions from Mojave thru Ventura ⚠️


### 🖥 Usage

To use this patched version of MAS 1.9.0, you'll need to either build from the source in this repo or download the pre-buil ZIP release version.

Open Terminal, and navigate to the directory where the patched version of MAS is located.

If you've downloaded the pre-built ZIP from the releases section of this repo and extracted it into your downloadeds folders, run:
```console
cd ~/Downloads/mas190-verpkgextract-build/x86_64-apple-macosx/release/
```


### 🪪 App IDs

Each application in the Mac App Store has an integer app identifier (app ID).
mas commands accept app IDs as arguments & output App IDs to uniquely identify apps.

`mas search` & `mas list` can be used to find the app IDs of relevant apps.


Alternatively, to find an app's app ID:

1. Find the app in the Mac App Store
2. Select `Share` > `Copy Link`
3. Extract the app ID from the URL. e.g., the Mac App Store URL for Xcode
   (<https://apps.apple.com/us/app/xcode/id497799835?mt=12>) has app ID `497799835`


For specific versions of Apple Pro Apps and certain Apple productivity apps:
1. Checkout https://github.com/handyandy87/Pro-Apps-App-External-IDs . 
2. This is currently a work in progress and if you have any IDs for the apps I'm tracking there please let me know!


### ⬇️ Installing Apps

All the commands in this section require you to be logged into an Apple ID in the Mac App Store.


#### `mas install`

`mas install <app-id>…` installs apps that you have already gotten/"purchased" from the Mac App Store.

Providing the `--force` flag re-installs the app even if it is already installed on your computer.

Providing the `--ver` flag followed by an App External ID allows you to install a specific software version.

```console
$ mas install 497799835
==> Downloading Xcode
==> Installed Xcode
```

```console
$ mas install 634148309 --ver 16404831
==> Downloading Logic Pro (10.0.3)
==> Downloaded Logic Pro (10.0.3)
==> Installing Logic Pro (10.0.3)
==> Installed Logic Pro (10.0.3)
```

**That's it -- your app should now be in the Applications folder.**


### 🛟 If an install fails after a download (package rescue + extraction)

Sometimes the Mac App Store download succeeds but the install step fails (for example due to Gatekeeper policy, installer/receipt validation, or other system restrictions). When this happens, MAS may report an error like:

```console
Error: Download failed: The installation could not be started.
```

If an install fails after a download attempt, this patched version will attempt to rescue the downloaded package before macOS deletes the temporary files.

You'll see the following reported:
```console
==> Install failed. Attempting to rescue and extract the downloaded package…
```

What'll happen next, is MAS will:

Stage the App Store cached files (the in-progress .pkg and receipt) into:
```console
/Users/Shared/MASExtractedPkgs/.staging/<app-id>/
```

Extract the staged .pkg to:
```console
/Users/Shared/MASExtractedPkgs/<app-id>/<YYYYMMDD-HHMMSS>-<AppName>[-<bundleVersion>]/
```

Copy the receipt into the same output folder as:
```console
<app-id>-receipt
```

Once MAS is done extracting the downloaded pkg, you'll see the result along with the file path for the extracted app:
```console
=> Rescue extraction complete.
==> Extracted app path:
    /Users/Shared/MASExtractedPkgs/424389933/20260203-091512-Final Cut Pro-10.7.1/Applications/Final Cut Pro.app
==> Receipt saved alongside extracted output:
    /Users/Shared/MASExtractedPkgs/424389933/20260203-091512-Final Cut Pro-10.7.1/424389933-receipt
```

MAS will then ask you if you'd like to copy the app's associated Mac App Store receipt to the app bundle:
```console
“Would you like to copy the Mac App Store receipt into the extracted app bundle? [Y/N]”
```

1. If you answer Y, MAS will copy the receipt into:
```console
<AppName>.app/Contents/_MASReceipt/receipt
```
> Note: This is a copy, not a move. The <app-id>-receipt file remains alongside the extracted output.

2. If you answer N, MAS will leave the extracted bundle as-is.


After either selection, MAS will report:
```console
==> Done. Copy the extracted app to your /Applications folder to complete installation.
```


## 🧭 What you should do next

Open the output folder printed by MAS, for example:
```console
/Users/Shared/MASExtractedPkgs/<app-id>/<timestamp>-<AppName>.../
```

Then copy <AppName>.app into your system /Applications folder.

That’s it — you now have the extracted app available locally even though the Mac App Store install phase failed.


## ℹ️ Build from source

You can build from Xcode by opening the root mas directory, or from the Terminal:

```shell
script/build
```

Build output can be found in the `.build` directory within the project.


## 📄 License

Code is under the [MIT license](LICENSE).

original mas was created by [@argon](https://github.com/argon)

[homebrew-bundle]: https://github.com/Homebrew/homebrew-bundle
