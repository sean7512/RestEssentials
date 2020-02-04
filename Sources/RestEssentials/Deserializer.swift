//
//  Deserializer.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 7/13/16.
//  Copyright © 2017 Sean Kosanovich. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

/// Protocol for de-serializing responses from the web server.
public protocol Deserializer {

    associatedtype ResponseType = Any

    /// The `Accept` Hader to send in the request, ex: `application/json`
    var acceptHeader: String { get }

    init()

    /// Deserializes the data returned by the web server to the desired type.
    /// - parameter data: The data returned by the server.
    /// - returns: The deserialized value of the desired type.
    func deserialize(_ data: Data) throws -> ResponseType
}

/// A `Deserializer` for `JSON`
public class JSONDeserializer: Deserializer {

    public typealias ResponseType = JSON

    public let acceptHeader = "application/json"

    public required init() { }

    public func deserialize(_ data: Data) throws -> JSON {
        return try JSON(fromData: data)
    }
}

/// A `Deserializer` for Swift 4's `Decodable` protocol
public class DecodableDeserializer<T: Decodable>: Deserializer {

    public typealias ResponseType = T

    public let acceptHeader = "application/json"

    public required init() { }

    public func deserialize(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkingError.malformedResponse(data, error)
        }
    }
}

/// A `Deserializer` for `Void` (for use with servers that return no data).
public class VoidDeserializer: Deserializer {

    public typealias ResponseType = Void

    public let acceptHeader = "*/*"

    public required init() { }

    public func deserialize(_ data: Data) throws -> Void {
        // do nothing
        return Void()
    }
}

#if os(iOS) || os(watchOS) || os(tvOS)
    /// A `Deserializer` for `UIImage`
    public class ImageDeserializer: Deserializer {

        public typealias ResponseType = UIImage

        public let acceptHeader = "image/*"

        public required init() { }

        public func deserialize(_ data: Data) throws -> UIImage {
            guard let image = UIImage(data: data) else {
                throw NetworkingError.malformedResponse(data, nil)
            }
            return image
        }
    }
#elseif os(OSX)
    /// A `Deserializer` for `NSImage`
    public class ImageDeserializer: Deserializer {

    public typealias ResponseType = NSImage

    public let acceptHeader = "image/*"

    public required init() { }

    public func deserialize(_ data: Data) throws -> NSImage {
        guard let image = NSImage(data: data) else {
            throw NetworkingError.malformedResponse(data, nil)
        }
        return image
    }
}
#endif

/// A `Deserializer` for `Data`
public class DataDeserializer: Deserializer {

    public typealias ResponseType = Data

    public let acceptHeader = "*/*"

    public required init() { }

    public func deserialize(_ data: Data) throws -> Data {
        return data
    }
}
