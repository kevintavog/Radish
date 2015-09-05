//
//  Radish
//


import Quartz

public class RadishImageBrowserView : IKImageBrowserView
{
    public override func newCellForRepresentedItem(item: AnyObject!) -> IKImageBrowserCell!
    {
        return RadishImageBrowserCell()
    }

}
