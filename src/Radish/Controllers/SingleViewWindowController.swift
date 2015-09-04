//
//  Radish
//

import AppKit
import AVFoundation
import AVKit
import Foundation


class SingleViewWindowController: NSWindowController
{
    @IBOutlet weak var videoPlayer: AVPlayerView!
    @IBOutlet weak var imageViewer: NSImageView!
    @IBOutlet weak var statusTimestamp: NSTextField!
    @IBOutlet weak var statusKeywords: NSTextField!
    @IBOutlet weak var statusIndex: NSTextField!
    @IBOutlet weak var statusLocation: NSTextField!
    @IBOutlet weak var statusFilename: NSTextField!



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
    }


    // MARK: Actions
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
    }

    func displayImage(media:MediaData)
    {
        videoPlayer.player?.pause()

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
        videoPlayer.player = AVPlayer(URL: media.url)
        if (videoPlayer.hidden) {
            videoPlayer.hidden = false
            imageViewer.hidden = true
            imageViewer.image = nil
        }
        videoPlayer.player?.play()
    }

    func displayUnsupportedFileType(media:MediaData)
    {
        videoPlayer.player?.pause()
        videoPlayer.hidden = true
        imageViewer.hidden = true

        print("Unhandled file: '\(media.name)'")
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
        }
    }

    func selectFoldersToAdd() -> (urls:[NSURL]!,selected:NSURL!)
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

    func addFolders(urls:[NSURL], selected:NSURL!)
    {
        for folderUrl in urls
        {
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

        if (selected != nil)
        {
            var index = 0
            for f in mediaProvider!.mediaFiles {
                if f.url == selected {
                    currentFileIndex = index
                    break
                }

                ++index
            }
        }
    }
}