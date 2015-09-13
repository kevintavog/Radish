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
                    if mediaType == SupportedTypes.MediaType.Image || mediaType == SupportedTypes.MediaType.Video {
                        mediaFiles.append(FileMediaData.create(f, mediaType: mediaType))
                    }
                }
            }

            mediaFiles.sortInPlace( { (m1:MediaData, m2:MediaData) -> Bool in
                return m1.timestamp!.compare(m2.timestamp!) == NSComparisonResult.OrderedAscending })

            Notifications.postNotification(Notifications.MediaProvider.UpdatedNotification, object: self)

            folderWatcher.append(RangicFsEventStreamWrapper(path: folderName, callback: { (numEvents, typeArray, pathArray) -> () in
                var eventTypes = [RangicFsEventType]()
                for index in 0..<Int(numEvents) {
                    eventTypes.append(typeArray[index] as RangicFsEventType)
                }
                self.processFileSystemEvents(Int(numEvents), eventTypes: eventTypes, pathArray: pathArray as! [String])
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

    func processFileSystemEvents(numEvents: Int, eventTypes: [RangicFsEventType], pathArray: [String])
    {
        for index in 0..<numEvents {
            processOneFileSystemEvent(eventTypes[index], path: pathArray[index])
        }

        Notifications.postNotification(Notifications.MediaProvider.UpdatedNotification, object: self)
    }

    func processOneFileSystemEvent(eventType: RangicFsEventType, path: String)
    {
        if eventType == .RescanFolder {
            rescanFolder(path)
        }
        else {
            let mediaType = SupportedTypes.getTypeFromFileExtension((path as NSString).pathExtension)
            if mediaType == .Unknown {
                return
            }

            let url = NSURL(fileURLWithPath: path)
            if eventType == .Removed {
                removeFile(url)
            }
            else {
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
            mediaFiles.removeAtIndex(index)
            mediaFiles.insert(mediaData, atIndex: index)
        }
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
        if let index = getFileIndex(url) {
            mediaFiles[index] = FileMediaData.create(url, mediaType: mediaType)
        }
        else {
            Logger.log("Updated file '\(url)' not in list, adding it")
            addFile(url, mediaType: mediaType)
            mediaFiles.sortInPlace(isOrderedBefore)
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

            let midPath = mediaFiles[mid].url.path!
            if midPath.compare(mediaData.url.path!, options: NSStringCompareOptions.CaseInsensitiveSearch) == NSComparisonResult.OrderedSame {
                return mid
            }

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