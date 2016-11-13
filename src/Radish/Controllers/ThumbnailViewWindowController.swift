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
    func initialize(_ mediaProvider: MediaProvider)
    {
        self.mediaProvider = mediaProvider

        imageBrowser.setValue(NSColor.darkGray, forKey: IKImageBrowserBackgroundColorKey)

        let newAttrs = NSMutableDictionary(dictionary: imageBrowser.value(forKey: IKImageBrowserCellsTitleAttributesKey) as! [String:Any])
        newAttrs.setValue(NSColor.white, forKeyPath: NSForegroundColorAttributeName)
        imageBrowser?.setValue(newAttrs, forKey: IKImageBrowserCellsTitleAttributesKey)

        imageBrowser.viewFileDelegate = self

        sizeSlider.floatValue = Preferences.thumbnailZoom
        imageBrowser.setZoomValue(Preferences.thumbnailZoom)
        imageBrowser.setIntercellSpacing(NSSize(width: 16, height: 16))

        Notifications.addObserver(self, selector: #selector(ThumbnailViewWindowController.mediaUpdated(_:)), name: Notifications.MediaProvider.UpdatedNotification, object: self.mediaProvider)
    }

    // MARK: Actions
    @IBAction func updateThumbnailSize(_ sender: AnyObject)
    {
        Preferences.thumbnailZoom = sizeSlider.floatValue
        imageBrowser.setZoomValue(sizeSlider.floatValue)
    }

    override func imageBrowser(_ browser: IKImageBrowserView!, cellWasDoubleClickedAt index: Int)
    {
        viewFileAtIndex(index)
    }

    func viewSelectedFile()
    {
        if imageBrowser.selectionIndexes().count == 1 {
            viewFileAtIndex(imageBrowser.selectionIndexes().first!)
        }
    }

    func viewFileAtIndex(_ index: Int)
    {
        if index < (mediaProvider?.mediaFiles.count)! {
            let mediaItem = mediaProvider?.mediaFiles[index]
            let userInfo: [String: MediaData] = ["MediaData": mediaItem!]
            Notifications.postNotification(Notifications.SingleView.MediaData, object: self, userInfo:userInfo)
        }
    }

    // MARK: Notification handlers
    func mediaUpdated(_ notification: Notification)
    {
        thumbnailItems = [ThumbnailViewItem]()
        for m in mediaProvider!.mediaFiles {
            thumbnailItems.append(ThumbnailViewItem(mediaData: m))
        }
        imageBrowser.reloadData()
    }

    // MARK: ImageBrowser data provider
    override func numberOfItems(inImageBrowser browser: IKImageBrowserView!) -> Int
    {
        return thumbnailItems.count
    }

    override func imageBrowser(_ browser: IKImageBrowserView!, itemAt index: Int) -> Any!
    {
        return thumbnailItems[index]
    }

    // MARK: ImageBrowser Delegate
    override func imageBrowserSelectionDidChange(_ browser: IKImageBrowserView!)
    {
        if imageBrowser.selectionIndexes().count == 1 {
            let media = mediaProvider?.mediaFiles[imageBrowser.selectionIndexes().first!]
            let userInfo: [String: MediaData] = ["MediaData": media!]
            Notifications.postNotification(Notifications.Selection.MediaData, object: self, userInfo: userInfo)
        }

    }
}

open class ThumbnailViewItem : NSObject
{
    open let mediaData: MediaData


    init(mediaData: MediaData) {
        self.mediaData = mediaData
    }

    open override func imageUID() -> String! {
        return mediaData.url.path
    }

    open override func imageRepresentationType() -> String! {
        switch mediaData.type! {
        case .image:
            return IKImageBrowserNSURLRepresentationType
        case .video:
            return IKImageBrowserQTMoviePathRepresentationType
        default:
            return IKImageBrowserNSURLRepresentationType
        }
    }

    open override func imageRepresentation() -> Any! {
        switch mediaData.type! {
        case .image:
            return mediaData.url
        case .video:
            return mediaData.url
        default:
            return mediaData.url
        }
    }
}
