

import SwiftUI
import EventKit

struct EventDetailView: View {
    @Binding var event: Event
    @State private var showingSafari = false
    @State private var showingCalendarAlert = false
    @State private var calendarError: String?
    let eventStore = EKEventStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row with calendar icon, title, and action buttons
            HStack(alignment: .top) {
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.name)
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 4)
                    
                    Text(formatDates(from: event.dateFrom, to: event.dateTo))
                        .foregroundColor(.gray)
                    
                    Text(event.city)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Text("Host:")
                            .bold()
                        Text(event.host)
                    }
                    
                    if let category = event.category {
                        HStack(spacing: 4) {
                            Text("Category:")
                                .bold()
                            Text(category)
                        }
                    }
                }
                .font(.subheadline)
                .padding(.leading, 12)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {
                        addToCalendar()
                    }) {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    
                    Button(action: {
                        event.starred.toggle()
                        print("Star toggled for event: \(event.id), New starred status: \(event.starred)")
                        EventManager.shared.updateEvent(event)
                    }) {
                        Image(systemName: event.starred ? "star.fill" : "star")
                            .foregroundColor(event.starred ? .yellow : .gray)
                            .font(.title2)
                    }
                }
            }
            
            Spacer()

            // View Agenda Button
            if let link = event.link, !link.isEmpty, let url = URL(string: link) {
                Button(action: {
                    showingSafari = true // Show the SafariView
                }) {
                    Text("View Agenda")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .sheet(isPresented: $showingSafari) {
                    SafariView(url: url) // Present SafariView as a sheet
                }
            }
        }
        .padding()
        .navigationTitle("Event Details")
        .alert("Calendar Access", isPresented: $showingCalendarAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(calendarError ?? "Unknown error occurred")
        }
    }

    // Emd
    
    
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
    
    private func formatDates(from: String, to: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let fromDate = formatter.date(from: from) else { return from }
        guard let toDate = formatter.date(from: to) else { return from }
        
        formatter.dateFormat = "dd-MMM"
        
        if fromDate == toDate {
            return formatter.string(from: fromDate)
        } else {
            return "\(formatter.string(from: fromDate)) to \(formatter.string(from: toDate))"
        }
    }
    
    private func addToCalendar() {
        Task {
            do {
                let accessGranted = try await eventStore.requestAccess(to: .event)
                if accessGranted {
                    await createCalendarEvent()
                } else {
                    await MainActor.run {
                        self.calendarError = "Please allow calendar access in Settings to add events."
                        self.showingCalendarAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.calendarError = "Error accessing calendar: \(error.localizedDescription)"
                    self.showingCalendarAlert = true
                }
            }
        }
    }
    
    private func createCalendarEvent() async {
        guard !event.name.isEmpty else {
            await MainActor.run {
                self.calendarError = "Event must have a name"
                self.showingCalendarAlert = true
            }
            return
        }
        
        let newEvent = EKEvent(eventStore: eventStore)
        newEvent.title = event.name.trimmingCharacters(in: .whitespacesAndNewlines)
        newEvent.location = event.city
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let startDate = formatter.date(from: event.dateFrom),
           let endDate = formatter.date(from: event.dateTo) {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            let startDateTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startDate) ?? startDate
            let endDateTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: endDate) ?? endDate
            
            newEvent.startDate = startDateTime
            newEvent.endDate = endDateTime
            newEvent.timeZone = TimeZone.current
            newEvent.notes = """
            Host: \(event.host)
            Category: \(event.category ?? "Not Specified")
            """
            
            // Set the event's calendar to the default calendar
            if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                newEvent.calendar = defaultCalendar
            } else {
                await MainActor.run {
                    self.calendarError = "No default calendar available. Please configure one in your Calendar app."
                    self.showingCalendarAlert = true
                }
                return
            }
            
            do {
                try eventStore.save(newEvent, span: .thisEvent)
                await MainActor.run {
                    self.calendarError = "Event successfully added to calendar!"
                    self.showingCalendarAlert = true
                }
            } catch {
                await MainActor.run {
                    self.calendarError = "Failed to save event: \(error.localizedDescription)"
                    self.showingCalendarAlert = true
                }
            }
        } else {
            await MainActor.run {
                self.calendarError = "Invalid date format"
                self.showingCalendarAlert = true
            }
        }
    }

}

