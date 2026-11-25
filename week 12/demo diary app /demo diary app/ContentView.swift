//
//  ContentView.swift
//  Footprints prototype (version 2)
//
//  Replace the whole contents of the ContentView.swift that Xcode created with this file.
//  Needs iOS 17 or later. Memories live in memory only: they disappear when the app closes.
//

import SwiftUI
import MapKit
import PhotosUI
import AVFoundation

// MARK: - Data

enum Category: String, CaseIterable, Identifiable {
    case home = "Home"
    case uni = "Uni"
    case fun = "Fun"
    case trips = "Trips"
    var id: String { rawValue }
}

struct StickerItem: Identifiable {
    let id = UUID()
    var emoji: String
    var offset: CGSize = .zero
}

struct Memory: Identifiable {
    let id = UUID()
    var title: String
    var note: String
    var coordinate: CLLocationCoordinate2D
    var color: Color
    var category: Category
    var images: [UIImage]
    var stickers: [StickerItem]
    var audioURL: URL?
    var date: Date
}

let cardColors: [Color] = [
    Color(red: 1.00, green: 0.95, blue: 0.88),
    Color(red: 0.98, green: 0.85, blue: 0.78),
    Color(red: 0.87, green: 0.92, blue: 0.83),
    Color(red: 0.84, green: 0.91, blue: 0.95),
    Color(red: 0.97, green: 0.86, blue: 0.90),
    Color(red: 0.98, green: 0.93, blue: 0.71)
]

let stickerOptions: [String] = ["❤️", "⭐️", "☀️", "🎵", "📸", "🌴", "🍕", "🎓"]

let startRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
)

// MARK: - Audio (record and play a short clip)

@MainActor
@Observable
final class AudioManager {
    var isRecording: Bool = false
    var isPlaying: Bool = false
    var fileURL: URL? = nil

    @ObservationIgnored private var recorder: AVAudioRecorder? = nil
    @ObservationIgnored private var player: AVAudioPlayer? = nil

    func toggleRecording() {
        if isRecording {
            recorder?.stop()
            isRecording = false
            return
        }
        Task {
            let granted = await AVAudioApplication.requestRecordPermission()
            if granted { startRecording() }
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        if recorder?.record() == true {
            fileURL = url
            isRecording = true
        }
    }

    func togglePlay(_ url: URL) {
        if isPlaying {
            player?.stop()
            isPlaying = false
            return
        }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback)
        try? session.setActive(true)
        player = try? AVAudioPlayer(contentsOf: url)
        guard let player = player else { return }
        player.play()
        isPlaying = true
        let length = player.duration
        Task {
            try? await Task.sleep(for: .seconds(length + 0.2))
            if self.player?.isPlaying == false { self.isPlaying = false }
        }
    }
}

// MARK: - Card (colored background + photo + draggable stickers)

struct DraggableSticker: View {
    @Binding var sticker: StickerItem
    var editable: Bool
    @GestureState private var drag: CGSize = .zero

    var body: some View {
        let dragGesture = DragGesture()
            .updating($drag) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                sticker.offset.width += value.translation.width
                sticker.offset.height += value.translation.height
            }

        return Text(sticker.emoji)
            .font(.system(size: 44))
            .offset(x: sticker.offset.width + drag.width,
                    y: sticker.offset.height + drag.height)
            .gesture(dragGesture)
            .allowsHitTesting(editable)
    }
}

struct CardView: View {
    let color: Color
    let image: UIImage?
    @Binding var stickers: [StickerItem]
    var editable: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(color)
            photo
            ForEach($stickers) { $s in
                DraggableSticker(sticker: $s, editable: editable)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var photo: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)
        } else {
            Text("Add a photo")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Map pin (dot when zoomed out, photo when zoomed in)

struct PinView: View {
    let memory: Memory
    let zoomedIn: Bool

    var body: some View {
        if zoomedIn {
            bigPin
        } else {
            dot
        }
    }

    private var dot: some View {
        Circle()
            .fill(memory.color)
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(radius: 2)
    }

    @ViewBuilder
    private var bigPin: some View {
        if let img = memory.images.first {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(memory.color, lineWidth: 4))
                .shadow(radius: 3)
        } else {
            Text("📍")
                .font(.title2)
                .padding(8)
                .background(memory.color, in: Circle())
                .shadow(radius: 3)
        }
    }
}

// MARK: - Screen 1: Map

struct ContentView: View {
    @State private var memories: [Memory] = []
    @State private var filter: Category? = nil
    @State private var camera: MapCameraPosition = .region(startRegion)
    @State private var span: Double = 0.3
    @State private var showEditor: Bool = false
    @State private var selected: Memory? = nil

    private var filtered: [Memory] {
        memories.filter { filter == nil || $0.category == filter }
    }

    private var zoomedIn: Bool { span < 0.08 }

    var body: some View {
        ZStack {
            mapLayer
            topLayer
            plusButton
        }
        .sheet(isPresented: $showEditor) {
            EditorView { newMemory in
                addMemory(newMemory)
            }
        }
        .sheet(item: $selected) { memory in
            DetailView(memory: memory) {
                memories.removeAll { $0.id == memory.id }
                selected = nil
            }
        }
    }

    private func addMemory(_ newMemory: Memory) {
        memories.append(newMemory)
        let region = MKCoordinateRegion(
            center: newMemory.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        camera = .region(region)
    }

    private var mapLayer: some View {
        Map(position: $camera) {
            ForEach(filtered) { memory in
                Annotation(memory.title, coordinate: memory.coordinate) {
                    PinView(memory: memory, zoomedIn: zoomedIn)
                        .onTapGesture { selected = memory }
                }
            }
        }
        .onMapCameraChange { context in
            span = context.region.span.latitudeDelta
        }
        .ignoresSafeArea()
    }

    private var topLayer: some View {
        VStack(spacing: 0) {
            filterBar
            Spacer()
            if memories.isEmpty {
                Text("Tap + to add your first memory")
                    .padding(12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 24)
            }
        }
    }

    private var plusButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.orange, in: Circle())
                        .shadow(radius: 5)
                }
                .padding(20)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                chip("All", isOn: filter == nil) { filter = nil }
                ForEach(Category.allCases) { c in
                    chip(c.rawValue, isOn: filter == c) { filter = c }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func chip(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        let background: Color = isOn ? .black : .white
        let foreground: Color = isOn ? .white : .black
        return Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(background, in: Capsule())
                .foregroundStyle(foreground)
        }
    }
}

// MARK: - Screen 2: Add a memory

struct EditorView: View {
    var onSave: (Memory) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var category: Category = .fun
    @State private var colorIndex: Int = 1
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var position: MapCameraPosition = .region(startRegion)
    @State private var searchText: String = ""
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var stickers: [StickerItem] = []
    @State private var audio = AudioManager()

    private var canSave: Bool {
        !title.isEmpty && coordinate != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    placeSection
                    photosSection
                    textSection
                    colorSection
                    stickersSection
                    soundSection
                    categorySection
                }
                .padding(16)
            }
            .navigationTitle("New memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: pickerItems) { _, newItems in
                loadPhotos(newItems)
            }
        }
    }

    // MARK: Sections

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1. Place").font(.headline)
            TextField("Search a place, then press return", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { search() }
            pickerMap
            Text(coordinate == nil ? "Tap the map to drop a pin" : "Pin placed")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var pickerMap: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let coordinate = coordinate {
                    Marker("Memory", coordinate: coordinate)
                }
            }
            .onTapGesture { point in
                if let c = proxy.convert(point, from: .local) {
                    coordinate = c
                }
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2. Photos").font(.headline)
            PhotosPicker(selection: $pickerItems, maxSelectionCount: 6, matching: .images) {
                Label("Choose photos", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)
            if !images.isEmpty {
                photoStrip
            }
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(images.indices, id: \.self) { i in
                    Image(uiImage: images[i])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("3. Title and note").font(.headline)
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("What do you want to remember?", text: $note, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("4. Card color").font(.headline)
            HStack(spacing: 12) {
                ForEach(cardColors.indices, id: \.self) { i in
                    swatch(i)
                }
            }
        }
    }

    private func swatch(_ i: Int) -> some View {
        let ringWidth: CGFloat = (colorIndex == i) ? 3 : 0
        return Circle()
            .fill(cardColors[i])
            .frame(width: 40, height: 40)
            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            .overlay(Circle().stroke(Color.orange, lineWidth: ringWidth))
            .onTapGesture { colorIndex = i }
    }

    private var stickersSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("5. Stickers").font(.headline)
            HStack {
                ForEach(stickerOptions, id: \.self) { emoji in
                    Button {
                        stickers.append(StickerItem(emoji: emoji))
                    } label: {
                        Text(emoji).font(.title)
                    }
                }
            }
            Text("Tap to add, then drag the stickers around the card below.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            CardView(color: cardColors[colorIndex],
                     image: images.first,
                     stickers: $stickers,
                     editable: true)
            if !stickers.isEmpty {
                Button("Clear stickers", role: .destructive) {
                    stickers.removeAll()
                }
                .font(.footnote)
            }
        }
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("6. Sound").font(.headline)
            HStack(spacing: 12) {
                recordButton
                playButton
            }
        }
    }

    private var recordButton: some View {
        let label = audio.isRecording ? "Stop" : "Record"
        let icon = audio.isRecording ? "stop.circle.fill" : "mic.circle.fill"
        let tint: Color = audio.isRecording ? .red : .orange
        return Button {
            audio.toggleRecording()
        } label: {
            Label(label, systemImage: icon)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    @ViewBuilder
    private var playButton: some View {
        if let url = audio.fileURL, !audio.isRecording {
            Button {
                audio.togglePlay(url)
            } label: {
                Label(audio.isPlaying ? "Stop" : "Play",
                      systemImage: audio.isPlaying ? "stop.fill" : "play.fill")
            }
            .buttonStyle(.bordered)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7. Category").font(.headline)
            Picker("Category", selection: $category) {
                ForEach(Category.allCases) { c in
                    Text(c.rawValue).tag(c)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: Actions

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            var loaded: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loaded.append(image)
                }
            }
            images = loaded
        }
    }

    private func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        MKLocalSearch(request: request).start { response, _ in
            guard let item = response?.mapItems.first else { return }
            let c = coordinateOf(item)
            DispatchQueue.main.async {
                coordinate = c
                let region = MKCoordinateRegion(
                    center: c,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                position = .region(region)
            }
        }
    }

    private func save() {
        guard let coordinate = coordinate else { return }
        let memory = Memory(title: title,
                            note: note,
                            coordinate: coordinate,
                            color: cardColors[colorIndex],
                            category: category,
                            images: images,
                            stickers: stickers,
                            audioURL: audio.fileURL,
                            date: Date())
        onSave(memory)
        dismiss()
    }
}

/// Reads a search result's coordinate in a way that works on every iOS version.
func coordinateOf(_ item: MKMapItem) -> CLLocationCoordinate2D {
    if #available(iOS 26.0, *) {
        return item.location.coordinate
    } else {
        return item.placemark.coordinate
    }
}

// MARK: - Screen 3: Memory detail

struct DetailView: View {
    let memory: Memory
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var audio = AudioManager()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CardView(color: memory.color,
                             image: memory.images.first,
                             stickers: .constant(memory.stickers),
                             editable: false)
                    tagRow
                    Text(memory.title)
                        .font(.largeTitle.bold())
                    if !memory.note.isEmpty {
                        Text(memory.note)
                    }
                    if memory.images.count > 1 {
                        photoStrip
                    }
                    soundButton
                    Button("Delete memory", role: .destructive) {
                        onDelete()
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(memory.color.opacity(0.35))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var tagRow: some View {
        HStack {
            Text(memory.category.rawValue)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.black, in: Capsule())
                .foregroundStyle(.white)
            Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(memory.images.indices, id: \.self) { i in
                    Image(uiImage: memory.images[i])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    @ViewBuilder
    private var soundButton: some View {
        if let url = memory.audioURL {
            Button {
                audio.togglePlay(url)
            } label: {
                Label(audio.isPlaying ? "Stop sound" : "Play sound",
                      systemImage: audio.isPlaying ? "stop.fill" : "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }
}

#Preview {
    ContentView()
}
