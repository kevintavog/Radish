//
//  Radish
//


import Quartz

protocol RadishImageBrowserViewDelegate: class
{
    func viewSelectedFile()
}

public class RadishImageBrowserView : IKImageBrowserView
{
    weak var viewFileDelegate:RadishImageBrowserViewDelegate?


    public override func newCellForRepresentedItem(item: AnyObject!) -> IKImageBrowserCell!
    {
        return RadishImageBrowserCell()
    }

    public override func performKeyEquivalent(theEvent: NSEvent) -> Bool {

        // Return (no modifiers) means open the currently selected item in the single view
        if (theEvent.keyCode == 36 || theEvent.keyCode == 76) &&
            ((theEvent.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == 0) {
            if !super.performKeyEquivalent(theEvent) {

                if selectionIndexes().count == 1 {
                    viewFileDelegate?.viewSelectedFile()
                    return true
                }
            }
        }
        return super.performKeyEquivalent(theEvent)
    }

}
