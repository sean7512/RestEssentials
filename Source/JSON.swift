//
//  JSON.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/8/15.
//  Copyright © 2016 Sean Kosanovich. All rights reserved.
//

import Foundation

public typealias JSONValue = Any

/// Represents any valid JSON type: another JSON object, an array, a string, a number, or a boolean.
public struct JSON : CustomStringConvertible, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    
    public typealias Element = JSONValue
    
    public typealias Key = String
    
    public typealias Value = JSONValue

    private static let kJSONNull = JSON(rawValue: Void())

    fileprivate let raw: JSONValue

    public var description: String {
        return (raw as AnyObject).description
    }

    /// Represents a Null JSON value
    public static var Null: JSON {
        return kJSONNull
    }

    fileprivate init(rawValue: JSONValue) {
        raw = rawValue
    }

    /// Creates an instance initialized with the given elements.
    public init(arrayLiteral elements: JSONValue...) {
        self.init(array: elements)
    }
    
    /// Creates an instance initialized with the given key-value pairs.
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        var jsonDict = [String: JSONValue]()
        for (key, value) in elements {
            jsonDict[key] = value
        }
        self.init(dict: jsonDict)
    }
    
    /// Creates a new `JSON` that is a `JSONArray` at the root.
    ///
    /// - parameter array: The array this `JSON` contains.
    public init(array: [JSONValue]) {
        raw = array
    }

    /// Creates a new `JSON` that is a JSON object at the root.
    ///
    /// - parameter dict: The dictionary this `JSON` contains.
    public init(dict: [String : JSONValue]) {
        raw = dict
    }

    /// Used if this value represents a JSON object and returns the value associated with the key.
    ///
    /// - parameter key: The key of the value to retrieve.
    /// - returns: The value if this value is a JSON Ooject and if the key exists; otherwise `JSON.Null` is returned.
    public subscript (key: String) -> JSON {
        guard let dict = object else {
            return JSON.Null
        }

        guard let rawValue = dict[key] else {
            return JSON.Null
        }

        return JSON(rawValue: rawValue)
    }

    /// Used if this value represents a `JSONArray` and returns the value at the given index.
    ///
    /// - parameter index: The index of the value to retrieve.
    /// - returns: The value at the index if this value is a `JSONArray` and if the array contains a value at the given index; otherwise `JSON.Null` is returned.
    public subscript (index: Int) -> JSON {
        return array?[index] ?? JSON.Null
    }

    /// Get the JSON object from this value.
    ///
    /// - returns: The JSON object this value represents or `nil` if this value is not a JSON object.
    private var object: [String : JSONValue]? {
        return raw as? [String : JSONValue]
    }

    /// Get the `JSONArray` from this value.
    ///
    /// - returns: The `JSONArray` this value represents or `nil` if this value is not a `JSONArray`.
    public var array: JSONArray? {
        if let jsonArray = raw as? [JSONValue] {
            return JSONArray(array: jsonArray)
        }
        return nil
    }

    /// Get the `String` from this value.
    ///
    /// - returns: The `String` this value represents or `nil` if this value is not a `String`.
    public var string: String? {
        return raw as? String
    }

    /// Get the `NSNumber` from this value.
    ///
    /// - returns: The `NSNumber` this value represents or `nil` if this value is not a `NSNumber`.
    public var numerical: NSNumber? {
        return raw as? NSNumber
    }

    /// Get the `Int` from this value.
    ///
    /// - returns: The `Int` this value represents or `nil` if this value is not a `Int`. If the value contains a decimal, then the decimal portion will be removed.
    public var int: Int? {
        return numerical?.intValue
    }

    /// Get the `Double` from this value.
    ///
    /// - returns: The `Double` this value represents or `nil` if this value is not a `Double`.
    public var double: Double? {
        return numerical?.doubleValue
    }

    /// Get the `Bool` from this value.
    ///
    /// - returns: The `Bool` this value represents or `nil` if this value is not a `Bool`.
    public var bool: Bool? {
        return raw as? Bool
    }
}

/// Represents an array of `JSONValue`s.
public class JSONArray : CustomStringConvertible, Sequence {

    fileprivate let backingArray: [JSON]

    /// The number of elements in this JSONArray.
    public var count: Int {
        return backingArray.count
    }

    public var description: String {
        return backingArray.description
    }

    /// Creates a new `JSONArray` that contains the given array.
    public init(array: [JSONValue]) {
        backingArray = array.map { JSON(rawValue: $0) }
    }

    /// Gets the `JSON` at the given index.
    ///
    /// - parameter index: The index of the value to retrieve.
    /// - returns: The `JSON` at the index if the array contains a value at the given index; otherwise `JSON.Null` is returned.
    public subscript (index: Int) -> JSON {
        if backingArray.count > index {
            return backingArray[index]
        }
        return JSON.Null
    }

    public func makeIterator() -> IndexingIterator<[JSON]> {
        return backingArray.makeIterator()
    }
}

internal extension JSON {
    internal init?(fromData data: Data) {
        do {
            let json = try  JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            if let jsonObj = json as? [String : JSONValue] {
                self.init(dict: jsonObj)
            } else if let jsonArray = json as? [JSONValue] {
                self.init(array: jsonArray)
            } else {
                print("Unknown json data type: \(json)")
                return nil
            }
        } catch {
            print("An error occurred deserializing data to JSON: \(error)")
            return nil
        }
    }

    internal func makeData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: raw, options: [])
    }
}
