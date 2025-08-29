import SwiftUI

struct ColorScale {
    static func colorFor(elapsedSeconds: Int, thresholds: SittingTimer.Thresholds) -> Color {
        let t = Double(elapsedSeconds)
        let t0 = 0.0
        let t1 = Double(thresholds.yellow)
        let t2 = Double(thresholds.red)

        let h0: UInt32 = 0x4CAF50 // green
        let h1: UInt32 = 0xFFC107 // amber
        let h2: UInt32 = 0xF44336 // red

        if t <= t0 { return color(hex: h0) }
        if t >= t2 { return color(hex: h2) }
        if t <= t1 {
            let u = (t - t0) / max(1.0, (t1 - t0))
            return lerpColor(from: h0, to: h1, u: u)
        } else {
            let u = (t - t1) / max(1.0, (t2 - t1))
            return lerpColor(from: h1, to: h2, u: u)
        }
    }

    private static func color(hex: UInt32) -> Color {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    private static func lerpColor(from h0: UInt32, to h1: UInt32, u: Double) -> Color {
        let a = components(hex: h0)
        let b = components(hex: h1)
        let t = min(max(u, 0.0), 1.0)
        let r = a.r + (b.r - a.r) * t
        let g = a.g + (b.g - a.g) * t
        let bl = a.b + (b.b - a.b) * t
        return Color(red: r, green: g, blue: bl)
    }

    private static func components(hex: UInt32) -> (r: Double, g: Double, b: Double) {
        (Double((hex >> 16) & 0xFF)/255.0,
         Double((hex >> 8) & 0xFF)/255.0,
         Double(hex & 0xFF)/255.0)
    }
}

