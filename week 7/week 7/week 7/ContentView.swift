import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {

    
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var filteredImage: UIImage?
    @State private var finalImage: UIImage?
    @State private var intensity = 0.5
    @State private var currentFilter = "Sepia"
    @State private var caption = ""

    // the CIContext is the "engine" that turns filter results into real images
    let context = CIContext()

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.96, blue: 0.92)
                .ignoresSafeArea()

            VStack(spacing: 16) {

                Text("Photo Filters")
                    .font(.largeTitle)
                    .bold()
                Text("Pick a photo, give it a filter, add a little caption, and share it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let finalImage {
                    Image(uiImage: finalImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                } else {
                    Text("Pick a photo to start")
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
                }

                // PhotosPicker opens the photo library
                // $selectedItem connects the picker to our variable
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Choose Photo")
                }
                .buttonStyle(.borderedProminent)
                TextField("Add a small caption...", text: $caption)
                    .textFieldStyle(.roundedBorder)

                Slider(value: $intensity)

                HStack {
                    Button("Sepia") { currentFilter = "Sepia"; applyFilter() }
                    Button("Blur") { currentFilter = "Blur"; applyFilter() }
                    Button("Pixelate") { currentFilter = "Pixelate"; applyFilter() }
                    Button("Noir") { currentFilter = "Noir"; applyFilter() }
                }
                .buttonStyle(.bordered)

                // lets the user save or share the edited photo (with the caption)
                if let finalImage {
                    ShareLink(
                        item: Image(uiImage: finalImage),
                        preview: SharePreview("My photo", image: Image(uiImage: finalImage))
                    )
                }
            }
            .padding()
        } //runs whenever X happens, live updates
        .onChange(of: selectedItem) {
            loadPhoto()
        }
        .onChange(of: intensity) {
            applyFilter()
        }
        .onChange(of: caption) {
            updateFinalImage()
        }
    }

    func loadPhoto() {
        Task { // Task lets us wait for the photo to load without freezing the app
            if let data = try? await selectedItem?.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                originalImage = uiImage
                applyFilter() // show it with the current filter right away
            }
        }
    }

    func applyFilter() {
        // make sure we have a photo, and convert it to a CIImage (what filters need)
        guard let originalImage, let startImage = CIImage(image: originalImage) else { return }

        var output: CIImage?
        switch currentFilter {
        case "Sepia":
            let filter = CIFilter.sepiaTone()
            filter.inputImage = startImage
            filter.intensity = Float(intensity)
            output = filter.outputImage

        case "Blur":
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = startImage
            filter.radius = Float(intensity * 20)
            output = filter.outputImage

        case "Pixelate":
            let filter = CIFilter.pixellate()
            filter.inputImage = startImage
            filter.scale = Float(intensity * 50) + 1
            output = filter.outputImage

        default: // Noir (black and white) has no intensity setting
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = startImage
            output = filter.outputImage
        }

      
        // cropped(to:) keeps blur from making the picture bigger than the original
        if let output = output?.cropped(to: startImage.extent),
           let cgImage = context.createCGImage(output, from: output.extent) {
            filteredImage = UIImage(cgImage: cgImage)
            updateFinalImage() // add the caption on top of the new filtered photo
        }
    }

    // combine the filtered photo with the caption
    func updateFinalImage() {
        guard let filteredImage else { return }
        finalImage = addCaption(to: filteredImage)
    }

    // draw the caption text onto the bottom of the photo
    func addCaption(to image: UIImage) -> UIImage {
        // no text typed? just return the photo as it is
        if caption.isEmpty { return image }

        // scale = 1 keeps the final image the same size as the original photo
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        // the renderer is like a blank canvas the same size as the photo
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        return renderer.image { _ in
            // 1. draw the photo onto the canvas
            image.draw(at: .zero)

            // 2. make the text size depend on the photo width, so it looks right on any photo
            let fontSize = image.size.width / 15

            // 3. style the text: bold, white, with a see-through dark background so it's easy to read
            let style: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white,
                .backgroundColor: UIColor.black.withAlphaComponent(0.4)
            ]
            let text = NSAttributedString(string: caption, attributes: style)

            // 4. put the text in the bottom center of the photo
            let textSize = text.size()
            let point = CGPoint(
                x: (image.size.width - textSize.width) / 2,
                y: image.size.height - textSize.height - fontSize
            )
            text.draw(at: point)
        }
    }
}

#Preview {
    ContentView()
}
