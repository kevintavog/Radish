//
//  Radish
//

import AppKit
import Foundation
import Quartz

import RangicCore

class ThumbnailViewWindowController : NSWindowController, RadishImageBrowserViewDelegate
{
    @IBOutlet weak var sizeSlider: NSSlider!
    @IBOutlet weak var imageBrowser: RadishImageBrowserView!

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

        imageBrowser.viewFileDelegate = self

        sizeSlider.floatValue = Preferences.thumbnailZoom
        imageBrowser.setZoomValue(Preferences.thumbnailZoom)
        imageBrowser.setIntercellSpacing(NSSize(width: 16, height: 16))

        Notifications.addObserver(self, selector: "mediaUpdated:", name: Notifications.MediaProvider.UpdatedNotification, object: self.mediaProvider)
    }

    // MARK: Actions
    @IBAction func updateThumbnailSize(sender: AnyObject)
    {
        Preferences.thumbnailZoom = sizeSlider.floatValue
        imageBrowser.setZoomValue(sizeSlider.floatValue)
    }

    override func imageBrowser(browser: IKImageBrowserView!, cellWasDoubleClickedAtIndex index: Int)
    {
        viewFileAtIndex(index)
    }

    func viewSelectedFile()
    {
        if imageBrowser.selectionIndexes().count == 1 {
            viewFileAtIndex(imageBrowser.selectionIndexes().firstIndex)
        }
    }

    func viewFileAtIndex(index: Int)
    {
        if index < mediaProvider?.mediaFiles.count {
            let mediaItem = mediaProvider?.mediaFiles[index]
            let userInfo: [String: MediaData] = ["MediaData": mediaItem!]
            Notifications.postNotification(Notifications.SingleView.MediaData, object: self, userInfo:userInfo)
        }
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

    // MARK: ImageBrowser Delegate
    override func imageBrowserSelectionDidChange(browser: IKImageBrowserView!)
    {
        if imageBrowser.selectionIndexes().count == 1 {
            let media = mediaProvider?.mediaFiles[imageBrowser.selectionIndexes().firstIndex]
            let userInfo: [String: MediaData] = ["MediaData": media!]
            Notifications.postNotification(Notifications.Selection.MediaData, object: self, userInfo: userInfo)
        }

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
