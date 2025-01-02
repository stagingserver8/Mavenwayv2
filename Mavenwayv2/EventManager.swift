import Foundation

class EventManager {
    static let shared = EventManager()
    private let starredEventsKey = "starredEventIds"
    
    private init() {}
    
    func isEventStarred(_ eventId: String) -> Bool {
        let starredEvents = getStarredEventIds()
        return starredEvents.contains(eventId)
    }
    
    func toggleEventStarred(_ eventId: String) {
        var starredEvents = getStarredEventIds()
        if starredEvents.contains(eventId) {
            starredEvents.remove(eventId)
        } else {
            starredEvents.insert(eventId)
        }
        UserDefaults.standard.set(Array(starredEvents), forKey: starredEventsKey)
        UserDefaults.standard.synchronize()
    }
    
    private func getStarredEventIds() -> Set<String> {
        let starredArray = UserDefaults.standard.array(forKey: starredEventsKey) as? [String] ?? []
        return Set(starredArray)
    }
}
