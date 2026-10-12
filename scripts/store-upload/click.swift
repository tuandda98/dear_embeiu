import Cocoa
let x = Double(CommandLine.arguments[1])!, y = Double(CommandLine.arguments[2])!
let p = CGPoint(x: x, y: y)
for t in [CGEventType.leftMouseDown, .leftMouseUp] {
  let e = CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: p, mouseButton: .left)!
  e.post(tap: .cghidEventTap); usleep(80000)
}
print("clicked \(x),\(y)")
