//
//  RestEssentialsTests.swift
//  RestEssentialsTests
//
//  Created by Sean Kosanovich on 7/30/15.
//  Copyright (c) 2017 Sean Kosanovich. All rights reserved.
//

import XCTest
@testable import RestEssentials
#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

class RestControllerTests: XCTestCase {

    struct HttpBinResponse: Codable {
        let url: String
        let json: SomeObject?
    }

    struct SomeObject: Codable {
        let someString: String
        let someInt: Int
        let someDouble: Double
        let someBoolean: Bool
        let someNumberArray: [Int]
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGETEncodable() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }

        let (response, _) = try await rest.get(HttpBinResponse.self)
        XCTAssert(response.url == "https://httpbin.org/get")
    }

    func testGETGenericJSON() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }
        
        let (json, _) = try await rest.get(withDeserializer: JSONDeserializer())
        XCTAssert(json["url"].string == "https://httpbin.org/get")
    }

    func testPOST() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true, "key5": [1, 2, 3, 4]]
        let (resposneJson, _) = try await rest.post(json, at: "post")
        XCTAssert(resposneJson["url"].string == "https://httpbin.org/post")
        XCTAssert(resposneJson["json"]["key1"].string == "value1")
        XCTAssert(resposneJson["json"]["key2"].int == 2)
        XCTAssert(resposneJson["json"]["key3"].double == 4.5)
        XCTAssert(resposneJson["json"]["key4"].bool == true)
        XCTAssert(resposneJson["json"]["key5"][2].numerical == 3)
        XCTAssert(resposneJson["json"]["key6"].string == nil)

        guard let jsonArray = resposneJson["json"]["key5"].array else {
            XCTFail("Array not returned in JSON")
            return
        }

        for item in jsonArray {
            XCTAssert(item.numerical != nil)
        }
    }

    func testPUT() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let (json, _) = try await rest.put(JSON(dict: ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true]), at: "put")
        XCTAssert(json["url"].string == "https://httpbin.org/put")
    }

    func testGetImage() async throws {
        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        let (img, _) = try await rest.get(withDeserializer: ImageDeserializer())
        #if os(iOS) || os(watchOS) || os(tvOS)
            XCTAssert(img is UIImage)
        #elseif os(OSX)
            XCTAssert(img is NSImage)
        #endif
    }

    func testVoidResponse() async throws {
        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        let _ = try await rest.get(withDeserializer: VoidDeserializer())
    }

    func testDataResponse() async throws {
        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        let (data, _) = try await rest.get(withDeserializer: DataDeserializer())
        XCTAssert(data is Data)
    }

    func testDecodableResponse() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["someString": "value1", "someInt": 2, "someDouble": 4.5, "someBoolean": true, "someNumberArray": [1, 2, 3, 4]]
        let (httpBinResponse, _) = try await rest.post(json, withDeserializer: DecodableDeserializer<HttpBinResponse>(), at: "post")
        XCTAssert(httpBinResponse is HttpBinResponse)
        XCTAssert(httpBinResponse.url == "https://httpbin.org/post")
        XCTAssert(httpBinResponse.json?.someString == "value1")
        XCTAssert(httpBinResponse.json?.someInt == 2)
        XCTAssert(httpBinResponse.json?.someDouble == 4.5)
        XCTAssert(httpBinResponse.json?.someBoolean == true)
        XCTAssert(httpBinResponse.json?.someNumberArray[2] == 3)
    }

    func testWrongDecodabelResponse() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["someString": "value1", "someInt": 2, "someDouble": 4.5, "someBoolean": true, "someNumberArray": [1, 2, 3, 4]]
        do {
            let _ = try await rest.post(json, withDeserializer: DecodableDeserializer<SomeObject>(), at: "post")
             XCTFail("Response should not have succeeded")
        } catch NetworkingError.malformedResponse(_, _, let originalError) {
            XCTAssertNotNil(originalError as? DecodingError)
        } catch {
            XCTFail("Error performing POST: \(error)")
        }
    }

    func testEncodableObject() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let someObject = SomeObject(someString: "value1", someInt: 2, someDouble: 4.5, someBoolean: true, someNumberArray: [1, 2, 3, 4])
        let (httpBinResponse, _) = try await rest.post(someObject, at: "post", responseType: HttpBinResponse.self)
        XCTAssert(httpBinResponse is HttpBinResponse)
        XCTAssert(httpBinResponse.url == "https://httpbin.org/post")
        XCTAssert(httpBinResponse.json?.someString == someObject.someString)
        XCTAssert(httpBinResponse.json?.someInt == someObject.someInt)
        XCTAssert(httpBinResponse.json?.someDouble == someObject.someDouble)
        XCTAssert(httpBinResponse.json?.someBoolean == someObject.someBoolean)
        XCTAssert(httpBinResponse.json?.someNumberArray[2] == someObject.someNumberArray[2])
    }

    func testUnexpectedStatusCode() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }
        
        var options = RestOptions()
        options.expectedStatusCode = 201
        do {
            let _ = try await rest.get(HttpBinResponse.self, options: options)
            XCTFail("Expected to get an error, but call succeeded")
        } catch NetworkingError.unexpectedStatusCode(let actualStatusCode, _, _) {
            XCTAssert(actualStatusCode != options.expectedStatusCode)
        } catch {
            XCTFail("Received unexpected error: \(error)")
        }
    }

    func testJsonParsing() async throws {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["error_code": 2, "error_description": "Invalid credentials", "result": 1]
        let (responseJson, _) = try await rest.post(json, at: "post")
        XCTAssert(responseJson["url"].string == "https://httpbin.org/post")
        if let errorCode = responseJson["json"]["error_code"].int, errorCode != 5 {
            XCTAssert(errorCode == 2)
        } else {
            XCTFail("Error code sent was a 2, should pass")
        }
    }
}
