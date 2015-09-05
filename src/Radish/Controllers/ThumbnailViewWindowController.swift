//
//  Radish
//

import AppKit
import Foundation
import Quartz

class ThumbnailViewWindowController : NSWindowController
{
    @IBOutlet weak var sizeSlider: NSSlider!
    @IBOutlet weak var imageBrowser: IKImageBrowserView!

    var mediaProvider: MediaProvider?
    var thumbnailItems = [ThumbnailViewItem]()


    // MARK: Initialize
    func initialize(mediaProvider: MediaProvider)
    {
        self.mediaProvider = mediaProvider

        imageBrowser.setValue(NSColor.darkGrayColor(), forKey: IKImageBrowserBackgroundColorKey)

        let newAttrs = imageBrowser.valueForKey(IKImageBrowserCellsTitleAttributesKey)?.mutableCopy()
        newAttrs?.setValue(NSColor.whiteColor(), forKey: NSForegroundColorAttributeName)
        imageBrowser?.setValue(newAttrs, forKey: IKImageBrowserCellsTitleAttributesKey)


        sizeSlider.floatValue = Preferences.thumbnailZoom
        imageBrowser.setZoomValue(Preferences.thumbnailZoom)
        imageBrowser.setIntercellSpacing(NSSize(width: 16, height: 16))


        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mediaUpdated:",
            name: MediaProvider.MediaProviderUpdatedNotification, object: self.mediaProvider)
    }

    // MARK: Actions
    @IBAction func updateThumbnailSize(sender: AnyObject)
    {
        Preferences.thumbnailZoom = sizeSlider.floatValue
        imageBrowser.setZoomValue(sizeSlider.floatValue)
    }

    // MARK: Notification handlers
    func mediaUpdated(notification: NSNotification)
    {
        thumbnailItems = [ThumbnailViewItem]()
        for m in mediaProvider!.mediaFiles {
            thumbnailItems.append(ThumbnailViewItem(mediaData: m))
        }
        imageBrowser.reloadData()
    }

    // MARK: ImageBrowser data provider
    override func numberOfItemsInImageBrowser(browser: IKImageBrowserView!) -> Int
    {
        return thumbnailItems.count
    }

    override func imageBrowser(browser: IKImageBrowserView!, itemAtIndex index: Int) -> AnyObject!
    {
        return thumbnailItems[index]
    }
}

public class ThumbnailViewItem : NSObject
{
    public let mediaData: MediaData


    init(mediaData: MediaData) {
        self.mediaData = mediaData
    }

    public override func imageUID() -> String! {
        return mediaData.url.path
    }

    public override func imageRepresentationType() -> String! {
        switch mediaData.type! {
        case .Image:
            return IKImageBrowserNSURLRepresentationType
        case .Video:
            return IKImageBrowserQTMoviePathRepresentationType
        default:
            return IKImageBrowserNSURLRepresentationType
        }
    }

    public override func imageRepresentation() -> AnyObject! {
        switch mediaData.type! {
        case .Image:
            return mediaData.url
        case .Video:
            return mediaData.url
        default:
            return mediaData.url
        }
    }
}
