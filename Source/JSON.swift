//
//  JSON.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/8/15.
//  Copyright © 2016 Sean Kosanovich. All rights reserved.
//

import Foundation

/// Represents any valid JSON type: another JSON object, an array, a string, a number, or a boolean.
public struct JSONValue : CustomStringConvertible {

    fileprivate let value: Any

    public var description: String {
        return (value as AnyObject).description
    }

    /// Used if this value represents a `JSONObject` and returns the value associated with the key.
    ///
    /// - parameter key: The key of the value to retrieve.
    /// - returns: The value if this value is a `JSONObject` and if the key exists; otherwise `nil`.
    public subscript (key: String) -> JSONValue? {
        return jsonObject?[key]
    }

    /// Used if this value represents a `JSONArray` and returns the value at the given index.
    ///
    /// - parameter index: The index of the value to retrieve.
    /// - returns: The value at the index if this value is a `JSONArray` and if the array contains a value at the given index; otherwise `nil`.
    public subscript (index: Int) -> JSONValue? {
        return jsonArray?[index]
    }

    /// Get the `JSONObject` from this value.
    ///
    /// - returns: The `JSONObject` this value represents or `nil` if this value is not a `JSONObject`.
    public var jsonObject: JSONObject? {
        if let dict = value as? [String : Any] {
            return JSONObject(dict: dict)
        }
        return nil
    }

    /// Get the `JSONArray` from this value.
    ///
    /// - returns: The `JSONArray` this value represents or `nil` if this value is not a `JSONArray`.
    public var jsonArray: JSONArray? {
        if let jsonArray = value as? [Any] {
            return JSONArray(array: jsonArray)
        }
        return nil
    }

    /// Get the `String` from this value.
    ///
    /// - returns: The `String` this value represents or `nil` if this value is not a `String`.
    public var string: String? {
        return value as? String
    }

    /// Get the `NSNumber` from this value.
    ///
    /// - returns: The `NSNumber` this value represents or `nil` if this value is not a `NSNumber`.
    public var numberical: NSNumber? {
        return value as? NSNumber
    }

    /// Get the `Int` from this value.
    ///
    /// - returns: The `Int` this value represents or `nil` if this value is not a `Int`. If the value contains a decimal, then the decimal portion will be removed.
    public var int: Int? {
        return numberical?.intValue
    }

    /// Get the `Double` from this value.
    ///
    /// - returns: The `Double` this value represents or `nil` if this value is not a `Double`.
    public var double: Double? {
        return numberical?.doubleValue
    }

    /// Get the `Bool` from this value.
    ///
    /// - returns: The `Bool` this value represents or `nil` if this value is not a `Bool`.
    public var bool: Bool? {
        return value as? Bool
    }
}

/// Represents a root JSON type, which can either be a `JSONObject` or a `JSONArray`.
public class JSON : CustomStringConvertible {

    private let value: JSONValue

    public var description: String {
        return value.description
    }

    /// Get the `JSONObject` from this value.
    ///
    /// - returns: The `JSONObject` this value represents or `nil` if this value is not a `JSONObject`.
    public var jsonObject: JSONObject? {
        return value.jsonObject
    }

    /// Get the `JSONArray` from this value.
    ///
    /// - returns: The `JSONArray` this value represents or `nil` if this value is not a `JSONArray`.
    public var jsonArray: JSONArray? {
        return value.jsonArray
    }

    /// Creates a new `JSON` that is a `JSONArray` at the root.
    ///
    /// - parameter array: The array this `JSON` contains.
    public init(array: [Any]) {
        value = JSONValue(value: array)
    }

    /// Creates a new `JSON` that is a `JSONObject` at the root.
    ///
    /// - parameter dict: The dictionary this `JSON` contains.
    public init(dict: [String : Any]) {
        value = JSONValue(value: dict)
    }

    /// Used if this represents a `JSONObject` and returns the value associated with the gen key.
    ///
    /// - parameter key: The key of the value to retrieve.
    /// - returns: The value if this value is a `JSONObject` and if the key exists; otherwise `nil`.
    public subscript (key: String) -> JSONValue? {
        return jsonObject?[key]
    }

    /// Used if this value represents a `JSONArray` and returns the value at the given index.
    ///
    /// - parameter index: The index of the value to retrieve.
    /// - returns: The value at the index if this value is a `JSONArray` and if the array contains a value at the given index; otherwise `nil`.
    public subscript (index: Int) -> JSONValue? {
        return jsonArray?[index]
    }

    fileprivate func jsonValue() -> Any {
        return value.value
    }
}

/// Represents an array of `JSONValue`s.
public class JSONArray : CustomStringConvertible, Sequence {

    fileprivate let backingArray: [JSONValue]

    /// The number of elements in this JSONArray.
    public var count: Int {
        return backingArray.count
    }

    public var description: String {
        return backingArray.description
    }

    /// Creates a new `JSONArray` that contains the given array.
    public init(array: [Any]) {
        backingArray = array.map { JSONValue(value: $0) }
    }

    /// Gets the `JSONValue` at the given index.
    ///
    /// - parameter index: The index of the value to retrieve.
    /// - returns: The value at the index if the array contains a value at the given index; otherwise `nil`.
    public subscript (index: Int) -> JSONValue? {
        if backingArray.count > index {
            return backingArray[index]
        }
        return nil
    }

    public func makeIterator() -> IndexingIterator<[JSONValue]> {
        return backingArray.makeIterator()
    }
}

/// Represents a dictionary of key->`JSONValue`
public class JSONObject : CustomStringConvertible {

    fileprivate let backingDict: [String : JSONValue]

    public var description: String {
        return backingDict.description
    }

    /// Creates a new `JSONObject` that contains the given dictionary
    public init(dict: [String : Any]) {
        var jsonDictionary = [String : JSONValue]()
        for (key, value) in dict {
            jsonDictionary[key] = JSONValue(value: value)
        }
        backingDict = jsonDictionary
    }

    /// Gets the `JSONValue` for the given key.
    ///
    /// - parameter key: The key of the value to get.
    /// - returns: The value for the given key if this object contains a value for the key; otherwise `nil`.
    public subscript (key: String) -> JSONValue? {
        return backingDict[key]
    }
}

internal extension JSON {
    convenience internal init?(fromData data: Data) {
        do {
            let json = try  JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            if let jsonObj = json as? [String : Any] {
                self.init(dict: jsonObj)
            } else if let jsonArray = json as? [Any] {
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

    internal func createData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: jsonValue(), options: [])
    }
}
