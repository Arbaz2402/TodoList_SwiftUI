import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {
    
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest(
        fetchRequest: ToDoListItem.getAllToDoListItems()
    ) var items: FetchedResults<ToDoListItem>
    
    @State var text: String = ""
    @State var reminderDate: Date = Date()
    @State private var showingEditView = false
    @State private var selectedTask: ToDoListItem? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("New Task")) {
                    HStack {
                        TextField("Enter new task...", text: $text)
                            .onSubmit(saveItem)
                    }
                    DatePicker("Reminder Time", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    ForEach(items) { item in
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unnamed Task")
                                .font(.headline)
                            if let reminder = item.reminderDate {
                                Text("Reminder set for \(formatDate(reminder))")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            
                            if let date = item.createdAt {
                                Text(formatDate(date))
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                        }
                        .contentShape(Rectangle())  // Make the whole row tappable
                        .onTapGesture {
                            selectedTask = item
                            showingEditView = true
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("To Do List")
            .toolbar {
                EditButton()
            }
            .onAppear(perform: requestNotificationPermission)
            .sheet(isPresented: $showingEditView) {
                if let task = selectedTask {
                    EditTaskView(isPresented: $showingEditView, taskName: task.name ?? "", reminderDate: task.reminderDate ?? Date(), task: task)
                }
            }
        }
    }
    
    func saveItem() {
        guard !text.isEmpty else { return }
        
        let newItem = ToDoListItem(context: context)
        newItem.name = text
        newItem.createdAt = Date()
        newItem.reminderDate = reminderDate
        
        do {
            try context.save()
            scheduleNotification(for: newItem)
            text = ""
            reminderDate = Date()
        } catch {
            print("Failed to save item: \(error)")
        }
    }
    
    func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            context.delete(item)
            cancelNotification(for: item)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to delete item: \(error)")
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy, h:mm a"
        return formatter.string(from: date)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            if success {
                print("Permission granted")
            } else if let error = error {
                print("Permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for item: ToDoListItem) {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = item.name ?? "Your task is due"
        content.sound = .default
        
        if let reminderDate = item.reminderDate {
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            
            let request = UNNotificationRequest(identifier: item.objectID.uriRepresentation().absoluteString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func cancelNotification(for item: ToDoListItem) {
        let identifier = item.objectID.uriRepresentation().absoluteString
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
