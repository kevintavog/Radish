//
//  Radish
//

import Foundation


public class MediaData
{
    public var name: String!
    public var url: NSURL!
    public var timestamp: NSDate!
    public var fileTimestamp: NSDate!
    public var location: Location!
    public var type: SupportedTypes.MediaType!
    public var keywords: [String]!

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
}