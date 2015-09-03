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


    func initialize(mediaProvider: MediaProvider)
    {
        self.mediaProvider = mediaProvider

        super.awakeFromNib()

        imageBrowser.setValue(NSColor.darkGrayColor(), forKey: IKImageBrowserBackgroundColorKey)

        let newAttrs = imageBrowser.valueForKey(IKImageBrowserCellsTitleAttributesKey)?.mutableCopy()
        newAttrs?.setValue(NSColor.whiteColor(), forKey: NSForegroundColorAttributeName)
        imageBrowser?.setValue(newAttrs, forKey: IKImageBrowserCellsTitleAttributesKey)


        imageBrowser.setZoomValue(Preferences.thumbnailZoom)


        NSNotificationCenter.defaultCenter().addObserver(self, selector: "mediaUpdated:",
            name: MediaProvider.MediaProviderUpdatedNotification, object: self.mediaProvider)
    }

    @IBAction func updateThumbnailSize(sender: AnyObject)
    {
        Preferences.thumbnailZoom = sizeSlider.floatValue
        imageBrowser.setZoomValue(sizeSlider.floatValue)
    }

    func mediaUpdated(notification: NSNotification)
    {
        Logger.log("mediaUpdated")
        thumbnailItems = [ThumbnailViewItem]()
        for m in mediaProvider!.mediaFiles
        {
            thumbnailItems.append(ThumbnailViewItem(mediaData: m))
        }
        imageBrowser.reloadData()
    }

    override func numberOfItemsInImageBrowser(browser: IKImageBrowserView!) -> Int
    {
        return thumbnailItems.count
    }

    override func imageBrowser(browser: IKImageBrowserView!, itemAtIndex index: Int) -> AnyObject!
    {
        return thumbnailItems[index]
    }
}

class ThumbnailViewItem : NSObject
{
    private let mediaData: MediaData


    init(mediaData: MediaData)
    {
        self.mediaData = mediaData
    }

    override func imageUID() -> String!
    {
        return mediaData.url.path
    }

    override func imageRepresentationType() -> String!
    {
        return IKImageBrowserNSURLRepresentationType
    }

    override func imageRepresentation() -> AnyObject!
    {
        return mediaData.url
    }
}
