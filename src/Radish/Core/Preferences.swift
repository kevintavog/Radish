//
//  Radish
//

import Foundation

class Preferences
{
    static private let ThumbnailZoomKey = "ThumbnailZoom"
    static private let VideoPlayerVolume = "VideoPlayerVolume"

    static func setMissingDefaults()
    {
        setDefaultValue(Float(0.43), key: ThumbnailZoomKey)
        setDefaultValue(Float(0.5), key: VideoPlayerVolume)
    }

    static var thumbnailZoom: Float
    {
        get { return floatForKey(ThumbnailZoomKey) }
        set { setValue(newValue, key: ThumbnailZoomKey) }
    }

    static var videoPlayerVolume: Float
    {
        get { return floatForKey(VideoPlayerVolume) }
        set { setValue(newValue, key: VideoPlayerVolume) }
    }



    // Doubles
    static private func setValue(value: Double, key: String)
    {
        NSUserDefaults.standardUserDefaults().setDouble(value, forKey: key)
    }

    static private func doubleForKey(key: String) -> Double
    {
        return NSUserDefaults.standardUserDefaults().doubleForKey(key)
    }

    static private func setDefaultValue(value: Double, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }

    // Floats
    static private func setValue(value: Float, key: String)
    {
        NSUserDefaults.standardUserDefaults().setFloat(value, forKey: key)
    }

    static private func floatForKey(key: String) -> Float
    {
        return NSUserDefaults.standardUserDefaults().floatForKey(key)
    }

    static private func setDefaultValue(value: Float, key: String)
    {
        if (!keyExists(key)) { setValue(value, key: key) }
    }
    

    static private func keyExists(key: String) -> Bool
    {
        return NSUserDefaults.standardUserDefaults().objectForKey(key) != nil
    }
}