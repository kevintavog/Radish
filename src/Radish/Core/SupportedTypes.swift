//
//  SupportedTypes.swift
//  Radish
//

import AVFoundation

class SupportedTypes
{
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
}