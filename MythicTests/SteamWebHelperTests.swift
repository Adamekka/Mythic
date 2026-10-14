import Foundation
import XCTest

final class SteamWebHelperTests: XCTestCase {
    private static let valveV1 = Data("MZ-test-Valve-v1".utf8)
    private static let valveV2 = Data("MZ-test-Valve-v2".utf8)
    private static let wrapperV1 = Data("MZ-test-Mythic-v1".utf8) + Wine.SteamWebHelper.ownershipMarker
    private static let wrapperV2 = Data("MZ-test-Mythic-v2".utf8) + Wine.SteamWebHelper.ownershipMarker

    private struct Installation {
        let root: URL
        let steam: URL
        let directory: URL
        let helper: URL
        let original: URL
        let wrapper: URL

        init() throws {
            root = FileManager.default.temporaryDirectory.appending(path: "MythicSteamWebHelperTests-\(UUID())")
            steam = root.appending(path: "Steam folder/steam.exe")
            directory = steam.deletingLastPathComponent().appending(path: "bin/cef/cef.win64")
            helper = directory.appending(path: "steamwebhelper.exe")
            original = directory.appending(path: "steamwebhelper.mythic-original.exe")
            wrapper = root.appending(path: "wrapper.exe")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            // Fixtures are confined to this temporary installation and passed explicitly to production code.
            try SteamWebHelperTests.valveV1.write(to: helper)
            try SteamWebHelperTests.wrapperV1.write(to: wrapper)
        }
    }

    private func withInstallation(_ test: (Installation) throws -> Void) throws {
        let installation = try Installation()
        defer { try? FileManager.default.removeItem(at: installation.root) }
        try test(installation)
    }

    func testFirstLaunchPreservesValveHelper() throws {
        try withInstallation { installation in
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.wrapperV1)
            XCTAssertEqual(try Data(contentsOf: installation.original), Self.valveV1)
        }
    }

    func testRepeatLaunchDoesNotSaveWrapperAsOriginal() throws {
        try withInstallation { installation in
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            XCTAssertEqual(try Data(contentsOf: installation.original), Self.valveV1)
        }
    }

    func testMythicUpgradePreservesValveHelper() throws {
        try withInstallation { installation in
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            try Self.wrapperV2.write(to: installation.wrapper)
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.wrapperV2)
            XCTAssertEqual(try Data(contentsOf: installation.original), Self.valveV1)
        }
    }

    func testSteamUpdateRefreshesOriginalAndReappliesWrapper() throws {
        try withInstallation { installation in
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            try Self.valveV2.write(to: installation.helper)
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            XCTAssertEqual(try Data(contentsOf: installation.original), Self.valveV2)
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.wrapperV1)
        }
    }

    func testInterruptedPreparationCanBeRepeated() throws {
        try withInstallation { installation in
            // Simulate stopping after the original's atomic write and before installing the wrapper.
            try Self.valveV1.write(to: installation.original)
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            XCTAssertEqual(try Data(contentsOf: installation.original), Self.valveV1)
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.wrapperV1)
        }
    }

    func testWrapperCannotBeUsedAsSavedOriginal() throws {
        try withInstallation { installation in
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            try Self.wrapperV1.write(to: installation.original)
            XCTAssertThrowsError(try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)) { error in
                guard case Wine.SteamWebHelper.PreparationError.missingOriginal = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.wrapperV1)
        }
    }

    func testMissingSavedOriginalIsRejected() throws {
        try withInstallation { installation in
            try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)
            try FileManager.default.removeItem(at: installation.original)
            XCTAssertThrowsError(try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)) { error in
                guard case Wine.SteamWebHelper.PreparationError.missingOriginal = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.wrapperV1)
        }
    }

    func testMissingHelperIsRejected() throws {
        try withInstallation { installation in
            try FileManager.default.removeItem(at: installation.helper)
            XCTAssertThrowsError(try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)) { error in
                guard case Wine.SteamWebHelper.PreparationError.missingOriginal = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }

    func testInvalidWrapperPreservesValveHelper() throws {
        try withInstallation { installation in
            try Data("not a wrapper".utf8).write(to: installation.wrapper)
            XCTAssertThrowsError(try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)) { error in
                guard case Wine.SteamWebHelper.PreparationError.invalidWrapper = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.valveV1)
        }
    }

    func testMissingWrapperPreservesValveHelper() throws {
        try withInstallation { installation in
            try FileManager.default.removeItem(at: installation.wrapper)
            XCTAssertThrowsError(try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)) { error in
                guard case Wine.SteamWebHelper.PreparationError.invalidWrapper = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.valveV1)
        }
    }

    func testFailedBackupWriteLeavesValveHelperIntact() throws {
        try withInstallation { installation in
            try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: installation.directory.path)
            defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installation.directory.path) }
            XCTAssertThrowsError(try Wine.SteamWebHelper.prepare(at: installation.steam, wrapperURL: installation.wrapper)) { error in
                guard case Wine.SteamWebHelper.PreparationError.fileAccess = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
            XCTAssertEqual(try Data(contentsOf: installation.helper), Self.valveV1)
        }
    }
}
