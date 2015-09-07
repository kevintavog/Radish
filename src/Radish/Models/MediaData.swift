//
//  Radish
//

import Foundation


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

    public var details: [MediaDataDetail]! {
        get {
            if cachedDetails == nil {
                cachedDetails = loadDetails()
            }
            return cachedDetails
        }
    }

    private var cachedDetails: [MediaDataDetail]!


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
        return [MediaDataDetail]()
    }
}