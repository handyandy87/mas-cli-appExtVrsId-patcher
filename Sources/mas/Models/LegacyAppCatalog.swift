//
//  LegacyAppCatalog.swift
//  mas
//
//  Created by github.com/handyandy87 on 2026-03-05.
//
//  Static catalog of Apple Pro and productivity apps with the last compatible
//  App External Version ID for each major macOS release.
//
//  Source data: https://github.com/handyandy87/Pro-Apps-App-External-IDs
//

/// A single Mac App Store app entry in the legacy restore catalog.
struct LegacyApp {
    let name: String
    let appID: AppID
    let appExtVrsId: Int
    let version: String

    /// Rough estimated download size in GB, used for pre-install disk-space warnings.
    let estimatedSizeGB: Double
}

/// A macOS release with its catalog of last-compatible app versions.
struct MacOSRelease {
    let name: String

    /// Lowercase, no-spaces identifier used with the `--os` flag (e.g. "monterey").
    let shortName: String

    /// Human-readable version string shown in menus (e.g. "12.0").
    let displayVersion: String

    let apps: [LegacyApp]
}

/// Static catalog of macOS releases and the last compatible version of each Apple
/// Pro and productivity app available for that release.
///
/// Apps are ordered smallest-to-largest by estimated download size so users see
/// quick wins (Keynote, Pages, Numbers) before long-running downloads (Xcode).
///
/// Data sourced from https://github.com/handyandy87/Pro-Apps-App-External-IDs
///
/// - Note: Big Sur (11), Ventura (13), Sonoma (14), and Sequoia (15) entries are
///   not yet available in the source data and are therefore absent here.
enum LegacyAppCatalog {
    static let releases: [MacOSRelease] = [
        MacOSRelease(
            name: "High Sierra",
            shortName: "highsierra",
            displayVersion: "10.13",
            apps: [
                LegacyApp(name: "Keynote",        appID: 409183694, appExtVrsId: 831242334, version: "9.1",     estimatedSizeGB: 0.3),
                LegacyApp(name: "Numbers",        appID: 409203825, appExtVrsId: 830786366, version: "6.1",     estimatedSizeGB: 0.3),
                LegacyApp(name: "Pages",          appID: 409201541, appExtVrsId: 830786372, version: "8.1",     estimatedSizeGB: 0.3),
                LegacyApp(name: "MainStage",      appID: 634159523, appExtVrsId: 834637212, version: "3.4.4",   estimatedSizeGB: 0.5),
                LegacyApp(name: "Compressor",     appID: 424390742, appExtVrsId: 830431847, version: "4.4.4",   estimatedSizeGB: 0.5),
                LegacyApp(name: "iMovie",         appID: 408981434, appExtVrsId: 831420740, version: "10.1.12", estimatedSizeGB: 0.5),
                LegacyApp(name: "GarageBand",     appID: 682658836, appExtVrsId: 836732248, version: "10.3.5",  estimatedSizeGB: 1.5),
                LegacyApp(name: "Logic Pro",      appID: 634148309, appExtVrsId: 833082327, version: "10.4.8",  estimatedSizeGB: 1.2),
                LegacyApp(name: "Final Cut Pro",  appID: 424389933, appExtVrsId: 830604740, version: "10.4.6",  estimatedSizeGB: 3.3),
                LegacyApp(name: "Motion",         appID: 434290957, appExtVrsId: 830431815, version: "5.4.3",   estimatedSizeGB: 3.0),
            ]
        ),
        MacOSRelease(
            name: "Mojave",
            shortName: "mojave",
            displayVersion: "10.14",
            apps: [
                LegacyApp(name: "Keynote",        appID: 409183694, appExtVrsId: 836428229, version: "10.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "Numbers",        appID: 409203825, appExtVrsId: 836428231, version: "10.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "Pages",          appID: 409201541, appExtVrsId: 836428233, version: "10.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "MainStage",      appID: 634159523, appExtVrsId: 834637212, version: "3.4.4",   estimatedSizeGB: 0.5),
                LegacyApp(name: "Compressor",     appID: 424390742, appExtVrsId: 837625598, version: "4.4.8",   estimatedSizeGB: 0.5),
                LegacyApp(name: "iMovie",         appID: 408981434, appExtVrsId: 833677695, version: "10.1.14", estimatedSizeGB: 0.5),
                LegacyApp(name: "GarageBand",     appID: 682658836, appExtVrsId: 836732248, version: "10.3.5",  estimatedSizeGB: 1.5),
                LegacyApp(name: "Logic Pro",      appID: 634148309, appExtVrsId: 835960408, version: "10.5.1",  estimatedSizeGB: 1.2),
                LegacyApp(name: "Final Cut Pro",  appID: 424389933, appExtVrsId: 837625711, version: "10.4.10", estimatedSizeGB: 3.3),
                LegacyApp(name: "Motion",         appID: 434290957, appExtVrsId: 837625726, version: "5.4.7",   estimatedSizeGB: 3.0),
                LegacyApp(name: "Xcode",          appID: 497799835, appExtVrsId: 833988030, version: "11.3.1",  estimatedSizeGB: 7.0),
            ]
        ),
        MacOSRelease(
            name: "Catalina",
            shortName: "catalina",
            displayVersion: "10.15",
            apps: [
                LegacyApp(name: "Keynote",        appID: 409183694, appExtVrsId: 842170568, version: "11.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "Numbers",        appID: 409203825, appExtVrsId: 842170571, version: "11.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "Pages",          appID: 409201541, appExtVrsId: 842170573, version: "11.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "MainStage",      appID: 634159523, appExtVrsId: 841990111, version: "3.5.3",   estimatedSizeGB: 0.5),
                LegacyApp(name: "Compressor",     appID: 424390742, appExtVrsId: 842932628, version: "4.5.4",   estimatedSizeGB: 0.5),
                LegacyApp(name: "iMovie",         appID: 408981434, appExtVrsId: 842933683, version: "10.2.5",  estimatedSizeGB: 0.5),
                LegacyApp(name: "GarageBand",     appID: 682658836, appExtVrsId: 836732248, version: "10.3.5",  estimatedSizeGB: 1.5),
                LegacyApp(name: "Logic Pro",      appID: 634148309, appExtVrsId: 841990097, version: "10.6.3",  estimatedSizeGB: 1.2),
                LegacyApp(name: "Final Cut Pro",  appID: 424389933, appExtVrsId: 842932377, version: "10.5.4",  estimatedSizeGB: 3.3),
                LegacyApp(name: "Motion",         appID: 434290957, appExtVrsId: 842933665, version: "5.5.3",   estimatedSizeGB: 3.0),
                LegacyApp(name: "Xcode",          appID: 497799835, appExtVrsId: 839994694, version: "12.4",    estimatedSizeGB: 11.0),
            ]
        ),
        MacOSRelease(
            name: "Monterey",
            shortName: "monterey",
            displayVersion: "12.0",
            apps: [
                LegacyApp(name: "Keynote",        appID: 409183694, appExtVrsId: 857401958, version: "13.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "Numbers",        appID: 409203825, appExtVrsId: 857401959, version: "13.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "Pages",          appID: 409201541, appExtVrsId: 857401961, version: "13.1",    estimatedSizeGB: 0.3),
                LegacyApp(name: "MainStage",      appID: 634159523, appExtVrsId: 854029745, version: "3.6.4",   estimatedSizeGB: 0.5),
                LegacyApp(name: "Compressor",     appID: 424390742, appExtVrsId: 858081833, version: "4.6.5",   estimatedSizeGB: 0.5),
                LegacyApp(name: "iMovie",         appID: 408981434, appExtVrsId: 858759843, version: "10.3.8",  estimatedSizeGB: 0.5),
                LegacyApp(name: "GarageBand",     appID: 682658836, appExtVrsId: 853773014, version: "10.4.8",  estimatedSizeGB: 1.5),
                LegacyApp(name: "Logic Pro",      appID: 634148309, appExtVrsId: 857501258, version: "10.7.9",  estimatedSizeGB: 1.3),
                LegacyApp(name: "Final Cut Pro",  appID: 424389933, appExtVrsId: 858759812, version: "10.6.8",  estimatedSizeGB: 3.5),
                LegacyApp(name: "Motion",         appID: 434290957, appExtVrsId: 858081811, version: "5.6.5",   estimatedSizeGB: 3.0),
                LegacyApp(name: "Xcode",          appID: 497799835, appExtVrsId: 853602198, version: "14.2",    estimatedSizeGB: 12.0),
            ]
        ),
    ]
}
