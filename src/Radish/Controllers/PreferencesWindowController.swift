//
//  Radish
//

import AppKit
import RangicCore
import Async

class PreferencesWindowController : NSWindowController
{
    @IBOutlet weak var openStreetMapHost: NSTextField!
    @IBOutlet weak var movieVolume: NSSlider!
    @IBOutlet weak var movieVolumeLabel: NSTextField!

    @IBOutlet weak var testOsmWorkingIndicator: NSProgressIndicator!
    @IBOutlet weak var testOsmResultImage: NSImageView!
    @IBOutlet weak var testOsmErrorMessage: NSTextField!

    @IBOutlet weak var showOnMapMatrix: NSMatrix!

    @IBOutlet weak var placenameLevelMatrix: NSMatrix!


    override func awakeFromNib()
    {
        movieVolume!.floatValue = Preferences.videoPlayerVolume
        movieVolumeLabel!.floatValue = movieVolume!.floatValue

        openStreetMapHost.stringValue = Preferences.baseLocationLookup

        testOsmWorkingIndicator!.isHidden = true
        testOsmErrorMessage.stringValue = ""

        showOnMapMatrix.selectCell(atRow: Preferences.showOnMap.rawValue - 1, column: 0)
        placenameLevelMatrix.selectCell(atRow: Preferences.placenameLevel.rawValue - 1, column: 0)
    }

    @objc
    func windowWillClose(_ notification: Notification)
    {
        updateBaseLocationLookup()
        Preferences.showOnMap = Preferences.ShowOnMap(rawValue: showOnMapMatrix.selectedRow + 1)!
        Preferences.placenameLevel = Preferences.PlacenameLevel(rawValue: placenameLevelMatrix.selectedRow + 1)!

        NSApplication.shared.stopModal()
    }
    
    @IBAction func testOpenStreetMapHost(_ sender: AnyObject)
    {
        updateBaseLocationLookup()
        testOsmWorkingIndicator.startAnimation(sender)
        testOsmWorkingIndicator.isHidden = false
        testOsmResultImage.image = nil
        testOsmErrorMessage.stringValue = ""

        Logger.info("Test host: \(Preferences.baseLocationLookup)")

        Async.background {
            ReverseNameLookupProvider.set(host: Preferences.baseLocationLookup)
            let response = ReverseNameLookupProvider().lookup(latitude: 51.484509, longitude: 0.002570)

            Async.main {
                self.testOsmWorkingIndicator.isHidden = true
                self.testOsmWorkingIndicator.stopAnimation(sender)

                let succeeded = response.description.count > 0
                let imageName = succeeded ? "SucceededCheck" : "FailedCheck"
                self.testOsmResultImage.image = NSImage(named: imageName)

                if !succeeded {
                    Logger.info("Response: \(response)")
                    let code = "You need to give back an error code..." // response["apiStatusCode"]
                    let message = "You gotta provide a message" // response["apiMessage"]
                    var error = ""
                    error = "code: \(code); "
                    error += "\(message)"
                    self.testOsmErrorMessage.stringValue = error
                }
            }
        }
    }

    @IBAction func movieVolumeUpdated(_ sender: AnyObject)
    {
        movieVolumeLabel!.floatValue = movieVolume!.floatValue
        Preferences.videoPlayerVolume = movieVolume!.floatValue
    }

    func updateBaseLocationLookup()
    {
        Preferences.baseLocationLookup = openStreetMapHost!.stringValue
        ReverseNameLookupProvider.set(host: Preferences.baseLocationLookup)
        Logger.info("Placename lookups are now via \(Preferences.baseLocationLookup)")
    }
}
