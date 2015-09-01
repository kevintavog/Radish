//
//  Radish
//

import Foundation

class MediaGatherer
{
    var folders:[String] = []
    var mediaFiles:[MediaData] = []

    init()
    {
    }

    func clear()
    {
        folders = []
        mediaFiles = []
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
                        mediaFiles.append(FileMediaData(fileUrl:f, type:mediaType))
                    }
                }
            }
        }
    }

    func getFiles(folderName:String) -> [NSURL]?
    {
        do
        {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(
                NSURL(fileURLWithPath: folderName),
                includingPropertiesForKeys: nil,
                options:NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        }
        catch
        {
            return nil
        }
    }
}