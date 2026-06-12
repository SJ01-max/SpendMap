// CoreDataManager.swift

import CoreData

final class CoreDataManager {

    static let shared = CoreDataManager()
    private init() {}

    // MARK: - Stack

    lazy var persistentContainer: NSPersistentContainer = {
        // Build model programmatically — no .xcdatamodeld file dependency
        let model = CoreDataManager.makeModel()
        let container = NSPersistentContainer(name: "SpendMap", managedObjectModel: model)
        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data load error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    // MARK: - Programmatic Model (avoids bundle lookup issues)

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "Expense"
        entity.managedObjectClassName = "SpendMap.Expense"

        func str(_ name: String, optional: Bool = true) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name; a.attributeType = .stringAttributeType; a.isOptional = optional
            return a
        }
        func dbl(_ name: String, default d: Double = 0) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = name; a.attributeType = .doubleAttributeType
            a.defaultValue = d; a.isOptional = false
            return a
        }

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"; idAttr.attributeType = .UUIDAttributeType; idAttr.isOptional = true

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"; dateAttr.attributeType = .dateAttributeType; dateAttr.isOptional = true

        entity.properties = [
            idAttr,
            dbl("amount"),
            str("category"),
            str("memo"),
            dateAttr,
            dbl("latitude"),
            dbl("longitude"),
            str("placeName")
        ]
        model.entities = [entity]
        return model
    }

    // MARK: - Save

    func save() {
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { print("CoreData save error: \(error)") }
    }

    // MARK: - Create

    @discardableResult
    func createExpense(
        amount: Double,
        category: String,
        memo: String?,
        date: Date,
        latitude: Double,
        longitude: Double,
        placeName: String
    ) -> Expense {
        let expense = Expense(context: context)
        expense.id        = UUID()
        expense.amount    = amount
        expense.category  = category
        expense.memo      = memo
        expense.date      = date
        expense.latitude  = latitude
        expense.longitude = longitude
        expense.placeName = placeName
        save()
        NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
        return expense
    }

    // MARK: - Fetch

    func fetchAll() -> [Expense] {
        let req = Expense.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    func fetchForMonth(_ date: Date) -> [Expense] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        guard let start = cal.date(from: comps),
              let end   = cal.date(byAdding: .month, value: 1, to: start) else { return [] }
        return fetchForRange(from: start, to: end)
    }

    func fetchForRange(from start: Date, to end: Date) -> [Expense] {
        let req = Expense.fetchRequest()
        req.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                    start as CVarArg, end as CVarArg)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }

    func fetchRecent(_ count: Int) -> [Expense] {
        let req = Expense.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        req.fetchLimit = count
        return (try? context.fetch(req)) ?? []
    }

    // MARK: - Delete

    func delete(_ expense: Expense) {
        context.delete(expense)
        save()
        NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
    }

    func deleteAll() {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "Expense")
        let del = NSBatchDeleteRequest(fetchRequest: req)
        _ = try? context.execute(del)
        _ = try? context.save()
        NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
    }

    // MARK: - Aggregates

    func totalAmount(for expenses: [Expense]) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    func amountByCategory(for expenses: [Expense]) -> [String: Double] {
        var dict: [String: Double] = [:]
        for e in expenses { dict[e.category ?? "기타", default: 0] += e.amount }
        return dict
    }

    func dailyTotals(days: Int) -> [(date: Date, amount: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -(days - 1), to: today),
              let endOfToday = cal.date(byAdding: .day, value: 1, to: today) else { return [] }
        let expenses = fetchForRange(from: start, to: endOfToday)
        return (0..<days).compactMap { i in
            guard let dayStart = cal.date(byAdding: .day, value: i, to: start),
                  let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
            let total = expenses
                .filter { ($0.date ?? Date()) >= dayStart && ($0.date ?? Date()) < dayEnd }
                .reduce(0) { $0 + $1.amount }
            return (dayStart, total)
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let expenseDataChanged = Notification.Name("expenseDataChanged")
}
