//
//  Radish
//

import Foundation
import RangicCore

class Preferences : BasePreferences
{
    static fileprivate let BaseLocationLookupKey = "BaseLocationLookup"
    static fileprivate let PageSizeKey = "PageSize"
    static fileprivate let PlacenameLevelKey = "PlacenameLevel"
    static fileprivate let ShowOnMapKey = "ShowOnMap"
    static fileprivate let ThumbnailZoomKey = "ThumbnailZoom"
    static fileprivate let VideoPlayerVolume = "VideoPlayerVolume"

    enum ShowOnMap: Int
    {
        case bing = 1, openStreetMap = 2, google = 3
    }

    enum PlacenameLevel: Int
    {
        case short = 1, medium = 2, long = 3
    }


    static func setMissingDefaults()
    {
        setDefaultValue("http://open.mapquestapi.com", key: BaseLocationLookupKey)
        setDefaultValue(10, key: PageSizeKey)
        setDefaultValue(PlacenameLevel.medium.rawValue, key: PlacenameLevelKey)
        setDefaultValue(ShowOnMap.openStreetMap.rawValue, key: ShowOnMapKey)
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
        case .short:
            return .standard
        case .medium:
            return .detailed
        case .long:
            return .minimal
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
