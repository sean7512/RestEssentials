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

    func testGETEncodable() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }

        let (result, _) = await rest.get(HttpBinResponse.self)
        do {
            let response = try result.value()
            XCTAssert(response.url == "https://httpbin.org/get")
        } catch NetworkingError.malformedResponse(let data, _) {
            XCTFail("Error performing GET, malformed data response: \(data)")
        } catch {
            XCTFail("Error performing GET: \(error)")
        }
    }

    func testGETGenericJSON() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }
        
        let (result, _) = await rest.get(withDeserializer: JSONDeserializer())
        do {
            let json = try result.value()
            XCTAssert(json["url"].string == "https://httpbin.org/get")
        } catch {
            XCTFail("Error performing GET: \(error)")
        }
    }

    func testPOST() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true, "key5": [1, 2, 3, 4]]
        let (result, _) = await rest.post(json, at: "post")
        do {
            let json = try result.value()
            XCTAssert(json["url"].string == "https://httpbin.org/post")
            XCTAssert(json["json"]["key1"].string == "value1")
            XCTAssert(json["json"]["key2"].int == 2)
            XCTAssert(json["json"]["key3"].double == 4.5)
            XCTAssert(json["json"]["key4"].bool == true)
            XCTAssert(json["json"]["key5"][2].numerical == 3)
            XCTAssert(json["json"]["key6"].string == nil)

            guard let jsonArray = json["json"]["key5"].array else {
                XCTFail("Array not returned in JSON")
                return
            }

            for item in jsonArray {
                XCTAssert(item.numerical != nil)
            }
        } catch {
            XCTFail("Error performing POST: \(error)")
        }
    }

    func testPUT() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let (result, _) = await rest.put(JSON(dict: ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true]), at: "put")
        do {
            let json = try result.value()
            XCTAssert(json["url"].string == "https://httpbin.org/put")
        } catch {
            XCTFail("Error performing PUT: \(error)")
        }
    }

    func testGetImage() async{
        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        let (result, _) = await rest.get(withDeserializer: ImageDeserializer())
        do {
            let img = try result.value()
            #if os(iOS) || os(watchOS) || os(tvOS)
                XCTAssert(img is UIImage)
            #elseif os(OSX)
                XCTAssert(img is NSImage)
            #endif
        } catch {
            XCTFail("Error performing GET: \(error)")
        }
    }

    func testVoidResponse() async {
        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        let _ = await rest.get(withDeserializer: VoidDeserializer())
    }

    func testDataResponse() async {
        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        let (result, _) = await rest.get(withDeserializer: DataDeserializer())
        do {
            let data = try result.value()
            XCTAssert(data is Data)
        } catch {
            XCTFail("Error performing GET: \(error)")
        }
    }

    func testDecodableResponse() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["someString": "value1", "someInt": 2, "someDouble": 4.5, "someBoolean": true, "someNumberArray": [1, 2, 3, 4]]
        let (result, _) = await rest.post(json, withDeserializer: DecodableDeserializer<HttpBinResponse>(), at: "post")
        do {
            let response = try result.value()
            XCTAssert(response is HttpBinResponse)
            XCTAssert(response.url == "https://httpbin.org/post")
            XCTAssert(response.json?.someString == "value1")
            XCTAssert(response.json?.someInt == 2)
            XCTAssert(response.json?.someDouble == 4.5)
            XCTAssert(response.json?.someBoolean == true)
            XCTAssert(response.json?.someNumberArray[2] == 3)
        } catch {
            XCTFail("Error performing POST: \(error)")
        }
    }

    func testWrongDecodabelResponse() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["someString": "value1", "someInt": 2, "someDouble": 4.5, "someBoolean": true, "someNumberArray": [1, 2, 3, 4]]
        let (result, _) = await rest.post(json, withDeserializer: DecodableDeserializer<SomeObject>(), at: "post")
        do {
            _ = try result.value()
             XCTFail("Response should not have succeeded")
        } catch NetworkingError.malformedResponse( _, let originalError) {
            XCTAssertNotNil(originalError as? DecodingError)
        } catch {
            XCTFail("Error performing POST: \(error)")
        }
    }

    func testEncodableObject() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let someObject = SomeObject(someString: "value1", someInt: 2, someDouble: 4.5, someBoolean: true, someNumberArray: [1, 2, 3, 4])
        let (result, _) = await rest.post(someObject, at: "post", responseType: HttpBinResponse.self)
        do {
            let response = try result.value()
            XCTAssert(response is HttpBinResponse)
            XCTAssert(response.url == "https://httpbin.org/post")
            XCTAssert(response.json?.someString == someObject.someString)
            XCTAssert(response.json?.someInt == someObject.someInt)
            XCTAssert(response.json?.someDouble == someObject.someDouble)
            XCTAssert(response.json?.someBoolean == someObject.someBoolean)
            XCTAssert(response.json?.someNumberArray[2] == someObject.someNumberArray[2])
        } catch {
            XCTFail("Error performing POST: \(error)")
        }
    }

    func testUnexpectedStatusCode() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }
        
        var options = RestOptions()
        options.expectedStatusCode = 201
        let (result, _) = await rest.get(HttpBinResponse.self, options: options)
        do {
            let _ = try result.value()
            XCTFail("Expected to get an error, but call succeeded")
        } catch NetworkingError.unexpectedStatusCode(let actualStatusCode, _) {
            XCTAssert(actualStatusCode != options.expectedStatusCode)
        } catch {
            XCTFail("Received unexpected error: \(error)")
        }
    }

    func testJsonParsing() async {
        guard let rest = RestController.make(urlString: "https://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["error_code": 2, "error_description": "Invalid credentials", "result": 1]
        let (result, _) = await rest.post(json, at: "post")
        do {
            let json = try result.value()
            XCTAssert(json["url"].string == "https://httpbin.org/post")
            if let errorCode = json["json"]["error_code"].int, errorCode != 5 {
                XCTAssert(errorCode == 2)
            } else {
                XCTFail("Error code sent was a 2, should pass")
            }
        } catch {
            XCTFail("Error performing POST: \(error)")
        }
    }
}
