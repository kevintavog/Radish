//
//  Radish
//

import AppKit

import RangicCore



// Menu handlers for SingleViewWindowController
extension SingleViewWindowController
{
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        switch MenuItemTag(rawValue: menuItem.tag)! {
        case .alwaysEnable:
            return true
        case .requiresFile:
            return (mediaProvider?.mediaCount)! > 0
        }
    }

    func tryToMoveTo(_ calculate: (_ index: Int, _ maxIndex: Int) -> Int)
    {
        if let provider = mediaProvider {
            let count = provider.mediaCount
            if  count > 0 {
                displayFileByIndex(calculate(currentFileIndex, count - 1))
            }
        }
    }

    override func pageUp(_ sender: Any?)
    {
        tryToMoveTo({ index, maxIndex in max(0, index - Preferences.pageSize) })
    }

    override func pageDown(_ sender: Any?)
    {
        tryToMoveTo({ index, maxIndex in min(maxIndex, index + Preferences.pageSize) })
    }

    func moveToFirstItem(_ sender: AnyObject?)
    {
        tryToMoveTo({ index, maxIndex in 0 })
    }

    func moveToLastItem(_ sender: AnyObject?)
    {
        tryToMoveTo({ index, maxIndex in maxIndex })
    }
    
    func moveToPercent(_ percent: Int)
    {
        tryToMoveTo({ index, maxIndex in (maxIndex * percent) / 100 })
    }

    func moveToTenPercent(_ sender: AnyObject?)
    {
        moveToPercent(10)
    }

    func moveToTwentyPercent(_ sender: AnyObject?)
    {
        moveToPercent(20)
    }

    func moveToThirtyPercent(_ sender: AnyObject?)
    {
        moveToPercent(30)
    }

    func moveToFortyPercent(_ sender: AnyObject?)
    {
        moveToPercent(40)
    }

    func moveToFiftyPercent(_ sender: AnyObject?)
    {
        moveToPercent(50)
    }

    func moveToSixtyPercent(_ sender: AnyObject?)
    {
        moveToPercent(60)
    }

    func moveToSeventyPercent(_ sender: AnyObject?)
    {
        moveToPercent(70)
    }

    func moveToEightyPercent(_ sender: AnyObject?)
    {
        moveToPercent(80)
    }

    func moveToNinetyPercent(_ sender: AnyObject?)
    {
        moveToPercent(90)
    }

    override func keyDown(with theEvent: NSEvent)
    {
        if let chars = theEvent.charactersIgnoringModifiers {
            let modFlags = NSEventModifierFlags(rawValue: theEvent.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue)
            let keySequence = KeySequence(modifierFlags: modFlags, chars: chars)
            if let selector = keyMappings[keySequence] {
                self.performSelector(onMainThread: selector, with: theEvent.window, waitUntilDone: true)
                return
            } else {
//                Logger.debug("Unable to find match for \(keySequence)")
            }
        }

        super.keyDown(with: theEvent)
    }

    @IBAction func openFolder(_ sender: AnyObject)
    {
        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        currentMediaData = nil
        currentFileIndex = 0;
        mediaProvider!.clear()

        addFolders(folders.urls!, selected: folders.selected)
    }

    @IBAction func addFolder(_ sender: AnyObject)
    {
        if (mediaProvider?.mediaCount)! < 1 {
            openFolder(sender)
            return
        }

        let folders = selectFoldersToAdd()
        if (folders.urls == nil) { return }

        addFolders(folders.urls!, selected: currentMediaData!.url)
        updateStatusView()
    }

    @IBAction func refreshFiles(_ sender: AnyObject)
    {
        mediaProvider!.refresh()
    }

    @IBAction func nextFile(_ sender: AnyObject)
    {
        displayFileByIndex(currentFileIndex + 1)
    }

    @IBAction func previousFile(_ sender: AnyObject)
    {
        displayFileByIndex(currentFileIndex - 1)
    }

    @IBAction func firstFile(_ sender: AnyObject)
    {
        displayFileByIndex(0)
    }

    @IBAction func lastFile(_ sender: AnyObject)
    {
        displayFileByIndex(mediaProvider!.mediaCount - 1)
    }
    
    @IBAction func revealInFinder(_ sender: AnyObject)
    {
        NSWorkspace.shared().selectFile(currentMediaData!.url!.path, inFileViewerRootedAtPath: "")
    }

    @IBAction func setFileDateFromExifDate(_ sender: AnyObject)
    {
        let filename = currentMediaData!.url.path
        Logger.info("setFileDateFromExifDate: \(filename)")

        let result = mediaProvider?.setFileDatesToExifDates([currentMediaData!])
        if !result!.allSucceeded {
            let alert = NSAlert()
            alert.messageText = "Set file date of '\(filename)' failed: \(result!.errorMessage)."
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "Close")
            alert.runModal()
        }
    }

    @IBAction func autoRotate(_ sender: AnyObject)
    {
        let filename = currentMediaData!.url.path
        Logger.info("autoRotate: \(filename)")

        let jheadInvoker = JheadInvoker.autoRotate([filename])
        if jheadInvoker.processInvoker.exitCode != 0 {
            let alert = NSAlert()
            alert.messageText = "Auto rotate of '\(filename)' failed: \(jheadInvoker.processInvoker.error)."
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "Close")
            alert.runModal()
        }
    }

    @IBAction func moveToTrash(_ sender: AnyObject)
    {
        let url = currentMediaData!.url
        Logger.info("moveToTrash: \((url?.path)!)")

        let filename = (url?.lastPathComponent)!
        NSWorkspace.shared().recycle([url!]) { newUrls, error in
            if error != nil {
                let alert = NSAlert()
                alert.messageText = "Failed moving '\(filename)' to trash."
                alert.alertStyle = NSAlertStyle.warning
                alert.addButton(withTitle: "Close")
                alert.runModal()
            }
            else {
                NSSound(contentsOfFile: self.trashSoundPath, byReference: false)?.play()
            }
        }
    }

    @IBAction func showOnMap(_ sender: AnyObject)
    {
        Logger.info("showOnMap '\((currentMediaData?.locationString())!)'")
        if let location = currentMediaData?.location {

            var url = ""
            switch Preferences.showOnMap {
            case .bing:
                url = "http://www.bing.com/maps/default.aspx?cp=\(location.latitude)~\(location.longitude)&lvl=17&rtp=pos.\(location.latitude)_\(location.longitude)"
            case .google:
                url = "http://maps.google.com/maps?q=\(location.latitude),\(location.longitude)"

            case .openStreetMap:
                url = "http://www.openstreetmap.org/?&mlat=\(location.latitude)&mlon=\(location.longitude)#map=18/\(location.latitude)/\(location.longitude)"
            }

            if url.characters.count > 0 {
                NSWorkspace.shared().open(URL(string: url)!)
            }
            
        }
    }
    
}
