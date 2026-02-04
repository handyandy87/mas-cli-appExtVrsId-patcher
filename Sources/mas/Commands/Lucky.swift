//
//  Lucky.swift
//  mas
//
//  Copyright © 2016 Andrew Naylor. All rights reserved.
//
//  Modified by github.com/handyandy87 on 02/03/2026 09:49:09 AM CST.

import ArgumentParser
import CommerceKit

extension MAS {
    /// Command which installs the first search result.
    ///
    /// This is handy as many MAS titles can be long with embedded keywords.
    struct Lucky: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract:
                """
                Install the first app returned from searching the Mac App Store
                (app must have been previously purchased)
                """
        )

        @Flag(help: "Force reinstall")
        var force = false

        @Option(name: .customLong("ver"), help: "Override the appExtVrsId parameter used for App Store downloads (default: 0). You can also pass '-ver' as a shorthand alias.")
        var appExtVrsId: Int = 0
        @Argument(help: "Search term")
        var searchTerm: String

        /// Runs the command.
        func run() throws {
            try run(appLibrary: SoftwareMapAppLibrary(), searcher: ITunesSearchAppStoreSearcher())
        }

        func run(appLibrary: AppLibrary, searcher: AppStoreSearcher) throws {
            var appID: AppID?

            do {
                let results = try searcher.search(for: searchTerm).wait()
                guard let result = results.first else {
                    throw MASError.noSearchResultsFound
                }

                appID = result.trackId
            } catch {
                throw error as? MASError ?? .searchFailed
            }

            guard let appID else {
                fatalError("app ID returned from Apple is null")
            }

            try install(appID: appID, appLibrary: appLibrary)
        }

        /// Installs an app.
        ///
        /// - Parameters:
        ///   - appID: App identifier
        ///   - appLibrary: Library of installed apps
        /// - Throws: Any error that occurs while attempting to install the app.
        private func install(appID: AppID, appLibrary: AppLibrary) throws {
            // Try to download applications with given identifiers and collect results
            if let displayName = appLibrary.installedApps(withAppID: appID).first?.displayName, !force {
                printWarning("\(displayName) is already installed")
            } else {
                do {
                    try downloadApps(withAppIDs: [appID], appExtVrsId: appExtVrsId).wait()
                } catch {
                    throw error as? MASError ?? .downloadFailed(error: error as NSError)
                }
            }
        }
    }
}
