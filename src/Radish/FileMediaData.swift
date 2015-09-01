//
//  Radish
//

import Foundation

class FileMediaData : MediaData
{
    init(fileUrl:NSURL, type:SupportedTypes.MediaType, date:NSDate?)
    {
        super.init()

        super.url = fileUrl
        super.name = fileUrl.lastPathComponent!
        super.type = type
        super.timestamp = date
    }
}