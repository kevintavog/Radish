//
//

import Foundation
import AppKit

class ZoomView {
    let view: NSView
    let minimumScale = 1.0
    let maximumScale = 25.0
    var viewScale = 1.0


    public init(_ view: NSView) {
        self.view = view
    }

    public func zoomIn() {
        self.zoomViewByFactor(factor: 2.0)
    }

    public func zoomOut() {
        self.zoomViewByFactor(factor: 0.5)
    }

    public func zoomToFit() {
        zoomViewByFactor(factor: 1.0 / self.viewScale)
    }

    public func zoomToActualSize(imageSize: NSSize) {
        let frame = self.view.frame
        var factor = (imageSize.width / frame.width)
        factor = min(factor, (imageSize.height / frame.height))
        self.zoomViewByFactor(factor: (Double(factor)))
    }
    
    private func zoomViewByFactor(factor: Double) {
        zoomViewByFactor(factor: factor, point: documentCenterPoint())
    }

    private func zoomViewByFactor(factor: Double, point: NSPoint) {
        var scale = factor * self.viewScale
        scale = max(scale, self.minimumScale)
        scale = min(scale, self.maximumScale)
        let checkedFactor = scale / self.viewScale
//        print("scaling from \(self.viewScale) to \(scale) [\(checkedFactor) and \(factor)]")

        if (abs(scale - viewScale) > 0.0001) {
            self.viewScale = scale
            view.scaleUnitSquare(to: NSSize(width: checkedFactor, height: checkedFactor))

            var frame = self.view.frame
            frame.size.width = frame.size.width * CGFloat(factor)
            frame.size.height = frame.size.height * CGFloat(factor)
            self.view.setFrameSize(frame.size)

            self.scrollPointToCenter(point: point)
            self.view.needsDisplay = true
        }
    }

    private func scrollPointToCenter(point: NSPoint) {
        let frame = (self.view.superview as! NSClipView).documentVisibleRect
        let centerPoint = NSPoint(
            x: point.x - (frame.width / 2),
            y: point.y - (frame.height / 2))
        self.view.scroll(centerPoint)
    }

    private func documentCenterPoint() -> NSPoint {
        let frame = (self.view.superview as! NSClipView).documentVisibleRect
        return NSPoint(
            x: frame.origin.x + (frame.width / 2),
            y: frame.origin.y + (frame.height / 2))
    }
}
