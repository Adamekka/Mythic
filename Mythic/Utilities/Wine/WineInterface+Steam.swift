import Foundation

extension Wine {
    struct SteamWebHelper {
        // The build appends this stable PE overlay so wrapper upgrades remain distinguishable from Valve's executable.
        static let ownershipMarker = Data("MythicSteamWebHelperWrapper:v1".utf8)
        private static let preparationLock = NSLock()

        static func prepare(at steamExecutable: URL, wrapperURL: URL) throws {
            preparationLock.lock()
            defer { preparationLock.unlock() }

            let helper = steamExecutable.deletingLastPathComponent().appending(path: "bin/cef/cef.win64/steamwebhelper.exe")
            let original = helper.deletingLastPathComponent().appending(path: "steamwebhelper.mythic-original.exe")
            do {
                guard FileManager.default.fileExists(atPath: wrapperURL.path) else {
                    throw PreparationError.invalidWrapper
                }
                let wrapper = try Data(contentsOf: wrapperURL)
                guard wrapper.starts(with: [0x4D, 0x5A]),
                      wrapper.suffix(ownershipMarker.count) == ownershipMarker else {
                    throw PreparationError.invalidWrapper
                }
                guard FileManager.default.fileExists(atPath: helper.path) else {
                    throw PreparationError.missingOriginal
                }
                let installed = try Data(contentsOf: helper)
                if installed.suffix(ownershipMarker.count) == ownershipMarker {
                    guard FileManager.default.fileExists(atPath: original.path) else {
                        throw PreparationError.missingOriginal
                    }
                    let savedOriginal = try Data(contentsOf: original)
                    guard savedOriginal.starts(with: [0x4D, 0x5A]),
                          savedOriginal.suffix(ownershipMarker.count) != ownershipMarker else {
                        throw PreparationError.missingOriginal
                    }
                } else {
                    guard installed.starts(with: [0x4D, 0x5A]) else {
                        throw PreparationError.missingOriginal
                    }
                    // Save Valve's current file before replacement. A Steam update becomes the new original on the next launch.
                    // Atomic writes leave the genuine helper usable if preparation stops before the wrapper is installed.
                    try installed.write(to: original, options: .atomic)
                }
                if installed != wrapper {
                    try wrapper.write(to: helper, options: .atomic)
                }
            } catch let error as PreparationError {
                throw error
            } catch {
                throw PreparationError.fileAccess(error)
            }
        }

        enum PreparationError: LocalizedError {
            case invalidWrapper
            case missingOriginal
            case fileAccess(Error)

            var errorDescription: String? {
                switch self {
                case .invalidWrapper:
                    return String(localized: "Mythic's Steam browser helper is missing or damaged. Reinstall Mythic, then try again.")
                case .missingOriginal:
                    return String(localized: "Steam's browser files are missing or damaged. Repair or reinstall Windows Steam, then try again.")
                case .fileAccess(let error):
                    let message = String(localized: "Unable to update Steam's browser files. Close Steam and check that its folder is writable, then try again.")
                    #if DEBUG
                    return message + "\n" + error.localizedDescription
                    #else
                    return message
                    #endif
                }
            }
        }
    }
}
