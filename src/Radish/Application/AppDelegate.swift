//
//  Radish
//

import Cocoa
import RangicCore
import CocoaLumberjackSwift

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
        #if DEBUG
            defaultDebugLevel = DDLogLevel.Verbose
            #else
            defaultDebugLevel = DDLogLevel.Info
        #endif
        Logger.configure()

        Preferences.setMissingDefaults()

        OpenMapLookupProvider.BaseLocationLookup = Preferences.baseLocationLookup
        Logger.info("Placename lookups via \(OpenMapLookupProvider.BaseLocationLookup)")

        singleViewWindowController.initialize(mediaProvider)
        thumbnailViewWindowController.initialize(mediaProvider)
        fileInformationController.initialize()
        hasInitialized = true

        if filename != nil {
            Logger.info("openFile post init: \(filename)")
            singleViewWindowController.openFolderOrFile(filename!)
        }
    }

    func application(sender: NSApplication, openFile: String) -> Bool
    {
        if !hasInitialized {
            self.filename = openFile
            return true
        }

        Logger.info("openFile: \(openFile)")
        return singleViewWindowController.openFolderOrFile(openFile)
    }

    func application(application: NSApplication, willPresentError error: NSError) -> NSError
    {
        Logger.error("willPresentError: \(error)")
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
