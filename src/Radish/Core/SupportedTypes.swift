//
//  Radish
//

import AVFoundation

class SupportedTypes
{
    enum MediaType
    {
        case Image, Video, Unknown
    }

    static private var imageTypes:[String]? = nil
    static private var videoTypes:[String]? = nil

    static private var supportedTypes:[String]? = nil


    static func all() -> [String]
    {
        if (supportedTypes == nil)
        {
            supportedTypes = [String]()
            supportedTypes!.appendContentsOf(images())
            supportedTypes!.appendContentsOf(videos())

        }
        return supportedTypes!;
    }

    static func isSupportedFile(fullUrl:NSURL) -> Bool
    {
        return all().contains(getFileType(fullUrl))
    }

    static func getType(fullUrl:NSURL) -> MediaType
    {
        let fileType = getFileType(fullUrl)
        if images().contains(fileType)
        {
            return MediaType.Image
        }
        if videos().contains(fileType)
        {
            return MediaType.Video
        }
        return MediaType.Unknown
    }

    static func images() -> [String]
    {
        if (imageTypes == nil)
        {
            let cgImageTypes: NSArray = CGImageSourceCopyTypeIdentifiers()
            imageTypes = (cgImageTypes as [AnyObject] as! [String])
        }
        return imageTypes!;
    }

    static func videos() -> [String]
    {
        if (videoTypes == nil)
        {
            videoTypes = [AVFileTypeAIFC, AVFileTypeAIFF, AVFileTypeCoreAudioFormat, AVFileTypeAppleM4V, AVFileTypeMPEG4,
                AVFileTypeAppleM4A, AVFileTypeQuickTimeMovie, AVFileTypeWAVE, AVFileTypeAMR, AVFileTypeAC3, AVFileTypeMPEGLayer3, AVFileTypeSunAU]
        }
        return videoTypes!
    }

    static func getFileType(fullUrl:NSURL) -> String
    {
        var uti:AnyObject?
        do
        {
            try fullUrl.getResourceValue(&uti, forKey:NSURLTypeIdentifierKey)
            return uti as! String
        }
        catch
        {
        }
        return ""
    }
}