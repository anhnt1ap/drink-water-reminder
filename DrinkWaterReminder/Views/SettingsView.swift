import SwiftUI
import ServiceManagement
import AppKit

struct SettingsView: View {
    @ObservedObject var dataManager: DataManager
    @ObservedObject var timerManager: TimerManager
    @State private var launchAtLogin: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var customMinutes: String = ""

    private let intervalOptions = [15, 30, 45, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Reminder Interval")
                    .font(.subheadline.bold())
                Picker("", selection: Binding(
                    get: {
                        intervalOptions.contains(dataManager.reminderInterval)
                            ? dataManager.reminderInterval : -1
                    },
                    set: { newValue in
                        if newValue != -1 {
                            dataManager.reminderInterval = newValue
                            customMinutes = ""
                            timerManager.logDrink(intervalMinutes: newValue)
                        }
                    }
                )) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                    Text("Custom").tag(-1)
                }
                .pickerStyle(.segmented)

                HStack(spacing: 8) {
                    TextField("1–120", text: $customMinutes)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                        .onSubmit {
                            applyCustomInterval()
                        }
                    Text("min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
            if !intervalOptions.contains(dataManager.reminderInterval) {
                customMinutes = "\(dataManager.reminderInterval)"
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func applyCustomInterval() {
        guard let value = Int(customMinutes) else {
            customMinutes = "\(dataManager.reminderInterval)"
            return
        }
        let clamped = min(max(value, 1), 120)
        customMinutes = "\(clamped)"
        dataManager.reminderInterval = clamped
        timerManager.logDrink(intervalMinutes: clamped)
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
