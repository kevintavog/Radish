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
    case alwaysEnable = 1, requiresFile = 2
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
    fileprivate var dateFormatter: DateFormatter? = nil


    let keyMappings: [KeySequence: Selector] = [
        KeySequence(modifierFlags: NSEventModifierFlags.function, chars: "\u{F729}"): #selector(SingleViewWindowController.moveToFirstItem(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.function, chars: "\u{F72B}"): #selector(SingleViewWindowController.moveToLastItem(_:)),

        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "1"): #selector(SingleViewWindowController.moveToTenPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "2"): #selector(SingleViewWindowController.moveToTwentyPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "3"): #selector(SingleViewWindowController.moveToThirtyPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "4"): #selector(SingleViewWindowController.moveToFortyPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "5"): #selector(SingleViewWindowController.moveToFiftyPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "6"): #selector(SingleViewWindowController.moveToSixtyPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "7"): #selector(SingleViewWindowController.moveToSeventyPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "8"): #selector(SingleViewWindowController.moveToEightyPercent(_:)),
        KeySequence(modifierFlags: NSEventModifierFlags.command, chars: "9"): #selector(SingleViewWindowController.moveToNinetyPercent(_:)),
    ]


    // MARK: Initialize
    func initialize(_ mediaProvider: MediaProvider)
    {
        self.mediaProvider = mediaProvider

        window?.backgroundColor = NSColor.darkGray

        videoPlayer.isHidden = true
        imageViewer.isHidden = true

        dateFormatter = DateFormatter()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"

        updateStatusView()

        Notifications.addObserver(self, selector: #selector(SingleViewWindowController.viewMediaData(_:)), name: Notifications.SingleView.MediaData, object: nil)
        Notifications.addObserver(self, selector: #selector(SingleViewWindowController.mediaProviderUpdated(_:)), name: Notifications.MediaProvider.UpdatedNotification, object: nil)
    }


    // MARK: Notification handlers
    func viewMediaData(_ notification: Notification)
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

    func mediaProviderUpdated(_ notification: Notification)
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
    func displayFileByIndex(_ index: Int)
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
        case .image:
            displayImage(currentMediaData!)
        case .video:
            displayVideo(currentMediaData!)
        default:
            displayUnsupportedFileType(currentMediaData)
        }

        let userInfo: [String: MediaData] = ["MediaData": currentMediaData!]
        Notifications.postNotification(Notifications.Selection.MediaData, object: self, userInfo: userInfo)
    }

    func displayImage(_ media:MediaData)
    {
        stopVideoPlayer()

        imageViewer.image = nil
        if (imageViewer.isHidden) {
            imageViewer.isHidden = false
            videoPlayer.isHidden = true
        }

        Async.background {
            var nsImage: NSImage
            if let rotation = media.rotation, rotation == 1 {
                nsImage = NSImage(byReferencing: media.url)
            } else {
                let imageSource = CGImageSourceCreateWithURL(media.url as CFURL, nil)
                let image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
                nsImage = NSImage(cgImage: image!, size: NSSize(width: (image?.width)!, height: (image?.height)!))
            }

            Async.main {
                self.imageViewer.image = nsImage;
            }
        }
    }

    func displayVideo(_ media:MediaData)
    {
        stopVideoPlayer()

        videoPlayer.player = AVPlayer(url: media.url)
        videoPlayer.player?.volume = Preferences.videoPlayerVolume

        if (videoPlayer.isHidden) {
            videoPlayer.isHidden = false
            imageViewer.isHidden = true
            imageViewer.image = nil
        }

        videoPlayer.player?.addObserver(self, forKeyPath: "volume", options: .new, context: nil)

        videoPlayer.player?.play()
    }

    func displayUnsupportedFileType(_ media:MediaData!)
    {
        videoPlayer.player?.pause()
        videoPlayer.isHidden = true
        imageViewer.isHidden = true

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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        switch keyPath! {
        case "volume":
            if let volume = change![NSKeyValueChangeKey.newKey] as? Float {
                Preferences.videoPlayerVolume = volume
            }

        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
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
            statusFilename.stringValue = "\(media.name!)"
            statusLocation.stringValue = media.locationString()
            statusKeywords.stringValue = media.keywordsString()

            let timestamp = "\(dateFormatter!.string(from: media.timestamp!))"
            if media.doFileAndExifTimestampsMatch() {
                statusTimestamp.stringValue = timestamp
            }
            else {
                let fullRange = NSRange(location: 0, length: timestamp.characters.count)
                let attributeString = NSMutableAttributedString(string: timestamp)
                attributeString.addAttribute(NSForegroundColorAttributeName, value: NSColor.yellow, range: fullRange)
                attributeString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: fullRange)
                statusTimestamp.attributedStringValue = attributeString
            }

            window?.title = "Radish - \(media.name!)"

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
    func openFolderOrFile(_ filename: String) -> Bool
    {
        var isFolder:ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: filename, isDirectory:&isFolder)
        if !fileExists {
            return false
        }

        currentMediaData = nil
        currentFileIndex = 0;
        mediaProvider!.clear()

        let url = [URL(fileURLWithPath: filename)]
        addFolders(url, selected: url[0])
        return true
    }

    func selectFoldersToAdd() -> (urls: [URL]?, selected: URL?)
    {
        let dialog = NSOpenPanel()

        dialog.allowedFileTypes = SupportedMediaTypes.all()
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = true
        if 1 != dialog.runModal() || dialog.urls.count < 1 {
            return (nil, nil)
        }


        let localFile = dialog.urls[0]
        var isFolder:ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: localFile.path, isDirectory:&isFolder)
        if !fileExists {
            return (nil, nil)
        }

        return (dialog.urls, localFile)
    }

    func addFolders(_ urls: [URL], selected: URL!)
    {
        for folderUrl in urls {
            var isFolder: ObjCBool = false
            let fileExists = FileManager.default.fileExists(atPath: folderUrl.path, isDirectory:&isFolder)
            if !fileExists {
                continue
            }

            var url = folderUrl
            if !isFolder.boolValue {
                url = folderUrl.deletingLastPathComponent()
            }

            mediaProvider!.addFolder(url.path)
        }

        if selected != nil {
            let _ = selectByUrl(selected, display: true)
        }

        NSDocumentController.shared().noteNewRecentDocumentURL(urls[0])
    }

    func selectByUrl(_ url: URL, display: Bool) -> Int?
    {
        for (index, mediaFile) in mediaProvider!.mediaFiles.enumerated() {
            if mediaFile.url == url {
                if display {
                    currentFileIndex = -1
                    displayFileByIndex(index)
                } else {
                    currentFileIndex = index
                    currentMediaData = mediaFile
                }
                return currentFileIndex
            }
        }

        return nil
    }
}

