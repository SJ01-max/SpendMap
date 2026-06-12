// NotificationManager.swift

import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func checkPermission(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Budget Alerts

    func checkBudgetAndNotify(currentTotal: Double) {
        let budget = UserDefaults.standard.double(forKey: "monthlyBudget")
        guard budget > 0 else { return }

        let ratio = currentTotal / budget
        if ratio >= 1.0 {
            sendBudgetNotification(
                title: "💸 예산 초과!",
                body: "이번 달 예산 \(formatAmount(budget))을 초과했습니다.",
                identifier: "budgetExceeded"
            )
        } else if ratio >= 0.8 {
            sendBudgetNotification(
                title: "⚠️ 예산 80% 도달",
                body: "이번 달 예산의 80%를 사용했습니다. 남은 예산: \(formatAmount(budget - currentTotal))",
                identifier: "budget80"
            )
        }
    }

    private func sendBudgetNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }

    private func formatAmount(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return "₩\(f.string(from: NSNumber(value: amount)) ?? "0")"
    }
}
