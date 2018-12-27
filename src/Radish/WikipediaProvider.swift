import Foundation

import Alamofire
import SwiftyJSON

open class WikipediaDetail
{
    public let title: String
    public let pageId: Int
    public let distance: Int
    public let type: String
    
    init(title: String, pageId: Int, distance: Int, type: String)
    {
        self.title = title
        self.pageId = pageId
        self.distance = distance
        self.type = type
    }
}


open class WikipediaProvider {
    
    public init() {
    }
    
    public func lookup(latitude: Double, longitude: Double) -> [WikipediaDetail] {
        var details = [WikipediaDetail]()
        
        let url = "https://en.wikipedia.org/w/api.php"
        let parameters = [
            "action": "query",
            "format": "json",
            "gslimit": "20",
            "gscoord": "\(latitude)|\(longitude)",
            "gsprop": "globe|type",
            "gsradius": "2000",
            "list": "geosearch"]

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
            if let resultsJson = json["query"]["geosearch"].array {
                for itemJson in resultsJson {
                    if let title = itemJson["title"].string, let pageId = itemJson["pageid"].int, let distance = itemJson["dist"].double {
                        details.append(WikipediaDetail(title: title, pageId: pageId, distance: Int(distance), type: itemJson["type"].string ?? ""))
                    }
                }
            }
            return details
        } catch {
            return details
        }
    }
}
