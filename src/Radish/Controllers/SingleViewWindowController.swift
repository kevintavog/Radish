//
//  Radish
//

import AppKit
import AVFoundation
import AVKit
import Foundation

import Async

enum MenuItemTag: Int
{
    case AlwaysEnable = 1, RequiresFile = 2
}

class SingleViewWindowController: NSWindowController
{
    @IBOutlet weak var videoPlayer: AVPlayerView!
    @IBOutlet weak var imageViewer: NSImageView!
    @IBOutlet weak var statusTimestamp: NSTextField!
    @IBOutlet weak var statusKeywords: NSTextField!
    @IBOutlet weak var statusIndex: NSTextField!
    @IBOutlet weak var statusLocation: NSTextField!
    @IBOutlet weak var statusFilename: NSTextField!



    let trashSoundPath = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/dock/drag to trash.aif"
    var mediaProvider: MediaProvider?
    var currentFileIndex = 0
    private var dateFormatter: NSDateFormatter? = nil


    // MARK: Initialize
    func initialize(mediaProvider: MediaProvider)
    {
        self.mediaProvider = mediaProvider

        window?.backgroundColor = NSColor.darkGrayColor()

        videoPlayer.hidden = true
        imageViewer.hidden = true

        dateFormatter = NSDateFormatter()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"

        updateStatusView()

        Notifications.addObserver(self, selector: "viewMediaData:", name: Notifications.SingleView.MediaData, object: nil)
    }


    // MARK: Actions
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool
    {
        switch MenuItemTag(rawValue: menuItem.tag)! {
        case .AlwaysEnable:
            return true
        case .RequiresFile:
            return mediaProvider?.mediaFiles.count > 0
        }
    }

    @IBAction func openFolder(sender: AnyObject)
    {
        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        currentFileIndex = 0;
        mediaProvider!.clear()

        addFolders(folders.urls, selected: folders.selected)

        if (mediaProvider!.mediaFiles.count > 0) {
            displayFile(mediaProvider!.mediaFiles[currentFileIndex])
        }
    }

    @IBAction func addFolder(sender: AnyObject)
    {
        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        addFolders(folders.urls, selected: mediaProvider!.mediaFiles[currentFileIndex].url)
        updateStatusView()
    }

    @IBAction func nextFile(sender: AnyObject)
    {
        displayFileByIndex(currentFileIndex + 1)
    }

    @IBAction func previousFile(sender: AnyObject)
    {
        displayFileByIndex(currentFileIndex - 1)
    }

    @IBAction func revealInFinder(sender: AnyObject)
    {
        NSWorkspace.sharedWorkspace().selectFile(mediaProvider?.mediaFiles[currentFileIndex].url!.path!, inFileViewerRootedAtPath: "")
    }

    @IBAction func setFileDateFromExifDate(sender: AnyObject)
    {
        Logger.log("setFileDateFromExifDate")
    }

    @IBAction func autoRotate(sender: AnyObject)
    {
        Logger.log("autoRotate")
    }

    @IBAction func moveToTrash(sender: AnyObject)
    {
        let url = mediaProvider?.mediaFiles[currentFileIndex].url!
        Logger.log("moveToTrash: \((url?.path!)!)")

        let folder = url?.URLByDeletingLastPathComponent?.path
        let filename = (url?.lastPathComponent!)!
        let succeeded = NSWorkspace.sharedWorkspace().performFileOperation(
            NSWorkspaceRecycleOperation,
            source: folder!,
            destination: "",
            files: [filename],
            tag: nil)

        if !succeeded {
            let alert = NSAlert()
            alert.messageText = "Failed moving '\(filename)' to trash."
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.addButtonWithTitle("Close")
            alert.runModal()
        }
        else {
            NSSound(contentsOfFile: trashSoundPath, byReference: false)?.play()
        }
    }

    // MARK: Notification handlers
    func viewMediaData(notification: NSNotification)
    {
        if let userInfo = notification.userInfo as? Dictionary<String,MediaData> {
            if let mediaData = userInfo["MediaData"] {
                if selectByUrl(mediaData.url, display: true) == nil {
                    Logger.log("Unable to find \(mediaData.url)")
                }
                self.showWindow(nil)
            }
        }
    }

    // MARK: Display files
    func displayFileByIndex(index: Int)
    {
        if (mediaProvider!.mediaFiles.count > 0) {
            currentFileIndex = index
            if (currentFileIndex < 0) { currentFileIndex = mediaProvider!.mediaFiles.count - 1; }
            if (currentFileIndex >= mediaProvider!.mediaFiles.count) { currentFileIndex = 0; }

            displayFile(mediaProvider!.mediaFiles[currentFileIndex])
        }
    }

    func displayFile(media:MediaData)
    {
        updateStatusView()

        switch media.type! {
        case .Image:
            displayImage(media)
        case .Video:
            displayVideo(media)
        default:
            displayUnsupportedFileType(media)
        }

        let userInfo: [String: MediaData] = ["MediaData": media]
        Notifications.postNotification(Notifications.Selection.MediaData, object: self, userInfo: userInfo)
    }

    func displayImage(media:MediaData)
    {
        stopVideoPlayer()

        imageViewer.image = nil
        if (imageViewer.hidden) {
            imageViewer.hidden = false
            videoPlayer.hidden = true
        }

        Async.background {
            let imageSource = CGImageSourceCreateWithURL(media.url, nil)
            let image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
            let nsImage = NSImage(CGImage: image!, size: NSSize(width: CGImageGetWidth(image), height: CGImageGetHeight(image)))

            Async.main {
                self.imageViewer.image = nsImage;
            }
        }
    }

    func displayVideo(media:MediaData)
    {
        stopVideoPlayer()

        videoPlayer.player = AVPlayer(URL: media.url)
        videoPlayer.player?.volume = Preferences.videoPlayerVolume

        if (videoPlayer.hidden) {
            videoPlayer.hidden = false
            imageViewer.hidden = true
            imageViewer.image = nil
        }

        videoPlayer.player?.addObserver(self, forKeyPath: "volume", options: .New, context: nil)

        videoPlayer.player?.play()
    }

    func displayUnsupportedFileType(media:MediaData)
    {
        videoPlayer.player?.pause()
        videoPlayer.hidden = true
        imageViewer.hidden = true

        Logger.log("Unhandled file: '\(media.name)'")
    }

    // MARK: Video helpers
    func stopVideoPlayer()
    {
        if let player = videoPlayer.player {
            player.removeObserver(self, forKeyPath: "volume", context: nil)
            player.pause()
            videoPlayer.player = nil
        }
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        switch keyPath! {
        case "volume":
            if let volume = change![NSKeyValueChangeNewKey] as? Float {
                Preferences.videoPlayerVolume = volume
            }

        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }


    // MARK: Update UI elements
    func updateStatusView()
    {
        if (currentFileIndex < 0 || currentFileIndex >= mediaProvider!.mediaFiles.count || mediaProvider!.mediaFiles.count == 0) {
            statusFilename.stringValue = ""
            statusTimestamp.stringValue = ""
            statusLocation.stringValue = ""
            statusKeywords.stringValue = ""
            statusIndex.stringValue = ""
            window?.title = "Radish - <No files>"
        }
        else {
            let media = mediaProvider!.mediaFiles[currentFileIndex]

            statusIndex.stringValue = "\(currentFileIndex + 1) of \(mediaProvider!.mediaFiles.count)"
            statusFilename.stringValue = "\(media.name)"
            statusLocation.stringValue = media.locationString()
            statusKeywords.stringValue = media.keywordsString()

            let timestamp = "\(dateFormatter!.stringFromDate(media.timestamp!))"
            if media.doFileAndExifTimestampsMatch() {
                statusTimestamp.stringValue = timestamp
            }
            else {
                let fullRange = NSRange(location: 0, length: timestamp.characters.count)
                let attributeString = NSMutableAttributedString(string: timestamp)
                attributeString.addAttribute(NSForegroundColorAttributeName, value: NSColor.yellowColor(), range: fullRange)
                attributeString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: fullRange)
                statusTimestamp.attributedStringValue = attributeString
            }

            window?.title = "Radish - \(media.name)"

            if media.location != nil {
                Async.background {
                    let placename = media.location.placename()
                    if placename.characters.count > 0 {
                        Async.main {
                            self.statusLocation.stringValue = placename
                        }
                    }
                }
            }
        }
    }

    // MARK: add/open folder helpers
    func openFolderOrFile(filename: String) -> Bool
    {
        var isFolder:ObjCBool = false
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(filename, isDirectory:&isFolder)
        if !fileExists {
            return false
        }

        currentFileIndex = 0;
        mediaProvider!.clear()

        let url = [NSURL(fileURLWithPath: filename)]
        addFolders(url, selected: url[0])

        if (mediaProvider!.mediaFiles.count > 0) {
            displayFile(mediaProvider!.mediaFiles[currentFileIndex])
        }

        return true
    }

    func selectFoldersToAdd() -> (urls: [NSURL]!, selected: NSURL!)
    {
        let dialog = NSOpenPanel()

        dialog.allowedFileTypes = SupportedTypes.all()
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = true
        if 1 != dialog.runModal() || dialog.URLs.count < 1 {
            return (nil, nil)
        }


        let localFile = dialog.URLs[0]
        var isFolder:ObjCBool = false
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(localFile.path!, isDirectory:&isFolder)
        if !fileExists {
            return (nil, nil)
        }

        return (dialog.URLs, localFile)
    }

    func addFolders(urls: [NSURL], selected: NSURL!)
    {
        for folderUrl in urls {
            var isFolder: ObjCBool = false
            let fileExists = NSFileManager.defaultManager().fileExistsAtPath(folderUrl.path!, isDirectory:&isFolder)
            if !fileExists {
                continue
            }

            var url = folderUrl
            if !isFolder {
                url = folderUrl.URLByDeletingLastPathComponent!
            }

            mediaProvider!.addFolder(url.path!)
        }

        if (selected != nil) {
            selectByUrl(selected, display: false)
        }

        NSDocumentController.sharedDocumentController().noteNewRecentDocumentURL(urls[0])
    }

    func selectByUrl(url: NSURL, display: Bool) -> Int?
    {
        for (index, mediaFile) in mediaProvider!.mediaFiles.enumerate() {
            if mediaFile.url == url {
                currentFileIndex = index
                if display {
                    displayFileByIndex(currentFileIndex)
                }
                return currentFileIndex
            }
        }

        return nil
    }
}