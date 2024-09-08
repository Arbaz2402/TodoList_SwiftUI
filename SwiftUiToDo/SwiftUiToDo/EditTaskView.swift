import SwiftUI
import CoreData
import UserNotifications

struct EditTaskView: View {
    @Environment(\.managedObjectContext) var context
    @Binding var isPresented: Bool
    @State var taskName: String
    @State var reminderDate: Date
    var task: ToDoListItem
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Task")) {
                    TextField("Task Name", text: $taskName)
                    DatePicker("Reminder Time", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Button("Save Changes") {
                    saveChanges()
                    isPresented = false
                }
                .disabled(taskName.isEmpty)
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
    
    func saveChanges() {
        task.name = taskName
        task.reminderDate = reminderDate
        
        do {
            try context.save()
            // Schedule or reschedule notification if necessary
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.objectID.uriRepresentation().absoluteString])
            scheduleNotification(for: task)
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
    
    func scheduleNotification(for task: ToDoListItem) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = task.name ?? "Your task is due"
        content.sound = .default
        
        if let reminderDate = task.reminderDate {
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            let request = UNNotificationRequest(identifier: task.objectID.uriRepresentation().absoluteString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
}
