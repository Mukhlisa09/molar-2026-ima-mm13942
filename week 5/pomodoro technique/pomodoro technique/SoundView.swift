//
//  File.swift
//  pomodoro technique
//
//  Created by Mukhlisa Mamatova on 01/10/2026.
//

import SwiftUI
import AVFoundation

struct SoundView: View {
    
    // The audio player
    @State private var player: AVAudioPlayer?
    
    // Used to show whether music is playing
    @State private var isPlaying = false
    @AppStorage("selectedSound") private var selectedSound = "piano"
    
    var body: some View {
        
        ZStack {
            
            // Background
            Color(red: 0.94, green: 0.93, blue: 0.97)
                .ignoresSafeArea()
            
            // Floating circles in the background
            FloatingCircles()
            
            VStack(spacing: 30) {
                
                Text("🎧 Study Sounds")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose your study atmosphere")
                    .foregroundStyle(.gray)
                
                Text("Selected sound: \(selectedSound.capitalized)")
                    .foregroundStyle(.secondary)
                
                // Sound buttons
                Button("Fire") {
                    selectedSound = "fire"
                    playSound(name: "fire")
                }

                Button("Rain") {
                    selectedSound = "rain"
                    playSound(name: "rain")
                }

                Button("Piano") {
                    selectedSound = "piano"
                    playSound(name: "piano")
                }
                // Play / Pause button
                Button {
                    
                    if isPlaying {
                        player?.pause()
                        isPlaying = false
                    } else {
                        player?.play()
                        isPlaying = true
                    }
                    
                } label: {
                    Text(isPlaying ? "Pause" : "▶ Play")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(width: 150)
                        .background(.pink)
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }
    
    // Function for playing a sound
    func playSound(name: String) {
        
        // Find the audio file inside the project
        if let url = Bundle.main.url(
            forResource: name,
            withExtension: "mp3"
        ) {
            
            do {
                // Create the audio player
                player = try AVAudioPlayer(contentsOf: url)
                
                // Start playing
                player?.play()
                
                isPlaying = true
                
            } catch {
                print("Could not play the sound")
            }
        }
    }
}

//floating circles
struct FloatingCircles: View {
    
    // These control the movement of the circles
    @State private var move1 = false
    @State private var move2 = false
    @State private var move3 = false
    @State private var move4 = false
    
    var body: some View {
        
        ZStack {
            
            // Circle 1
            Circle()
                .fill(.pink.opacity(0.25))
                .frame(width: 180)
                .offset(
                    x: move1 ? -100 : 100,
                    y: move1 ? -250 : 250
                )
            
            // Circle 2
            Circle()
                .fill(.purple.opacity(0.20))
                .frame(width: 130)
                .offset(
                    x: move2 ? 120 : -120,
                    y: move2 ? 200 : -200
                )
            
            // Circle 3
            Circle()
                .fill(.blue.opacity(0.18))
                .frame(width: 220)
                .offset(
                    x: move3 ? 150 : -150,
                    y: move3 ? -150 : 150
                )
            
            // Circle 4
            Circle()
                .fill(.orange.opacity(0.15))
                .frame(width: 100)
                .offset(
                    x: move4 ? -150 : 150,
                    y: move4 ? 100 : -100
                )
        }
        .blur(radius: 10)
        
        // Start the animations when the page appears
        .onAppear {
            
            withAnimation(
                .easeInOut(duration: 6)
                .repeatForever(autoreverses: true)
            ) {
                move1.toggle()
            }
            
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                move2.toggle()
            }
            
            withAnimation(
                .easeInOut(duration: 7)
                .repeatForever(autoreverses: true)
            ) {
                move3.toggle()
            }
            
            withAnimation(
                .easeInOut(duration: 9)
                .repeatForever(autoreverses: true)
            ) {
                move4.toggle()
            }
        }
    }
}


#Preview {
    SoundView()
}
