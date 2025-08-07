import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Notification Permission
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Limit Alerts
    
    func checkAndSendLimitAlerts(for cards: [CreditCard], preferences: UserPreferences) {
        guard preferences.notificationsEnabled else { return }
        
        for card in cards {
            for spendingLimit in card.spendingLimits {
                let usagePercentage = spendingLimit.usagePercentage
                let alertThreshold = preferences.alertThreshold
                
                if usagePercentage >= 1.0 && !spendingLimit.isLimitReached {
                    // Limit reached
                    sendLimitReachedNotification(for: card, category: spendingLimit.category)
                } else if usagePercentage >= alertThreshold && !spendingLimit.isWarningThreshold {
                    // Warning threshold
                    sendLimitWarningNotification(for: card, category: spendingLimit.category, usagePercentage: usagePercentage)
                }
            }
        }
    }
    
    private func sendLimitReachedNotification(for card: CreditCard, category: SpendingCategory) {
        let content = UNMutableNotificationContent()
        content.title = "Limit Reached"
        content.body = "Your \(card.name) has reached its limit for \(category.rawValue.lowercased()). Consider using another card."
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "limit-reached-\(card.id)-\(category.rawValue)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending limit reached notification: \(error)")
            }
        }
    }
    
    private func sendLimitWarningNotification(for card: CreditCard, category: SpendingCategory, usagePercentage: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Limit Warning"
        content.body = "Your \(card.name) is \(Int(usagePercentage * 100))% full for \(category.rawValue.lowercased())."
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: "limit-warning-\(card.id)-\(category.rawValue)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending limit warning notification: \(error)")
            }
        }
    }
    
    // MARK: - Spending Reminders
    
    func scheduleSpendingReminder(for card: CreditCard, category: SpendingCategory, amount: Double) {
        guard let preferences = loadUserPreferences(), preferences.notificationsEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Spending Reminder"
        content.body = "Don't forget to update your \(card.name) spending for \(category.rawValue.lowercased()): $\(String(format: "%.2f", amount))"
        content.sound = .default
        
        // Schedule for 1 hour later
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "spending-reminder-\(card.id)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling spending reminder: \(error)")
            }
        }
    }
    
    // MARK: - Quarterly Bonus Reminders
    
    func checkQuarterlyBonusReminders(for cards: [CreditCard]) {
        let currentQuarter = Calendar.currentQuarter
        let currentYear = Calendar.current.component(.year, from: Date())
        
        for card in cards {
            if let quarterlyBonus = card.quarterlyBonus,
               quarterlyBonus.quarter == currentQuarter,
               quarterlyBonus.year == currentYear {
                
                let usagePercentage = quarterlyBonus.currentSpending / quarterlyBonus.limit
                
                if usagePercentage >= 0.9 && usagePercentage < 1.0 {
                    sendQuarterlyBonusReminder(for: card, quarterlyBonus: quarterlyBonus)
                }
            }
        }
    }
    
    private func sendQuarterlyBonusReminder(for card: CreditCard, quarterlyBonus: QuarterlyBonus) {
        let content = UNMutableNotificationContent()
        content.title = "Quarterly Bonus Alert"
        content.body = "Your \(card.name) quarterly bonus for \(quarterlyBonus.category.rawValue.lowercased()) is almost maxed out. Use it while you can!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "quarterly-bonus-\(card.id)-\(quarterlyBonus.category.rawValue)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending quarterly bonus reminder: \(error)")
            }
        }
    }
    
    // MARK: - Daily Summary
    
    func scheduleDailySummary() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Card Summary"
        content.body = "Check your credit card spending progress and get recommendations for today's purchases."
        content.sound = .default
        
        // Schedule for 9 AM daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily summary: \(error)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotifications(for cardId: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let cardNotifications = requests.filter { $0.identifier.contains(cardId.uuidString) }
            let identifiers = cardNotifications.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadUserPreferences() -> UserPreferences? {
        // This would typically load from UserDefaults or Core Data
        // For now, return default preferences
        return UserPreferences()
    }
    
    // MARK: - Notification Categories
    
    func setupNotificationCategories() {
        let limitReachedCategory = UNNotificationCategory(
            identifier: "LIMIT_REACHED",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_CARDS",
                    title: "View Cards",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Dismiss",
                    options: [.destructive]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let limitWarningCategory = UNNotificationCategory(
            identifier: "LIMIT_WARNING",
            actions: [
                UNNotificationAction(
                    identifier: "UPDATE_SPENDING",
                    title: "Update Spending",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Dismiss",
                    options: [.destructive]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            limitReachedCategory,
            limitWarningCategory
        ])
    }
}

// MARK: - Notification Extensions

extension NotificationService {
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "VIEW_CARDS":
            // Navigate to cards view
            NotificationCenter.default.post(name: .navigateToCards, object: nil)
        case "UPDATE_SPENDING":
            // Navigate to spending update
            NotificationCenter.default.post(name: .navigateToSpendingUpdate, object: nil)
        case "DISMISS":
            // Dismiss notification
            break
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToCards = Notification.Name("navigateToCards")
    static let navigateToSpendingUpdate = Notification.Name("navigateToSpendingUpdate")
    static let limitAlertTriggered = Notification.Name("limitAlertTriggered")
    static let spendingReminderTriggered = Notification.Name("spendingReminderTriggered")
} 