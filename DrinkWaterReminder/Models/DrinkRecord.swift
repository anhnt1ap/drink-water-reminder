import Foundation

struct DrinkRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let points: Int

    init(id: UUID = UUID(), timestamp: Date = Date(), points: Int) {
        self.id = id
        self.timestamp = timestamp
        self.points = points
    }
}
