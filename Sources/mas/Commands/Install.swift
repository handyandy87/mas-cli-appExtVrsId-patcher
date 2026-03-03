//
//  Install.swift
//  mas
//
//  Copyright (c) 2015 Andrew Naylor. All rights reserved.
//

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

        @Flag(name: .customLong("lookup"), help: "Look up version for the given --ver appExtVrsId without downloading. Prints '==> Version lookup: <AppName> (<version>)' and exits.")
        var lookupOnly = false

        @Option(name: .customLong("ver"), help: "Override the appExtVrsId parameter used for App Store downloads (default: 0). You can also pass '-ver' as a shorthand alias.")
        var appExtVrsId: Int = 0

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
