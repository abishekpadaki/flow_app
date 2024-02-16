import SwiftUI
import UserNotifications

struct ToDoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var dueDate: Date
    var reminderTime: Date
    var isCompleted: Bool = false
}


struct ToDoList: View {
    @State private var toDoItems = [ToDoItem]()
    @State private var newToDoTitle = ""
    @State private var newToDoReminderTime = Date()
    
    private func taskCard(item: ToDoItem) -> some View {
            VStack(alignment: .leading, spacing: 8) { // Adjust spacing inside each card
                HStack {
                    Text(item.title)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        markAsCompleted(item: item)
                    }) {
                        Image(systemName: "checkmark.circle")
                    }
                }
                DatePicker("Reminder", selection: Binding(get: {
                    toDoItems.first(where: { $0.id == item.id })?.reminderTime ?? Date()
                }, set: { newTime in
                    if let index = toDoItems.firstIndex(where: { $0.id == item.id }) {
                        toDoItems[index].reminderTime = newTime
                    }
                }), displayedComponents: .hourAndMinute)
            }
            .padding() // Padding inside the card
            .background(RoundedRectangle(cornerRadius: 10) // Rounded corners for the card
                            .fill(Color(UIColor.secondarySystemBackground)) // Background color of the card
                            .shadow(radius: 5)) // Shadow for card-like appearance
            .padding(.horizontal) // Padding on each side of the card for spacing from screen edges
        }
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    var body: some View {
        NavigationView {
            
            ScrollView {
                
                            LazyVStack(spacing: 10) { // Control spacing between cards
                                HStack {
                                            TextField("New To-Do Item", text: $newToDoTitle)
                                            DatePicker("Time:", selection: $newToDoReminderTime, displayedComponents: .hourAndMinute)
                                            Button(action: {
                                                addNewItem()
                                            }) {
                                                Image(systemName: "plus")
                                            }
                                }.padding()
                                
                                ForEach(toDoItems) { item in
                                    if !item.isCompleted {
                                        taskCard(item: item)
                                    }
                                }
                            }
                            .padding() // Add padding around the stack for better appearance
                        }
            .navigationBarTitle("Flow.")
        }.onAppear {
            self.requestNotificationPermissions()
            self.loadTasks()
        }
    }
    
    private func markAsCompleted(item: ToDoItem) {
        if let index = toDoItems.firstIndex(where: { $0.id == item.id }) {
            toDoItems[index].isCompleted = true
            
            // Delay removal to allow for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.toDoItems.removeAll { $0.id == item.id }
                    self.saveTasks()
                }
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        toDoItems.remove(atOffsets: offsets)
        saveTasks()
    }
    
    func saveTasks() {
        if let encoded = try? JSONEncoder().encode(toDoItems) {
            UserDefaults.standard.set(encoded, forKey: "ToDoItems")
        }
    }
    
    func loadTasks() {
        if let savedItems = UserDefaults.standard.data(forKey: "ToDoItems"),
           let decodedItems = try? JSONDecoder().decode([ToDoItem].self, from: savedItems) {
            toDoItems = decodedItems
        }
    }

    
    private func scheduleNotification(for item: ToDoItem) {
        let content = UNMutableNotificationContent()
        content.title = "Flow."
        
        let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a" // Use "h:mm a" for minute accuracy, "ha" for hour only with am/pm
            let reminderTimeString = dateFormatter.string(from: item.reminderTime)
        
        content.body = "Reminder: \(item.title) at \(reminderTimeString)"
        content.sound = UNNotificationSound.default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: item.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func addNewItem() {
        let newToDoItem = ToDoItem(title: newToDoTitle, dueDate: Date(), reminderTime: newToDoReminderTime)
            toDoItems.append(newToDoItem)
            scheduleNotification(for: newToDoItem) // Schedule the notification
            newToDoTitle = ""
            newToDoReminderTime = Date()
            saveTasks()
    }
}

struct ToDoList_Previews: PreviewProvider {
    static var previews: some View {
        ToDoList()
    }
}

