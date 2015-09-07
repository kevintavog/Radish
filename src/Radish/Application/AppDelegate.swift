//
//  Radish
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var fileInformationController: FileInformationController!
    @IBOutlet weak var singleViewWindowController: SingleViewWindowController!
    @IBOutlet weak var thumbnailViewWindowController: ThumbnailViewWindowController!


    let mediaProvider = MediaProvider()


    // MARK: Application hooks
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        Preferences.setMissingDefaults()

        singleViewWindowController.initialize(mediaProvider)
        thumbnailViewWindowController.initialize(mediaProvider)
        fileInformationController.initialize()
    }


    // MARK: IBActions
    @IBAction func viewThumbnails(sender: AnyObject)
    {
        thumbnailViewWindowController.showWindow(sender)
    }

    @IBAction func viewImage(sender: AnyObject)
    {
        singleViewWindowController.showWindow(sender)
    }

    @IBAction func toggleFileInformation(sender: AnyObject)
    {
        fileInformationController.toggleVisibility()
    }
}
