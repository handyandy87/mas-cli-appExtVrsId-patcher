# mas

A command-line interface for the Mac App Store. Designed for scripting & automation.


## This fork contains a patched version to accept a "--ver" argument for the appExtVrsId (aka App External ID)


⚠️ MAS Version 1.9.0 is used in this fork. I've tested it was working with versions from Mojave thru Ventura ⚠️


### 🖥 Usage

To use this patched version of MAS 1.9.0, you'll need to either build from the source in this fork or download the release version.


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
