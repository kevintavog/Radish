
import Foundation

import Alamofire
import SwiftyJSON

open class PlacenameDetail
{
    public let name: String
    public let value: String
    
    init(name: String, value: String)
    {
        self.name = name
        self.value = value
    }
}


open class PlacenameDetailsProvider {

    public init() {
    }

    public func lookup(latitude: Double, longitude: Double) -> [PlacenameDetail] {
        var details = [PlacenameDetail]()

        let url = "\(Preferences.baseLocationLookup)api/v1/test"
        let parameters = [
            "lat": "\(latitude)",
            "lon": "\(longitude)"]

        var error: Swift.Error? = nil
        var resultData: Data? = nil
        let semaphore = DispatchSemaphore(value: 0)
        Alamofire.request(url, parameters: parameters)
            .validate()
            .response { response in
                
                if response.error != nil {
                    error = response.error
                }
                else {
                    resultData = response.data
                }
                
                semaphore.signal()
        }
        
        semaphore.wait()
        if error != nil {
            return details
        }
        
        do {
            let json = try JSON(data: resultData!)
            details.append(contentsOf: getDetails(json["azure"], "azure"))
            details.append(contentsOf: getDetails(json["foursquare"], "foursquare"))
            details.append(contentsOf: getDetails(json["ocd"], "ocd"))
            details.append(contentsOf: getDetails(json["osm"], "osm"))
            details.append(contentsOf: getDetails(json["azure_results"], "azure_results"))
            details.append(contentsOf: getDetails(json["foursquare_compact"], "foursquare_venues"))
            details.append(contentsOf: getDetails(json["ocd_components"], "ocd_components"))
            details.append(contentsOf: getDetails(json["osm_address"], "osm_address"))
            return details
        } catch {
            return details
        }
    }
    
    private func getDetails(_ json: JSON?, _ prefix: String) -> [PlacenameDetail] {
        var details = [PlacenameDetail]()
        if let validJson = json {
            for (key,subJson):(String, JSON) in validJson {
                if let jsonArray = subJson.array {
                    for (index, arraySubJson) in jsonArray.enumerated() {
                        details.append(contentsOf: getDetails(arraySubJson, "\(prefix).\(key).\(index)"))
                    }
                } else if let jsonDictionary = subJson.dictionary {
                    for (dictionaryKey, dictionaryJson) in jsonDictionary {
                        details.append(contentsOf: getDetails(dictionaryJson, "\(prefix).\(key).\(dictionaryKey)"))
                    }
                } else {
                    details.append(PlacenameDetail(name: prefix + "." + key, value: subJson.rawString()!))
                }
            }
        }
        if details.count > 0 {
            details.insert(PlacenameDetail(name: "", value: ""), at: 0)
        }
        return details
    }
}
