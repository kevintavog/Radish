//
//  Radish
//

import Foundation

public class CachedLookupProvider
{
    static var cache = Dictionary<String, OrderedDictionary<String,String>>()

    /// Asynchronously resolves latitude/longitude into a dictionary of component names. "DisplayName" is a single string
    static public func lookup(latitude: Double, longitude: Double, completion: (placename: OrderedDictionary<String,String>) -> () )
    {
        let key = Location.toDms(latitude, longitude: longitude)
        if let result = cache[key] {
            Logger.log("Found cached item for \(key)")
            completion(placename: result)
        }
        else {
            StandardLookupProvider.lookup(latitude, longitude: longitude, completion: { (placename: OrderedDictionary<String,String>) -> () in
                Logger.log("Caching \(key)")

                cache[key] = placename
                completion(placename: placename)
                })
        }
    }

}