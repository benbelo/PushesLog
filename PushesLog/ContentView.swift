// By Benjamin Belot
// PushUps app

import SwiftUI
import UIKit
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: PushesLog.CounterEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \PushesLog.CounterEntry.date, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<PushesLog.CounterEntry>
    
    @State private var counter = 1
    @State private var isEditing = false
    @State private var showEntryForm = false
    @State private var selectedEntry: PushesLog.CounterEntry?
    @State private var showingDocumentPicker = false

    var body: some View {
        VStack {
            Spacer()

            // Circle Button with the Counter (2x Bigger)
            Button(action: {
                self.counter += 1

                if let todayEntry = entries.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: Date()) }) {
                    // If an entry exists for today, update it
                    todayEntry.value = Int64(self.counter)
                    saveContext()
                } else {
                    // Otherwise, create a new entry for today
                    let newEntry = PushesLog.CounterEntry(context: viewContext)
                    newEntry.date = Date()
                    newEntry.value = Int64(self.counter)
                    saveContext()
                }
            }) {
                Text("\(counter)")
                    .font(.system(size: 150, weight: .bold, design: .rounded)) // Adjust font size and weight
                    .foregroundColor(.black)
                    .frame(width: 400, height: 400)
                    .background(Circle().fill(Color.gray))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 100)
            .disabled(isEditing)  // Disable button when in editing mode

            // Entries List with Swipe-to-Delete
            List {
                ForEach(entries) { entry in
                    HStack {
                        Text("\(entry.value)")
                            .font(.system(size: 14)) // Adjust font size and weight
                        Spacer()
                        Text(entry.date!, style: .date)
                            .font(.system(size: 14)) // Adjust font size and weight
                    }
                    .onTapGesture {
                        if isEditing {
                            selectedEntry = entry
                            showEntryForm.toggle()
                        }
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .frame(height: 200)
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))

            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "Done" : "Edit")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                if isEditing {
                    Button(action: {
                        selectedEntry = nil
                        showEntryForm.toggle()
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    exportEntries()
                }) {
                    Text("Export")
                }
            }
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    resetCounter()
                }) {
                    Text("Reset")
                }
            }
        }
        .sheet(isPresented: $showEntryForm) {
            EntryFormView(entry: $selectedEntry, counter: $counter)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            if let todayEntry = entries.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: Date()) }) {
                self.counter = Int(todayEntry.value)
            } else {
                self.counter = 1
            }
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }

    private func exportEntries() {
        // Create file content
        var fileContent = "Date\tValue\n"
        for entry in entries {
            if let date = entry.date {
                let formattedDate = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
                fileContent += "\(formattedDate)\t\(entry.value)\n"
            }
        }
        
        // Create a temporary file URL
        let fileName = "Entries.txt"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try fileContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Present the share sheet
            let activityViewController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        } catch {
            print("Failed to save file: \(error.localizedDescription)")
        }
    }

    private func resetCounter() {
        // Reset the counter value
        counter = 1
        
        // Optionally, reset the entry for today
        if let todayEntry = entries.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: Date()) }) {
            todayEntry.value = 1
            saveContext()
        }
    }
}

struct EntryFormView: View {
    @Binding var entry: PushesLog.CounterEntry?
    @Binding var counter: Int
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var entryValue: String = ""
    @State private var entryDate: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Counter Value")) {
                    TextField("Value", text: $entryValue)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("Date")) {
                    DatePicker("Select Date", selection: $entryDate, displayedComponents: .date)
                }
            }
            .navigationBarTitle(entry == nil ? "New Entry" : "Edit Entry", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                saveEntry()
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                if let entry = entry {
                    entryValue = "\(entry.value)"
                    entryDate = entry.date ?? Date()
                }
            }
        }
    }

    private func saveEntry() {
        if let entry = entry {
            entry.value = Int64(entryValue) ?? entry.value
            entry.date = entryDate
        } else {
            let newEntry = PushesLog.CounterEntry(context: viewContext)
            newEntry.date = entryDate
            newEntry.value = Int64(entryValue) ?? 0
        }
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
