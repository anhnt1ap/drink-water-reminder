import Foundation
import UserNotifications
import Combine

@MainActor
class TimerManager: ObservableObject {
    @Published var nextDrinkDate: Date?
    @Published var isOverdue: Bool = false
    @Published var countdownString: String = "--:--"
    @Published var progress: Double = 1.0

    private var timerCancellable: AnyCancellable?
    private var intervalMinutes: Int = 30
    var selectedSound: String = "Default"

    func start(intervalMinutes: Int) {
        self.intervalMinutes = intervalMinutes
        nextDrinkDate = Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))
        isOverdue = false
        startTicking()
    }

    func logDrink(intervalMinutes: Int) {
        self.intervalMinutes = intervalMinutes
        nextDrinkDate = Date().addingTimeInterval(TimeInterval(intervalMinutes * 60))
        isOverdue = false
        dismissNotification()
        updateCountdown()
    }

    func updateCountdown() {
        guard let target = nextDrinkDate else {
            countdownString = "--:--"
            progress = 1.0
            return
        }

        let remaining = target.timeIntervalSinceNow
        if remaining <= 0 {
            countdownString = "00:00"
            isOverdue = true
            progress = 0.0
        } else {
            let minutes = Int(remaining) / 60
            let seconds = Int(remaining) % 60
            countdownString = String(format: "%02d:%02d", minutes, seconds)
            isOverdue = false
            let totalInterval = TimeInterval(intervalMinutes * 60)
            progress = min(remaining / totalInterval, 1.0)
        }
    }

    private func startTicking() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCountdown()
                if self?.isOverdue == true {
                    self?.fireNotificationIfNeeded()
                }
            }
    }

    // MARK: - Notifications

    /// Returns false when running inside a unit-test bundle (no app host),
    /// which prevents UNUserNotificationCenter from crashing.
    private var canUseNotifications: Bool {
        NSClassFromString("XCTestCase") == nil
    }

    func requestNotificationPermission() {
        guard canUseNotifications else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private var notificationFired = false

    private func fireNotificationIfNeeded() {
        guard !notificationFired else { return }
        notificationFired = true
        guard canUseNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to drink water!"
        content.body = "Stand up, stretch, and drink a glass of water."
        if selectedSound == "Default" {
            content.sound = .default
        } else {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(selectedSound).aiff"))
        }

        let request = UNNotificationRequest(
            identifier: "drinkReminder",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func dismissNotification() {
        notificationFired = false
        guard canUseNotifications else { return }
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: ["drinkReminder"]
        )
    }
}
