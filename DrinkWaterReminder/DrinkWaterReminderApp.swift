import SwiftUI

@main
struct DrinkWaterReminderApp: App {
    @StateObject private var timerManager = TimerManager()
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        MenuBarExtra {
            MainPopoverView(dataManager: dataManager, timerManager: timerManager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(timerManager.isOverdue ? .red : .primary)
                Text(timerManager.countdownString)
                    .font(.system(.caption2, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }
}
