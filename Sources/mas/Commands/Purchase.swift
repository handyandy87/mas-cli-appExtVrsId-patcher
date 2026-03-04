//
//  Purchase.swift
//  mas
//
//  Copyright (c) 2017 Jakob Rieck. All rights reserved.
//
//  Modified by github.com/handyandy87 on 03/03/2026 07:51:00 PM CST.

import ArgumentParser
import CommerceKit

extension MAS {
    struct Purchase: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "\"Purchase\" and install free apps from the Mac App Store"
        )

        /// Install a specific historical version of a free app by its App External Version ID.
        /// When provided, overrides the default `appExtVrsId` (0) used for App Store downloads.
        /// Also supports `-ver` as a shorthand alias (e.g., `mas purchase 634148309 -ver 16404831`).
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
                if let displayName = appLibrary.installedApps(withAppID: appID).first?.displayName {
                    printWarning("\(displayName) has already been purchased.")
                    return false
                }

                return true
            }

            do {
                try downloadApps(withAppIDs: appIDs, verifiedBy: searcher, purchasing: true, appExtVrsId: appExtVrsId).wait()
            } catch {
                throw error as? MASError ?? .downloadFailed(error: error as NSError)
            }
        }
    }
}
