//
//  Radish
//


import Quartz

protocol RadishImageBrowserViewDelegate: class
{
    func viewSelectedFile()
}

open class RadishImageBrowserView : IKImageBrowserView
{
    weak var viewFileDelegate:RadishImageBrowserViewDelegate?


    open override func newCell(forRepresentedItem item: Any!) -> IKImageBrowserCell!
    {
        return RadishImageBrowserCell()
    }

    open override func performKeyEquivalent(with theEvent: NSEvent) -> Bool {

        // Return (no modifiers) means open the currently selected item in the single view
        if (theEvent.keyCode == 36 || theEvent.keyCode == 76) &&
            ((theEvent.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue) == 0) {
            if !super.performKeyEquivalent(with: theEvent) {

                if selectionIndexes().count == 1 {
                    viewFileDelegate?.viewSelectedFile()
                    return true
                }
            }
        }
        return super.performKeyEquivalent(with: theEvent)
    }
}
