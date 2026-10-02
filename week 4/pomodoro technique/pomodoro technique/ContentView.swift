//  ContentView.swift
//  pomodoro technique
//  Created by Mukhlisa Mamatova on 31/9/2026.

import SwiftUI
import Combine

struct ContentView: View {
    
    // The timer starts at 25 minutes = 1500 seconds
    @State private var seconds = 25 * 60
    
    // keeps track of whether the timer is currently running
    @State private var isRunning = false
    
    //  creates a timer that updates every 1 second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // Simple background color
                Color(red: 0.95, green: 0.92, blue: 0.95)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    
                    Text("🍅Pomodoro🍅")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    
                    // Show the remaining time
                    Text(timeString)
                        .font(.system(size: 65, weight: .light))
                        .monospacedDigit()
                    
                    // Start / Pause button
                    Button {
                        isRunning.toggle()
                    } label: {
                        Text(isRunning ? "Pause" : "Start Studying")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(width: 200)
                            .background(.pink)
                            .clipShape(Capsule())
                    }
                    
                    // Reset button
                    Button("Reset") {
                        seconds = 25 * 60
                        isRunning = false
                    }
                    .foregroundStyle(.gray)
                    
                    // Go to the second page
                    NavigationLink("Study Sounds") {
                        SoundView()
                    }
                    .font(.headline)
                    .padding(.top, 20)
                }
            }
            
            // This code runs every second
            .onReceive(timer) { _ in
                
                if isRunning {
                    
                    if seconds > 0 {
                        // Take one second away
                        seconds -= 1
                    } else {
                        // When we reach 00:00,
                        // automatically start another 25-minute session
                        seconds = 25 * 60
                    }
                }
            }
        }
    }
    
    // Converts seconds into minutes:seconds
    var timeString: String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    ContentView()
}
