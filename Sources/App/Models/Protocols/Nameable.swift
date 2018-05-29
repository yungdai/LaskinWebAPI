//
//  Nameable.swift
//  LaskinMobileApp
//
//  Created by Christopher Szatmary on 2017-10-16.
//  Copyright © 2017 Yung Dai. All rights reserved.
//

import Foundation

public protocol Nameable {
      func propertyNames() -> [String]
      func properties() -> [Any]
      func propertiesDictionary() -> [String: Any]
      func propertiesTupleArray() -> [(String, Any)]
}

public extension Nameable {
     func propertyNames() -> [String] {
        return Mirror(reflecting: self).children.compactMap { $0.label }
    }
    
     func properties() -> [Any] {
        return Mirror(reflecting: self).children.compactMap { $0.value }
    }
    
     func propertiesDictionary() -> [String: Any] {
        var dictionary = [String: Any]()
        Mirror(reflecting: self).children.forEach { dictionary[$0.label!] = $0.value }
        return dictionary
    }
    
     func propertiesTupleArray() -> [(String, Any)] {
        var array = [(String, Any)]()
        Mirror(reflecting: self).children.forEach { array.append((label: $0.label!, value: $0.value)) }
        return array
    }
}
