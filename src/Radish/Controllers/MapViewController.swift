//
//

import AppKit
import WebKit

import Async
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
        Notifications.addObserver(self, selector: #selector(MapViewController.detailsUpdated(_:)), name: MediaProvider.Notifications.DetailsAvailable, object: nil)
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
    @objc func fileSelected(_ notification: Notification)
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
    
    @objc func detailsUpdated(_ notification: Notification)
    {
        if panel.isVisible {
            if let _ = notification.object as? MediaData {
                updateView()
            }
        }
    }

    func updateView()
    {
        Async.main {
            let name = self.currentMediaData?.name
            let location = self.currentMediaData?.location
            
            if location == nil {
                let _ = self.invokeMapScript("clearMarker()")
                if name == nil {
                    self.panel.title = "Map View"
                } else {
                    self.panel.title = "Map View - No location for \(name!)"
                }
            } else {
                self.panel.title = "Map View - \(name!)"
                let _ = self.invokeMapScript("setMarker([\(location!.latitude), \(location!.longitude)])")
            }
        }
    }

    func invokeMapScript(_ script: String) -> AnyObject?
    {
        //        Logger.info("Script: \(script)")
        return mapView.windowScriptObject.evaluateWebScript(script) as AnyObject?
    }

}
