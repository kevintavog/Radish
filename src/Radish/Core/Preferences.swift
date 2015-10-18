//
//  Radish
//

import Foundation
import RangicCore

class Preferences : BasePreferences
{
    static private let BaseLocationLookupKey = "BaseLocationLookup"
    static private let PageSizeKey = "PageSize"
    static private let PlacenameLevelKey = "PlacenameLevel"
    static private let ShowOnMapKey = "ShowOnMap"
    static private let ThumbnailZoomKey = "ThumbnailZoom"
    static private let VideoPlayerVolume = "VideoPlayerVolume"

    enum ShowOnMap: Int
    {
        case Bing = 1, OpenStreetMap = 2, Google = 3
    }

    enum PlacenameLevel: Int
    {
        case Short = 1, Medium = 2, Long = 3
    }


    static func setMissingDefaults()
    {
        setDefaultValue("http://open.mapquestapi.com", key: BaseLocationLookupKey)
        setDefaultValue(10, key: PageSizeKey)
        setDefaultValue(PlacenameLevel.Medium.rawValue, key: PlacenameLevelKey)
        setDefaultValue(ShowOnMap.OpenStreetMap.rawValue, key: ShowOnMapKey)
        setDefaultValue(Float(0.43), key: ThumbnailZoomKey)
        setDefaultValue(Float(0.5), key: VideoPlayerVolume)
    }

    static var baseLocationLookup: String
    {
        get { return stringForKey(BaseLocationLookupKey) }
        set { super.setValue(newValue, key: BaseLocationLookupKey) }
    }
    
    static var pageSize: Int
    {
        get { return intForKey(PageSizeKey) }
        set { super.setValue(newValue, key: PageSizeKey) }
    }
    
    static var placenameLevel: PlacenameLevel
    {
        get { return PlacenameLevel(rawValue: intForKey(PlacenameLevelKey))! }
        set { super.setValue(newValue.rawValue, key: PlacenameLevelKey) }
    }

    static var placenameFilter: PlaceNameFilter
    {
        switch placenameLevel {
        case .Short:
            return .Standard
        case .Medium:
            return .Detailed
        case .Long:
            return .Minimal
        }
    }

    static var showOnMap: ShowOnMap
    {
        get { return ShowOnMap(rawValue: intForKey(ShowOnMapKey))! }
        set { super.setValue(newValue.rawValue, key: ShowOnMapKey) }
    }
    
    static var thumbnailZoom: Float
    {
        get { return floatForKey(ThumbnailZoomKey) }
        set { super.setValue(newValue, key: ThumbnailZoomKey) }
    }
    
    static var videoPlayerVolume: Float
    {
        get { return floatForKey(VideoPlayerVolume) }
        set { setValue(newValue, key: VideoPlayerVolume) }
    }
    
}
