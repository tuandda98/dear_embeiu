import Foundation
import CoreLocation
import MapKit

func hav(_ a: Double,_ b: Double,_ c: Double,_ d: Double)->Double{
  let r=6371000.0; let p1=a*Double.pi/180,p2=c*Double.pi/180
  let dp=(c-a)*Double.pi/180, dl=(d-b)*Double.pi/180
  let x=sin(dp/2)*sin(dp/2)+cos(p1)*cos(p2)*sin(dl/2)*sin(dl/2)
  return 2*r*asin(sqrt(x))
}
let dir = CommandLine.arguments[1]
func rows(_ f:String)->[[String]]{ (try! String(contentsOfFile: dir+"/"+f, encoding:.utf8)).split(separator:"\n").map{$0.split(separator:"\t",omittingEmptySubsequences:false).map(String.init)} }
let vnRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 16.0, longitude: 106.0), span: MKCoordinateSpan(latitudeDelta: 16, longitudeDelta: 8))
func out(_ s:String){ print(s); fflush(stdout) }

final class Comp: NSObject, MKLocalSearchCompleterDelegate {
  var last: [MKLocalSearchCompletion] = []; var err: Error?; var got = false
  func completerDidUpdateResults(_ c: MKLocalSearchCompleter){ last=c.results; err=nil; got=true }
  func completer(_ c: MKLocalSearchCompleter, didFailWithError e: Error){ err=e; got=true }
}

Task {
  let mode = CommandLine.arguments[2]
  if mode == "geo" {
    out("id\tgrp\tera\tapi\tn\tlat\tlon\tdist_m\tlabel")
    for r in rows("addrs.tsv") + rows("probes.tsv") {
      let isProbe = r[0].hasPrefix("P")
      let q = isProbe ? r[3] : r[3]
      let tl: (Double,Double)? = isProbe ? nil : (Double(r[4])!, Double(r[5])!)
      func rep(_ api:String,_ n:Int,_ lat:Double?,_ lon:Double?,_ label:String){
        var d = "NA"
        if let t=tl, let la=lat, let lo=lon { d = String(Int(hav(t.0,t.1,la,lo))) }
        out("\(r[0])\t\(r[1])\t\(r[2])\t\(api)\t\(n)\t\(lat.map{String($0)} ?? "")\t\(lon.map{String($0)} ?? "")\t\(d)\t\(label)")
      }
      // CLGeocoder as typed
      do {
        let p = try await CLGeocoder().geocodeAddressString(q)
        if let f=p.first { rep("CL",p.count,f.location?.coordinate.latitude,f.location?.coordinate.longitude,[f.name,f.thoroughfare,f.subLocality,f.locality].compactMap{$0}.joined(separator:" | ")) } else { rep("CL",0,nil,nil,"empty") }
      } catch { rep("CL",0,nil,nil,"ERR \((error as NSError).domain) \((error as NSError).code)") }
      try? await Task.sleep(nanoseconds: 1_500_000_000)
      // MKLocalSearch
      do {
        let req = MKLocalSearch.Request(); req.naturalLanguageQuery = q; req.region = vnRegion
        req.resultTypes = [.address, .pointOfInterest]
        let resp = try await MKLocalSearch(request: req).start()
        // best-of-first-5 also tracked
        var best = Double.infinity
        if let t=tl { for it in resp.mapItems.prefix(5){ let c=it.placemark.coordinate; best=min(best,hav(t.0,t.1,c.latitude,c.longitude)) } }
        if let f=resp.mapItems.first { rep("MK",resp.mapItems.count,f.placemark.coordinate.latitude,f.placemark.coordinate.longitude,"\(f.name ?? "") | \(f.placemark.title ?? "") | best5=\(best.isFinite ? String(Int(best)) : "NA")") } else { rep("MK",0,nil,nil,"empty") }
      } catch { rep("MK",0,nil,nil,"ERR \((error as NSError).domain) \((error as NSError).code)") }
      try? await Task.sleep(nanoseconds: 1_500_000_000)
    }
  } else {
    let target = "45 Lê Văn Sỹ, Phường 13"
    let comp = Comp(); let c = MKLocalSearchCompleter(); c.delegate = comp; c.region = vnRegion
    c.resultTypes = [.address, .pointOfInterest, .query]
    out("step\tfragment\tn\terror\tfirst")
    let chars = Array(target)
    let idx = [2,5,8,10,12,14,16,17,18,19,20,21,22,23,chars.count]
    var i = 0
    for k in idx {
      i += 1
      let frag = String(chars.prefix(k))
      comp.got = false; c.queryFragment = frag
      try? await Task.sleep(nanoseconds: 300_000_000)
      let e = comp.err.map{ "\(($0 as NSError).domain) \(($0 as NSError).code) \($0.localizedDescription)" } ?? "-"
      out("\(i)\t\(frag)\t\(comp.got ? comp.last.count : -1)\t\(e)\t\(comp.last.first.map{$0.title+" / "+$0.subtitle} ?? "")")
    }
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    out("final\t\(target)\t\(comp.last.count)\t\(comp.err.map{"\($0)"} ?? "-")\t\(comp.last.first.map{$0.title+" / "+$0.subtitle} ?? "")")
  }
  exit(0)
}
RunLoop.main.run()
