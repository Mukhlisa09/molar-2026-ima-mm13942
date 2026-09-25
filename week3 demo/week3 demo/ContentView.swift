//
//  ContentView.swift
//  week3 demo
//
//  Created by Mukhlisa Mamatova on 18/09/2026.
//

import SwiftUI

struct ContentView: View {
    @State  var count = 0
    var body: some View {
        VStack {
            Text ("count \(count)")
                .font(.system(size: 60))
            Spacer ()
            HStack{
                Image(systemName: count == 0 ? "heart.fill" : "globe")
                    .resizable()
                    . aspectRatio(contentMode: .fit)
            }
            //.foregroundStyle(.tint)
            Text("Hello, world!")
                .font(.system(size: 50, weight: .light, design: .serif))
                .italic()
            
            Spacer ()
            HStack {
                Button("<") {
                    count += 1
                    print ("i am tapped")
                }
                .buttonStyle(.bordered)
                .font(.system(size:60))
                
                Button(">") {
                    count -= 1
                    print ("i am tapped")
                }
                .buttonStyle(.bordered)
                .font(.system(size:60))
            }
        }
        .padding()
    }
}
#Preview {
    ContentView()
}
