// AppColors.swift – SpendMap Design System

import UIKit

extension UIColor {
    convenience init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.hasPrefix("#") ? String(s.dropFirst()) : s
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    // MARK: - Brand Colors
    static let smPrimary        = UIColor(hex: "#00C896") // Mint Green
    static let smBackground     = UIColor(hex: "#0D1B2A") // Deep Navy
    static let smSurface        = UIColor(hex: "#112436") // Card Background
    static let smSurface2       = UIColor(hex: "#1A3248") // Elevated surface
    static let smGold           = UIColor(hex: "#F4B860") // Gold accent
    static let smDanger         = UIColor(hex: "#E8667A") // Coral / Danger
    static let smTextPrimary    = UIColor.white
    static let smTextSecondary  = UIColor(hex: "#A8D5C8")
    static let smSeparator      = UIColor(hex: "#1E3A50")
}
