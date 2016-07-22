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
    case NoResponse
}

/// Options for `RestController` calls. Allows you to set an expected HTTP status code, HTTP Headers, or to modify the request timeout.
public struct RestOptions {
    /// The expected status call for the call, defaults to allowing any.
    public var expectedStatusCode: Int?

    /// An optional set of HTTP Headers to send with the call.
    public var httpHeaders: [String : String]?

    /// The amount of time in `seconds` until the request times out.
    public var requestTimeoutSeconds = RestController.kDefaultRequestTimeout
    
    public init() {}
}

/// Allos users to create HTTP REST networking calls that deal with JSON.
///
/// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately.
public class RestController : NSObject, NSURLSessionDelegate {

    private static let kPostType = "POST"
    private static let kPatchType = "PATCH"
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
    /// - returns: If the given URL string represents a valid `NSURL`, then a `RestController` for the URL will be returned; it not then `nil` will be returned.
    public static func createFromURLString(urlString: String) -> RestController? {
        if let validURL = NSURL(string: urlString) {
            return createFromURL(validURL)
        }

        return nil
    }

    /// Creates a new `RestController` for the given URL endpoint.
    ///
    /// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately for the server.
    /// - parameter url: The URL of the server to send requests to.
    /// - returns: A `RestController` for the given URL.
    public static func createFromURL(url: NSURL) -> RestController {
        let restController = RestController(url)
        restController.session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: restController, delegateQueue: nil)
        return restController
    }

    @objc public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if(acceptSelfSignedCertificate && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust && challenge.protectionSpace.host == url.host) {
            let credential = NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)
            completionHandler(.UseCredential, credential);
        } else {
            completionHandler(.PerformDefaultHandling, nil)
        }
    }

    private func makeCall(relativePath: String?, forHTTPMethod httpMethod: String, forAcceptType accept: String, withJSONData json: JSON?, withOptions options: RestOptions, withCallback callback: (Result<(NSData)>, NSHTTPURLResponse?) -> ()) throws {
        let restURL: NSURL;
        if let relativeURL = relativePath {
            restURL = url.URLByAppendingPathComponent(relativeURL)
        } else {
            restURL = url
        }

        let request = NSMutableURLRequest(URL: restURL, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: options.requestTimeoutSeconds)
        request.HTTPMethod = httpMethod

        request.setValue(accept, forHTTPHeaderField: RestController.kAcceptKey)
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
                callback(.Failure(err), nil)
                return
            }

            guard let httpResponse = response as? NSHTTPURLResponse else {
                callback(.Failure(NetworkingError.BadResponse), nil)
                return
            }

            if let expectedStatusCode = options.expectedStatusCode where httpResponse.statusCode != expectedStatusCode {
                callback(.Failure(NetworkingError.UnexpectedStatusCode(httpResponse.statusCode)), httpResponse)
                return
            }

            guard let returnedData = data else {
                callback(.Failure(NetworkingError.NoResponse), httpResponse)
                return
            }

            callback(.Success(returnedData), httpResponse)
        }.resume()
    }

    private func makeCall<T: ResponseHandler>(relativePath: String?, forHTTPMethod httpMethod: String, withJSONData json: JSON?, withResponseHandler handler: T, withOptions options: RestOptions, withCallback callback: (Result<T.ResponseType>, NSHTTPURLResponse?) -> ()) {
        do {
            try makeCall(relativePath, forHTTPMethod: httpMethod, forAcceptType: handler.acceptHeaderValue, withJSONData: json, withOptions: options) { (result, httpResponse) -> () in
                do {
                    let data = try result.value()
                    guard let transformedResponse = handler.transform(data) else {
                        callback(.Failure(NetworkingError.MalformedResponse), httpResponse)
                        return
                    }

                    callback(.Success(transformedResponse), httpResponse)
                } catch {
                    callback(.Failure(error), httpResponse)
                }
            }
        } catch {
            callback(.Failure(error), nil)
        }
    }

    /// Performs a GET request to the server, capturing the output of the server using the supplied `ResponseHandler`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter handler: A `ResponseHandler` to handle de-serializing the response to.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<Any>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func get<T: ResponseHandler>(relativePath: String? = nil, withResponseHandler handler: T, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<T.ResponseType>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kGetType, withJSONData: nil, withResponseHandler: handler, withOptions: options, withCallback: callback)
    }

    /// Performs a GET request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func get(relativePath: String? = nil, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kGetType, withJSONData: nil, withResponseHandler: JSONResponseHandler(), withOptions: options, withCallback: callback)
    }

    /// Performs a POST request to the server, capturing the output of the server using the supplied `ResponseHandler`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter json: The JSON body of the request.
    /// - parameter handler: A `ResponseHandler` to handle de-serializing the response to.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<Any>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func post<T: ResponseHandler>(relativePath: String? = nil, withJSON json: JSON, withResponseHandler handler: T, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<T.ResponseType>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kPostType, withJSONData: json, withResponseHandler: handler, withOptions: options, withCallback: callback)
    }

    /// Performs a POST request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter json: The JSON body of the request.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func post(relativePath: String? = nil, withJSON json: JSON, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kPostType, withJSONData: json, withResponseHandler: JSONResponseHandler(), withOptions: options, withCallback: callback)
    }

    /// Performs a PUT request to the server, capturing the output of the server using the supplied `ResponseHandler`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter json: The JSON body of the request.
    /// - parameter handler: A `ResponseHandler` to handle de-serializing the response to.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<Any>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func put<T: ResponseHandler>(relativePath: String? = nil, withJSON json: JSON, withResponseHandler handler: T, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<T.ResponseType>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kPutType, withJSONData: nil, withResponseHandler: handler, withOptions: options, withCallback: callback)
    }

    /// Performs a PUT request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter json: The JSON body of the request.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func put(relativePath: String? = nil, withJSON json: JSON, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kPutType, withJSONData: nil, withResponseHandler: JSONResponseHandler(), withOptions: options, withCallback: callback)
    }

    /// Performs a DELETE request to the server, capturing the output of the server using the supplied `ResponseHandler`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter json: The JSON body of the request.
    /// - parameter handler: A `ResponseHandler` to handle de-serializing the response to.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<Any>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.n the main thread.
    public func delete<T: ResponseHandler>(relativePath: String? = nil, withJSON json: JSON, withResponseHandler handler: T, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<T.ResponseType>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kDeleteType, withJSONData: json, withResponseHandler: handler, withOptions: options, withCallback: callback)
    }

    /// Performs a DELETE request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter json: The JSON body of the request.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func delete(relativePath: String? = nil, withJSON json: JSON, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kDeleteType, withJSONData: json, withResponseHandler: JSONResponseHandler(), withOptions: options, withCallback: callback)
    }

    /// Performs a PATCH request to the server, capturing the output of the server using the supplied `ResponseHandler`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter json: The JSON body of the request.
    /// - parameter handler: A `ResponseHandler` to handle de-serializing the response to.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<Any>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func patch<T: ResponseHandler>(relativePath: String? = nil, withJSON json: JSON, withResponseHandler handler: T, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<T.ResponseType>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kPatchType, withJSONData: json, withResponseHandler: handler, withOptions: options, withCallback: callback)
    }

    /// Performs a PATCH request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter json: The JSON body of the request.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func patch(relativePath: String? = nil, withJSON json: JSON, withOptions options: RestOptions = RestOptions(), withCallback callback: (Result<JSON>, NSHTTPURLResponse?) -> ()) {
        makeCall(relativePath, forHTTPMethod: RestController.kPatchType, withJSONData: json, withResponseHandler: JSONResponseHandler(), withOptions: options, withCallback: callback)
    }
}