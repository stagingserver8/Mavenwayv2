//
//  EventsManager.swift
//  Mavenwayv2
//
//  Created by Michal Chojnacki on 30/12/2024.

import Foundation

class EventManager {
    static let shared = EventManager()
    private let eventsKey = "savedEvents"
    
    private init() {}
    
    func loadEvents() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: eventsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let events = try decoder.decode([Event].self, from: data)
            return events
        } catch {
            print("Error decoding events: \(error)")
            return []
        }
    }
    
    func saveEvents(_ events: [Event]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(events)
            UserDefaults.standard.set(data, forKey: eventsKey)
            UserDefaults.standard.synchronize() // Force immediate write
        } catch {
            print("Error encoding events: \(error)")
        }
    }
    
    func updateEvent(_ event: Event) {
        var events = loadEvents()
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents(events)
        }
    }
}

