import SwiftUI

@main
struct MadeiraApp: App {
    init() {
        // ml1172: read the screen on the main thread; library entries, whose
        // default Resolution comes from it, are also made on other threads.
        _ = ResolutionChoices.screen
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(ClaimGamepadEvents())
                .onAppear {
                    GamepadInput.shared.start()
                    HardwareInput.shared.start()
                    JITNetworkShortcut.shared.restoreLeftover()   // also starts its network path monitor
                }
                // madeira://jit-network/... (the Madeira JIT shortcut returning, JITNetwork.swift),
                // else madeira://play?exe=... (Home Screen shortcuts, SavesAndShortcuts.swift).
                .onOpenURL { url in if !JITNetworkShortcut.shared.handle(url) { ShortcutRouter.shared.handle(url) } }
        }
    }
}

// ============================================================================
// iOS 15 compatibility shims (support for iPhone 6s / A9 / iOS 15).
//
// Madeira's deployment target is now 15.0. These wrappers keep call sites
// readable while providing the iOS 16/17 behaviour where the system has it:
// each shim branches on #available, so the same binary runs on both.
// Kept in this file (registered in the Xcode project) so no pbxproj edit is
// needed for the shim itself.
// ============================================================================

/// NavigationStack on iOS 16+, NavigationView (stack style) on iOS 15.
/// Call sites write `CompatNavigationStack { ... }` exactly like the system's
/// parameterless `CompatNavigationStack { ... }`.
struct CompatNavigationStack<Content: View>: View {
    @ViewBuilder let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack(content: content)
        } else {
            NavigationView(content: content)
                .navigationViewStyle(.stack)
        }
    }
}

/// ContentUnavailableView on iOS 17+, a plain centered stack on iOS 15.
struct CompatContentUnavailableView: View {
    let title: String
    let systemImage: String
    let description: Text?

    init(_ title: String, systemImage: String, description: Text? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
            if let description {
                description
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

/// ShareLink (iOS 16+) replacement: presents UIActivityViewController, which
/// exists since iOS 9. Used by the JIT setup and onboarding pages to share the
/// bundled shortcut file.
enum CompatShare {
    /// Share one URL through the system share sheet. iPad gets a centered
    /// popover anchor; iPhone a sheet.
    static func shareURL(_ url: URL) {
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let root = scenes.first(where: { $0.activationState == .foregroundActive })?.keyWindow?.rootViewController
                ?? scenes.first?.keyWindow?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        if UIDevice.current.userInterfaceIdiom == .pad {
            av.popoverPresentationController?.sourceView = top.view
            av.popoverPresentationController?.sourceRect = CGRect(
                x: top.view.bounds.midX, y: top.view.bounds.midY, width: 1, height: 1)
        }
        top.present(av, animated: true)
    }
}
