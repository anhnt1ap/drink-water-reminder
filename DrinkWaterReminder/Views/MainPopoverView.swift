import SwiftUI

enum PopoverTab: String, CaseIterable {
    case home = "Home"
    case stats = "Stats"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "drop.fill"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape"
        }
    }
}

struct MainPopoverView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var timerManager: TimerManager
    @State private var selectedTab: PopoverTab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(timerManager: timerManager, dataManager: dataManager)
                case .stats:
                    StatsView(dataManager: dataManager)
                case .settings:
                    SettingsView(dataManager: dataManager, timerManager: timerManager)
                }
            }
            .frame(height: 410)

            Divider()

            HStack {
                ForEach(PopoverTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 300, height: 450)
        .onAppear {
            timerManager.requestNotificationPermission()
            timerManager.selectedSound = dataManager.notificationSound
            if timerManager.nextDrinkDate == nil {
                timerManager.start(intervalMinutes: dataManager.reminderInterval)
            }
        }
    }
}
