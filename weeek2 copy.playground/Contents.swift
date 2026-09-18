//loading and displaying ASCII art
import Foundation

let files = ["cat.txt", "flower.txt", "star.txt"]

func load(_ file: String) -> String {
    let path = Bundle.main.path(forResource: file, ofType: nil)
    let str = try? String(contentsOfFile: path!, encoding: .utf8)
    return str ?? ""
}

print(load(files.randomElement()!))

