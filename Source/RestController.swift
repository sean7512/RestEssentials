//
//  RestController.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/7/15.
//  Copyright © 2015 Sean Kosanovich. All rights reserved.
//

import UIKit
import Foundation
import MobileCoreServices

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

/// Errors related to the networking for `RestController`
public enum NetworkingError: ErrorType {
    /// Indicates the server responded with an unexpected statuscode.
    /// - parameter int: The status code the server respodned with.
    case UnexpectedStatusCode(Int)

    /// Indicates that the server responded using an unknown protocol.
    case BadResponse

    /// Indicates the server's response could not be parsed to `JSON`.
    case MalformedResponse

    /// Inidcates the server did not respond to the request.
    case NoResposne
}

/// Options for `RestController` calls.
public struct RestOptions {
    /// The expected status call for the call, defaults to 200.
    public var expectedStatusCode = 200

    /// An optional set of HTTP Headers to send with the call.
    public var httpHeaders: [String : String]?

    /// The amount of time in `seconds` until the request times out.
    public var requestTimeoutSeconds = RestController.kDefaultRequestTimeout
}

/// Allos users to create HTTP REST networking calls that deal with JSON.
///
/// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately.
public class RestController : NSObject, NSURLSessionDelegate {

    private static let kPostType = "POST"
    private static let kGetType = "GET"
    private static let kPutType = "PUT"
    private static let kDeleteType = "DELETE"
    private static let kJsonType = "application/json"
    private static let kContentType = "Content-Type"
    private static let kAcceptKey = "Accept"
    private static let kDefaultRequestTimeout = 60 as NSTimeInterval

    private let url: NSURL
    private var session: NSURLSession

    /// If set to *true*, then self signed SSL certificates will be accepted from the **SAME** host only.
    ///
    /// If you are making a request to *https://foo.com* and you get redirected to *https://bar.com* (where bar.com uses a self signed SSL certificate), then the request will fail; as the SSL host of *bar.com* does not match the intended host of *foo.com*.
    ///
    /// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately.
    public var acceptSelfSignedCertificate = false

    private init(_ url: NSURL) {
        self.url = url
        self.session = NSURLSession.sharedSession()
    }

    /// Creates a new `RestController` for the given URL endpoint.
    ///
    /// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately for the server.
    /// - parameter urlString: The URL of the server to send requests to.
    /// - returns: If the given URL string represents a valid `NSURL`, then a `RestController` will be returned; it not then `nil` will be returned.
    public static func createFromURLString(urlString: String) -> RestController? {
        if let validURL = NSURL(string: urlString) {
            let restController = RestController(validURL)
            restController.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: restController, delegateQueue: nil)
            return restController
        }

        return nil
    }

    @objc public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if(acceptSelfSignedCertificate && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust && challenge.protectionSpace.host == url.host) {
            let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
            completionHandler(.UseCredential, credential);
        } else {
            completionHandler(.PerformDefaultHandling, nil)
        }
    }

    private func makeCall(httpMethod: String, withJSONData json: JSON?, withOptions options: RestOptions, withCallback callback: (Result<(data: NSData, response: NSHTTPURLResponse)>) -> ()) throws {
        let request = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: options.requestTimeoutSeconds)
        request.HTTPMethod = httpMethod

        request.setValue(RestController.kJsonType, forHTTPHeaderField: RestController.kAcceptKey)
        if let customHeaders = options.httpHeaders {
            for (httpHeaderKey, httpHeaderValue) in customHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }

        if let jsonObj = json {
            request.setValue(RestController.kJsonType, forHTTPHeaderField: RestController.kContentType)
            let jsonData = try jsonObj.createNSData()
            request.HTTPBody = jsonData
        }

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

        session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false

            if let err = error {
                callback(.Failure(err))
                return
            }

            guard let httpResponse = response as? NSHTTPURLResponse else {
                callback(.Failure(NetworkingError.BadResponse))
                return
            }

            if httpResponse.statusCode != options.expectedStatusCode {
                callback(.Failure(NetworkingError.UnexpectedStatusCode(httpResponse.statusCode)))
                return
            }

            guard let returnedData = data else {
                callback(.Failure(NetworkingError.NoResposne))
                return
            }

            callback(.Success(data: returnedData, response: httpResponse))
            }.resume()
    }

    private func makeCallForJSONData(httpMethod: String, withJSONData json: JSON?, withOptions options: RestOptions, withCallback callback: (Result<JSON>) -> ()) throws {
        try makeCall(httpMethod, withJSONData: json, withOptions: options) { (result) -> () in
            do {
                let jsonData = try result.value().data

                if let jsonObj = JSON(fromData: jsonData) {
                    callback(.Success(jsonObj))
                } else {
                    callback(.Failure(NetworkingError.MalformedResponse))
                }
            } catch {
                callback(.Failure(error))
            }
        }
    }

    private func makeCallForNoResponseData(httpMethod: String, withJSONData json: JSON?, withOptions options: RestOptions, withCallback callback: (Result<NSHTTPURLResponse>) -> ()) throws {
        try makeCall(httpMethod, withJSONData: json, withOptions: options) { (result) -> () in
            do {
                let httpResponse = try result.value().response
                callback(.Success(httpResponse))
            } catch {
                callback(.Failure(error))
            }
        }
    }

    /// Performs a POST request to the server, capturing the `JSON` response from the server
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON to post to the server.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` indicating the success of the call with the returned data. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    /// - throws: Throws an error if the JSON cannot be serialized.
    public func post(json: JSON, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>) -> ()) throws {
        try makeCallForJSONData(RestController.kPostType, withJSONData: json, withOptions: options, withCallback: callback)
    }

    /// Performs a POST request to the server, while ignoring any response sent back from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON to post to the server.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<NSHTTPURLResponse>` indicating the success of the call. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    /// - throws: Throws an error if the JSON cannot be serialized.
    public func postIgnoringResponseData(json: JSON, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<NSHTTPURLResponse>) -> ()) throws {
        try makeCallForNoResponseData(RestController.kPostType, withJSONData: json, withOptions: options, withCallback: callback)
    }

    /// Performs a PUT request to the server, capturing the `JSON` response from the server
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON to post to the server. If nil, no data will be sent.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` indicating the success of the call with the returned data. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    /// - throws: Throws an error if the JSON cannot be serialized.
    public func put(json: JSON?, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>) -> ()) throws {
        try makeCallForJSONData(RestController.kPutType, withJSONData: nil, withOptions: options, withCallback: callback)
    }

    /// Performs a PUT request to the server, while ignoring any response sent back from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON to post to the server. If nil, no data will be sent.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<NSHTTPURLResponse>` indicating the success of the call. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    /// - throws: Throws an error if the JSON cannot be serialized.
    public func putIgnoringResponseData(json: JSON?, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<NSHTTPURLResponse>) -> ()) throws {
        try makeCallForNoResponseData(RestController.kPutType, withJSONData: nil, withOptions: options, withCallback: callback)
    }

    /// Performs a GET request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` indicating the success of the call with the returned data. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    public func get(withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>) -> ()) {
        // can only throw if serializing json
        try! makeCallForJSONData(RestController.kGetType, withJSONData: nil, withOptions: options, withCallback: callback)
    }

    /// Performs a GET request to the server, while ignoring any response sent back from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<NSHTTPURLResponse>` indicating the success of the call. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    public func getIgnoringResponseData(withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<NSHTTPURLResponse>) -> ()) {
        // can only throw if serializing json
        try! makeCallForNoResponseData(RestController.kGetType, withJSONData: nil, withOptions: options, withCallback: callback)
    }

    /// Performs a DELETE request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` indicating the success of the call with the returned data. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    public func delete(withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>) -> ()) {
        // can only throw if serializing json
        try! makeCallForJSONData(RestController.kDeleteType, withJSONData: nil, withOptions: options, withCallback: callback)
    }

    /// Performs a DELETE request to the server, while ignoring any response sent back from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<NSHTTPURLResponse>` indicating the success of the call. Note: The callback is **NOT** called on the main thread.
    /// - returns: Nothing.
    public func deleteIgnoringResponseData(withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<NSHTTPURLResponse>) -> ()) {
        // can only throw if serializing json
        try! makeCallForNoResponseData(RestController.kDeleteType, withJSONData: nil, withOptions: options, withCallback: callback)
    }
}