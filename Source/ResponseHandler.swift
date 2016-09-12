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
    func transform(data: Data) -> ResponseType?
}

/// A `ResponseHandler` for `JSON`
open class JSONResponseHandler: ResponseHandler {

    public typealias ResponseType = JSON

    open let acceptHeaderValue = "application/json"

    public required init() { }

    open func transform(data: Data) -> JSON? {
        return JSON(fromData: data)
    }
}

/// A `ResponseHandler` for `Void` (for use with servers that return no data).
open class VoidResponseHandler: ResponseHandler {

    public typealias ResponseType = Void

    open let acceptHeaderValue = "*/*"

    public required init() { }

    open func transform(data: Data) -> Void? {
        // do nothing
        return Void()
    }
}

/// A `ResponseHandler` for `UIImage`
open class ImageResponseHandler: ResponseHandler {

    public typealias ResponseType = UIImage

    open let acceptHeaderValue = "image/*"

    public required init() { }

    open func transform(data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}

/// A `ResponseHandler` for `NSData`
open class DataResponseHandler: ResponseHandler {

    public typealias ResponseType = Data

    open let acceptHeaderValue = "*/*"

    public required init() { }

    open func transform(data: Data) -> Data? {
        return data
    }
}
