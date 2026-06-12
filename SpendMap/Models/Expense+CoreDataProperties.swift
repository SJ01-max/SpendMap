// Expense+CoreDataProperties.swift

import Foundation
import CoreData

extension Expense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var memo: String?
    @NSManaged public var date: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var placeName: String?

    // MARK: - Computed helpers

    var categoryEnum: ExpenseCategory {
        ExpenseCategory.from(category ?? "")
    }

    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let str = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "₩\(str)"
    }

    var formattedDate: String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }

    var formattedDateTime: String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }
}
