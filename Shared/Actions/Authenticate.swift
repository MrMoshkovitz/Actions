import AppIntents
import LocalAuthentication
import SwiftUI

struct Authenticate: AppIntent {
	static let title: LocalizedStringResource = "Authenticate"

	static let description = IntentDescription(
"""
Authenticate the user using Face ID or Touch ID.

IMPORTANT: The result is copied to the clipboard as the text “true” or “false”. Add the “Wait to Return” and “Get Clipboard” actions after this one. Use the “If” action to decide what to do with the result.
""",
		categoryName: "Device",
		searchKeywords: [
			"face id",
			"touch id",
			"faceid",
			"touchid",
			"biometry",
			"password",
			"passcode"
		]
	)

	// AppIntents cannot handle this conditional. (Xcode 14.1)
//	#if canImport(UIKit)
	static let openAppWhenRun = true
//	#endif

	@Parameter(
		title: "Open When Finished",
		description: "If provided, opens the URL instead of the Shortcuts app when finished."
	)
	var openURL: URL?

	@MainActor
	func perform() async throws -> some IntentResult {
		AppState.shared.isFullscreenOverlayPresented = true

		#if canImport(UIKit)
		defer {
			Task {
				try? await Task.sleep(for: .seconds(2))
				AppState.shared.isFullscreenOverlayPresented = false
			}
		}
		#endif

		do {
			let context = LAContext()
			try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate the shortcut")
			XPasteboard.general.stringForCurrentHostOnly = "true"
		} catch {
			XPasteboard.general.stringForCurrentHostOnly = "false"
		}

		if let openURL {
			try await openURL.openAsyncOrOpenShortcutsApp()
		} else {
			// This makes the “Wait to Return” action work.
			#if canImport(AppKit)
			NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.shortcuts").first?.hide()
			#endif

			ShortcutsApp.open()

			// TODO: This can be removed when we disable the `static let openAppWhenRun = true` for macOS again.
			#if canImport(AppKit)
			SSApp.quit()
			#endif
		}

		return .result()
	}
}
