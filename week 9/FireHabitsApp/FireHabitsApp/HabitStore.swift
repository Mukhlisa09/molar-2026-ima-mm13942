//
//  HabitStore.swift
//   only file that talks to Firestore.
//  The screen asks this class to add / update / delete habits.
//

import Foundation
import Combine
import FirebaseFirestore

class HabitStore: ObservableObject {

    // @Published: when this array changes, the screen redraws by itself
    @Published var habits: [Habit] = []

    // "habits" is the collection (like a folder) in Firestor
    private let collection = Firestore.firestore().collection("habits")

    init() {
        listen()
    }

    // SNAPSHOT LISTENER Firestore calls this code once at the start
    // and again every time the data changes. That is how we get live updates.
    func listen() {
        collection.order(by: "title").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error loading habits: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }

            // Turn every Firestore document into a Habit.
            self.habits = snapshot.documents.compactMap { document in
                try? document.data(as: Habit.self)
            }
        }
    }

    //  save a new habit
    func add(title: String, goal: Int) {
        let habit = Habit(title: title, goal: goal, count: 0)
        do {
            try collection.addDocument(from: habit)
        } catch {
            print("Error adding habit: \(error)")
        }
    }

    //  change only the "count" field of one document
    func addOne(to habit: Habit) {
        guard let id = habit.id else { return }
        collection.document(id).updateData(["count": habit.count + 1])
    }

    //  start the week again
    func reset(_ habit: Habit) {
        guard let id = habit.id else { return }
        collection.document(id).updateData(["count": 0])
    }

    // remove the document
    func delete(_ habit: Habit) {
        guard let id = habit.id else { return }
        collection.document(id).delete()
    }
}
