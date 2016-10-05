//
//  Deserializer.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 7/13/16.
//  Copyright © 2016 Sean Kosanovich. All rights reserved.
//

import Foundation

/// Protocol for de-serializing responses from the web server.
public protocol Deserializer {

    associatedtype ResponseType = Any

    /// The `Accept` Hader to send in the request, ex: `application/json`
    var acceptHeader: String { get }

    init()

    /// Deserializes the data returned by the web server to the desired type.
    /// - parameter data: The data returned by the server.
    /// - returns: The deserialized value of the desired type.
    func deserialize(_ data: Data) -> ResponseType?
}

/// A `Deserializer` for `JSON`
public class JSONDeserializer: Deserializer {

    public typealias ResponseType = JSON

    public let acceptHeader = "application/json"

    public required init() { }

    public func deserialize(_ data: Data) -> JSON? {
        return JSON(fromData: data)
    }
}

/// A `Deserializer` for `Void` (for use with servers that return no data).
public class VoidDeserializer: Deserializer {

    public typealias ResponseType = Void

    public let acceptHeader = "*/*"

    public required init() { }

    public func deserialize(_ data: Data) -> Void? {
        // do nothing
        return Void()
    }
}

/// A `Deserializer` for `UIImage`
public class ImageDeserializer: Deserializer {

    public typealias ResponseType = UIImage

    public let acceptHeader = "image/*"

    public required init() { }

    public func deserialize(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}

/// A `Deserializer` for `Data`
public class DataDeserializer: Deserializer {

    public typealias ResponseType = Data

    public let acceptHeader = "*/*"

    public required init() { }

    public func deserialize(_ data: Data) -> Data? {
        return data
    }
}
