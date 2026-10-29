import Foundation
import MapKit
final class D: NSObject, MKLocalSearchCompleterDelegate {
  var log: [(String,Int,String)] = []
  func completerDidUpdateResults(_ c: MKLocalSearchCompleter){ log.append((c.queryFragment,c.results.count,c.results.first.map{$0.title+" / "+$0.subtitle} ?? "")) }
  func completer(_ c: MKLocalSearchCompleter, didFailWithError e: Error){ let n=e as NSError; log.append((c.queryFragment,-1,"FAIL \(n.domain) \(n.code) \(n.localizedDescription)")) }
}
let d = D(); let c = MKLocalSearchCompleter(); c.delegate = d
c.resultTypes = [.address,.pointOfInterest,.query]
if CommandLine.arguments.count > 1 { c.region = MKCoordinateRegion(center: .init(latitude: 16, longitude: 106), span: .init(latitudeDelta: 16, longitudeDelta: 8)) }
let target = "45 Lê Văn Sỹ, Phường 13"; let ch = Array(target)
let idx = [2,5,8,10,12,14,16,17,18,19,20,21,22,23,24]
for (i,k) in idx.enumerated() {
  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3*Double(i)) { c.queryFragment = String(ch.prefix(k)) }
}
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3*15 + 4) {
  print("step_fragment\tresults\tfirst")
  for l in d.log { print("\(l.0)\t\(l.1)\t\(l.2)") }
  print("total callbacks \(d.log.count), failures \(d.log.filter{$0.1 == -1}.count)"); exit(0) }
RunLoop.main.run()
