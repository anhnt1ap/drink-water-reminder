import SwiftUI

@main
struct DrinkWaterReminderApp: App {
    var body: some Scene {
        MenuBarExtra("Drink Water", systemImage: "drop.fill") {
            Text("Hello, Drink Water!")
                .frame(width: 300, height: 450)
        }
        .menuBarExtraStyle(.window)
    }
}
