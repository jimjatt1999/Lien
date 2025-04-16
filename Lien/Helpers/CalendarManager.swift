import Foundation
import EventKit
import SwiftUI // For Color

class CalendarManager: ObservableObject {
    let eventStore = EKEventStore()
    @Published var hasCalendarAccess: Bool = false
    @Published var reminderPermissionStatus: EKAuthorizationStatus = .notDetermined

    init() {
        checkCalendarAuthorizationStatus()
        checkReminderAuthorizationStatus()
    }

    // MARK: - Authorization Checks

    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.hasCalendarAccess = (status == .authorized)
        }
    }
    
    func checkReminderAuthorizationStatus() {
         let status = EKEventStore.authorizationStatus(for: .reminder)
         DispatchQueue.main.async {
             self.reminderPermissionStatus = status
         }
     }

    func requestCalendarAccess(completion: @escaping (Bool, Error?) -> Void) {
        eventStore.requestFullAccessToEvents {(granted, error) in
            DispatchQueue.main.async {
                self.hasCalendarAccess = granted
                completion(granted, error)
            }
        }
    }
    
    func requestReminderAccess(completion: @escaping (Bool, Error?) -> Void) {
         eventStore.requestFullAccessToReminders {(granted, error) in
             DispatchQueue.main.async {
                 self.reminderPermissionStatus = granted ? .authorized : .denied
                 completion(granted, error)
             }
         }
     }

    // MARK: - Event Creation

    func addEventToCalendar(title: String, startDate: Date, endDate: Date? = nil, notes: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
        guard hasCalendarAccess else {
            print("Calendar access not granted.")
            // Optionally trigger requestCalendarAccess here or inform user
            completion(false, nil) // Indicate failure due to permissions
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        // If no end date, make it a 1-hour event by default
        event.endDate = endDate ?? Calendar.current.date(byAdding: .hour, value: 1, to: startDate)
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents // Use the default calendar

        do {
            try eventStore.save(event, span: .thisEvent)
            print("Event added to calendar successfully.")
            completion(true, nil)
        } catch let error {
            print("Failed to save event: \(error.localizedDescription)")
            completion(false, error)
        }
    }
    
    // MARK: - Reminder Creation (Example)
    
    func addReminder(title: String, dueDate: Date?, notes: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
         guard reminderPermissionStatus == .authorized else {
             print("Reminder access not granted.")
             completion(false, nil)
             return
         }
         
         let reminder = EKReminder(eventStore: eventStore)
         reminder.title = title
         reminder.notes = notes
         
         if let dueDate = dueDate {
             reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
         }
         
         // Assign to a default reminder list (consider letting user choose)
         reminder.calendar = eventStore.defaultCalendarForNewReminders()
         
         do {
             try eventStore.save(reminder, commit: true)
             print("Reminder added successfully.")
             completion(true, nil)
         } catch let error {
             print("Failed to save reminder: \(error.localizedDescription)")
             completion(false, error)
         }
     }
} 