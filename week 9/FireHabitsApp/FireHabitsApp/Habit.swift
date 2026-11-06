//
//  Habit.swift
//  MODEL: what one habit looks like.
//

import Foundation
import FirebaseFirestore

struct Habit: Identifiable, Codable {

    @DocumentID var id: String? // filled in by Firestore, not stored as a field

    var title: String
    var goal: Int    // how many times per week I want to do it
    var count: Int  // how many times I did it so far this week

    // progress from 0.0 to 1.0, used by the progress bar
    var progress: Double {
        if goal == 0 { return 0 }
        return min(Double(count) / Double(goal), 1.0) // never more than 100%
    }
}
