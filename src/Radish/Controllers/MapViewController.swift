//
//

import AppKit
import WebKit

import RangicCore


class MapViewController: NSWindowController
{
    @IBOutlet weak var panel: NSPanel!
    @IBOutlet weak var mapView: WebView!

    fileprivate var currentMediaData: MediaData?


    // MARK: Initialize
    func initialize()
    {
        mapView.mainFrame.load(URLRequest(url: URL(fileURLWithPath: Bundle.main.path(forResource: "map", ofType: "html")!)))

        Notifications.addObserver(self, selector: #selector(MapViewController.fileSelected(_:)), name: Notifications.Selection.MediaData, object: nil)
        Notifications.addObserver(self, selector: #selector(MapViewController.detailsUpdated(_:)), name: CoreNotifications.MediaProvider.DetailsAvailable, object: nil)
    }
    
    
    // MARK: actions
    func toggleVisibility()
    {
        if panel.isVisible {
            panel.orderOut(self)
        }
        else {
            updateView()
            panel.makeKeyAndOrderFront(self)
        }
    }
    
    
    // MARK: Notification handlers
    func fileSelected(_ notification: Notification)
    {
        if let userInfo = notification.userInfo as? Dictionary<String,MediaData> {
            if let mediaData = userInfo["MediaData"] {
                currentMediaData = mediaData
                if panel.isVisible {
                    updateView()
                }
            }
        }
    }
    
    func detailsUpdated(_ notification: Notification)
    {
        if let _ = notification.object as? MediaData {
            updateView()
        }
    }

    func updateView()
    {
        let name = currentMediaData?.name
        let location = currentMediaData?.location

        if location == nil {
            if name == nil {
                panel.title = "Map View"
            } else {
                panel.title = "Map View - No location for \(name!)"
            }
        } else {
            panel.title = "Map View - \(name!)"
            let _ = invokeMapScript("setMarker([\(location!.latitude), \(location!.longitude)])")
        }
    }

    func invokeMapScript(_ script: String) -> AnyObject?
    {
        //        Logger.info("Script: \(script)")
        return mapView.windowScriptObject.evaluateWebScript(script) as AnyObject?
    }

}
