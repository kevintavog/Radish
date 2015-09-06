//
//  Radish
//

import Foundation

class MediaProvider
{
    var folders:[String] = []
    var mediaFiles:[MediaData] = []


    func clear()
    {
        folders = []
        mediaFiles = []

        Notifications.postNotification(Notifications.MediaProvider.Cleared, object: self)
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
                        mediaFiles.append(FileMediaData.create(f, mediaType: mediaType))
                    }
                }
            }

            mediaFiles.sortInPlace({(m1:MediaData, m2:MediaData) -> Bool in return m1.timestamp!.compare(m2.timestamp!) == NSComparisonResult.OrderedAscending })

            Notifications.postNotification(Notifications.MediaProvider.UpdatedNotification, object: self)
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