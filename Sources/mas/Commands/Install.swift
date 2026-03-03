//
//  Install.swift
//  mas
//
//  Copyright (c) 2015 Andrew Naylor. All rights reserved.
//
//  Modified by github.com/handyandy87 on 02/03/2026 09:49:09 AM CST.

import ArgumentParser
import CommerceKit

extension MAS {
    /// Installs previously purchased apps from the Mac App Store.
    struct Install: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Install previously purchased app(s) from the Mac App Store"
        )

        @Flag(help: "Force reinstall")
        var force = false

        /// Install a specific historical version of an app by its App External Version ID.
        /// When provided, overrides the default `appExtVrsId` (0) used for App Store downloads.
        /// Allows installation of older versions of Mac App Store apps that are no longer available in the public catalog.
        /// Also supports `-ver` as a shorthand alias (e.g., `mas install 634148309 -ver 16404831`).
        @Option(name: .customLong("ver"), help: "Override the appExtVrsId parameter used for App Store downloads (default: 0). You can also pass '-ver' as a shorthand alias.")
        var appExtVrsId: Int = 0

        /// Resolve an App External Version ID to its version string without downloading.
        /// Contacts Apple's servers to read the `bundleVersion` from CommerceKit metadata, cancels the download immediately, and exits.
        /// Nothing is written to disk. Useful for resolving unknown App External IDs to their version strings in bulk.
        /// Must be used together with `--ver` to specify which version to lookup.
        @Flag(name: .customLong("lookup"), help: "Look up version for the given --ver appExtVrsId without downloading. Prints '==> Version lookup: <AppName> (<version>)' and exits.")
        var lookupOnly = false

        @Argument(help: ArgumentHelp("App ID", valueName: "app-id"))
        var appIDs: [AppID]

        /// Runs the command.
        func run() throws {
            try run(appLibrary: SoftwareMapAppLibrary(), searcher: ITunesSearchAppStoreSearcher())
        }

        func run(appLibrary: AppLibrary, searcher: AppStoreSearcher) throws {
            // Try to download applications with given identifiers and collect results
            let appIDs = appIDs.filter { appID in
                // In lookup-only mode, always proceed regardless of installed state
                if lookupOnly { return true }
                if let displayName = appLibrary.installedApps(withAppID: appID).first?.displayName, !force {
                    printWarning("\(displayName) is already installed")
                    return false
                }

                return true
            }

            do {
                try downloadApps(withAppIDs: appIDs, verifiedBy: searcher, appExtVrsId: appExtVrsId, lookupOnly: lookupOnly).wait()
            } catch {
                throw error as? MASError ?? .downloadFailed(error: error as NSError)
            }
        }
    }
}
