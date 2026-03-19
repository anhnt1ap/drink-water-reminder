import SwiftUI

struct HomeView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var dataManager: DataManager

    private let accentBlue = Color(red: 0.290, green: 0.565, blue: 0.851)

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Drink Water")
                    .font(.headline)
                Spacer()
                if dataManager.currentStreak > 0 {
                    Label("\(dataManager.currentStreak)", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal)

            // Countdown Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        timerManager.isOverdue ? Color.red : accentBlue,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.progress)

                Text(timerManager.countdownString)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundStyle(timerManager.isOverdue ? .red : .primary)
            }

            // Log Drink Button
            Button(action: logDrink) {
                Label("Log Drink", systemImage: "drop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(accentBlue)
            .padding(.horizontal)

            // Today's Progress
            VStack(spacing: 6) {
                HStack {
                    Text("Today")
                        .font(.subheadline)
                    Spacer()
                    Text("\(dataManager.drinksToday)/\(dataManager.dailyGoal)")
                        .font(.subheadline.bold())
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        Capsule()
                            .fill(accentBlue)
                            .frame(
                                width: geo.size.width * min(
                                    Double(dataManager.drinksToday) / Double(max(dataManager.dailyGoal, 1)),
                                    1.0
                                ),
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.3), value: dataManager.drinksToday)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal)

            // Points Today
            HStack {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("\(dataManager.pointsToday) points today")
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }

    private func logDrink() {
        let points = DataManager.calculatePoints(
            reminderTime: timerManager.isOverdue ? timerManager.nextDrinkDate : nil,
            logTime: Date(),
            currentStreak: dataManager.currentStreak
        )
        let allowed = dataManager.addRecordIfAllowed(points: points)
        if allowed {
            let milestone = dataManager.streakMilestoneBonus()
            if milestone > 0 {
                dataManager.addMilestoneBonus(milestone)
            }
            timerManager.logDrink(intervalMinutes: dataManager.reminderInterval)
        }
    }
}
