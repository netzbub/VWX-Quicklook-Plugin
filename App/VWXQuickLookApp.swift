import SwiftUI

// The host app only exists to carry the Quick Look extensions.
// Launching it once registers them with the system.

@main
struct VWXQuickLookApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 12) {
                Text("VWX QuickLook").font(.title2).bold()
                Text("Quick Look previews and Finder thumbnails for Vectorworks® files (.vwx, .sta, .vwxp, .vwxw).")
                Text("The extensions are now registered. This app can be closed; keep it in /Applications.")
                    .foregroundStyle(.secondary)
                Text("Not affiliated with or endorsed by Vectorworks, Inc. or Nemetschek Group.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(width: 460)
        }
        .windowResizability(.contentSize)
    }
}
