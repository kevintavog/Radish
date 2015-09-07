//
//  Radish
//

import AppKit

class FileInformationController : NSViewController
{
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var panel: NSPanel!

    private var currentMediaData: MediaData?


    // MARK: Initialize
    func initialize()
    {
        tableView.backgroundColor = NSColor.clearColor()
        Notifications.addObserver(self, selector: "fileSelected:", name: Notifications.Selection.MediaData, object: nil)
    }


    // MARK: actions
    func toggleVisibility()
    {
        if panel.visible {
            panel.orderOut(self)
        }
        else {
            reloadAndSizeColumns()
            panel.makeKeyAndOrderFront(self)
        }
    }


    // MARK: Notification handlers
    func fileSelected(notification: NSNotification)
    {
        if let userInfo = notification.userInfo as? Dictionary<String,MediaData> {
            if let mediaData = userInfo["MediaData"] {
                currentMediaData = mediaData
                if panel.visible {
                    reloadAndSizeColumns()
                }
            }
        }
    }


    func reloadAndSizeColumns()
    {
        panel.title = "File Information - \(currentMediaData!.name!)"
        tableView.reloadData()

        for column in tableView.tableColumns {
            var biggestWidth: CGFloat = 0.0
            for row in 0..<tableView.numberOfRows {
                let cellWidth = column.dataCellForRow(row).cellSize.width
//                Logger.log("max: \(biggestWidth), current: \(cellWidth): \(column.dataCellForRow(row).cellSize)")
                biggestWidth = max(biggestWidth, cellWidth)
            }

//            column.width = biggestWidth
//            column.maxWidth = biggestWidth
        }
    }

    // MARK: table view data
    func numberOfRowsInTableView(tv: NSTableView) -> Int
    {
        return currentMediaData == nil ? 0 : (currentMediaData?.details.count)!
    }

    func tableView(tv: NSTableView, objectValueForTableColumn: NSTableColumn?, row: Int) -> String
    {
        let detail = currentMediaData?.details[row]
        switch objectValueForTableColumn!.dataCell.tag() {
        case 1:
            return detail?.category == nil ? "" : (detail?.category)!
        case 2:
            return detail?.name == nil ? "" : (detail?.name)!
        case 3:
            return detail?.value == nil ? "" : (detail?.value)!
        default:
            Logger.log("Unhandled file information tag: \(objectValueForTableColumn!.dataCell.tag())")
            return ""
        }
    }

    func tableView(tableView: NSTableView, isGroupRow row: Int) -> Bool
    {
        return currentMediaData?.details[row].category != nil
    }

    func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int)
    {
        let textCell = cell as? NSTextFieldCell
        if textCell != nil {
            textCell!.textColor = NSColor.whiteColor()
            textCell!.drawsBackground = false

            // Force a redraw, otherwise the color for column 1 doesn't update properly
            textCell!.stringValue = textCell!.stringValue
        }
    }
}