//
//  Radish
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var singleViewWindowController: SingleViewWindowController!

    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        singleViewWindowController.initialize()
    }
}
