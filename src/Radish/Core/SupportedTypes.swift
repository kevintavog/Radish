//
//  Radish
//

import AVFoundation

public class SupportedTypes
{
    public enum MediaType
    {
        case Image, Video, Unknown
    }

    static private var imageTypes:[String]? = nil
    static private var videoTypes:[String]? = nil

    static private var supportedTypes:[String]? = nil


    static public func all() -> [String]
    {
        if (supportedTypes == nil) {
            supportedTypes = [String]()
            supportedTypes!.appendContentsOf(images())
            supportedTypes!.appendContentsOf(videos())
        }
        return supportedTypes!;
    }

    static public func isSupportedFile(fullUrl:NSURL) -> Bool
    {
        return all().contains(getFileType(fullUrl))
    }

    static public func getType(fullUrl:NSURL) -> MediaType
    {
        let fileType = getFileType(fullUrl)

        if images().contains(fileType) {
            return MediaType.Image
        }

        if videos().contains(fileType) {
            return MediaType.Video
        }

        return MediaType.Unknown
    }

    static public func images() -> [String]
    {
        if (imageTypes == nil) {
            let cgImageTypes: NSArray = CGImageSourceCopyTypeIdentifiers()
            imageTypes = (cgImageTypes as [AnyObject] as! [String])
        }
        return imageTypes!;
    }

    static public func videos() -> [String]
    {
        if (videoTypes == nil) {
            videoTypes = [AVFileTypeAIFC, AVFileTypeAIFF, AVFileTypeCoreAudioFormat, AVFileTypeAppleM4V, AVFileTypeMPEG4,
                AVFileTypeAppleM4A, AVFileTypeQuickTimeMovie, AVFileTypeWAVE, AVFileTypeAMR, AVFileTypeAC3, AVFileTypeMPEGLayer3, AVFileTypeSunAU]
        }
        return videoTypes!
    }

    static public func getFileType(fullUrl:NSURL) -> String
    {
        var uti:AnyObject?
        do {
            try fullUrl.getResourceValue(&uti, forKey:NSURLTypeIdentifierKey)
            return uti as! String
        }
        catch {
            return ""
        }
    }
}