import Foundation
import ScreenCaptureKit

public struct ScreenCaptureKitSourceProvider: Sendable {
    public init() {}

    public func listingState() async -> CaptureSourceListingState {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            return .sources(mapApplications(content.applications) + mapWindows(content.windows))
        } catch {
            if isPermissionDenied(error) {
                return .permissionDenied
            }
            return .failed(String(describing: error))
        }
    }

    private func mapApplications(_ applications: [SCRunningApplication]) -> [CaptureSource] {
        applications.map { application in
            CaptureSource(
                kind: .application,
                id: UInt32(application.processID),
                name: application.applicationName,
                processID: application.processID,
                bundleIdentifier: application.bundleIdentifier
            )
        }
    }

    private func mapWindows(_ windows: [SCWindow]) -> [CaptureSource] {
        windows.map { window in
            CaptureSource(
                kind: .window,
                id: window.windowID,
                name: window.title ?? "",
                owningApplicationName: window.owningApplication?.applicationName,
                processID: window.owningApplication?.processID,
                bundleIdentifier: window.owningApplication?.bundleIdentifier
            )
        }
    }

    private func isPermissionDenied(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == SCStreamErrorDomain && nsError.code == -3801
    }
}
