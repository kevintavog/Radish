//
//  SingleViewWindowController.swift
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


    var allFiles = [NSURL]()
    var currentFileIndex = 0


    func initialize()
    {
        window?.backgroundColor = NSColor.darkGrayColor()

        videoPlayer.hidden = true
        imageViewer.hidden = true

        updateStatusView()
    }

    @IBAction func openFile(sender: AnyObject)
    {
        let dialog = NSOpenPanel()

        dialog.allowedFileTypes = SupportedTypes.all()
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = false
        if 1 != dialog.runModal() || dialog.URLs.count < 1
        {
            return
        }


        let localFile = dialog.URLs[0]
        var isFolder:ObjCBool = false
        let fileExists = NSFileManager.defaultManager().fileExistsAtPath(localFile.path!, isDirectory:&isFolder)
        if !fileExists
        {
            return
        }

        var localFolder = localFile.path
        if !isFolder
        {
            localFolder = localFile.URLByDeletingLastPathComponent?.path
        }

        let filesInFolder = (try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(localFolder!)) as NSArray
        allFiles = []
        currentFileIndex = 0;

        var index = 0
        for f in filesInFolder
        {
            var fullName = localFolder! as NSString
            fullName = fullName.stringByAppendingPathComponent(f as! String)

            let fullUrl = NSURL(fileURLWithPath: fullName as String)
            if (isSupportedFile(fullUrl))
            {
                allFiles.append(fullUrl)

                if fullName == localFile.path
                {
                    currentFileIndex = allFiles.count - 1
                }
            }
            else
            {
                print("Ignoring file \(fullName)")
            }

            ++index
        }
        
        if (allFiles.count > 0)
        {
            displayFile(allFiles[currentFileIndex])
        }
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
        if (allFiles.count > 0)
        {
            currentFileIndex = index
            if (currentFileIndex < 0) { currentFileIndex = allFiles.count - 1; }
            if (currentFileIndex >= allFiles.count) { currentFileIndex = 0; }

            displayFile(allFiles[currentFileIndex])
        }
    }

    func displayFile(localFile: NSURL)
    {
        updateStatusView()

        let fileType = getFileType(localFile.path!)
        if SupportedTypes.images().contains(fileType)
        {
            displayImage(localFile)
        }
        else
            if SupportedTypes.videos().contains(fileType)
            {
                displayVideo(localFile)
            }
            else
            {
                displayUnsupportedFileType(localFile, fileType:fileType)
            }
    }

    func displayImage(fileUrl: NSURL)
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
            Logger.log("Loading \(fileUrl.lastPathComponent!)")
            let imageSource = CGImageSourceCreateWithURL(fileUrl, nil)
            let image = CGImageSourceCreateImageAtIndex(imageSource!, 0, nil)
            let nsImage = NSImage(CGImage: image!, size: NSSize(width: CGImageGetWidth(image), height: CGImageGetHeight(image)))

            Async.main
            {
                Logger.log("Setting the image...")
                self.imageViewer.image = nsImage;
                Logger.log("...Done")
            }
        }
    }

    func displayVideo(fileUrl: NSURL)
    {
        videoPlayer.player = AVPlayer(URL: fileUrl)
        if (videoPlayer.hidden)
        {
            videoPlayer.hidden = false
            imageViewer.hidden = true
            imageViewer.image = nil
        }
        videoPlayer.player?.play()
    }

    func displayUnsupportedFileType(fileUrl: NSURL, fileType: String)
    {
        videoPlayer.player?.pause()
        videoPlayer.hidden = true
        imageViewer.hidden = true

        print("Unhandled file type \(fileType) for '\(fileUrl)'")
    }

    func isSupportedFile(fullUrl:NSURL) -> Bool
    {
        var itemUti:String?
        var uti:AnyObject?
        do
        {
            try fullUrl.getResourceValue(&uti, forKey:NSURLTypeIdentifierKey)
            itemUti = uti as? String
        }
        catch
        {
        }

        return SupportedTypes.all().contains(itemUti!)
    }

    func getFileType(filename:String) -> String
    {
        do {
            return try NSWorkspace.sharedWorkspace().typeOfFile(filename)
        } catch  {
            return "";
        }
    }

    func updateStatusView()
    {
        if (currentFileIndex < 0 || currentFileIndex >= allFiles.count || allFiles.count == 0)
        {
            statusFilename.stringValue = ""
            statusTimestamp.stringValue = ""
            statusLocation.stringValue = ""
            statusKeywords.stringValue = ""
            statusIndex.stringValue = ""
        }
        else
        {
            let fileUrl = allFiles[currentFileIndex]

            statusIndex.stringValue = "\(currentFileIndex + 1) of \(allFiles.count)"
            statusFilename.stringValue = "\(fileUrl.lastPathComponent!)"
        }
    }

}