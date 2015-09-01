//
//  Radish
//

import Foundation

class FileMediaData : MediaData
{
    init(fileUrl:NSURL, type:SupportedTypes.MediaType)
    {
        super.init()

        super.url = fileUrl
        super.name = fileUrl.lastPathComponent!
        super.type = type
    }
}