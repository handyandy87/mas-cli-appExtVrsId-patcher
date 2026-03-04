//
//  MAS.swift
//  mas
//
//  Copyright © 2021 mas-cli. All rights reserved.
//
//  Modified by github.com/handyandy87 on 03/03/2026 07:51:00 PM CST.

import ArgumentParser
import PromiseKit

@main
struct MAS: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Mac App Store command-line interface",
        subcommands: [
            Account.self,
            Config.self,
            Home.self,
            Info.self,
            Install.self,
            List.self,
            Lucky.self,
            Open.self,
            Outdated.self,
            Purchase.self,
            Region.self,
            Reset.self,
            Search.self,
            SignIn.self,
            SignOut.self,
            Uninstall.self,
            Upgrade.self,
            Vendor.self,
            Version.self,
        ]
    )

    static func initialize() {
        PromiseKit.conf.Q.map = .global()
        PromiseKit.conf.Q.return = .global()
        PromiseKit.conf.logHandler = { event in
            switch event {
            case .waitOnMainThread:
                // Ignored. This is a console app that waits on the main thread for
                // promises to be processed on the global DispatchQueue.
                break
            default:
                // Other events indicate a programming error.
                fatalError("PromiseKit event: \(event)")
            }
        }
    }

    func validate() throws {
        Self.initialize()
    }

    /// Custom entry point so we can support a shorthand alias `-ver` (single-dash, multi-character)
    /// by translating it to the standard long option `--ver` before ArgumentParser runs.
    ///
    /// This also allows the option to appear after positional arguments, e.g.:
    ///   mas install 123456789 -ver 987654321
    static func main() {
        main(nil)
    }

    static func main(_ arguments: [String]?) {
        do {
            // ArgumentParser expects the argument array *without* the executable name.
            var args = arguments ?? Array(CommandLine.arguments.dropFirst())

            // Support `-ver` as an alias for `--ver`.
            // (Swift ArgumentParser only supports single-character short options.)
            for i in args.indices {
                if args[i] == "-ver" {
                    args[i] = "--ver"
                }
            }

            var command = try parseAsRoot(args)
            try command.run()
        } catch {
            exit(withError: error)
        }
    }
}
