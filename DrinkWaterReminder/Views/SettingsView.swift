import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var timerManager: TimerManager
    @State private var launchAtLogin: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let intervalOptions = [15, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Reminder Interval")
                    .font(.subheadline.bold())
                Picker("", selection: $dataManager.reminderInterval) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: dataManager.reminderInterval) { newValue in
                    timerManager.logDrink(intervalMinutes: newValue)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Goal")
                    .font(.subheadline.bold())
                Stepper(
                    "\(dataManager.dailyGoal) glasses",
                    value: $dataManager.dailyGoal,
                    in: 1...20
                )
            }

            // Notification Sound
            VStack(alignment: .leading, spacing: 6) {
                Text("Notification Sound")
                    .font(.subheadline.bold())
                Picker("", selection: $dataManager.notificationSound) {
                    ForEach(DataManager.availableSounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: dataManager.notificationSound) { newValue in
                    timerManager.selectedSound = newValue
                    if newValue != "Default" {
                        NSSound(named: NSSound.Name(newValue))?.play()
                    }
                }
            }

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { newValue in
                    toggleLaunchAtLogin(enabled: newValue)
                }

            Spacer()

            VStack(spacing: 2) {
                Text("Drink Water Reminder v1.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Stay hydrated, stay healthy")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .onAppear {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = "Failed to update login item: \(error.localizedDescription)"
            showError = true
            launchAtLogin = !enabled
        }
    }
}
