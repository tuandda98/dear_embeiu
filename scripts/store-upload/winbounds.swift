import Cocoa
let want = Int(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as! [[String: Any]]
for w in list {
  let wid = w[kCGWindowNumber as String] as! Int
  if wid == want { let b = w[kCGWindowBounds as String] as! [String: Any]; print("\(b["X"]!) \(b["Y"]!) \(b["Width"]!) \(b["Height"]!)") }
}
