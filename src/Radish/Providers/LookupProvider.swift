//
//  Radish
//

import Foundation
import RangicCore

public protocol LookupProvider
{
    func lookup(latitude: Double, longitude: Double) -> OrderedDictionary<String,String>
}