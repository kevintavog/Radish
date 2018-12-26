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
            placename = 5
    }
    static let numTabs = 5
    
    @IBOutlet weak var exifTableView: NSTableView!
    @IBOutlet weak var iptcTableView: NSTableView!
    @IBOutlet weak var xmpTableView: NSTableView!
    @IBOutlet weak var compositeTableView: NSTableView!
    @IBOutlet weak var placenameTableView: NSTableView!
    @IBOutlet weak var tabsView: NSTabView!
    @IBOutlet weak var panel: NSPanel!

    // EXIF, Placename, Properties, Composite, XMP, IPTC
    fileprivate var currentMediaData: MediaData?
    fileprivate var tabStart = [Int](repeating: -1, count: FileInformationController.numTabs + 1)
    fileprivate var tabCount = [Int](repeating: -1, count: FileInformationController.numTabs + 1)


    // MARK: Initialize
    func initialize()
    {
        exifTableView.backgroundColor = NSColor.clear
        iptcTableView.backgroundColor = NSColor.clear
        xmpTableView.backgroundColor = NSColor.clear
        compositeTableView.backgroundColor = NSColor.clear
        placenameTableView.backgroundColor = NSColor.clear

        Notifications.addObserver(self, selector: #selector(FileInformationController.fileSelected(_:)), name: Notifications.Selection.MediaData, object: nil)
        Notifications.addObserver(self, selector: #selector(FileInformationController.detailsUpdated(_:)), name: MediaProvider.Notifications.DetailsAvailable, object: nil)
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

    func updateView()
    {
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

        let detail = currentMediaData?.details[self.tabStart[tabId] + row]
        switch (objectValueForTableColumn!.dataCell as AnyObject).tag {
        case 1:
            return detail?.name == nil ? "" : (detail?.name)!
        case 2:
            return detail?.value == nil ? "" : (detail?.value)!
        default:
            Logger.error("Unhandled information column tag: \(String(describing: (objectValueForTableColumn!.dataCell as AnyObject).tag))")
            return ""
        }
    }

    @objc
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool
    {
        return currentMediaData?.details[row].category != nil
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
