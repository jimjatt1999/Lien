import UserNotifications
import UIKit // For UIApplication

class NotificationManager {
    
    static let shared = NotificationManager()
    private init() {} // Singleton pattern
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Ensure completion handler is called on the main thread
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification authorization: \(error.localizedDescription)")
                }
                completion(granted, error)
            }
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // Helper to open app settings if needed
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString), 
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
    
    // MARK: - Scheduling Connection Reminders
    
    func scheduleConnectionReminders(entries: [LienViewModel.ConnectionGoalEntry]) {
        // 1. Remove previously scheduled connection reminders to avoid duplicates
        //    We need a way to identify these specific notifications.
        //    Let's use identifiers starting with a specific prefix.
        let reminderPrefix = "lien_connection_reminder_"
        notificationCenter.getPendingNotificationRequests { requests in
            let reminderIdentifiers = requests.filter { $0.identifier.hasPrefix(reminderPrefix) }.map { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers)
            print("Removed \(reminderIdentifiers.count) pending connection reminders.")
            
            // 2. Schedule new reminders
            self.scheduleNewReminders(entries: entries, prefix: reminderPrefix)
        }
    }
    
    private func scheduleNewReminders(entries: [LienViewModel.ConnectionGoalEntry], prefix: String) {
        var scheduledCount = 0
        for entry in entries {
            let personName = entry.person.name
            let identifier = "\(prefix)\(entry.id.uuidString)" // Unique ID per person
            
            var title = ""
            var body = ""
            var shouldSchedule = false
            var triggerDate: Date? = nil
            
            switch entry.status {
            case .overdue(let days):
                title = "Connection Overdue"
                body = "It's been a while since you connected with \(personName). Time to reach out! (Overdue by \(days)d)"
                shouldSchedule = true
                // Schedule for tomorrow morning? Or immediate?
                triggerDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) // Example: Tomorrow
                
            case .dueIn(let days):
                if days <= 1 { // Notify if due today or tomorrow
                    title = "Connect Soon"
                    body = "Remember to connect with \(personName) \(days == 0 ? "today" : "soon")!"
                    shouldSchedule = true
                    // Schedule for today/tomorrow morning?
                    triggerDate = Date() // Example: Now (or adjust time component)
                }
                
            case .neverContacted:
                title = "Connect with \(personName)"
                body = "Don't forget to make an initial connection with \(personName)!"
                shouldSchedule = true
                 // Schedule for tomorrow morning?
                 triggerDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) // Example: Tomorrow

            case .noGoalSet:
                shouldSchedule = false
            }
            
            // Ensure we have a valid date for scheduling
            guard shouldSchedule, var dateToSchedule = triggerDate else { continue }
            
            // --- Set a specific time (e.g., 9:00 AM) ---
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dateToSchedule)
            dateComponents.hour = 9
            dateComponents.minute = 0
            
            // Try to get 9AM today or 9AM tomorrow
            let potentialTriggerDateToday = Calendar.current.date(from: dateComponents)
            var finalTriggerDate: Date?

            if let today9AM = potentialTriggerDateToday, today9AM > Date() {
                // Today 9AM is valid and in the future
                finalTriggerDate = today9AM
            } else {
                // Today 9AM is nil or already past, try tomorrow 9AM
                if let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: dateToSchedule) {
                    var tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrowDate)
                    tomorrowComponents.hour = 9
                    tomorrowComponents.minute = 0
                    if let tomorrow9AM = Calendar.current.date(from: tomorrowComponents), tomorrow9AM > Date() {
                        // Tomorrow 9AM is valid and in the future
                        finalTriggerDate = tomorrow9AM
                        // Update dateComponents to be used for the trigger
                        dateComponents = tomorrowComponents
                    } else {
                        // Neither today 9AM nor tomorrow 9AM worked
                        print("Could not calculate valid future trigger date (today/tomorrow 9AM) for \(personName)")
                        continue // Exit this loop iteration
                    }
                } else {
                    // Couldn't even calculate tomorrow's base date
                     print("Could not calculate tomorrow's date for \(personName)")
                     continue // Exit this loop iteration
                 }
            }
            
            // If we get here, finalTriggerDate should be non-nil (but we guard just in case)
            guard let _ = finalTriggerDate else { 
                print("Error: finalTriggerDate unexpectedly nil for \(personName)")
                continue 
            }
            // We use the potentially updated dateComponents for the trigger
            // --- End Set Time ---
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.userInfo = ["personId": entry.id.uuidString] // Add person ID for potential actions
            
            // Use the final, validated dateComponents
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling notification for \(personName): \(error.localizedDescription)")
                } else {
                    // Use DispatchQueue.main if you were updating UI, but print is fine here.
                    // print("Scheduled reminder for \(personName) on \(finalTriggerDate)")
                    // Avoid race condition for count increment
                    DispatchQueue.main.async {
                         scheduledCount += 1 // Incrementing within completion might be tricky across multiple async calls
                    }
                }
            }
        }
        
        // Can't reliably print final count here due to async nature of `add` completion.
        // Perhaps print inside the completion handler or use other tracking.
        // print("Finished scheduling loop. Attempted to schedule \(scheduledCount) reminders.")
    }
    
    // Function to clear all app notifications (use with caution)
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
} 