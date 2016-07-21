//
//  ResponseHandler.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 7/13/16.
//  Copyright © 2016 Sean Kosanovich. All rights reserved.
//

import Foundation

public protocol ResponseHandler {
    associatedtype ResponseType = Any
    func transform(data: NSData) -> ResponseType?
}

public class JSONResponseHandler: ResponseHandler {

    public typealias ResponseType = JSON

    public init() { }

    public func transform(data: NSData) -> JSON? {
        return JSON(fromData: data)
    }
}

public class VoidResponseHandler: ResponseHandler {

    public typealias ResponseType = Void

    public init() { }

    public func transform(data: NSData) -> Void? {
        // do nothing
        return Void()
    }
}

public class ImageResponseHandler: ResponseHandler {

    public typealias ResponseType = UIImage

    public init() { }

    public func transform(data: NSData) -> UIImage? {
        return UIImage(data: data)
    }
}

public class DataesponseHandler: ResponseHandler {

    public typealias ResponseType = NSData

    public init() { }

    public func transform(data: NSData) -> NSData? {
        return data
    }
}