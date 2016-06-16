//
//  Radish
//

import AppKit
import AVFoundation
import AVKit
import Foundation

import RangicCore
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
    var currentMediaData: MediaData?
    private var dateFormatter: NSDateFormatter? = nil


    let keyMappings: [KeySequence: Selector] = [
        KeySequence(modifierFlags: NSEventModifierFlags.FunctionKeyMask, chars: "\u{F729}"): "moveToFirstItem:",
        KeySequence(modifierFlags: NSEventModifierFlags.FunctionKeyMask, chars: "\u{F72B}"): "moveToLastItem:",

        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "1"): "moveToTenPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "2"): "moveToTwentyPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "3"): "moveToThirtyPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "4"): "moveToFortyPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "5"): "moveToFiftyPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "6"): "moveToSixtyPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "7"): "moveToSeventyPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "8"): "moveToEightyPercent:",
        KeySequence(modifierFlags: NSEventModifierFlags.CommandKeyMask, chars: "9"): "moveToNinetyPercent:",
    ]


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
        Notifications.addObserver(self, selector: "mediaProviderUpdated:", name: Notifications.MediaProvider.UpdatedNotification, object: nil)
    }


    // MARK: Notification handlers
    func viewMediaData(notification: NSNotification)
    {
        if let userInfo = notification.userInfo as? Dictionary<String,MediaData> {
            if let mediaData = userInfo["MediaData"] {
                if selectByUrl(mediaData.url, display: true) == nil {
                    Logger.warn("Unable to find \(mediaData.url)")
                }
                self.showWindow(nil)
            }
        }
    }

    func mediaProviderUpdated(notification: NSNotification)
    {
        // The media files have been updated (added to, removed from or an instance updated).
        // This may cause our current selection to change - or the currently displayed metadata to change
        if mediaProvider!.mediaFiles.count == 0 {
            displayUnsupportedFileType(nil)
        }
        else {
            let oldIndex = currentFileIndex

            if currentFileIndex >= mediaProvider!.mediaFiles.count {
                currentFileIndex = mediaProvider!.mediaFiles.count - 1;
            }

            // Try to select the same file that was previously selected - if lotsa files are added to the list,
            // keep the same selection
            if currentMediaData != nil {
                let mediaData = mediaProvider!.mediaFiles[currentFileIndex]
                if mediaData.url != currentMediaData!.url {
                    // Scan the list for it
                    if let index = mediaProvider?.getFileIndex(currentMediaData!.url) {
                        currentFileIndex = index
                    }
                    else {
                        currentFileIndex = min(oldIndex, mediaProvider!.mediaFiles.count - 1)
                        currentMediaData = mediaProvider!.mediaFiles[currentFileIndex]
                    }
                }
            }
            else {
                currentMediaData = mediaProvider!.mediaFiles[currentFileIndex]
            }

            displayCurrentFile()
        }
    }


    // MARK: Display files
    func displayFileByIndex(index: Int)
    {
        if (mediaProvider!.mediaFiles.count > 0) {
            let originalIndex = currentFileIndex
            currentFileIndex = index
            if (currentFileIndex < 0) { currentFileIndex = mediaProvider!.mediaFiles.count - 1; }
            if (currentFileIndex >= mediaProvider!.mediaFiles.count) { currentFileIndex = 0; }

            if currentFileIndex == originalIndex {
                return
            }

            currentMediaData = mediaProvider!.mediaFiles[currentFileIndex]
        }
        else {
            currentMediaData = nil
        }

        displayCurrentFile()
    }

    func displayCurrentFile()
    {
        updateStatusView()
        if currentMediaData == nil || !(currentMediaData!.doesExist()) {
            displayUnsupportedFileType(currentMediaData)
            return
        }

        switch currentMediaData!.type! {
        case .Image:
            displayImage(currentMediaData!)
        case .Video:
            displayVideo(currentMediaData!)
        default:
            displayUnsupportedFileType(currentMediaData)
        }

        let userInfo: [String: MediaData] = ["MediaData": currentMediaData!]
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

    func displayUnsupportedFileType(media:MediaData!)
    {
        videoPlayer.player?.pause()
        videoPlayer.hidden = true
        imageViewer.hidden = true

        if media != nil {
            Logger.warn("Unhandled file: '\(media!.name)'")
        }
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
        if (currentMediaData == nil
            || currentFileIndex < 0
            || currentFileIndex >= mediaProvider!.mediaFiles.count
            || mediaProvider!.mediaFiles.count == 0) {

            statusFilename.stringValue = ""
            statusTimestamp.stringValue = ""
            statusLocation.stringValue = ""
            statusKeywords.stringValue = ""
            statusIndex.stringValue = ""
            window?.title = "Radish - <No files>"
        }
        else {
            let media = currentMediaData!
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
                    let placename = media.location.placenameAsString(Preferences.placenameFilter)
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

        currentMediaData = nil
        currentFileIndex = 0;
        mediaProvider!.clear()

        let url = [NSURL(fileURLWithPath: filename)]
        addFolders(url, selected: url[0])
        return true
    }

    func selectFoldersToAdd() -> (urls: [NSURL]!, selected: NSURL!)
    {
        let dialog = NSOpenPanel()

        dialog.allowedFileTypes = SupportedMediaTypes.all()
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

        if selected != nil {
            selectByUrl(selected, display: true)
        }

        NSDocumentController.sharedDocumentController().noteNewRecentDocumentURL(urls[0])
    }

    func selectByUrl(url: NSURL, display: Bool) -> Int?
    {
        for (index, mediaFile) in mediaProvider!.mediaFiles.enumerate() {
            if mediaFile.url == url {
                currentFileIndex = index
                currentMediaData = mediaFile
                if display {
                    displayFileByIndex(currentFileIndex)
                    displayCurrentFile()
                }
                return currentFileIndex
            }
        }

        return nil
    }
}

