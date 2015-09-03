//
//  Radish
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    @IBOutlet weak var window: NSWindow!
    @IBAction func openFolder(sender: AnyObject) {
    }
    @IBOutlet weak var singleViewWindowController: SingleViewWindowController!
    @IBOutlet weak var thumbnailViewWindowController: ThumbnailViewWindowController!


    let mediaProvider = MediaProvider()


    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        singleViewWindowController.initialize(mediaProvider)
        thumbnailViewWindowController.initialize(mediaProvider)
    }

    @IBAction func viewThumbnails(sender: AnyObject)
    {
        thumbnailViewWindowController.showWindow(sender)
    }

    @IBAction func viewImage(sender: AnyObject)
    {
        singleViewWindowController.showWindow(sender)
    }
}
