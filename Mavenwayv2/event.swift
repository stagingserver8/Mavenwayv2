import Foundation

import Foundation

struct Event: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var host: String
    var city: String
    var dateFrom: String
    var dateTo: String
    var starred: Bool = false
    var category: String?
    var link: String? // New property for the event agenda link

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case host
        case city
        case dateFrom
        case dateTo
        case category
        case starred
        case link
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unnamed Event"
        host = try container.decode(String.self, forKey: .host)
        city = try container.decode(String.self, forKey: .city)
        dateFrom = try container.decode(String.self, forKey: .dateFrom)
        dateTo = try container.decode(String.self, forKey: .dateTo)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        starred = try container.decodeIfPresent(Bool.self, forKey: .starred) ?? false
        link = try container.decodeIfPresent(String.self, forKey: .link) // Decode the link property
    }

    // Equatable conformance
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.host == rhs.host &&
               lhs.city == rhs.city &&
               lhs.dateFrom == rhs.dateFrom &&
               lhs.dateTo == rhs.dateTo &&
               lhs.starred == rhs.starred &&
               lhs.category == rhs.category &&
               lhs.link == rhs.link
    }
}
