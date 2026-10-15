import Cocoa
// In: <owner app name>. Out: "<CGWindowID>\t<X> <Y> <W> <H>\t[<title>]" cho mọi cửa sổ on-screen của app.
let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Transporter"
let list = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as! [[String: Any]]
for w in list {
  let o = w[kCGWindowOwnerName as String] as? String ?? ""
  if o != owner { continue }
  let name = w[kCGWindowName as String] as? String ?? ""
  let wid = w[kCGWindowNumber as String] as! Int
  let b = w[kCGWindowBounds as String] as! [String: Any]
  print("\(wid)\t\(b["X"]!) \(b["Y"]!) \(b["Width"]!) \(b["Height"]!)\t[\(name)]")
}
