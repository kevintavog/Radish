//
//  OrderedDictionary.swift
//  SwiftDataStructures
//
//  Created by Tim Ekl on 6/2/14.
//  Copyright (c) 2014 Tim Ekl. All rights reserved.
//

import Foundation

public struct OrderedDictionary<Tk: Hashable, Tv> {
    var keys: Array<Tk> = []
    var values: Dictionary<Tk,Tv> = [:]

    var count: Int {
        assert(keys.count == values.count, "Keys and values array out of sync")
        return keys.count;
    }

    // Explicitly define an empty initializer to prevent the default memberwise initializer from being generated
    public init() {}

    public subscript(index: Int) -> Tv? {
        get {
            let key = keys[index]
            return values[key]
        }
        set(newValue) {
            let key = keys[index]
            if (newValue != nil) {
                values[key] = newValue
            } else {
                values.removeValueForKey(key)
                keys.removeAtIndex(index)
            }
        }
    }

    public subscript(key: Tk) -> Tv? {
        get {
            return values[key]
        }
        set(newValue) {
            if newValue == nil {
                values.removeValueForKey(key)
                keys.filter {$0 != key}
            }

            let oldValue = values.updateValue(newValue!, forKey: key)
            if oldValue == nil {
                keys.append(key)
            }
        }
    }

    public var description: String {
        var result = "{\n"
        for (index, key) in keys.enumerate() {
            result += "[\(index)]: \(key) => \([index])\n"
        }
        result += "}"
        return result
    }
}