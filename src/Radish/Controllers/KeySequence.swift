//
//  Radish
//

import AppKit

class KeySequence : Hashable, CustomStringConvertible
{
    let modifierFlags: NSEvent.ModifierFlags
    let chars: String

    init(modifierFlags: NSEvent.ModifierFlags, chars: String)
    {
        self.modifierFlags = modifierFlags
        self.chars = chars;
    }

    var description: String
    {
        var charValues = [UInt32]()
        for ch in chars.unicodeScalars {
            charValues.append(ch.value)
        }
        return "\(modifierFlags)->\(chars) (\(charValues))"
    }

    var hashValue: Int { return /* modifierFlags.rawValue.hashValue * */ chars.hashValue }
}

func == (lhs: KeySequence, rhs: KeySequence) -> Bool
{
    return lhs.modifierFlags == rhs.modifierFlags && lhs.chars == rhs.chars
}
