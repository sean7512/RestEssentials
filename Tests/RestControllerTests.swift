//
//  RestEssentialsTests.swift
//  RestEssentialsTests
//
//  Created by Sean Kosanovich on 7/30/15.
//  Copyright © 2016 Sean Kosanovich. All rights reserved.
//

import XCTest
@testable import RestEssentials

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

    func testGET() {
        let expectation = self.expectation(description: "GET JSON network call")

        guard let rest = RestController.make(urlString: "http://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }

        rest.get(HttpBinResponse.self) { result, httpResponse in
            do {
                let response = try result.value()
                XCTAssert(response.url == "http://httpbin.org/get")

                expectation.fulfill()
            } catch {
                XCTFail("Error performing GET: \(error)")
            }
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }
    
    func testGETGenericJSON() {
        let expectation = self.expectation(description: "GET JSON network call")

        guard let rest = RestController.make(urlString: "http://httpbin.org/get") else {
            XCTFail("Bad URL")
            return
        }


        rest.get(withDeserializer: JSONDeserializer()) { result, httpResponse in
            do {
                let json = try result.value()
                XCTAssert(json["url"].string == "http://httpbin.org/get")

                expectation.fulfill()
            } catch {
                XCTFail("Error performing GET: \(error)")
            }
        }
        
        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }
    
    func testPOST() {
        let expectation = self.expectation(description: "POST JSON network call")

        guard let rest = RestController.make(urlString: "http://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true, "key5": [1, 2, 3, 4]]
        rest.post(json, at: "post") { result, httpResponse in
            do {
                let json = try result.value()
                XCTAssert(json["url"].string == "http://httpbin.org/post")
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

                expectation.fulfill()
            } catch {
                XCTFail("Error performing POST: \(error)")
            }
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }

    func testPUT() {
        let expectation = self.expectation(description: "PUT JSON network call")

        guard let rest = RestController.make(urlString: "http://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        rest.put(JSON(dict: ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true]), at: "put") { result, httpResponse in
            do {
                let json = try result.value()
                XCTAssert(json["url"].string == "http://httpbin.org/put")

                expectation.fulfill()
            } catch {
                XCTFail("Error performing PUT: \(error)")
            }
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }

    func testGetImage() {
        let expectation = self.expectation(description: "GET Image network call")

        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        rest.get(withDeserializer: ImageDeserializer()) { result, httpResponse in
            do {
                let img = try result.value()
                XCTAssert(img is UIImage)

                expectation.fulfill()
            } catch {
                XCTFail("Error performing GET: \(error)")
            }
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }

    func testVoidResponse() {
        let expectation = self.expectation(description: "GET Void network call")

        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        rest.get(withDeserializer: VoidDeserializer()) { _, httpResponse in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }

    func testDataResponse() {
        let expectation = self.expectation(description: "GET Data network call")

        guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
            XCTFail("Bad URL")
            return
        }

        rest.get(withDeserializer: DataDeserializer()) { result, httpResponse in
            do {
                let data = try result.value()
                XCTAssert(data is Data)

                expectation.fulfill()
            } catch {
                XCTFail("Error performing GET: \(error)")
            }
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }

    func testDecodableResponse() {
        let expectation = self.expectation(description: "POST JSON network call and decodable object is returned")

        guard let rest = RestController.make(urlString: "http://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let json: JSON = ["someString": "value1", "someInt": 2, "someDouble": 4.5, "someBoolean": true, "someNumberArray": [1, 2, 3, 4]]
        rest.post(json, withDeserializer: JSONDecodableDeserializer<HttpBinResponse>(), at: "post") { result, httpResponse in
            do {
                let response = try result.value()
                XCTAssert(response is HttpBinResponse)
                XCTAssert(response.url == "http://httpbin.org/post")
                XCTAssert(response.json?.someString == "value1")
                XCTAssert(response.json?.someInt == 2)
                XCTAssert(response.json?.someDouble == 4.5)
                XCTAssert(response.json?.someBoolean == true)
                XCTAssert(response.json?.someNumberArray[2] == 3)

                expectation.fulfill()
            } catch {
                XCTFail("Error performing POST: \(error)")
            }
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }

    func testEncodableObject() {
        let expectation = self.expectation(description: "POST JSON network call and decodable object is returned")

        guard let rest = RestController.make(urlString: "http://httpbin.org") else {
            XCTFail("Bad URL")
            return
        }

        let someObject = SomeObject(someString: "value1", someInt: 2, someDouble: 4.5, someBoolean: true, someNumberArray: [1, 2, 3, 4])
        rest.post(someObject, withDeserializer: JSONDecodableDeserializer<HttpBinResponse>(), at: "post") { result, httpResponse in
            do {
                let response = try result.value()
                XCTAssert(response is HttpBinResponse)
                XCTAssert(response.url == "http://httpbin.org/post")
                XCTAssert(response.json?.someString == someObject.someString)
                XCTAssert(response.json?.someInt == someObject.someInt)
                XCTAssert(response.json?.someDouble == someObject.someDouble)
                XCTAssert(response.json?.someBoolean == someObject.someBoolean)
                XCTAssert(response.json?.someNumberArray[2] == someObject.someNumberArray[2])

                expectation.fulfill()
            } catch {
                XCTFail("Error performing POST: \(error)")
            }
        }

        waitForExpectations(timeout: 5) { (error) -> Void in
            if let _ = error {
                XCTFail("Test timeout reached")
            }
        }
    }
}
