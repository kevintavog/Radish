//
//  Radish
//

import Foundation

public class Notifications
{
    public class MediaProvider
    {
        static let Cleared = "MediaProvider.Cleared"
        static let UpdatedNotification = "MediaProvider.UpdatedNotification"
    }

    public class SingleView
    {
        static let MediaData = "SingleView.MediaData"
    }

    public class Selection
    {
        static let MediaData = "Selection.MediaData"
    }


    static public func postNotification(notification: String, object: AnyObject? = nil, userInfo: [NSObject : AnyObject]? = nil)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(notification, object: object, userInfo: userInfo)
    }

    static public func addObserver(observer: AnyObject, selector: Selector, name: String, object: AnyObject?)
    {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: selector, name: name, object: object)
    }
}