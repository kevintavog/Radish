//
//  Radish
//

import Foundation
import RangicCore

class Preferences : BasePreferences
{
    static private let ThumbnailZoomKey = "ThumbnailZoom"
    static private let VideoPlayerVolume = "VideoPlayerVolume"
    static private let BaseLocationLookupKey = "BaseLocationLookup"
    static private let ShowOnMapKey = "ShowOnMap"

    enum ShowOnMap: Int
    {
        case Bing = 1, OpenStreetMap = 2, Google = 3
    }

    static func setMissingDefaults()
    {
        setDefaultValue(Float(0.43), key: ThumbnailZoomKey)
        setDefaultValue(Float(0.5), key: VideoPlayerVolume)
        setDefaultValue("http://open.mapquestapi.com", key: BaseLocationLookupKey)
        setDefaultValue(ShowOnMap.OpenStreetMap.rawValue, key: ShowOnMapKey)
    }

    static var baseLocationLookup: String
    {
        get { return stringForKey(BaseLocationLookupKey) }
        set { super.setValue(newValue, key: BaseLocationLookupKey) }
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

    static var showOnMap: ShowOnMap
    {
        get { return ShowOnMap(rawValue: intForKey(ShowOnMapKey))! }
        set { super.setValue(newValue.rawValue, key: ShowOnMapKey) }
    }

}
