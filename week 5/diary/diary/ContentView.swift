import SwiftUI

struct Memory: Identifiable, Codable { //these are for reading info from json
    var id = UUID()
    var title: String
    var description: String
}


struct FloatingCircles: View {

    // control the movement of the circles
    @State private var move1 = false
    @State private var move2 = false
    @State private var move3 = false
    @State private var move4 = false

    var body: some View {

        ZStack {

            // Cream background
            Color(red: 1.0, green: 0.96, blue: 0.92)

            // Circle 1: Pink
            Circle()
                .fill(.pink.opacity(0.30))
                .frame(width: 190)
                .offset(
                    x: move1 ? -100 : 100,
                    y: move1 ? -250 : 250
                )

            // Circle 2: Lavender
            Circle()
                .fill(.purple.opacity(0.25))
                .frame(width: 120)
                .offset(
                    x: move2 ? 120 : -120,
                    y: move2 ? 200 : -200
                )

            // Circle 3: Soft blue
            Circle()
                .fill(.blue.opacity(0.20))
                .frame(width: 150)
                .offset(
                    x: move3 ? 150 : -150,
                    y: move3 ? -150 : 150
                )

            // Circle 4: Peach
            Circle()
                .fill(.orange.opacity(0.22))
                .frame(width: 120)
                .offset(
                    x: move4 ? -150 : 150,
                    y: move4 ? 100 : -100
                )
        }
        .blur(radius: 10)
        .ignoresSafeArea()
        .onAppear {

            //makes the change animated
            withAnimation(
                .easeInOut(duration: 6) //makes the movement start slowly
                    .repeatForever(autoreverses: true)
            ) {
                move1 = true
            }

            withAnimation(
                .easeInOut(duration: 8)
                    .repeatForever(autoreverses: true)
            ) {
                move2 = true
            }

            withAnimation(
                .easeInOut(duration: 7)
                    .repeatForever(autoreverses: true)
            ) {
                move3 = true
            }

            withAnimation(
                .easeInOut(duration: 9)
                    .repeatForever(autoreverses: true)
            ) {
                move4 = true
            }
        }
    }
}


struct ContentView: View {
    @State private var title = "" //state remembers changes temporarily
    @State private var description = ""
    @State private var memories: [Memory] = []
    
    var body: some View {
        ZStack {
            FloatingCircles()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {            Text("Little Moments")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Memory title", text: $title)
                    .textFieldStyle(.roundedBorder)
                //$ sign connects the text field to the title var, so it updates automatcally
                TextField("Write your memory...", text: $description)
                    .textFieldStyle(.roundedBorder)
                
                
                //this takes the text i typed and puts it into a new Memory object
                Button("Save Memory") {
                    let newMemory = Memory(
                        title: title,
                        description: description
                    )
                    
                    memories.append(newMemory) //adds it to the list
                    saveMemories()
                    
                    //emties both text fields after pressing the button
                    title = ""
                    description = ""
                }
                .buttonStyle(.borderedProminent)
                
                //displays the created memories
                ForEach(memories) { memory in //tells swift to repeat the same layout
                    VStack(alignment: .leading) {
                        Text(memory.title)
                            .font(.headline)
                        
                        Text(memory.description)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .onAppear {
                loadMemories() //Load automatically when the app opens
            }
        }
    }

    // find where json file is
    func getFileURL() -> URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("memories.json")
    }
    
    // save memories as json
    func saveMemories() {
        if let data = try? JSONEncoder().encode(memories) { //converts into json, continues even if the operation fails
            try? data.write( //writes data into the file
                to: getFileURL(),
                options: [.atomic]
            )
        }
    }
    
    // load memories from JSON
    func loadMemories() {
        if let data = try? Data(contentsOf: getFileURL()) {
            if let savedMemories = try? JSONDecoder().decode(
                [Memory].self,
                from: data
            ) {
                memories = savedMemories
            }
        }
    }
}

#Preview {
    ContentView()
}

