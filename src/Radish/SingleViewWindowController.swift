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



    let gatherer = MediaGatherer()
    var currentFileIndex = 0
    private var dateFormatter:NSDateFormatter? = nil


    func initialize()
    {
        window?.backgroundColor = NSColor.darkGrayColor()

        videoPlayer.hidden = true
        imageViewer.hidden = true

        dateFormatter = NSDateFormatter()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss"

        updateStatusView()
    }

    @IBAction func openFile(sender: AnyObject)
    {
        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        currentFileIndex = 0;
        gatherer.clear()

        addFolders(folders.urls, selected: folders.selected)

        if (gatherer.mediaFiles.count > 0)
        {
            displayFile(gatherer.mediaFiles[currentFileIndex])
        }
    }

    @IBAction func addFile(sender: AnyObject)
    {
        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        addFolders(folders.urls, selected: gatherer.mediaFiles[currentFileIndex].url)
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

    func displayFileByIndex(index: Int)
    {
        if (gatherer.mediaFiles.count > 0)
        {
            currentFileIndex = index
            if (currentFileIndex < 0) { currentFileIndex = gatherer.mediaFiles.count - 1; }
            if (currentFileIndex >= gatherer.mediaFiles.count) { currentFileIndex = 0; }

            displayFile(gatherer.mediaFiles[currentFileIndex])
        }
    }

    func displayFile(media:MediaData)
    {
        updateStatusView()

        switch media.type!
        {
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
        if (imageViewer.hidden)
        {
            imageViewer.hidden = false
            videoPlayer.hidden = true
        }

        Async.background
        {
            let imageSource = CGImageSourceCreateWithURL(media.url, nil)
            let image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
            let nsImage = NSImage(CGImage: image!, size: NSSize(width: CGImageGetWidth(image), height: CGImageGetHeight(image)))

            self.imageViewer.image = nsImage;
        }
    }

    func displayVideo(media:MediaData)
    {
        videoPlayer.player = AVPlayer(URL: media.url)
        if (videoPlayer.hidden)
        {
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

    func updateStatusView()
    {
        if (currentFileIndex < 0 || currentFileIndex >= gatherer.mediaFiles.count || gatherer.mediaFiles.count == 0)
        {
            statusFilename.stringValue = ""
            statusTimestamp.stringValue = ""
            statusLocation.stringValue = ""
            statusKeywords.stringValue = ""
            statusIndex.stringValue = ""
        }
        else
        {
            let media = gatherer.mediaFiles[currentFileIndex]

            statusIndex.stringValue = "\(currentFileIndex + 1) of \(gatherer.mediaFiles.count)"
            statusFilename.stringValue = "\(media.name)"
            statusTimestamp.stringValue = "\(dateFormatter!.stringFromDate(media.timestamp!))"
        }
    }

    func selectFoldersToAdd() -> (urls:[NSURL]!,selected:NSURL!)
    {
        let dialog = NSOpenPanel()

        dialog.allowedFileTypes = SupportedTypes.all()
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = true
        if 1 != dialog.runModal() || dialog.URLs.count < 1
        {
            return (nil, nil)
        }


        let localFile = dialog.URLs[0]
        var isFolder:ObjCBool = false
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(localFile.path!, isDirectory:&isFolder)
        if !fileExists
        {
            return (nil, nil)
        }

        return (dialog.URLs, localFile)
    }

    func addFolders(urls:[NSURL], selected:NSURL!)
    {
        for folderUrl in urls
        {
            gatherer.addFolder(folderUrl.path!)
        }

        if (selected != nil)
        {
            var index = 0
            for f in gatherer.mediaFiles
            {
                if f.url == selected
                {
                    currentFileIndex = index
                    break
                }

                ++index
            }
        }
    }
}