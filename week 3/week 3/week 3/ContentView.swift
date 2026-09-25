//
//  ContentView.swift
//  week 3
//  inspiration sourse: YouTube - Noah Does Coding
// https://www.youtube.com/watch?v=3rrv0TbkVR4&t=7s
//  Created by Mukhlisa Mamatova on 22/09/2026.

import SwiftUI

// define, create the circles
struct CircleParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var speedX: CGFloat
    var speedY: CGFloat
}

var particles: [CircleParticle] = []

let colors = [
    Color.red,
    Color.orange,
    Color.yellow,
    Color.green,
    Color.blue,
    Color.purple
]

struct ContentView: View {
    
    var body: some View {
        
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            
            Canvas { ctx, size in
                
                let center = CGPoint(
                    x: size.width / 2,
                    y: size.height / 2
                )
                
                let radius: CGFloat = 120
                
                // Draw the big circle
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )),
                    with: .color(.black)
                )
                
                // create a new small circle
                let particle = CircleParticle(
                    x: center.x,
                    y: center.y,
                    size: CGFloat.random(in: 8...20),
                    color: colors.randomElement()!,
                    speedX: CGFloat.random(in: -3...3),
                    speedY: CGFloat.random(in: -3...3)
                )
                
                particles.append(particle)
                
                // move and draw all the small circles
                for i in particles.indices {
                    
                    particles[i].x += particles[i].speedX
                    particles[i].y += particles[i].speedY
                    
                    let circle = Path(
                        ellipseIn: CGRect(
                            x: particles[i].x - particles[i].size / 2,
                            y: particles[i].y - particles[i].size / 2,
                            width: particles[i].size,
                            height: particles[i].size
                        )
                    )
                    
                    ctx.fill(
                        circle,
                        with: .color(particles[i].color)
                    )
                }
                // trigger another update
                _ = timeline.date
            }
        }
    }
}

#Preview {
    ContentView()
}
