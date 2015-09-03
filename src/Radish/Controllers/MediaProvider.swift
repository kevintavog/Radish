//
//  Radish
//

import Foundation

class MediaProvider
{
    static let MediaProviderCleared = "MediaProviderCleared"
    static let MediaProviderUpdatedNotification = "MediaProviderUpdatedNotification"


    var folders:[String] = []
    var mediaFiles:[MediaData] = []

    init()
    {
    }

    func clear()
    {
        folders = []
        mediaFiles = []

        NSNotificationCenter.defaultCenter().postNotificationName(MediaProvider.MediaProviderCleared, object: self)
    }

    func addFolder(folderName:String)
    {
        if (folders.contains(folderName))
        {
            return
        }

        if NSFileManager.defaultManager().fileExistsAtPath(folderName)
        {
            let files = getFiles(folderName)
            if files != nil
            {
                folders.append(folderName)

                for f in files!
                {
                    let mediaType = SupportedTypes.getType(f)
                    if mediaType == SupportedTypes.MediaType.Image || mediaType == SupportedTypes.MediaType.Video
                    {
                        var value:AnyObject?
                        try! f.getResourceValue(&value, forKey: NSURLContentModificationDateKey)
                        let date = value as! NSDate?
                        mediaFiles.append(FileMediaData(fileUrl:f, type:mediaType, date:date))
                    }
                }
            }

            mediaFiles.sortInPlace({(m1:MediaData, m2:MediaData) -> Bool in return m1.timestamp!.compare(m2.timestamp!) == NSComparisonResult.OrderedAscending })

            NSNotificationCenter.defaultCenter().postNotificationName(MediaProvider.MediaProviderUpdatedNotification, object: self)
        }
    }

    func getFiles(folderName:String) -> [NSURL]?
    {
        do
        {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(
                NSURL(fileURLWithPath: folderName),
                includingPropertiesForKeys: [NSURLContentModificationDateKey],
                options:NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        }
        catch
        {
            return nil
        }
    }
}