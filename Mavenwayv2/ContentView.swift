import SwiftUI

// Date Filter Enum
enum DateFilter: String, CaseIterable {
    case all = "All"
    case thisMonth = "This Month"
    case nextMonth = "Next Month"
    case starred = "Starred"
}

// Main ContentView
struct ContentView: View {
    @State private var events: [Event] = [] // All events loaded
    @State private var filteredEvents: [Event] = [] // Events after applying filters
    @State private var selectedDateFilter: DateFilter = .all
    @State private var selectedCity: String? = nil // Use nil to represent "City"
    @State private var selectedCategory: String? = nil // Use nil to represent "Category"
    
    var body: some View {
        NavigationView {
            VStack {
                // Filters Section
                VStack {
                    Picker("Filter", selection: $selectedDateFilter) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Inline City and Category Filters
                    HStack {
                        Picker("City", selection: $selectedCity) {
                            Text("City  ").tag(nil as String?)
                            ForEach(availableCities(), id: \.self) { city in
                                Text(city).tag(city as String?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)

                        Picker("Category", selection: $selectedCategory) {
                            Text("Category").tag(nil as String?)
                            ForEach(availableCategories(), id: \.self) { category in
                                Text(category).tag(category as String?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
                
                // Events List
                List {
                    ForEach(filteredEvents) { event in
                        NavigationLink(
                            destination: EventDetailView(event: binding(for: event))
                        ) {
                            HStack(spacing: 16) {
                                // Calendar Icon
                                VStack(spacing: 0) {
                                    Text(formatMonth(event.dateFrom))
                                        .font(.caption2)
                                        .bold()
                                        .padding(.vertical, 2)
                                        .frame(width: 45)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                    
                                    Text(formatDay(event.dateFrom))
                                        .font(.title3)
                                        .bold()
                                        .padding(.vertical, 4)
                                        .frame(width: 45)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                                
                                // Event Details
                                VStack(alignment: .leading) {
                                    Text(event.name)
                                        .font(.headline)
                                    Text(event.city)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if event.starred {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                }
            }
            .onAppear(perform: loadEvents)
            .navigationTitle("Events")
            .onChange(of: selectedDateFilter) { _ in applyFilters() }
            .onChange(of: selectedCity) { _ in applyFilters() }
            .onChange(of: selectedCategory) { _ in applyFilters() }
        }
    }
    
    private func binding(for event: Event) -> Binding<Event> {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else {
            fatalError("Event not found")
        }
        return Binding(
            get: { self.events[index] },
            set: { newValue in
                self.events[index] = newValue
                EventManager.shared.saveEvents(self.events) // Save updated events to UserDefaults
                self.applyFilters()
            }
        )
    }



    private func applyFilters() {
        // Start with all events
        let today = Date()
        filteredEvents = events

        // Filter for upcoming events
        filteredEvents = filteredEvents.filter { event in
            if let eventDate = dateFromString(event.dateFrom) {
                return eventDate >= today
            }
            return false
        }

        // Apply the Starred filter first
        if selectedDateFilter == .starred {
            filteredEvents = filteredEvents.filter { $0.starred }
        } else {
            // Apply Date, City, and Category filters
            filteredEvents = filterByDate(events: filteredEvents, filter: selectedDateFilter)

            if let selectedCity = selectedCity {
                filteredEvents = filteredEvents.filter { $0.city == selectedCity }
            }

            if let selectedCategory = selectedCategory {
                filteredEvents = filteredEvents.filter { $0.category == selectedCategory }
            }
        }

        // Sort chronologically by `dateFrom`
        filteredEvents.sort {
            guard let date1 = dateFromString($0.dateFrom), let date2 = dateFromString($1.dateFrom) else {
                return false
            }
            return date1 < date2
        }
    }


    private func filterByDate(events: [Event], filter: DateFilter) -> [Event] {
        let today = Date()
        let calendar = Calendar.current
        
        return events.filter { event in
            guard let eventDate = dateFromString(event.dateFrom) else { return false }
            switch filter {
            case .all:
                return true
            case .thisMonth:
                return calendar.isDate(eventDate, equalTo: today, toGranularity: .month)
            case .nextMonth:
                if let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) {
                    return calendar.isDate(eventDate, equalTo: nextMonth, toGranularity: .month)
                }
                return false
            default:
                return true
            }
        }
    }

    private func availableCities() -> [String] {
        Array(Set(events.map { $0.city })).sorted()
    }

    private func availableCategories() -> [String] {
        Array(Set(events.map { $0.category ?? "" })).filter { !$0.isEmpty }.sorted()
    }

    private func loadEvents() {
        // First load saved events from UserDefaults
        let savedEvents = EventManager.shared.loadEvents()
        
        // Then try to load events from JSON
        if let url = Bundle.main.url(forResource: "events", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                var jsonEvents = try JSONDecoder().decode([Event].self, from: data)
                
                // If we have saved events, preserve their starred states
                if !savedEvents.isEmpty {
                    // Update JSON events with saved starred states
                    jsonEvents = jsonEvents.map { jsonEvent in
                        if let savedEvent = savedEvents.first(where: { $0.name == jsonEvent.name && $0.dateFrom == jsonEvent.dateFrom }) {
                            var updatedEvent = jsonEvent
                            updatedEvent.starred = savedEvent.starred
                            return updatedEvent
                        }
                        return jsonEvent
                    }
                }
                
                events = jsonEvents
                EventManager.shared.saveEvents(events)
            } catch {
                print("Error loading events from JSON: \(error)")
                // Fallback to saved events if JSON loading fails
                events = savedEvents
            }
        } else {
            // If no JSON file exists, use saved events
            events = savedEvents
        }
        
        applyFilters()
    }

    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func formatMonth(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM"
            return formatter.string(from: date).uppercased()
        }
        return dateString
    }
    
    private func formatDay(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        }
        return dateString
    }
}
