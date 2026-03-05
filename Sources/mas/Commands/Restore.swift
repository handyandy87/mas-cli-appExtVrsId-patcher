//
//  Restore.swift
//  mas
//
//  Created by github.com/handyandy87 on 2026-03-05.
//

import ArgumentParser
import Foundation

extension MAS {
    /// Interactively installs the last compatible versions of Apple Pro and
    /// productivity apps for a chosen macOS release.
    ///
    /// Presents an OS selection menu, an app toggle list, a confirmation prompt, then
    /// runs installs sequentially. Apps not in the user's purchase history are skipped
    /// automatically with a clear message. If the App Store install step fails after a
    /// successful download, the package rescue and extraction flow activates exactly as
    /// it does in `mas install`.
    struct Restore: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Install last-compatible Apple Pro & productivity apps for a macOS release",
            discussion: """
            Presents a menu to select a macOS release, then installs the last compatible
            version of each Apple Pro and productivity app from the App Store.

            Apps not in your purchase history are skipped automatically.
            If the App Store install step fails, the downloaded .pkg is rescued and extracted
            to /Users/Shared/MASExtractedPkgs/ (same as `mas install --ver`).

            Currently covers:
              • High Sierra  (10.13)
              • Mojave       (10.14)
              • Catalina     (10.15)
              • Monterey     (12.0)

            Big Sur, Ventura, Sonoma, and Sequoia data is not yet available.

            Examples:
              mas restore                          # fully interactive
              mas restore --os catalina            # skip OS selection
              mas restore --os monterey --all      # skip app toggle
              mas restore --os mojave --all --yes  # fully automated (no prompts)
              mas restore --delay 30               # 30-second inter-app delay
            """
        )

        @Option(
            name: .customLong("os"),
            help: "macOS version to target, e.g. 'monterey', 'catalina'. Skips the interactive OS selection menu."
        )
        var targetOS: String?

        @Option(
            name: .customLong("delay"),
            help: "Seconds to wait between app installs to avoid Apple's rate limiter (default: 15, use 0 to disable)."
        )
        var delay: Int = 15

        @Flag(
            name: .customLong("all"),
            help: "Skip the per-app toggle menu and install everything for the selected OS."
        )
        var installAll = false

        @Flag(
            name: [.customShort("y"), .customLong("yes")],
            help: "Skip the final confirmation prompt. Useful for unattended or scripted runs."
        )
        var skipConfirmation = false

        // MARK: - Entry point

        func run() throws {
            printBanner()

            let release = try resolveRelease()
            let selected = try resolveApps(for: release)

            guard !selected.isEmpty else {
                printInfo("No apps selected. Exiting.")
                return
            }

            if !skipConfirmation {
                try confirmInstall(apps: selected, release: release)
            }

            let outcomes = performInstalls(apps: selected)
            printSummary(outcomes: outcomes, release: release)
            writeLog(outcomes: outcomes, release: release)
        }

        // MARK: - Release selection

        private func resolveRelease() throws -> MacOSRelease {
            guard let targetOS else {
                return try promptForRelease()
            }

            let key = targetOS.lowercased().replacingOccurrences(of: " ", with: "")
            guard let match = LegacyAppCatalog.releases.first(where: { $0.shortName == key }) else {
                let valid = LegacyAppCatalog.releases.map { "'\($0.shortName)'" }.joined(separator: ", ")
                throw MASError.runtimeError("Unknown macOS version '\(targetOS)'. Valid options: \(valid)")
            }

            printInfo("Targeting \(match.name) (\(match.displayVersion))")
            return match
        }

        private func promptForRelease() throws -> MacOSRelease {
            print("Select a macOS version:\n")

            for (index, release) in LegacyAppCatalog.releases.enumerated() {
                let num = "\(index + 1).".padding(toLength: 4, withPad: " ", startingAt: 0)
                let displayName = "\(release.name) (\(release.displayVersion))"
                    .padding(toLength: 24, withPad: " ", startingAt: 0)
                print("  \(num)  \(displayName)  \(release.apps.count) apps")
            }

            print()

            while true {
                print("Enter a number (or 'q' to quit): ", terminator: "")
                fflush(stdout)

                let raw = (readLine() ?? "").trimmingCharacters(in: .whitespaces)

                if raw.lowercased() == "q" {
                    throw MASError.runtimeError("Cancelled by user.")
                }
                if let choice = Int(raw), choice >= 1, choice <= LegacyAppCatalog.releases.count {
                    return LegacyAppCatalog.releases[choice - 1]
                }

                print("  Please enter a number from 1 to \(LegacyAppCatalog.releases.count).\n")
            }
        }

        // MARK: - App selection

        private func resolveApps(for release: MacOSRelease) throws -> [LegacyApp] {
            if installAll {
                return release.apps
            }
            return try promptForApps(from: release)
        }

        private func promptForApps(from release: MacOSRelease) throws -> [LegacyApp] {
            var deselected = Set<Int>()

            while true {
                printAppTable(release: release, deselected: deselected)

                print("  Enter a number to toggle on/off, 'a' for all, Enter to proceed, 'q' to quit")
                print()
                print("  > ", terminator: "")
                fflush(stdout)

                let raw = (readLine() ?? "").trimmingCharacters(in: .whitespaces)

                switch raw.lowercased() {
                case "":
                    return release.apps.enumerated()
                        .filter { !deselected.contains($0.offset) }
                        .map { $0.element }
                case "q":
                    throw MASError.runtimeError("Cancelled by user.")
                case "a":
                    deselected.removeAll()
                default:
                    if let num = Int(raw), num >= 1, num <= release.apps.count {
                        let idx = num - 1
                        if deselected.contains(idx) {
                            deselected.remove(idx)
                        } else {
                            deselected.insert(idx)
                        }
                    } else {
                        print("  Invalid input — enter a number, 'a', Enter, or 'q'.\n")
                    }
                }
            }
        }

        private func printAppTable(release: MacOSRelease, deselected: Set<Int>) {
            let selectedCount = release.apps.count - deselected.count
            let totalGB = release.apps.enumerated()
                .filter { !deselected.contains($0.offset) }
                .reduce(0.0) { $0 + $1.element.estimatedSizeGB }

            print()
            print("  Apps for \(release.name) (\(release.displayVersion))")
            print("  \(selectedCount)/\(release.apps.count) selected  •  ~\(String(format: "%.1f", totalGB)) GB estimated download")
            print()
            print("  #    On    \("App".padding(toLength: 16, withPad: " ", startingAt: 0))  \("Version".padding(toLength: 10, withPad: " ", startingAt: 0))  Est. Size")
            print("  \(String(repeating: "─", count: 58))")

            for (idx, app) in release.apps.enumerated() {
                let toggle = deselected.contains(idx) ? "[ ]" : "[✓]"
                let numStr = "\(idx + 1)".padding(toLength: 4, withPad: " ", startingAt: 0)
                let name = app.name.padding(toLength: 16, withPad: " ", startingAt: 0)
                let version = app.version.padding(toLength: 10, withPad: " ", startingAt: 0)
                let size = String(format: "~%.1f GB", app.estimatedSizeGB)
                print("  \(numStr) \(toggle)  \(name)  \(version)  \(size)")
            }

            print()
        }

        // MARK: - Confirmation

        private func confirmInstall(apps: [LegacyApp], release: MacOSRelease) throws {
            let totalGB = apps.reduce(0.0) { $0 + $1.estimatedSizeGB }

            print()
            print("Ready to install \(apps.count) app\(apps.count == 1 ? "" : "s") for \(release.name) (\(release.displayVersion)).")
            print()
            print("  • Estimated download         ~\(String(format: "%.1f", totalGB)) GB")
            print("  • Delay between apps         \(delay > 0 ? "\(delay)s (rate limit protection)" : "none")")
            print("  • Apps not purchased         skipped with a message")
            print("  • Install failures           .pkg rescued → /Users/Shared/MASExtractedPkgs/")
            print()
            print("Proceed? [Y/n]: ", terminator: "")
            fflush(stdout)

            let answer = (readLine() ?? "").trimmingCharacters(in: .whitespaces).lowercased()
            guard answer.isEmpty || answer == "y" || answer == "yes" else {
                throw MASError.runtimeError("Aborted by user.")
            }
        }

        // MARK: - Install loop

        private enum InstallOutcome {
            case installed
            case skippedNotPurchased(String)
            case failed(String)
        }

        private struct AppOutcome {
            let app: LegacyApp
            let outcome: InstallOutcome
        }

        private func performInstalls(apps: [LegacyApp]) -> [AppOutcome] {
            var results: [AppOutcome] = []

            for (index, app) in apps.enumerated() {
                print()
                print(String(repeating: "━", count: 66))
                printInfo("[\(index + 1)/\(apps.count)] \(app.name)  \(app.version)")

                do {
                    try downloadApps(
                        withAppIDs: [app.appID],
                        purchasing: false,
                        appExtVrsId: app.appExtVrsId
                    ).wait()
                    results.append(AppOutcome(app: app, outcome: .installed))
                } catch let error as MASError {
                    print()
                    switch error {
                    case .purchaseFailed:
                        printWarning("\(app.name) — not in purchase history, skipping.")
                        results.append(AppOutcome(app: app, outcome: .skippedNotPurchased(error.description)))
                    default:
                        printError("Could not install \(app.name): \(error.description)")
                        results.append(AppOutcome(app: app, outcome: .failed(error.description)))
                    }
                } catch {
                    print()
                    printError("Could not install \(app.name): \(error.localizedDescription)")
                    results.append(AppOutcome(app: app, outcome: .failed(error.localizedDescription)))
                }

                // Pause between installs to respect Apple's rate limiter, except after the last app.
                if index < apps.count - 1 && delay > 0 {
                    print()
                    printInfo("Waiting \(delay)s before next install…")
                    Thread.sleep(forTimeInterval: Double(delay))
                }
            }

            return results
        }

        // MARK: - Summary

        private func printSummary(outcomes: [AppOutcome], release: MacOSRelease) {
            var installedCount = 0
            var skippedCount = 0
            var failedCount = 0

            print()
            print(String(repeating: "━", count: 66))
            printInfo("Restore Summary — \(release.name) (\(release.displayVersion))")
            print(String(repeating: "━", count: 66))
            print()

            for entry in outcomes {
                let name = entry.app.name.padding(toLength: 16, withPad: " ", startingAt: 0)
                let version = entry.app.version.padding(toLength: 10, withPad: " ", startingAt: 0)

                switch entry.outcome {
                case .installed:
                    print("  ✓  \(name)  \(version)  Installed")
                    installedCount += 1
                case .skippedNotPurchased:
                    print("  ↷  \(name)  \(version)  Not purchased — skipped")
                    skippedCount += 1
                case .failed(let message):
                    print("  ✗  \(name)  \(version)  Failed")
                    print("       └─ \(message)")
                    failedCount += 1
                }
            }

            print()
            print("  \(installedCount) installed  •  \(skippedCount) skipped (not purchased)  •  \(failedCount) failed")

            if failedCount > 0 {
                print()
                print("  Apps that failed to install may have been extracted instead.")
                print("  Check /Users/Shared/MASExtractedPkgs/ for rescued packages.")
                print()
                print("  If Gatekeeper blocks an extracted app, run:")
                print("    xattr -cr \"/path/to/App.app\"")
                print("  then right-click the .app and choose Open.")
            }

            print()
        }

        // MARK: - Log file

        private func writeLog(outcomes: [AppOutcome], release: MacOSRelease) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let timestamp = formatter.string(from: Date())

            var lines: [String] = [
                "MAS Legacy Restore Log",
                "Generated : \(Date())",
                "macOS     : \(release.name) (\(release.displayVersion))",
                "",
            ]

            for entry in outcomes {
                let status: String
                switch entry.outcome {
                case .installed:
                    status = "INSTALLED"
                case .skippedNotPurchased(let detail):
                    status = "SKIPPED (not purchased) — \(detail)"
                case .failed(let message):
                    status = "FAILED — \(message)"
                }
                lines.append("\(entry.app.name) \(entry.app.version)  →  \(status)")
            }

            let logContent = lines.joined(separator: "\n") + "\n"
            let logPath = NSString(string: "~/.mas-restore-\(timestamp).log").expandingTildeInPath

            do {
                try logContent.write(toFile: logPath, atomically: true, encoding: .utf8)
                print()
                printInfo("Log saved: \(logPath)")
            } catch {
                printWarning("Could not write log file: \(error.localizedDescription)")
            }
        }

        // MARK: - Banner

        private func printBanner() {
            print("""
            ╔═══════════════════════════════════════════════════════════════════╗
            ║       MAS Legacy Restore — Apple Pro & Productivity Apps          ║
            ╚═══════════════════════════════════════════════════════════════════╝

            Installs the last compatible version of Apple's Pro and productivity
            apps for a selected macOS release.

            Apps not in your purchase history are skipped with a clear message.
            If an install fails after downloading, the .pkg is automatically
            rescued and extracted to /Users/Shared/MASExtractedPkgs/.

            Note: Currently covers High Sierra → Monterey only.
            """)
        }
    }
}
