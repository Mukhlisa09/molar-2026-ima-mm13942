
import Foundation

// house

let sun = "☀️"
let tree = "🌲"
let house = "🏠"
let water = "🌊"

func makeWaterLine() {
    var line = ""
    for _ in 0..<10 {
        line += water
    }

print(line)
}
print ("     ☁️     ☁️       ☁️")
print("☁️       ☁️ \(sun)   ☁️     ☁️")
print("")
print("   \(tree)    🧚‍♀️   \(tree)")
print("\(tree)    🧚‍♀️  \(house)  🧚‍♀️     \(tree)")
print("\(tree)  \(tree)     \(tree)")
print("")

makeWaterLine()
makeWaterLine()


// pyramid

let star = "⭐"

func makeStarLine(_ numberOfStars: Int) {
var line = ""
    for _ in 0..<numberOfStars {
        line += star
    }
    print(line)
}

print("")
print("")
print("        \(star)")
print("       ", terminator: "")
makeStarLine(3)

print("      ", terminator: "")
makeStarLine(5)

print("     ", terminator: "")
makeStarLine(7)

print("    ", terminator: "")
makeStarLine(9)

print("   ", terminator: "")
makeStarLine(11)

