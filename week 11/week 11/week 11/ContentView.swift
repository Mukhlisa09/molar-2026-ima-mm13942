import SwiftUI
import PhotosUI //lets us open the photo gallery

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
    @State private var text = ""
    @State private var pickedItems: [PhotosPickerItem] = [] //what the user picks in the gallery
    @State private var images: [UIImage] = [] //the photos added to the page

    var body: some View {
        ZStack {
            FloatingCircles()
                .ignoresSafeArea()

            ScrollView { //so the page can scroll when there are many photos
                VStack(spacing: 20) {
                    Text("Little Moments")
                        .font(.largeTitle)
                        .bold()

                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    //$ sign connects the text field to the title var, so it updates automatcally

                    TextField("Write your memory...", text: $text, axis: .vertical) //axis makes it grow with long text
                        .textFieldStyle(.roundedBorder)

                    //shows every photo that was added
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    //opens the gallery
                    PhotosPicker(selection: $pickedItems, matching: .images) {
                        Label("Add Photos", systemImage: "photo")
                    }
                    .buttonStyle(.borderedProminent)
                    .onChange(of: pickedItems) { _, items in
                        Task {
                            for item in items {
                                //loads each picked photo and turns it into a picture
                                if let data = try? await item.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    images.append(image)
                                }
                            }
                            pickedItems = [] //resets the picker so you can add more later
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
