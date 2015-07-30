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

extension JSON {
    
    convenience init?(fromData data: NSData) {
        do {
            let json = try  NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
            if let jsonObj = json as? [String : AnyObject] {
                self.init(map: jsonObj)
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

public enum NetworkingError: ErrorType {
    case BadRequest
    case UnexpectedStatusCode(Int)
    case NetworkingError
    case BadResponse
    case MalformedResponse
    case NoResposne
}

public class WebRequest {
    
    private static let kPostType = "POST"
    private static let kGetType = "GET"
    private static let kPutType = "PUT"
    private static let kJsonType = "application/json"
    private static let kContentType = "content-type"
    private static let kFileBoundary = "WebRequest.upload()#boundary"
    private static let kDefaultRequestTimeout = 60 as NSTimeInterval
    
    private let url: NSURL
    
    private init(_ url: NSURL) {
        self.url = url
    }
    
    public static func createFromURLString(urlString: String) -> WebRequest? {
        if let validURL = NSURL(string: urlString) {
            return WebRequest(validURL)
        }
        
        return nil
    }
    
    private func makeCall(httpMethod: String, withJSONData json: JSON?, withExpectedStatusCode expectedStatus: Int, withHTTPHeaders httpHeaders: [String : String]?, withCallback callback: (Result<(data: NSData, response: NSHTTPURLResponse)>) -> ()) throws {
        
        let request = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: WebRequest.kDefaultRequestTimeout)
        request.HTTPMethod = httpMethod

        if let customHeaders = httpHeaders {
            for (httpHeaderKey, httpHeaderValue) in customHeaders {
                request.setValue(httpHeaderValue, forHTTPHeaderField: httpHeaderKey)
            }
        }
        
        if let jsonObj = json {
            request.setValue(WebRequest.kJsonType, forHTTPHeaderField: WebRequest.kContentType)
            let jsonData = try jsonObj.createNSData()
            request.HTTPBody = jsonData
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false

            if let err = error {
                callback(.Failure(err))
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                callback(.Failure(NetworkingError.BadResponse))
                return
            }

            if httpResponse.statusCode != expectedStatus {
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
    
    private func makeCallForJSONData(httpMethod: String, withJSONData json: JSON?, withExpectedStatusCode expectedStatus: Int, withHTTPHeaders httpHeaders: [String : String]?, withCallback callback: (Result<JSON>) -> ()) throws {
        try makeCall(httpMethod, withJSONData: json, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders) { (result) -> () in
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

    private func makeCallForNoResponseData(httpMethod: String, withJSONData json: JSON?, withExpectedStatusCode expectedStatus: Int, withHTTPHeaders httpHeaders: [String : String]?, withCallback callback: (Result<NSHTTPURLResponse>) -> ()) throws {
        try makeCall(httpMethod, withJSONData: json, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders) { (result) -> () in
            do {
                let httpResponse = try result.value().response
                callback(.Success(httpResponse))
            } catch {
                callback(.Failure(error))
            }
        }
    }

    public func put(withExpectedStatusCode expectedStatus: Int = 200, withHTTPHeaders httpHeaders: [String : String]? = nil, withCallback callback: (Result<JSON>) -> ()) throws {
        try makeCallForJSONData(WebRequest.kPutType, withJSONData: nil, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders, withCallback: callback)
    }

    public func putIgnoringResponseData(withExpectedStatusCode expectedStatus: Int = 200, withHTTPHeaders httpHeaders: [String : String]? = nil, withCallback callback: (Result<NSHTTPURLResponse>) -> ()) throws {
        try makeCallForNoResponseData(WebRequest.kPutType, withJSONData: nil, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders, withCallback: callback)
    }

    public func post(json: JSON, withExpectedStatusCode expectedStatus: Int = 200, withHTTPHeaders httpHeaders: [String : String]? = nil, withCallback callback: (Result<JSON>) -> ()) throws {
        try makeCallForJSONData(WebRequest.kPostType, withJSONData: json, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders, withCallback: callback)
    }

    public func postIgnoringResponseData(json: JSON, withExpectedStatusCode expectedStatus: Int = 200, withHTTPHeaders httpHeaders: [String : String]? = nil, withCallback callback: (Result<NSHTTPURLResponse>) -> ()) throws {
        try makeCallForNoResponseData(WebRequest.kPostType, withJSONData: json, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders, withCallback: callback)
    }
    
    public func get(withExpectedStatusCode expectedStatus: Int = 200, withHTTPHeaders httpHeaders: [String : String]? = nil, withCallback callback: (Result<JSON>) -> ()) throws {
        try makeCallForJSONData(WebRequest.kGetType, withJSONData: nil, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders, withCallback: callback)
    }

    public func getIgnoringResponseData(withExpectedStatusCode expectedStatus: Int = 200, withHTTPHeaders httpHeaders: [String : String]? = nil, withCallback callback: (Result<NSHTTPURLResponse>) -> ()) throws {
        try makeCallForNoResponseData(WebRequest.kGetType, withJSONData: nil, withExpectedStatusCode: expectedStatus, withHTTPHeaders: httpHeaders, withCallback: callback)
    }
}