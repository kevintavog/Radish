//
//  Radish
//

import AppKit

import RangicCore



// Menu handlers for SingleViewWindowController
extension SingleViewWindowController
{
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool
    {
        switch MenuItemTag(rawValue: menuItem.tag)! {
        case .AlwaysEnable:
            return true
        case .RequiresFile:
            return mediaProvider?.mediaFiles.count > 0
        }
    }

    func tryToMoveTo(calculate: (index: Int, maxIndex: Int) -> Int)
    {
        if let provider = mediaProvider {
            let count = provider.mediaFiles.count
            if  count > 0 {
                displayFileByIndex(calculate(index: currentFileIndex, maxIndex: count - 1))
            }
        }
    }

    override func pageUp(sender: AnyObject?)
    {
        tryToMoveTo({ index, maxIndex in max(0, index - Preferences.pageSize) })
    }

    override func pageDown(sender: AnyObject?)
    {
        tryToMoveTo({ index, maxIndex in min(maxIndex, index + Preferences.pageSize) })
    }

    func moveToFirstItem(sender: AnyObject?)
    {
        tryToMoveTo({ index, maxIndex in 0 })
    }

    func moveToLastItem(sender: AnyObject?)
    {
        tryToMoveTo({ index, maxIndex in maxIndex })
    }
    
    func moveToPercent(percent: Int)
    {
        tryToMoveTo({ index, maxIndex in (maxIndex * percent) / 100 })
    }

    func moveToTenPercent(sender: AnyObject?)
    {
        moveToPercent(10)
    }

    func moveToTwentyPercent(sender: AnyObject?)
    {
        moveToPercent(20)
    }

    func moveToThirtyPercent(sender: AnyObject?)
    {
        moveToPercent(30)
    }

    func moveToFortyPercent(sender: AnyObject?)
    {
        moveToPercent(40)
    }

    func moveToFiftyPercent(sender: AnyObject?)
    {
        moveToPercent(50)
    }

    func moveToSixtyPercent(sender: AnyObject?)
    {
        moveToPercent(60)
    }

    func moveToSeventyPercent(sender: AnyObject?)
    {
        moveToPercent(70)
    }

    func moveToEightyPercent(sender: AnyObject?)
    {
        moveToPercent(80)
    }

    func moveToNinetyPercent(sender: AnyObject?)
    {
        moveToPercent(90)
    }

    override func keyDown(theEvent: NSEvent)
    {
        if let chars = theEvent.charactersIgnoringModifiers {
            let modFlags = NSEventModifierFlags(rawValue: theEvent.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue)
            let keySequence = KeySequence(modifierFlags: modFlags, chars: chars)
            if let selector = keyMappings[keySequence] {
                self.performSelectorOnMainThread(selector, withObject: theEvent.window, waitUntilDone: true)
                return
            } else {
//                Logger.debug("Unable to find match for \(keySequence)")
            }
        }

        super.keyDown(theEvent)
    }

    @IBAction func openFolder(sender: AnyObject)
    {
        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        currentMediaData = nil
        currentFileIndex = 0;
        mediaProvider!.clear()

        addFolders(folders.urls, selected: folders.selected)
    }

    @IBAction func addFolder(sender: AnyObject)
    {
        if mediaProvider?.mediaFiles.count < 1 {
            openFolder(sender)
            return
        }

        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        addFolders(folders.urls, selected: currentMediaData!.url)
        updateStatusView()
    }

    @IBAction func refreshFiles(sender: AnyObject)
    {
        mediaProvider!.refresh()
    }

    @IBAction func nextFile(sender: AnyObject)
    {
        displayFileByIndex(currentFileIndex + 1)
    }

    @IBAction func previousFile(sender: AnyObject)
    {
        displayFileByIndex(currentFileIndex - 1)
    }

    @IBAction func firstFile(sender: AnyObject)
    {
        displayFileByIndex(0)
    }

    @IBAction func lastFile(sender: AnyObject)
    {
        displayFileByIndex(mediaProvider!.mediaFiles.count - 1)
    }
    
    @IBAction func revealInFinder(sender: AnyObject)
    {
        NSWorkspace.sharedWorkspace().selectFile(currentMediaData!.url!.path!, inFileViewerRootedAtPath: "")
    }

    @IBAction func setFileDateFromExifDate(sender: AnyObject)
    {
        let filename = currentMediaData!.url.path!
        Logger.info("setFileDateFromExifDate: \(filename)")

        let result = mediaProvider?.setFileDatesToExifDates([currentMediaData!])
        if !result!.allSucceeded {
            let alert = NSAlert()
            alert.messageText = "Set file date of '\(filename)' failed: \(result!.errorMessage)."
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.addButtonWithTitle("Close")
            alert.runModal()
        }
    }

    @IBAction func autoRotate(sender: AnyObject)
    {
        let filename = currentMediaData!.url.path!
        Logger.info("autoRotate: \(filename)")

        let jheadInvoker = JheadInvoker.autoRotate([filename])
        if jheadInvoker.processInvoker.exitCode != 0 {
            let alert = NSAlert()
            alert.messageText = "Auto rotate of '\(filename)' failed: \(jheadInvoker.processInvoker.error)."
            alert.alertStyle = NSAlertStyle.WarningAlertStyle
            alert.addButtonWithTitle("Close")
            alert.runModal()
        }
    }

    @IBAction func moveToTrash(sender: AnyObject)
    {
        let url = currentMediaData!.url
        Logger.info("moveToTrash: \((url?.path!)!)")

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

    @IBAction func showOnMap(sender: AnyObject)
    {
        Logger.info("showOnMap '\((currentMediaData?.locationString())!)'")
        if let location = currentMediaData?.location {

            var url = ""
            switch Preferences.showOnMap {
            case .Bing:
                url = "http://www.bing.com/maps/default.aspx?cp=\(location.latitude)~\(location.longitude)&lvl=17&rtp=pos.\(location.latitude)_\(location.longitude)"
            case .Google:
                url = "http://maps.google.com/maps?q=\(location.latitude),\(location.longitude)"

            case .OpenStreetMap:
                url = "http://www.openstreetmap.org/?&mlat=\(location.latitude)&mlon=\(location.longitude)#map=18/\(location.latitude)/\(location.longitude)"
            }

            if url.characters.count > 0 {
                NSWorkspace.sharedWorkspace().openURL(NSURL(string: url)!)
            }
            
        }
    }
    
}