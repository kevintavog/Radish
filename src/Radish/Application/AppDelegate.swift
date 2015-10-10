//
//  Radish
//

import Cocoa
import RangicCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var fileInformationController: FileInformationController!
    @IBOutlet weak var singleViewWindowController: SingleViewWindowController!
    @IBOutlet weak var thumbnailViewWindowController: ThumbnailViewWindowController!


    let mediaProvider = MediaProvider()
    private var hasInitialized = false
    private var filename:String?


    // MARK: Application hooks
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        Preferences.setMissingDefaults()

        OpenMapLookupProvider.BaseLocationLookup = Preferences.baseLocationLookup
        Logger.log("Placename lookups via \(OpenMapLookupProvider.BaseLocationLookup)")

        singleViewWindowController.initialize(mediaProvider)
        thumbnailViewWindowController.initialize(mediaProvider)
        fileInformationController.initialize()
        hasInitialized = true

        if filename != nil {
            singleViewWindowController.openFolderOrFile(filename!)
        }
    }

    func application(sender: NSApplication, openFile filename: String) -> Bool
    {
        if !hasInitialized {
            self.filename = filename
            return true
        }

        return singleViewWindowController.openFolderOrFile(filename)
    }

    func application(application: NSApplication, willPresentError error: NSError) -> NSError
    {
        Logger.log("WillPresentError: \(error)")
        return error
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

    @IBAction func preferences(sender: AnyObject)
    {
        let preferencesController = PreferencesWindowController(windowNibName: "Preferences")
        NSApplication.sharedApplication().runModalForWindow(preferencesController.window!)
    }
}
