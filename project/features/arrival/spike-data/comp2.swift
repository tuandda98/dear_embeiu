import Foundation
import MapKit
final class D: NSObject, MKLocalSearchCompleterDelegate {
  func completerDidUpdateResults(_ c: MKLocalSearchCompleter){ print("UPDATE", c.queryFragment, c.results.count, c.results.first?.title ?? ""); fflush(stdout) }
  func completer(_ c: MKLocalSearchCompleter, didFailWithError e: Error){ print("FAIL", e); fflush(stdout) }
}
let d = D(); let c = MKLocalSearchCompleter(); c.delegate = d
c.resultTypes = [.address,.pointOfInterest,.query]
DispatchQueue.main.async { c.queryFragment = "Sydney Opera" }
DispatchQueue.main.asyncAfter(deadline: .now()+4){ c.queryFragment = "45 Le Van Sy"}
DispatchQueue.main.asyncAfter(deadline: .now()+8){ c.queryFragment = "Nhà hát Lớn Hà Nội"}
DispatchQueue.main.asyncAfter(deadline: .now()+12){ print("end"); exit(0) }
RunLoop.main.run()
