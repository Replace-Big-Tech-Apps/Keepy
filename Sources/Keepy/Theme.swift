import AppKit
import CoreText
import SwiftUI

// ORBIS design language: white canvas, black ink, hairlines, one amber alert.
// Same tokens as LBrowser — swap values here to re-theme the whole app.
extension Color {
    static func dynamic(_ light: UInt32, _ dark: UInt32, alpha: Double = 1, darkAlpha: Double? = nil) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let hex = isDark ? dark : light
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: isDark ? (darkAlpha ?? alpha) : alpha
            )
        })
    }
}

enum Orbis {
    static let canvas = Color.dynamic(0xFEFEFE, 0x0A0A0B)
    static let canvasSoft = Color.dynamic(0xF5F5F5, 0x141416)
    static let surface = Color.dynamic(0x000000, 0xFFFFFF, alpha: 0.04, darkAlpha: 0.05)
    static let surfaceHover = Color.dynamic(0x000000, 0xFFFFFF, alpha: 0.07, darkAlpha: 0.09)
    static let line = Color.dynamic(0x000000, 0xFFFFFF, alpha: 0.10, darkAlpha: 0.12)
    static let lineStrong = Color.dynamic(0x000000, 0xFFFFFF, alpha: 0.22, darkAlpha: 0.28)
    static let ink = Color.dynamic(0x0A0A0B, 0xF5F5F5)
    static let inkMute = Color.dynamic(0x0A0A0B, 0xF5F5F5, alpha: 0.52, darkAlpha: 0.56)
    static let inkWhisper = Color.dynamic(0x0A0A0B, 0xF5F5F5, alpha: 0.30, darkAlpha: 0.34)
    /// Text on an ink-filled (selected) control.
    static let inkInverse = Color.dynamic(0xFEFEFE, 0x0A0A0B)

    static let alert = Color.dynamic(0xD4860A, 0xF0A22A)
    static let negative = Color.dynamic(0xB83232, 0xE06060)

    static let radiusXS: CGFloat = 3
    static let radiusSM: CGFloat = 6
}

enum OrbisFont {
    /// Zen Dots — tracked uppercase labels.
    static func display(_ size: CGFloat) -> Font { .custom("ZenDots-Regular", size: size) }
    /// Alumni Sans Pinstripe — big thin numerals and headlines.
    static func pinstripe(_ size: CGFloat) -> Font { .custom("AlumniSansPinstripe-Regular", size: size) }

    static func registerBundled() {
        guard let dir = Bundle.main.resourceURL?.appending(path: "Fonts"),
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else { return }
        for file in files where file.pathExtension == "ttf" {
            CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
        }
    }
}

extension View {
    /// ORBIS "eyebrow": 9pt Zen Dots, uppercase, 0.14em tracking.
    func eyebrow(_ color: Color = Orbis.inkWhisper, size: CGFloat = 9) -> some View {
        font(OrbisFont.display(size))
            .tracking(size * 0.14)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    func hairline(_ edges: Edge.Set, color: Color = Orbis.line) -> some View {
        overlay(alignment: .top) { if edges.contains(.top) { color.frame(height: 1) } }
            .overlay(alignment: .bottom) { if edges.contains(.bottom) { color.frame(height: 1) } }
    }
}

/// Square icon button, like ORBIS's refresh control.
struct IconButton: View {
    let symbol: String
    var help: String = ""
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .regular))
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: Orbis.radiusSM).fill(hover ? Orbis.surfaceHover : .clear))
                .foregroundStyle(Orbis.ink)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hover = $0 }
        .animation(.easeOut(duration: 0.13), value: hover)
    }
}

/// Cell in a hairline-bordered filter bar ("+5 MIN"); selected = ink fill.
struct Chip: View {
    let title: String
    var selected = false
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .eyebrow(selected ? Orbis.inkInverse : Orbis.inkMute, size: 8)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(selected ? Orbis.ink : (hover ? Orbis.surface : .clear))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

/// Moves the traffic lights so they sit centered in our taller top bar.
struct WindowChrome: NSViewRepresentable {
    static let barHeight: CGFloat = 52

    func makeNSView(context: Context) -> ChromeView { ChromeView() }
    func updateNSView(_ view: ChromeView, context: Context) { view.relayout() }

    final class ChromeView: NSView {
        private var tokens: [NSObjectProtocol] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            tokens.forEach(NotificationCenter.default.removeObserver)
            tokens = []
            guard let window else { return }
            let names: [Notification.Name] = [
                NSWindow.didResizeNotification, NSWindow.didEndLiveResizeNotification,
                NSWindow.didExitFullScreenNotification, NSWindow.didBecomeKeyNotification,
            ]
            tokens = names.map {
                NotificationCenter.default.addObserver(forName: $0, object: window, queue: .main) { [weak self] _ in
                    self?.relayout()
                }
            }
            relayout()
        }

        func relayout() {
            guard let window, !window.styleMask.contains(.fullScreen),
                  let close = window.standardWindowButton(.closeButton),
                  let titlebar = close.superview, let container = titlebar.superview else { return }
            let height = WindowChrome.barHeight
            container.frame = NSRect(x: 0, y: window.frame.height - height, width: window.frame.width, height: height)
            titlebar.frame = container.bounds
            let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
            for (i, type) in buttons.enumerated() {
                guard let b = window.standardWindowButton(type) else { continue }
                b.setFrameOrigin(NSPoint(x: 20 + CGFloat(i) * 20, y: (height - b.frame.height) / 2))
            }
        }
    }
}
