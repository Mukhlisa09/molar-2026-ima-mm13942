//
//  ContentView.swift
//
import SwiftUI

struct ContentView: View {

    // @StateObject: this screen creates the store and keeps it alive
    @StateObject private var store = HabitStore()

    // @State: temporary values for the "add habit" form
    @State private var newTitle = ""
    @State private var newGoal = 3

    var body: some View {
        NavigationStack {
            List {

                //  form to add a habit
                Section("New habit") {
                    TextField("Name, e.g. Go running", text: $newTitle)

                    Stepper("Goal: \(newGoal) times per week", value: $newGoal, in: 1...7)

                    Button("Add") {
                        store.add(title: newTitle, goal: newGoal)
                        newTitle = ""          // clear the text field
                    }
                    .disabled(newTitle.isEmpty) // can't add an empty name
                }

                // the habits, loaded live from Firestore
                Section("My habits") {
                    ForEach(store.habits) { habit in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(habit.title).font(.headline)
                                Text("\(habit.count) of \(habit.goal) this week")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                // progress bar for the weekly goal
                                ProgressView(value: habit.progress)
                                    .tint(habit.progress >= 1 ? .green : .blue)
                            }

                            Spacer()

                            // +1 button (.borderless so only the button is tappable)
                            Button("+1") {
                                store.addOne(to: habit)
                            }
                            .buttonStyle(.borderless)
                        }
                        // Long-press a row to start the week again
                        .contextMenu {
                            Button("Reset week") { store.reset(habit) }
                        }
                    }
                    // Swipe left to delete
                    .onDelete { offsets in
                        for index in offsets {
                            store.delete(store.habits[index])
                        }
                    }
                }
            }
            .navigationTitle("FireHabits")
        }
    }
}
