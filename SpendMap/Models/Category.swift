// Category.swift – Expense category definitions

import UIKit

enum ExpenseCategory: String, CaseIterable {
    case cafe      = "카페"
    case meal      = "식사"
    case shopping  = "쇼핑"
    case transport = "교통"
    case other     = "기타"

    var sfSymbol: String {
        switch self {
        case .cafe:      return "cup.and.saucer.fill"
        case .meal:      return "fork.knife"
        case .shopping:  return "bag.fill"
        case .transport: return "bus.fill"
        case .other:     return "star.fill"
        }
    }

    var color: UIColor {
        switch self {
        case .cafe:      return UIColor(hex: "#F59E0B")
        case .meal:      return UIColor(hex: "#EF4444")
        case .shopping:  return UIColor(hex: "#8B5CF6")
        case .transport: return UIColor(hex: "#3B82F6")
        case .other:     return UIColor(hex: "#6B7280")
        }
    }

    static func from(_ string: String) -> ExpenseCategory {
        return ExpenseCategory(rawValue: string) ?? .other
    }
}
