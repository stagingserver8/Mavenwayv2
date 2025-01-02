struct Event: Codable, Identifiable, Equatable {
    let id: String  // Changed to String to match MongoDB _id
    let name: String
    let host: String
    let city: String
    let dateFrom: String
    let dateTo: String
    let category: String?
    let link: String?
    
    // Make starred a computed property
    var starred: Bool {
        get {
            EventManager.shared.isEventStarred(id)
        }
        set {
            EventManager.shared.toggleEventStarred(id)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"  // Map to MongoDB's _id
        case name
        case host
        case city
        case dateFrom
        case dateTo
        case category
        case link
        // Remove starred from CodingKeys since it's now computed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unnamed Event"
        host = try container.decode(String.self, forKey: .host)
        city = try container.decode(String.self, forKey: .city)
        dateFrom = try container.decode(String.self, forKey: .dateFrom)
        dateTo = try container.decode(String.self, forKey: .dateTo)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        // Remove starred initialization since it's now computed
    }

    // Custom encode implementation to exclude starred
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(city, forKey: .city)
        try container.encode(dateFrom, forKey: .dateFrom)
        try container.encode(dateTo, forKey: .dateTo)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(link, forKey: .link)
    }

    // Update Equatable conformance
    static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.host == rhs.host &&
               lhs.city == rhs.city &&
               lhs.dateFrom == rhs.dateFrom &&
               lhs.dateTo == rhs.dateTo &&
               lhs.category == rhs.category &&
               lhs.link == rhs.link &&
               lhs.starred == rhs.starred
    }
}
