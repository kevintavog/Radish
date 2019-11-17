//
//  Radish
//

import AppKit

import RangicCore
import Async


class FileInformationController : NSViewController
{
    enum TabIdentifier: Int {
        case none = 0,
            exif = 1,
            iptc = 2,
            xmp = 3,
            composite = 4,
            placename = 5,
            wikipedia = 6
    }
    static let numTabs = 6
    
    @IBOutlet weak var exifTableView: NSTableView!
    @IBOutlet weak var iptcTableView: NSTableView!
    @IBOutlet weak var xmpTableView: NSTableView!
    @IBOutlet weak var compositeTableView: NSTableView!
    @IBOutlet weak var placenameTableView: NSTableView!
    @IBOutlet weak var wikipediaTableView: NSTableView!
    @IBOutlet weak var tabsView: NSTabView!
    @IBOutlet weak var panel: NSPanel!

    // EXIF, IPTC, XMP, Composite, Placename
    fileprivate var currentMediaData: MediaData?
    fileprivate var tabStart = [Int](repeating: -1, count: FileInformationController.numTabs + 1)
    fileprivate var tabCount = [Int](repeating: -1, count: FileInformationController.numTabs + 1)

    fileprivate var showPlacenameDetails = false
    fileprivate var placenameDetails = [PlacenameDetail]()

    fileprivate var lastWikipediaLocation = ""
    fileprivate var showWikipediaOnMap = false
    fileprivate var wikipediaDetails = [WikipediaDetail]()


    // MARK: Initialize
    func initialize()
    {
        exifTableView.backgroundColor = NSColor.clear
        iptcTableView.backgroundColor = NSColor.clear
        xmpTableView.backgroundColor = NSColor.clear
        compositeTableView.backgroundColor = NSColor.clear
        placenameTableView.backgroundColor = NSColor.clear
        wikipediaTableView.backgroundColor = NSColor.clear

        Notifications.addObserver(self, selector: #selector(FileInformationController.fileSelected(_:)), name: Notifications.Selection.MediaData, object: nil)
        Notifications.addObserver(self, selector: #selector(FileInformationController.detailsUpdated(_:)), name: MediaProvider.Notifications.DetailsAvailable, object: nil)
        Notifications.addObserver(self, selector: #selector(FileInformationController.showPlacenameDetailsNotification(_:)), name: Notifications.SingleView.ShowPlacenameDetails, object: nil)
        Notifications.addObserver(self, selector: #selector(FileInformationController.showWikipediaOnMapNotification(_:)), name: Notifications.SingleView.ShowWikipediaOnMap, object: nil)

        wikipediaTableView.target = self
        wikipediaTableView.doubleAction = #selector(FileInformationController.doubleClickWikipedia(_ :))
    }

    @objc
    func doubleClickWikipedia(_ sender: Any) {
        let row = wikipediaTableView.selectedRow
        if row >= 0 && row < wikipediaDetails.count {
            NSWorkspace.shared.open(URL(string: "https://en.wikipedia.org/?curid=\(wikipediaDetails[row].pageId)")!)
        }
    }
    
    // MARK: actions
    func toggleVisibility()
    {
        if panel.isVisible {
            panel.orderOut(self)
        }
        else {
            panel.makeKeyAndOrderFront(self)
            updateView()
        }
    }


    // MARK: Notification handlers
    @objc func fileSelected(_ notification: Notification)
    {
        Async.main {
            if let userInfo = notification.userInfo as? Dictionary<String,MediaData> {
                if let mediaData = userInfo["MediaData"] {
                    self.currentMediaData = mediaData
                    self.updateView()
                }
            }
        }
    }

    @objc func detailsUpdated(_ notification: Notification)
    {
        Async.main {
            if let _ = notification.object as? MediaData {
                self.updateView()
            }
        }
    }
    
    @objc func showPlacenameDetailsNotification(_ notification: Notification)
    {
        if let userInfo = notification.userInfo as? Dictionary<String,Bool> {
            if let val = userInfo["ShowPlacenameDetails"] {
                self.showPlacenameDetails = val
                Async.main {
                    self.updateView()
                }
            }
        }
    }

    @objc func showWikipediaOnMapNotification(_ notification: Notification)
    {
        if let userInfo = notification.userInfo as? Dictionary<String,Bool> {
            if let val = userInfo["ShowWikipediaOnMap"] {
                self.showWikipediaOnMap = val
                Async.main {
                    if self.showWikipediaOnMap {
                        Notifications.postNotification(Notifications.FileInformationController.SetWikipediaDetails, object: self, userInfo: ["details": self.wikipediaDetails])
                    } else {
                        Notifications.postNotification(Notifications.FileInformationController.ClearedWikipediaDetails, object: self, userInfo: nil)
                    }
                }
            }
        }
    }

    func updateView()
    {
        self.updateWikipedia()
        
        if self.panel.isVisible {
            if let name = currentMediaData?.name {
                panel.title = "Information - \(name)"
            }
            else {
                panel.title = "Information"
            }

            for index in 0 ..< self.tabStart.count {
                self.tabStart[index] = -1
                self.tabCount[index] = 0
            }
            placenameDetails = []

            var safeToIgnore = false
            var tabId = TabIdentifier.none
            if currentMediaData != nil {
                for (index, md) in currentMediaData!.details.enumerated() {
                    if md.category != nil {
                        switch md.category! {
                        case "EXIF": tabId = TabIdentifier.exif
                        case "IPTC": tabId = TabIdentifier.iptc
                        case "XMP": tabId = TabIdentifier.xmp
                        case "Properties": tabId = TabIdentifier.composite
                        case "Composite": tabId = TabIdentifier.composite
                        case "Placename": tabId = TabIdentifier.placename
                        case "JFIF": tabId = TabIdentifier.none; safeToIgnore = true
                        case "ICC_Profile": tabId = TabIdentifier.none; safeToIgnore = true
                        case "QuickTime": tabId = TabIdentifier.none; safeToIgnore = true
                        case "MakerNotes": tabId = TabIdentifier.none; safeToIgnore = true
                        case "Photoshop": tabId = TabIdentifier.none; safeToIgnore = true
                        default: Logger.error("Unrecognized category: \(md.category!)")
                            tabId = TabIdentifier.none
                        }
                        if tabId != TabIdentifier.none {
                            self.tabStart[tabId.rawValue] = index + 1
                        }
                    } else {
                        if tabId == TabIdentifier.none {
                            if !safeToIgnore {
                                Logger.error("Ignoring property \(md.name!)=\(md.value!) ")
                            }
                        } else {
                            self.tabCount[tabId.rawValue] += 1
                        }
                    }
                }
            }
            self.exifTableView.reloadData()
            self.iptcTableView.reloadData()
            self.xmpTableView.reloadData()
            self.compositeTableView.reloadData()
            self.placenameTableView.reloadData()
            
            if self.tabCount[TabIdentifier.placename.rawValue] > 0 && self.showPlacenameDetails {
                Async.background {
                    self.placenameDetails.append(
                        contentsOf: PlacenameDetailsProvider().lookup(
                            latitude: self.currentMediaData!.location!.latitude,
                            longitude: self.currentMediaData!.location!.longitude))
                    
                    if self.placenameDetails.count > 0 {
                        Async.main {
                            self.placenameTableView.reloadData()
                        }
                    }
                }
            }
        }
    }

    func updateWikipedia() {
        var loadWikipedia = false
        var locationString = ""
        if let md = currentMediaData, let loc = md.location {
            locationString = "\(loc.latitude),\(loc.longitude)"
        }

        if self.lastWikipediaLocation != locationString {
            self.lastWikipediaLocation = locationString
            loadWikipedia = true
            wikipediaDetails = []
            self.wikipediaTableView.reloadData()
            if self.showWikipediaOnMap {
                Notifications.postNotification(Notifications.FileInformationController.ClearedWikipediaDetails, object: self, userInfo: nil)
            }
        }
        
        if loadWikipedia && self.currentMediaData != nil && self.currentMediaData?.location != nil  {
            Async.background {
                self.wikipediaDetails.append(contentsOf: WikipediaProvider().lookup(
                    latitude: self.currentMediaData!.location!.latitude,
                    longitude: self.currentMediaData!.location!.longitude))
                Async.main {
                    self.wikipediaTableView.reloadData()
                    if self.showWikipediaOnMap {
                        Notifications.postNotification(Notifications.FileInformationController.SetWikipediaDetails, object: self, userInfo: ["details": self.wikipediaDetails])
                    }
                }
            }
        }
    }
    
    // MARK: tab view
    @objc
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?)
    {
        Logger.info("tabView changed to \(String(describing: tabViewItem?.label)) - \(String(describing: tabViewItem?.identifier))")
    }

    // MARK: (various) table view data
    @objc
    func numberOfRowsInTableView(_ tv: NSTableView) -> Int
    {
        if currentMediaData != nil {
            let tabId = Int(self.tabsView.selectedTabViewItem?.identifier as? String ?? "") ?? 0
            if tabId < 1 || tabId > FileInformationController.numTabs {
                Logger.error("Unexpected tabId: \(tabId)")
                return 0
            }

            if tabId == TabIdentifier.placename.rawValue {
                return self.tabCount[tabId] + self.placenameDetails.count
            }

            if tabId == TabIdentifier.wikipedia.rawValue {
                return self.wikipediaDetails.count
            }
            
            return self.tabCount[tabId]
        }
        return 0
    }

    @objc
    func tableView(_ tv: NSTableView, objectValueForTableColumn: NSTableColumn?, row: Int) -> String
    {
        let tabId = Int(self.tabsView.selectedTabViewItem?.identifier as? String ?? "") ?? 0
        if tabId < 1 || tabId > FileInformationController.numTabs {
            Logger.error("Unexpected tabId: \(tabId)")
            return ""
        }
        
        if tabId == TabIdentifier.placename.rawValue && row >= tabCount[tabId] {
            let detailIndex = row - tabCount[tabId]
            switch (objectValueForTableColumn!.dataCell as AnyObject).tag {
            case 1:
                return placenameDetails[detailIndex].name
            case 2:
                return placenameDetails[detailIndex].value
            default:
                Logger.error("Unhandled information column tag: \(String(describing: (objectValueForTableColumn!.dataCell as AnyObject).tag))")
                return ""
            }
        }
        
        if tabId == TabIdentifier.wikipedia.rawValue {
            switch (objectValueForTableColumn!.dataCell as AnyObject).tag {
            case 1:
                return "\(wikipediaDetails[row].id) - \(wikipediaDetails[row].title)"
            case 2:
                return String(wikipediaDetails[row].distance)
            case 3:
                return wikipediaDetails[row].type
            default:
                Logger.error("Unhandled information column tag: \(String(describing: (objectValueForTableColumn!.dataCell as AnyObject).tag))")
                return ""
            }
        }

        if let mediaDetails = currentMediaData?.details {
            if (self.tabStart[tabId] + row) < mediaDetails.count {
                let detail = mediaDetails[self.tabStart[tabId] + row]
                switch (objectValueForTableColumn!.dataCell as AnyObject).tag {
                case 1:
                    return detail.name == nil ? "" : (detail.name)!
                case 2:
                    return detail.value == nil ? "" : (detail.value)!
                default:
                    Logger.error("Unhandled information column tag: \(String(describing: (objectValueForTableColumn!.dataCell as AnyObject).tag))")
                    return ""
                }
            }
        }
        return ""
    }

    @objc
    func tableView(_ tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int)
    {
        let textCell = cell as? NSTextFieldCell
        if textCell != nil {
            textCell!.textColor = NSColor.white
            textCell!.drawsBackground = false

            // Force a redraw, otherwise the color for column 1 doesn't update properly
            textCell!.stringValue = textCell!.stringValue
        }
    }
}
