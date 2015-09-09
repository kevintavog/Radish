//
//  Radish
//

import Foundation

public class Location
{
    var latitude: Double
    var longitude: Double
    private var placenameComponents: Placename?

    init(latitude:Double, longitude:Double)
    {
        self.latitude = latitude
        self.longitude = longitude
        self.placenameComponents = nil
    }

    init(latitude:Double, latitudeReference:String, longitude:Double, longitudeReference:String)
    {
        if latitudeReference == "S" {
            self.latitude = latitude * -1.0
        }
        else {
            self.latitude = latitude
        }

        if longitudeReference == "W" {
            self.longitude = longitude * -1.0
        }
        else {
            self.longitude = longitude
        }
    }

    public func toDms() -> String
    {
        return Location.toDms(latitude, longitude: longitude)
    }

    static public func toDms(latitude: Double, longitude: Double) -> String
    {
        let latitudeNorthOrSouth = latitude < 0 ? "S" : "N"
        let longitudeEastOrWest = longitude < 0 ? "W" : "E"
        return "\(toDms(latitude)) \(latitudeNorthOrSouth), \(toDms(longitude)) \(longitudeEastOrWest)"
    }

    static private func toDms(geo: Double) -> String
    {
        var g = geo
        if (g < 0.0) {
            g *= -1.0
        }

        let degrees = Int(g)
        let minutesDouble = (g - Double(degrees)) * 60.0
        let minutesInt = Int(minutesDouble)
        let seconds = (minutesDouble - Double(minutesInt)) * 60.0

        let s = String(format: "%.2d° %.2d' %.2f", degrees, minutesInt, seconds)
        return s
    }

    public func placename() -> String
    {
        if placenameComponents == nil {
            CachedLookupProvider.lookup(latitude, longitude: longitude, completion: { (placename: OrderedDictionary<String,String>) -> () in

                self.placenameComponents = Placename(components: placename)
            })

            return ""
        }
        else {
            return (placenameComponents?.name(.Detailed))!
        }
    }
}