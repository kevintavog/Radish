//
//  Radish
//

import Quartz
import RangicCore

open class RadishImageBrowserCell : IKImageBrowserCell
{
    static fileprivate var lineHeight: CGFloat?
    static fileprivate let textAttrs = [NSAttributedString.Key.foregroundColor : NSColor.white, NSAttributedString.Key.font : NSFont.labelFont(ofSize: 14)]
    static fileprivate let badDateAttrs = [
        NSAttributedString.Key.foregroundColor.rawValue : NSColor.yellow,
        NSAttributedString.Key.font : NSFont.labelFont(ofSize: 14),
        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
    ] as! [String : Any]


    // MARK: layer for type
    open override func layer(forType type: String!) -> CALayer!
    {
        switch (type!)
        {
        case IKImageBrowserCellBackgroundLayer:
            if cellState() != IKImageStateReady { return nil }

            let layer = CALayer()
            layer.frame = CGRect(x: 0, y: 0, width: frame().width, height: frame().height)

            let photoBackgroundLayer = CALayer()
            photoBackgroundLayer.frame = layer.frame

            let strokeComponents: [CGFloat] = [0.2, 0.2, 0.2, 0.5]
            let colorSpace = CGColorSpaceCreateDeviceRGB()

            photoBackgroundLayer.backgroundColor = NSColor.darkGray.cgColor

            let borderColor = CGColor(colorSpace: colorSpace, components: strokeComponents)
            photoBackgroundLayer.borderColor = borderColor

            photoBackgroundLayer.borderWidth = 1
            photoBackgroundLayer.shadowOpacity = 0.1
            photoBackgroundLayer.cornerRadius = 3
            
            layer.addSublayer(photoBackgroundLayer)

            return layer;


        case IKImageBrowserCellForegroundLayer:
            if cellState() != IKImageStateReady { return nil }
            let lineHeight = 20
            let lineOffset = 2
            let item = representedItem() as! ThumbnailViewItem

            let outerLayer = CALayer()
            outerLayer.frame = CGRect(x: 0, y: 0, width: frame().width, height: frame().height)
            outerLayer.contentsScale = (self.imageBrowserView().window?.backingScaleFactor)!
            
            let nameLayer = CATextLayer()
            nameLayer.frame = CGRect(x: 4, y: lineOffset, width: Int(frame().width), height: lineHeight)
            nameLayer.fontSize = 14
            nameLayer.contentsScale = (self.imageBrowserView().window?.backingScaleFactor)!

            let dateLayer = CATextLayer()
            dateLayer.frame = CGRect(x: 4, y: lineOffset + lineHeight, width: Int(frame().width), height: lineHeight)
            dateLayer.fontSize = 15
            dateLayer.contentsScale = (self.imageBrowserView().window?.backingScaleFactor)!
            if !item.mediaData.doFileAndExifTimestampsMatch() {
                dateLayer.foregroundColor = NSColor.yellow.cgColor
            }


            nameLayer.string = item.mediaData.name
            dateLayer.string = item.mediaData.formattedTime()

            outerLayer.addSublayer(nameLayer)
            outerLayer.addSublayer(dateLayer)
            outerLayer.setNeedsDisplay()

            return outerLayer;


        case IKImageBrowserCellSelectionLayer:
            let layer = CALayer()
            layer.frame = CGRect(x: 0, y: 0, width: frame().width, height: frame().height)

            let fillComponents: [CGFloat] = [0.9, 0.9, 0.9, 0.3]
            let strokeComponents: [CGFloat] = [0.9, 0.9, 0.9, 0.8]

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var color = CGColor(colorSpace: colorSpace, components: fillComponents)
            layer.backgroundColor = color

            color = CGColor(colorSpace: colorSpace, components: strokeComponents)
            layer.borderColor = color

            layer.borderWidth = 1.0
            layer.cornerRadius = 5

            return layer;


        default:
            return super.layer(forType: type)
        }
    }


    // MARK: Frame sizes
    open override func imageFrame() -> NSRect
    {
        let superImageFrame = super.imageFrame()
        if superImageFrame.size.height == 0 || superImageFrame.size.width == 0 { return NSZeroRect }

        let aspectRatio = superImageFrame.size.width / superImageFrame.size.height

        let containerFrame = NSInsetRect(imageContainerFrame(), 8, 8);
        if containerFrame.size.height <= 0 { return NSZeroRect }

        let containerAspectRatio = containerFrame.size.width / containerFrame.size.height

        var x, y, width, height: CGFloat
        if(containerAspectRatio > aspectRatio) {
            height = containerFrame.size.height
            y = containerFrame.origin.y
            width = superImageFrame.size.height * aspectRatio
            x = containerFrame.origin.x + (containerFrame.size.width - superImageFrame.size.width) * 0.5
        }
        else {
            width = containerFrame.size.width
            x = containerFrame.origin.x
            height = superImageFrame.size.width / aspectRatio
            y = containerFrame.origin.y + containerFrame.size.height - superImageFrame.size.height
        }

        x = floor(x)
        y = floor(y)
        width = ceil(width)
        height = ceil(height)

        let minHeight = RadishImageBrowserCell.getLineHeight() - 5

        var imageRect = NSRect(x: x, y: y, width: width, height: height)
        if imageRect.height >= (containerFrame.height - minHeight) {
            let heightAdjustment = imageRect.height - (containerFrame.height - minHeight)
            imageRect = NSInsetRect(imageRect, heightAdjustment, heightAdjustment)
            imageRect = NSOffsetRect(imageRect, 0, heightAdjustment)
        }
        return imageRect
    }

    open override func imageContainerFrame() -> NSRect
    {
        let superRect = super.frame()
        return NSRect(x: superRect.origin.x, y: superRect.origin.y + 15, width: superRect.width, height: superRect.height - 15)
    }

    open override func titleFrame() -> NSRect
    {
        let titleRect = super.titleFrame()
        let containerRect = frame()

        var rect = NSRect(x: titleRect.origin.x, y: containerRect.origin.y + 3, width: titleRect.width, height: titleRect.height)

        let margin = titleRect.origin.x - (containerRect.origin.x + 7)
        if margin < 0 {
            rect = NSInsetRect(rect, -margin, 0)
        }

        return rect
    }

    open override func selectionFrame() -> NSRect
    {
        return NSInsetRect(super.frame(), -3, -3)
    }

    // MARK: line height helper
    static fileprivate func getLineHeight() -> CGFloat
    {
        if lineHeight == nil {
            let attrStr = NSMutableAttributedString(string: "Mj", attributes: textAttrs)
            lineHeight = CTLineGetBoundsWithOptions(CTLineCreateWithAttributedString(attrStr), CTLineBoundsOptions.useHangingPunctuation).height
        }
        return lineHeight!
    }
}
