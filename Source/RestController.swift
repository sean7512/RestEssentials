//
//  RestController.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/7/15.
//  Copyright © 2016 Sean Kosanovich. All rights reserved.
//

import UIKit
import Foundation
import MobileCoreServices

/// Errors related to the networking for `RestController`
public enum NetworkingError: Error {
    /// Indicates the server responded with an unexpected statuscode.
    /// - parameter int: The status code the server respodned with.
    case unexpectedStatusCode(Int)

    /// Indicates that the server responded using an unknown protocol.
    case badResponse

    /// Indicates the server's response could not be parsed to `JSON`.
    case malformedResponse

    /// Inidcates the server did not respond to the request.
    case noResponse
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

/// Allows users to create HTTP REST networking calls that deal with JSON.
///
/// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately.
public class RestController : NSObject, URLSessionDelegate {

    fileprivate static let kDefaultRequestTimeout = 60 as TimeInterval
    private static let kPostType = "POST"
    private static let kPatchType = "PATCH"
    private static let kGetType = "GET"
    private static let kPutType = "PUT"
    private static let kDeleteType = "DELETE"
    private static let kJsonType = "application/json"
    private static let kContentType = "Content-Type"
    private static let kAcceptKey = "Accept"

    private let url: URL
    private var session: URLSession

    /// If set to *true*, then self signed SSL certificates will be accepted from the **SAME** host only.
    ///
    /// If you are making a request to *https://foo.com* and you get redirected to *https://bar.com* (where bar.com uses a self signed SSL certificate), then the request will fail; as the SSL host of *bar.com* does not match the intended host of *foo.com*.
    ///
    /// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately.
    public var acceptSelfSignedCertificate = false

    private init(url: URL) {
        self.url = url
        self.session = Foundation.URLSession.shared
    }

    /// Creates a new `RestController` for the given URL endpoint.
    ///
    /// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately for the server.
    /// - parameter urlString: The URL of the server to send requests to.
    /// - returns: If the given URL string represents a valid `URL`, then a `RestController` for the URL will be returned; it not then `nil` will be returned.
    public static func make(urlString: String) -> RestController? {
        if let validURL = URL(string: urlString) {
            return make(url: validURL)
        }

        return nil
    }

    /// Creates a new `RestController` for the given URL endpoint.
    ///
    /// **NOTE:** If running on iOS 9.0+ then ensure to configure `App Transport Security` appropriately for the server.
    /// - parameter url: The URL of the server to send requests to.
    /// - returns: A `RestController` for the given URL.
    public static func make(url: URL) -> RestController {
        let restController = RestController(url: url)
        restController.session = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate: restController, delegateQueue: nil)
        return restController
    }

    @objc public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if(acceptSelfSignedCertificate && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust && challenge.protectionSpace.host == url.host) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential);
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    private func dataTask(relativePath: String?, httpMethod: String, accept: String, json: JSON?, options: RestOptions, callback: @escaping (Result<Data>, HTTPURLResponse?) -> ()) throws {
        let restURL: URL;
        if let relativeURL = relativePath {
            restURL = url.appendingPathComponent(relativeURL)
        } else {
            restURL = url
        }

        var request = URLRequest(url: restURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: options.requestTimeoutSeconds)
        request.httpMethod = httpMethod

        request.setValue(accept, forHTTPHeaderField: RestController.kAcceptKey)
        if let customHeaders = options.httpHeaders {
            for (httpHeaderKey, httpHeaderValue) in customHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }

        if let jsonObj = json {
            request.setValue(RestController.kJsonType, forHTTPHeaderField: RestController.kContentType)
            let jsonData = try jsonObj.makeData()
            request.httpBody = jsonData as Data
        }

        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        session.dataTask(with: request) { (data, response, error) -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            if let err = error {
                callback(.failure(err), nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                callback(.failure(NetworkingError.badResponse), nil)
                return
            }

            if let expectedStatusCode = options.expectedStatusCode , httpResponse.statusCode != expectedStatusCode {
                callback(.failure(NetworkingError.unexpectedStatusCode(httpResponse.statusCode)), httpResponse)
                return
            }

            guard let returnedData = data else {
                callback(.failure(NetworkingError.noResponse), httpResponse)
                return
            }

            callback(.success(returnedData), httpResponse)
        }.resume()
    }

    private func makeCall<T: Deserializer>(_ relativePath: String?, httpMethod: String, json: JSON?, responseDeserializer: T, options: RestOptions, callback: @escaping (Result<T.ResponseType>, HTTPURLResponse?) -> ()) {
        do {
            try dataTask(relativePath: relativePath, httpMethod: httpMethod, accept: responseDeserializer.acceptHeader, json: json, options: options) { (result, httpResponse) -> () in
                do {
                    let data = try result.value()
                    guard let transformedResponse = responseDeserializer.deserialize(data) else {
                        callback(.failure(NetworkingError.malformedResponse), httpResponse)
                        return
                    }

                    callback(.success(transformedResponse), httpResponse)
                } catch {
                    callback(.failure(error), httpResponse)
                }
            }
        } catch {
            callback(.failure(error), nil)
        }
    }

    /// Performs a GET request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<T.ResponseType>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func get<T: Deserializer>(withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<T.ResponseType>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kGetType, json: nil, responseDeserializer: responseDeserializer, options: options, callback: callback)
    }

    /// Performs a GET request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func get(at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<JSON>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kGetType, json: nil, responseDeserializer: JSONDeserializer(), options: options, callback: callback)
    }

    /// Performs a POST request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<T.ResponseType>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func post<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<T.ResponseType>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kPostType, json: json, responseDeserializer: responseDeserializer, options: options, callback: callback)
    }

    /// Performs a POST request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func post(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<JSON>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kPostType, json: json, responseDeserializer: JSONDeserializer(), options: options, callback: callback)
    }

    /// Performs a PUT request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<T.ResponseType>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func put<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<T.ResponseType>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kPutType, json: json, responseDeserializer: responseDeserializer, options: options, callback: callback)
    }

    /// Performs a PUT request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func put(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<JSON>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kPutType, json: json, responseDeserializer: JSONDeserializer(), options: options, callback: callback)
    }

    /// Performs a DELETE request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<T.ResponseType>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.n the main thread.
    public func delete<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<T.ResponseType>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kDeleteType, json: json, responseDeserializer: responseDeserializer, options: options, callback: callback)
    }

    /// Performs a DELETE request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func delete(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<JSON>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kDeleteType, json: json, responseDeserializer: JSONDeserializer(), options: options, callback: callback)
    }

    /// Performs a PATCH request to the server, capturing the output of the server using the supplied `ResponseHandler`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<T.ResponseType>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func patch<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<T.ResponseType>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kPatchType, json: json, responseDeserializer: responseDeserializer, options: options, callback: callback)
    }

    /// Performs a PATCH request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - parameter callback: Called when the network operation has ended, giving back a Boxed `Result<JSON>` and a `NSHTTPURLResponse?` representing the response from the server. Note: The callback is **NOT** called on the main thread.
    public func patch(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions(), callback: @escaping (Result<JSON>, HTTPURLResponse?) -> ()) {
        makeCall(relativePath, httpMethod: RestController.kPatchType, json: json, responseDeserializer: JSONDeserializer(), options: options, callback: callback)
    }
}
