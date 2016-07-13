//
//  JSON.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/8/15.
//  Copyright © 2015 Sean Kosanovich. All rights reserved.
//

import Foundation

/// Represents any valid JSON type: another JSON object, an array, a string, a number, or a boolean.
public struct JSONValue : CustomStringConvertible {

    internal let value: AnyObject

    public var description: String {
        return value.description
    }

    /// Used if this value represents a `JSONObject` and returns the value associated with the gen key.
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
        if let dict = value as? [String : AnyObject] {
            return JSONObject(jsonDict: dict)
        }
        return nil
    }

    /// Get the `JSONArray` from this value.
    ///
    /// - returns: The `JSONArray` this value represents or `nil` if this value is not a `JSONArray`.
    public var jsonArray: JSONArray? {
        if let jsonArray = value as? [AnyObject] {
            return JSONArray(jsonArray: jsonArray)
        }
        return nil
    }

    /// Get the `String` from this value.
    ///
    /// - returns: The `String` this value represents or `nil` if this value is not a `String`.
    public var stringValue: String? {
        return value as? String
    }

    /// Get the `NSNumber` from this value.
    ///
    /// - returns: The `NSNumber` this value represents or `nil` if this value is not a `NSNumber`.
    public var numericalValue: NSNumber? {
        return value as? NSNumber
    }

    /// Get the `Int` from this value.
    ///
    /// - returns: The `Int` this value represents or `nil` if this value is not a `Int`. If the value contains a decimal, then the decimal portion will be removed.
    public var integerValue: Int? {
        return numericalValue?.integerValue
    }

    /// Get the `Double` from this value.
    ///
    /// - returns: The `Double` this value represents or `nil` if this value is not a `Double`.
    public var doubleValue: Double? {
        return numericalValue?.doubleValue
    }

    /// Get the `Bool` from this value.
    ///
    /// - returns: The `Bool` this value represents or `nil` if this value is not a `Bool`.
    public var boolValue: Bool? {
        return value as? Bool
    }
}

/// Represents a root JSON type, which can either be a `JSONObject` or a `JSONArray`.
public final class JSON : CustomStringConvertible {

    internal let jsonValue: JSONValue

    public var description: String {
        return jsonValue.description
    }

    /// Get the `JSONObject` from this value.
    ///
    /// - returns: The `JSONObject` this value represents or `nil` if this value is not a `JSONObject`.
    public var jsonObject: JSONObject? {
        return jsonValue.jsonObject
    }

    /// Get the `JSONArray` from this value.
    ///
    /// - returns: The `JSONArray` this value represents or `nil` if this value is not a `JSONArray`.
    public var jsonArray: JSONArray? {
        return jsonValue.jsonArray
    }

    /// Creates a new `JSON` that is a `JSONArray` at the root.
    ///
    /// - parameter array: The array this `JSON` contains.
    public init(array: [AnyObject]) {
        jsonValue = JSONValue(value: array)
    }

    /// Creates a new `JSON` that is a `JSONObject` at the root.
    ///
    /// - parameter dict: The dictionary this `JSON` contains.
    public init(dict: [String : AnyObject]) {
        jsonValue = JSONValue(value: dict)
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
}

/// Represents an array of `JSONValue`s.
public final class JSONArray : CustomStringConvertible, SequenceType {

    private let backingArray: [JSONValue]

    /// The number of elements in this JSONArray.
    public var count: Int {
        return backingArray.count
    }

    public var description: String {
        return backingArray.description
    }

    /// Creates a new `JSONArray` that contains the given array.
    public init(jsonArray: [AnyObject]) {
        backingArray = jsonArray.map { JSONValue(value: $0) }
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

    public func generate() -> IndexingGenerator<[JSONValue]> {
        return backingArray.generate()
    }
}

/// Represents a dictionary of key->`JSONValue`
public final class JSONObject : CustomStringConvertible {

    private let backingDict: [String : JSONValue]

    public var description: String {
        return backingDict.description
    }

    /// Creates a new `JSONObject` that contains the given dictionary
    public init(jsonDict: [String : AnyObject]) {
        var jsonDictionary = [String : JSONValue]()
        for (key, value) in jsonDict {
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

    /// Gets the `JSONObject` for the given key or the `defaultValue` if there is no `JSONObject` at the given key.
    ///
    /// - parameter key: The key to get the `JSONObject` for.
    /// - parameter defaultValue The default value to return if no object exists for the key.
    /// - returns: The `JSONObject` for the given key or the `defaultValue` if no object exists for the given key.
    public func getJSONObject(key: String, withDefaultValue defaultValue: JSONObject) -> JSONObject {
        return self[key]?.jsonObject ?? defaultValue
    }

    /// Gets the `JSONArray` for the given key or the `defaultValue` if there is no `JSONArray` at the given key.
    ///
    /// - parameter key: The key to get the `JSONArray` for.
    /// - parameter defaultValue The default value to return if no array exists for the key.
    /// - returns: The `JSONArray` for the given key or the `defaultValue` if no array exists for the given key.
    public func getJSONArray(key: String, withDefaultValue defaultValue: JSONArray) -> JSONArray {
        return self[key]?.jsonArray ?? defaultValue
    }

    /// Gets the `String` for the given key or the `defaultValue` if there is no `String` at the given key.
    ///
    /// - parameter key: The key to get the `String` for.
    /// - parameter defaultValue The default value to return if no string exists for the key.
    /// - returns: The `String` for the given key or the `defaultValue` if no string exists for the given key.
    public func getString(key: String, withDefaultValue defaultValue: String) -> String {
        return self[key]?.stringValue ?? defaultValue
    }

    /// Gets the `NSNumber` for the given key or the `defaultValue` if there is no `NSNumber` at the given key.
    ///
    /// - parameter key: The key to get the `NSNumber` for.
    /// - parameter defaultValue The default value to return if no number exists for the key.
    /// - returns: The `NSNumber` for the given key or the `defaultValue` if no number exists for the given key.
    public func getNumber(key: String, withDefaultValue defaultValue: NSNumber) -> NSNumber {
        return self[key]?.numericalValue ?? defaultValue
    }

    /// Gets the `Bool` for the given key or the `defaultValue` if there is no `Bool` at the given key.
    ///
    /// - parameter key: The key to get the `Bool` for.
    /// - parameter defaultValue The default value to return if no bool exists for the key.
    /// - returns: The `Bool` for the given key or the `defaultValue` if no bool exists for the given key.
    public func getBool(key: String, withDefaultValue defaultValue: Bool) -> Bool {
        return self[key]?.boolValue ?? defaultValue
    }
}

internal extension JSON {
    convenience internal init?(fromData data: NSData) {
        do {
            let json = try  NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
            if let jsonObj = json as? [String : AnyObject] {
                self.init(dict: jsonObj)
            } else if let jsonArray = json as? [AnyObject] {
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

    func createNSData() throws -> NSData {
        return try NSJSONSerialization.dataWithJSONObject(jsonValue.value, options: [])
    }
}