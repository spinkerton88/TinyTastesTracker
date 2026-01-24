//
//  RemindersIntegrationManager.swift
//  TinyTastesTracker
//

import Foundation
import EventKit

@Observable
class RemindersIntegrationManager {
    private let eventStore = EKEventStore()
    var hasAccess = false
    
    // MARK: - Permission
    
    func requestAccess() async -> Bool {
        do {
            hasAccess = try await eventStore.requestFullAccessToReminders()
            return hasAccess
        } catch {
            print("Failed to request reminders access: \(error)")
            return false
        }
    }
    
    // MARK: - Export Shopping List
    
    func exportShoppingList(_ items: [ShoppingListItem]) async throws {
        if !hasAccess {
            let granted = await requestAccess()
            guard granted else {
                throw RemindersError.accessDenied
            }
        }
        
        // Find or create "Tiny Tastes Shopping" list
        let calendar = try findOrCreateShoppingList()
        
        // Get existing reminders to avoid duplicates
        let predicate = eventStore.predicateForReminders(in: [calendar])
        let existingReminders = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[EKReminder], Error>) in
            eventStore.fetchReminders(matching: predicate) { reminders in
                if let reminders = reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
        let existingTitles = Set(existingReminders.map { $0.title?.lowercased() ?? "" })
        
        // Create reminders for items not already in the list
        for item in items where !item.isCompleted {
            let title = formatItemTitle(item)
            
            // Skip if already exists
            if existingTitles.contains(title.lowercased()) {
                continue
            }
            
            let reminder = EKReminder(eventStore: eventStore)
            reminder.calendar = calendar
            reminder.title = title
            reminder.notes = "Added from Tiny Tastes Tracker"
            
            try eventStore.save(reminder, commit: false)
        }
        
        // Commit all changes at once
        try eventStore.commit()
    }
    
    // MARK: - Helper Methods
    
    private func findOrCreateShoppingList() throws -> EKCalendar {
        let calendars = eventStore.calendars(for: .reminder)
        
        // Look for existing "Tiny Tastes Shopping" list
        if let existing = calendars.first(where: { $0.title == "Tiny Tastes Shopping" }) {
            return existing
        }
        
        // Create new list
        let newCalendar = EKCalendar(for: .reminder, eventStore: eventStore)
        newCalendar.title = "Tiny Tastes Shopping"
        newCalendar.source = eventStore.defaultCalendarForNewReminders()?.source
        
        try eventStore.saveCalendar(newCalendar, commit: true)
        return newCalendar
    }
    
    private func formatItemTitle(_ item: ShoppingListItem) -> String {
        var title = ""
        
        if let quantity = item.quantity {
            title += quantity
            if let unit = item.unit {
                title += " \(unit)"
            }
            title += " "
        }
        
        title += item.name
        return title
    }
    
    enum RemindersError: LocalizedError {
        case accessDenied
        
        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Access to Reminders was denied. Please enable it in Settings."
            }
        }
    }
}
