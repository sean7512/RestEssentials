//
//  RestController.swift
//  RestEssentials
//
//  Created by Sean Kosanovich on 6/7/15.
//  Copyright © 2017 Sean Kosanovich. All rights reserved.
//
import Foundation

/// Errors related to the networking for the `RestController`
public enum NetworkingError: Error {
    /// Indicates the server responded with an unexpected status code.
    /// - parameter Int: The status code the server respodned with.
    /// - parameter HTTPURLResponse: The HTTPURLResponse from the server
    /// - parameter Data: The raw returned data from the server
    case unexpectedStatusCode(Int, HTTPURLResponse, Data)

    /// Indicates that the server responded using an unknown protocol.
    /// - parameter URLResponse: The response returned form the server.
    /// - parameter Data: The raw returned data from the server.
    case badResponse(URLResponse, Data)

    /// Indicates the server's response could not be deserialized using the given Deserializer.
    /// - parameter HTTPURLResponse: The HTTPURLResponse from the server
    /// - parameter Data: The raw returned data from the server
    /// - parameter Error: The original system error (like a DecodingError, etc) that caused the malformedResponse to trigger
    case malformedResponse(HTTPURLResponse, Data, Error)
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

/// Allows users to generate headers before each REST call is made. The headers returned will be COMBINED with any headers set in the original RestController call. Any headers returned here will override the values given in the original call if they have the same name.
///
/// - parameter requestUrl: The URL that this header generation request is for. Never nu,,
public typealias HeaderGenerator = (URL) -> [String : String]?

/// Allows users to create HTTP REST networking calls that deal with JSON.
///
/// **NOTE:** Ensure to configure `App Transport Security` appropriately.
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

    /// This generator will be called before every useage of this RestController
    public var headerGenerator: HeaderGenerator?

    /// If set to *true*, then self signed SSL certificates will be accepted from the **SAME** host only.
    ///
    /// If you are making a request to *https://foo.com* and you get redirected to *https://bar.com* (where bar.com uses a self signed SSL certificate), then the request will fail; as the SSL host of *bar.com* does not match the intended host of *foo.com*.
    ///
    /// **NOTE:** Ensure to configure `App Transport Security` appropriately.
    public var acceptSelfSignedCertificate = false

    private init(url: URL) {
        self.url = url
        self.session = URLSession.shared
    }

    /// Creates a new `RestController` for the given URL endpoint.
    ///
    /// **NOTE:** Ensure to configure `App Transport Security` appropriately.
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
    /// **NOTE:** Ensure to configure `App Transport Security` appropriately.
    /// - parameter url: The URL of the server to send requests to.
    /// - returns: A `RestController` for the given URL.
    public static func make(url: URL) -> RestController {
        let restController = RestController(url: url)
        restController.session = URLSession(configuration: URLSessionConfiguration.default, delegate: restController, delegateQueue: nil)
        return restController
    }

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if(acceptSelfSignedCertificate && challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust && challenge.protectionSpace.host == url.host) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential);
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    private func dataTask(relativePath: String?, httpMethod: String, accept: String, payload: Data?, options: RestOptions) async throws -> (Data, HTTPURLResponse) {
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

        if let generatedHeaders = headerGenerator?(restURL) {
            for (httpHeaderKey, httpHeaderValue) in generatedHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }

        if let payloadToSend = payload {
            request.setValue(RestController.kJsonType, forHTTPHeaderField: RestController.kContentType)
            request.httpBody = payloadToSend
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkingError.badResponse(response, data)
        }

        if let expectedStatusCode = options.expectedStatusCode, httpResponse.statusCode != expectedStatusCode {
            throw NetworkingError.unexpectedStatusCode(httpResponse.statusCode, httpResponse, data)
        }

        return (data, httpResponse)
    }

    private func makeCall<T: Deserializer>(_ relativePath: String?, httpMethod: String, payload: Data?, responseDeserializer: T, options: RestOptions) async throws -> T.ResponseType {
        let (data, httpResponse) = try await dataTask(relativePath: relativePath, httpMethod: httpMethod, accept: responseDeserializer.acceptHeader, payload: payload, options: options)
        do {
            let transformedResponse = try responseDeserializer.deserialize(data)
            return transformedResponse
        } catch {
            throw NetworkingError.malformedResponse(httpResponse, data, error)
        }
    }
    
    /// Performs a GET request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func get<T: Deserializer>(withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        return try await makeCall(relativePath, httpMethod: RestController.kGetType, payload: nil, responseDeserializer: responseDeserializer, options: options)
    }

    /// Performs a GET request to the server, capturing the data object type response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter type: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server.
    public func get<D: Decodable>(_ type: D.Type, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> D {
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: RestController.kGetType, payload: nil, responseDeserializer: decodableDeserializer, options: options)
    }

    /// Performs a POST request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func post<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kPostType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }

    /// Performs a POST request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded. Must be of type `Encodable`
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func post<T: Deserializer, E: Encodable>(_ encodable: E, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try JSONEncoder().encode(encodable)
        return try await makeCall(relativePath, httpMethod: RestController.kPostType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }

    /// Performs a POST request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns:A  `JSON` object representing the response from the server.
    public func post(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> JSON {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kPostType, payload: payload, responseDeserializer: JSONDeserializer(), options: options)
    }

    /// Performs a POST request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server.
    public func post<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> D {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: RestController.kPostType, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Performs a PUT request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func put<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kPutType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }
    
    /// Performs a PUT request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded. Must be of type `Encodable`
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func put<T: Deserializer, E: Encodable>(_ encodable: E, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try JSONEncoder().encode(encodable)
        return try await makeCall(relativePath, httpMethod: RestController.kPutType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }
    
    /// Performs a PUT request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns:A  `JSON` object representing the response from the server.
    public func put(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> JSON {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kPutType, payload: payload, responseDeserializer: JSONDeserializer(), options: options)
    }
    
    /// Performs a PUT request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server.
    public func put<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> D {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: RestController.kPutType, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Performs a DELETE request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func delete<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kDeleteType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }
    
    /// Performs a DELETE request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded. Must be of type `Encodable`
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func delete<T: Deserializer, E: Encodable>(_ encodable: E, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try JSONEncoder().encode(encodable)
        return try await makeCall(relativePath, httpMethod: RestController.kDeleteType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }
    
    /// Performs a DELETE request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns:A  `JSON` object representing the response from the server.
    public func delete(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> JSON {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kDeleteType, payload: payload, responseDeserializer: JSONDeserializer(), options: options)
    }
    
    /// Performs a DELETE request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server.
    public func delete<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> D {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: RestController.kDeleteType, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
    /// Performs a PATCH request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func patch<T: Deserializer>(_ json: JSON, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kPatchType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }
    
    /// Performs a PATCH request to the server, capturing the output of the server using the supplied `Deserializer`.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded. Must be of type `Encodable`
    /// - parameter responseDeserializer: A `Deserializer` to handle de-serializing the response to.
    /// - parameter relativePath: An **optional** parameter of a relative path to append to this instance.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct for this call.
    /// - returns: A  `T.ResponseType` object that was returnd from the server.
    public func patch<T: Deserializer, E: Encodable>(_ encodable: E, withDeserializer responseDeserializer: T, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> T.ResponseType {
        let payload = try JSONEncoder().encode(encodable)
        return try await makeCall(relativePath, httpMethod: RestController.kPatchType, payload: payload, responseDeserializer: responseDeserializer, options: options)
    }
    
    /// Performs a PATCH request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter json: The JSON body of the request.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns:A  `JSON` object representing the response from the server.
    public func patch(_ json: JSON, at relativePath: String? = nil, options: RestOptions = RestOptions()) async throws -> JSON {
        let payload = try json.makeData()
        return try await makeCall(relativePath, httpMethod: RestController.kPatchType, payload: payload, responseDeserializer: JSONDeserializer(), options: options)
    }
    
    /// Performs a PATCH request to the server, capturing the `JSON` response from the server.
    ///
    /// Note: This is an **asynchronous** call and will return immediately.  The network operation is done in the background.
    ///
    /// - parameter encodable: Any object that can be encoded.
    /// - parameter relativePath: An **optional** parameter of a relative path of this inscatnaces main URL as setup at when created.
    /// - parameter responseType: The type of object this get call returns. This type must conform to `Decodable`
    /// - parameter options: An **optional** parameter of a `RestOptions` struct containing any header fields to include with the call or a different expected status code.
    /// - returns: A  `Decodable` tyoe of `D` object that was returned from the server.
    public func patch<E: Encodable, D: Decodable>(_ encodable: E, at relativePath: String? = nil, responseType type: D.Type, options: RestOptions = RestOptions()) async throws -> D {
        let payload = try JSONEncoder().encode(encodable)
        let decodableDeserializer = DecodableDeserializer<D>()
        return try await makeCall(relativePath, httpMethod: RestController.kPatchType, payload: payload, responseDeserializer: decodableDeserializer, options: options)
    }
    
}
