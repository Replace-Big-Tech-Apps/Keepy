// Renders the ORBIS-style app icon: white squircle, black dot-matrix clock face, amber dot.
import AppKit
import Foundation

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let tile = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
NSColor(white: 0.996, alpha: 1).setFill()
tile.fill()
NSColor(white: 0, alpha: 0.10).setStroke()
tile.lineWidth = 4
tile.stroke()

let ink = NSColor(srgbRed: 0.039, green: 0.039, blue: 0.043, alpha: 1)
let center = CGPoint(x: 512, y: 512)
func dot(_ p: CGPoint, _ s: CGFloat, alpha: CGFloat = 1) {
    ink.withAlphaComponent(alpha).setFill()
    NSBezierPath(rect: NSRect(x: p.x - s / 2, y: p.y - s / 2, width: s, height: s)).fill()
}
func point(_ angle: Double, _ r: Double) -> CGPoint {
    // angle in clock hours, 0 at 12 o'clock, clockwise
    let a = .pi / 2 - angle / 12 * 2 * .pi
    return CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
}

// Dial ring of small dots, heavier at the hour marks.
for i in 0..<60 {
    let hour = i % 5 == 0
    dot(point(Double(i) / 5, 300), hour ? 26 : 12, alpha: hour ? 1 : 0.35)
}
// Hands as runs of square dots, fading toward the tips: hour → 10, minute → 2.
for (hour, length) in [(10.0, 150.0), (2.0, 230.0)] {
    var r = 30.0
    while r <= length {
        dot(point(hour, r), 22, alpha: 0.35 + 0.65 * (1 - r / length * 0.6))
        r += 30
    }
}
NSColor(srgbRed: 0.831, green: 0.525, blue: 0.039, alpha: 1).setFill()
NSBezierPath(ovalIn: NSRect(x: center.x - 36, y: center.y - 36, width: 72, height: 72)).fill()
image.unlockFocus()

let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
