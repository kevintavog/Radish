//
//  Radish
//

import Foundation

import RangicCore

open class Notifications : CoreNotifications
{
    open class FileInformationController {
        static let ClearedWikipediaDetails = "FileInformationController.ClearedWikipediaDetails"
        static let SetWikipediaDetails = "FileInformationController.SetWikipediaDetails"
    }
    open class SingleView
    {
        static let MediaData = "SingleView.MediaData"
        static let ShowPlacenameDetails = "SingleView.ShowPlacenameDetails"
        static let ShowWikipediaOnMap = "SingleView.ShowWikipediaOnMap"
    }

    open class Selection
    {
        static let MediaData = "Selection.MediaData"
    }
}
