//
//  ResponseHandler.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 7/13/16.
//  Copyright © 2016 Sean Kosanovich. All rights reserved.
//

import Foundation

/// Protocol for de-serializing responses from the web server.
public protocol ResponseHandler {

    associatedtype ResponseType = Any

    /// The `Accept` Hader value, ex: `application/json`
    var acceptHeaderValue: String { get }

    init()

    /// Transforms the data returned by the web server to the desired type.
    /// - parameter data: The data returned by the server.
    /// - returns: The transformed type of the desired type.
    func transform(data: NSData) -> ResponseType?
}

/// A `ResponseHandler` for `JSON`
public class JSONResponseHandler: ResponseHandler {

    public typealias ResponseType = JSON

    public let acceptHeaderValue = "application/json"

    public required init() { }

    public func transform(data: NSData) -> JSON? {
        return JSON(fromData: data)
    }
}

/// A `ResponseHandler` for `Void` (for use with servers that return no data).
public class VoidResponseHandler: ResponseHandler {

    public typealias ResponseType = Void

    public let acceptHeaderValue = "*/*"

    public required init() { }

    public func transform(data: NSData) -> Void? {
        // do nothing
        return Void()
    }
}

/// A `ResponseHandler` for `UIImage`
public class ImageResponseHandler: ResponseHandler {

    public typealias ResponseType = UIImage

    public let acceptHeaderValue = "image/*"

    public required init() { }

    public func transform(data: NSData) -> UIImage? {
        return UIImage(data: data)
    }
}

/// A `ResponseHandler` for `NSData`
public class DataResponseHandler: ResponseHandler {

    public typealias ResponseType = NSData

    public let acceptHeaderValue = "*/*"

    public required init() { }

    public func transform(data: NSData) -> NSData? {
        return data
    }
}