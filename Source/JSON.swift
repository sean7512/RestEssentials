//
//  JSON.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/8/15.
//  Copyright © 2015 Sean Kosanovich. All rights reserved.
//

import Foundation

public struct JSONValue : CustomStringConvertible {

    internal let value: AnyObject

    public var description: String {
        return value.description
    }

    public subscript (key: String) -> JSONValue? {
        return jsonObject?[key]
    }

    public subscript (index: Int) -> JSONValue? {
        return jsonArray?[index]
    }

    public var jsonObject: JSONObject? {
        if let map = value as? [String : AnyObject] {
            return JSONObject(jsonMap: map)
        }
        return nil
    }

    public var jsonArray: JSONArray? {
        if let jsonArray = value as? [AnyObject] {
            return JSONArray(jsonArray: jsonArray)
        }
        return nil
    }

    public var stringValue: String? {
        return value as? String
    }

    public var numericalValue: NSNumber? {
        return value as? NSNumber
    }

    public var integerValue: Int? {
        return numericalValue?.integerValue
    }

    public var doubleValue: Double? {
        return numericalValue?.doubleValue
    }

    public var boolValue: Bool? {
        return value as? Bool
    }
}

public final class JSON : CustomStringConvertible {

    internal let jsonValue: JSONValue

    public var description: String {
        return jsonValue.description
    }

    public var jsonObject: JSONObject? {
        return jsonValue.jsonObject
    }

    public var jsonArray: JSONArray? {
        return jsonValue.jsonArray
    }

    public init(array: [AnyObject]) {
        jsonValue = JSONValue(value: array)
    }

    public init(map: [String : AnyObject]) {
        jsonValue = JSONValue(value: map)
    }

    public subscript (key: String) -> JSONValue? {
        return jsonObject?[key]
    }

    public subscript (index: Int) -> JSONValue? {
        return jsonArray?[index]
    }
}

public final class JSONArray : CustomStringConvertible, SequenceType {

    private let backingArray: [JSONValue]

    public var description: String {
        return backingArray.description
    }

    public init(jsonArray: [AnyObject]) {
        backingArray = jsonArray.map { JSONValue(value: $0) }
    }

    public subscript (index: Int) -> JSONValue? {
        return backingArray[index]
    }

    public func generate() -> IndexingGenerator<[JSONValue]> {
        return backingArray.generate()
    }
}

public final class JSONObject : CustomStringConvertible {

    private let backingDict: [String : JSONValue]

    public var description: String {
        return backingDict.description
    }

    public init(jsonMap: [String : AnyObject]) {
        var jsonDictionary = [String : JSONValue]()
        for (key, value) in jsonMap {
            jsonDictionary[key] = JSONValue(value: value)
        }
        backingDict = jsonDictionary
    }

    public subscript (key: String) -> JSONValue? {
        return backingDict[key]
    }

    public func getJSONObject(key: String, withDefaultValue defaultValue: JSONObject) -> JSONObject {
        return self[key]?.jsonObject ?? defaultValue
    }

    public func getJSONArray(key: String, withDefaultValue defaultValue: JSONArray) -> JSONArray {
        return self[key]?.jsonArray ?? defaultValue
    }

    public func getString(key: String, withDefaultValue defaultValue: String) -> String {
        return self[key]?.stringValue ?? defaultValue
    }

    public func getNumber(key: String, withDefaultValue defaultValue: NSNumber) -> NSNumber {
        return self[key]?.numericalValue ?? defaultValue
    }

    public func getBool(key: String, withDefaultValue defaultValue: Bool) -> Bool {
        return self[key]?.boolValue ?? defaultValue
    }
}