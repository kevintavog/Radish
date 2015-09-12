//
//  Radish
//

import Foundation

class MediaProvider
{
    var folders:[String] = []
    var mediaFiles:[MediaData] = []
    var folderWatcher:[RangicFsEventStreamWrapper] = []


    func clear()
    {
        folders = []
        mediaFiles = []
        folderWatcher = []

        Notifications.postNotification(Notifications.MediaProvider.Cleared, object: self)
    }

    func addFolder(folderName:String)
    {
        addFolder(folderName, notifyOnLoad:true)
    }

    private func addFolder(folderName:String, notifyOnLoad:Bool)
    {
        if (folders.contains(folderName)) {
            return
        }

        if NSFileManager.defaultManager().fileExistsAtPath(folderName) {
            if let files = getFiles(folderName) {
                folders.append(folderName)

                for f in files {
                    let mediaType = SupportedTypes.getTypeFromFileExtension(((f.path!) as NSString).pathExtension)
//                    let mediaType = SupportedTypes.getType(f)
                    if mediaType == SupportedTypes.MediaType.Image || mediaType == SupportedTypes.MediaType.Video {
                        mediaFiles.append(FileMediaData.create(f, mediaType: mediaType))
                    }
                }
            }

            mediaFiles.sortInPlace( { (m1:MediaData, m2:MediaData) -> Bool in
                return m1.timestamp!.compare(m2.timestamp!) == NSComparisonResult.OrderedAscending })

            Notifications.postNotification(Notifications.MediaProvider.UpdatedNotification, object: self)

            folderWatcher.append(RangicFsEventStreamWrapper(path: folderName, callback: { (type, path) -> () in
                self.processFileSystemEvent(type, path: path)
            }))
        }
    }

    func refresh()
    {
        let allFolders = folders
        clear()

        for f in allFolders {
            addFolder(f, notifyOnLoad: false)
        }

        Notifications.postNotification(Notifications.MediaProvider.UpdatedNotification, object: self)
    }

    func processFileSystemEvent(eventType: RangicFsEventType, path: String)
    {
        Logger.log("file system change \(eventType.rawValue) - \(path)")
        if eventType == .RescanFolder {
            rescanFolder(path)
        }
        else {
            let url = NSURL(fileURLWithPath: path)
            if eventType == .Removed {
                removeFile(url)
            }
            else {
                let mediaType = SupportedTypes.getTypeFromFileExtension(((url.path!) as NSString).pathExtension)
                if mediaType == .Unknown {
                    return
                }

                switch eventType {
                case .Created:
                    addFile(url, mediaType: mediaType)

                case .Updated:
                    updateFile(url, mediaType: mediaType)

                case .Removed:
                    break

                case .RescanFolder:
                    break
                }
            }
        }

        Notifications.postNotification(Notifications.MediaProvider.UpdatedNotification, object: self)
    }

    func rescanFolder(path: String)
    {
        Logger.log("RescanFolder: \(path)")
    }

    func addFile(url: NSURL, mediaType: SupportedTypes.MediaType)
    {
        let mediaData = FileMediaData.create(url, mediaType: mediaType)
        let index = getMediaDataIndex(mediaData)
        if index < 0 {
            mediaFiles.insert(mediaData, atIndex: -index)
        }
        else {
            Logger.log("adding a file that seems to exist \(url) - \(mediaFiles[index].url)")
            mediaFiles.insert(mediaData, atIndex: index)
        }

        mediaFiles.sortInPlace(isOrderedBefore)
    }

    func removeFile(url: NSURL)
    {
        if let index = getFileIndex(url) {
            mediaFiles.removeAtIndex(index)
        }
        else {
            Logger.log("Unable to remove '\(url)' - cannot find in media files")
        }
    }

    func updateFile(url: NSURL, mediaType: SupportedTypes.MediaType)
    {
        Logger.log("Update \(url)")
        if let index = getFileIndex(url) {
            mediaFiles[index] = FileMediaData.create(url, mediaType: mediaType)
        }
        else {
            Logger.log("Updated file '\(url)' not in list, adding it")
            addFile(url, mediaType: mediaType)
        }
    }

    func getFileIndex(url: NSURL) -> Int?
    {
        for (index, mediaData) in mediaFiles.enumerate() {
            if mediaData.url == url {
                return index
            }
        }

        return nil
    }

    func getMediaDataIndex(mediaData: MediaData) -> Int
    {
        var lo = 0
        var hi = mediaFiles.count - 1
        while lo <= hi {
            let mid = (lo + hi) / 2
            if isOrderedBefore(mediaFiles[mid], m2:mediaData) {
                lo = mid + 1
            } else if isOrderedBefore(mediaData, m2:mediaFiles[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return -lo // not found, would be inserted at position lo
    }

    func isOrderedBefore(m1: MediaData, m2: MediaData) -> Bool
    {
        let dateComparison = m1.timestamp!.compare(m2.timestamp!)
        switch dateComparison {
        case .OrderedAscending:
            return true
        case .OrderedDescending:
            return false
        case .OrderedSame:
            switch m1.name.compare(m2.name) {
            case .OrderedAscending:
                return true
            case .OrderedDescending:
                return false
            case .OrderedSame:
                return true
            }
        }
    }

    func getFiles(folderName:String) -> [NSURL]?
    {
        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(
                NSURL(fileURLWithPath: folderName),
                includingPropertiesForKeys: [NSURLContentModificationDateKey],
                options:NSDirectoryEnumerationOptions.SkipsHiddenFiles)
        }
        catch {
            return nil
        }
    }
}