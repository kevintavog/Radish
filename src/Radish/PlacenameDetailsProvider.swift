
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
            details.append(contentsOf: getDetails(json["ocd"], "ocd"))
            details.append(contentsOf: getDetails(json["overpass"], "overpass"))
            details.append(contentsOf: getDetails(json["azure"], "azure"))
            details.append(contentsOf: getDetails(json["foursquare"], "foursquare"))
            details.append(contentsOf: getDetails(json["ocd_results"], "ocd_results"))
            details.append(contentsOf: getDetails(json["azure_results"], "azure_results"))
            details.append(contentsOf: getDetails(json["overpass_elements"], "overpass_elements"))
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
                    // If it's an array of objects, call recursively, otherwise convert each item to a string
                    if let first = jsonArray.first {
                        if nil != first.rawValue as? String {
                            let items: [String] = jsonArray.compactMap({ $0.rawValue as? String })
                            let val = "[" + items.joined(separator: ", ") + "]"
                            details.append(PlacenameDetail(name: prefix + "." + key, value: val))
                        } else {
                            for (index, arraySubJson) in jsonArray.enumerated() {
                                details.append(contentsOf: getDetails(arraySubJson, "\(prefix).\(key).\(index)"))
                            }
                        }
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
