import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var dataManager: DataManager

    private let accentBlue = Color(red: 0.290, green: 0.565, blue: 0.851)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Today")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        StatCard(icon: "drop.fill", value: "\(dataManager.drinksToday)/\(dataManager.dailyGoal)", label: "Glasses")
                        StatCard(icon: "star.fill", value: "\(dataManager.pointsToday)", label: "Points")
                    }

                    HStack(spacing: 16) {
                        StatCard(icon: "flame.fill", value: "\(dataManager.currentStreak)", label: "Streak")
                        StatCard(icon: "trophy.fill", value: "\(dataManager.longestStreak)", label: "Best")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.headline)

                    Chart {
                        ForEach(dataManager.weeklyData, id: \.date) { entry in
                            BarMark(
                                x: .value("Day", entry.date, unit: .day),
                                y: .value("Glasses", entry.count)
                            )
                            .foregroundStyle(
                                entry.count >= dataManager.dailyGoal
                                    ? Color.green
                                    : Color.gray.opacity(0.4)
                            )
                            .cornerRadius(4)
                        }

                        RuleMark(y: .value("Goal", dataManager.dailyGoal))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            .foregroundStyle(accentBlue.opacity(0.6))
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 160)
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}
