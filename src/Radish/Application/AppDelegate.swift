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
    @IBOutlet weak var mapController: MapViewController!
    @IBOutlet weak var singleViewWindowController: SingleViewWindowController!
    @IBOutlet weak var thumbnailViewWindowController: ThumbnailViewWindowController!


    let mediaProvider = MediaProvider()
    fileprivate var hasInitialized = false
    fileprivate var filename:String?


    // MARK: Application hooks
    func applicationDidFinishLaunching(_ aNotification: Notification)
    {
        #if DEBUG
            defaultDebugLevel = DDLogLevel.verbose
            #else
            defaultDebugLevel = DDLogLevel.info
        #endif
        Logger.configure()

        Preferences.setMissingDefaults()

        OpenMapLookupProvider.BaseLocationLookup = Preferences.baseLocationLookup
        Logger.info("Placename lookups via \(OpenMapLookupProvider.BaseLocationLookup)")

        singleViewWindowController.initialize(mediaProvider)
        thumbnailViewWindowController.initialize(mediaProvider)
        fileInformationController.initialize()
        mapController.initialize()
        hasInitialized = true

        if filename != nil {
            Logger.info("openFile post init: \(filename!)")
            singleViewWindowController.window?.makeKeyAndOrderFront(self)
            let _ = singleViewWindowController.openFolderOrFile(filename!)
        }
    }

    func application(_ sender: NSApplication, openFile: String) -> Bool
    {
        if !hasInitialized {
            self.filename = openFile
            return true
        }

        Logger.info("openFile: \(openFile)")
        return singleViewWindowController.openFolderOrFile(openFile)
    }

    func application(_ application: NSApplication, willPresentError error: Error) -> Error
    {
        Logger.error("willPresentError: \(error)")
        return error
    }

    // MARK: IBActions
    @IBAction func viewThumbnails(_ sender: AnyObject)
    {
        thumbnailViewWindowController.showWindow(sender)
    }

    @IBAction func viewImage(_ sender: AnyObject)
    {
        singleViewWindowController.showWindow(sender)
    }

    @IBAction func toggleFileInformation(_ sender: AnyObject)
    {
        fileInformationController.toggleVisibility()
    }

    @IBAction func toggleMap(_ sender: AnyObject)
    {
        mapController.toggleVisibility()
    }
    
    @IBAction func preferences(_ sender: AnyObject)
    {
        let preferencesController = PreferencesWindowController(windowNibName: "Preferences")
        NSApplication.shared().runModal(for: preferencesController.window!)
    }

    @IBAction func search(_ sender: AnyObject)
    {
        let searchController = SearchWindowController(windowNibName: "Search")
        NSApplication.shared().runModal(for: searchController.window!)

        if searchController.viewSearchResults {
            singleViewWindowController.showSearchResults(searchController.searchText.stringValue)
        }
    }
}
