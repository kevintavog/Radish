//
//  Radish
//

import Foundation
import Async

public class MediaData
{
    static private var dateFormatter: NSDateFormatter? = nil

    public var name: String!
    public var url: NSURL!
    public var timestamp: NSDate!
    public var fileTimestamp: NSDate!
    public var location: Location!
    public var type: SupportedTypes.MediaType!
    public var keywords: [String]!

    private var cachedDetails: [MediaDataDetail]!


    public var details: [MediaDataDetail]!
    {
        get {
            if cachedDetails == nil {
                Async.background {
                    self.cachedDetails = self.loadDetails()
                    Notifications.postNotification(Notifications.MediaProvider.DetailsAvailable, object: self, userInfo: nil)
                }
                return [MediaDataDetail]()
            }
            return cachedDetails
        }
    }

    public func doesExist() -> Bool
    {
        return true
    }

    public func doFileAndExifTimestampsMatch() -> Bool
    {
        return timestamp == fileTimestamp
    }

    public func locationString() -> String
    {
        if location != nil {
            return "\(location.toDms())"
        }
        else {
            return ""
        }
    }

    public func keywordsString() -> String
    {
        if keywords != nil {
            return keywords.joinWithSeparator(", ")
        }
        else {
            return ""
        }
    }

    public func formattedTime() -> String
    {
        if MediaData.dateFormatter == nil {
            MediaData.dateFormatter = NSDateFormatter()
            MediaData.dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }

        return MediaData.dateFormatter!.stringFromDate(timestamp!)
    }

    internal func loadDetails() -> [MediaDataDetail]
    {
        var details = [MediaDataDetail]()

        if location != nil {
            if let components = location!.asPlacename()?.components {
                details.append(MediaDataDetail(category: "Placename", name: nil, value: nil))
                for key in components.keys {
                    let value = components[key]
                    details.append(MediaDataDetail(category: nil, name: key, value: value))
                }
            }
        }

        return details
    }

    public func setFileDateToExifDate() -> (succeeded:Bool, errorMessage:String)
    {
        return (false, "Not implemented")
    }
}