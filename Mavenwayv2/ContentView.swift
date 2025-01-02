import SwiftUI

enum DateFilter: String, CaseIterable {
    case all = "All"
    case thisMonth = "This Month"
    case nextMonth = "Next Month"
    case starred = "Starred"
}

struct ContentView: View {
    @State private var events: [Event] = []
    @State private var filteredEvents: [Event] = []
    @State private var selectedDateFilter: DateFilter = .all
    @State private var selectedCity: String? = nil
    @State private var selectedCategory: String? = nil
    @State private var needsRefresh = false
    
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
                
                // Events List with Pull-to-Refresh
                List {
                    
                    if events.isEmpty {
                            // Show nothing while initial loading
                            EmptyView()
                        } else if filteredEvents.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: selectedDateFilter == .starred ? "star.circle" : "calendar")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                    .padding(.top, 32)
                                
                                Text(selectedDateFilter == .starred ?
                                    "No highlighted events" :
                                    "No upcoming events")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text(selectedDateFilter == .starred ?
                                    "Star an event to see it here" :
                                    "Check back later for new events")
                                    .font(.subheadline)
                                    .foregroundColor(.gray.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                     } else {
                         ForEach(filteredEvents) { event in
                             // Your existing event cell code...
                         }
                     }
                    
                    
                    
                    ForEach(filteredEvents) { event in
                        ZStack {
                            NavigationLink(
                                destination: EventDetailView(event: binding(for: event))
                            ) {
                                EmptyView()
                            }
                            .opacity(0)
                            
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
                                
                                // Star Button
                                Button(action: {
                                    var updatedEvent = event
                                    updatedEvent.starred.toggle()
                                    if let index = events.firstIndex(where: { $0.id == event.id }) {
                                        events[index] = updatedEvent
                                    }
                                    applyFilters()
                                    needsRefresh.toggle()
                                }) {
                                    Image(systemName: event.starred ? "star.fill" : "star")
                                        .foregroundColor(event.starred ? .yellow : .gray)
                                        .font(.system(size: 22))
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                .padding(.trailing, 8)
                            }
                        }
                    }
                }
                .refreshable {
                    await refreshEvents()
                }
            }
            .onAppear(perform: loadEvents)
            .navigationTitle("Events")
            .onChange(of: selectedDateFilter) { _ in applyFilters() }
            .onChange(of: selectedCity) { _ in applyFilters() }
            .onChange(of: selectedCategory) { _ in applyFilters() }
            .onChange(of: needsRefresh) { _ in applyFilters() }
        }
    }
    
    private func refreshEvents() async {
        guard let url = URL(string: "https://maven-backend-9df3af747893.herokuapp.com/events") else {
            print("Invalid URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let fetchedEvents = try JSONDecoder().decode([Event].self, from: data)
            
            await MainActor.run {
                self.events = fetchedEvents
                self.applyFilters()
            }
        } catch {
            print("Error refreshing events: \(error)")
        }
    }

    private func binding(for event: Event) -> Binding<Event> {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else {
            fatalError("Event not found")
        }
        return Binding(
            get: { events[index] },
            set: { newValue in
                events[index] = newValue
                applyFilters()
                needsRefresh.toggle()
            }
        )
    }

    private func applyFilters() {
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

        // Sort chronologically
        filteredEvents.sort {
            guard let date1 = dateFromString($0.dateFrom),
                  let date2 = dateFromString($1.dateFrom) else {
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
            case .starred:
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
        guard let url = URL(string: "https://maven-backend-9df3af747893.herokuapp.com/events") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching events: \(error)")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            do {
                let fetchedEvents = try JSONDecoder().decode([Event].self, from: data)
                
                DispatchQueue.main.async {
                    self.events = fetchedEvents
                    self.applyFilters()
                }
            } catch {
                print("Error decoding events: \(error)")
            }
        }.resume()
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
