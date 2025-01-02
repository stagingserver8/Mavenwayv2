//
//  EventService.swift
//  Mavenwayv2
//
//  Created by Michal Chojnacki on 01/01/2025.
//



/*
class EventService {
    static let shared = EventService()
    private let baseURL = "http://localhost:3000"

    func fetchEvents() async throws -> [Event] {
        guard let url = URL(string: "\(baseURL)/events") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Event].self, from: data)
    }
    
    func updateEvent(_ event: Event) async throws {
        guard let url = URL(string: "\(baseURL)/events/\(event.id)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data = try JSONEncoder().encode(event)
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}

*/
