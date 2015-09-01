//
//  Radish
//

import Foundation


class MediaData
{
    var name = ""
    var url: NSURL! = nil
    var timestamp: NSDate! = nil
    var location: Location! = nil
    var type:SupportedTypes.MediaType! = nil

    init()
    {
    }

}