RestEssentials is an extremely lightweight REST and JSON library for Swift and can be used on iOS, tvOS, and watchOS.

## Features

- [x] Easily perform asynchronous REST networking calls (GET, POST, PUT, PATCH, or DELETE) that send JSON
- [x] Natively integrates with Swift's Decodable and Encodable types
- [x] Supports JSON, Void, UIImage, and Data resposne types
- [x] Full JSON parsing capabilities
- [x] HTTP response validation
- [x] Send custom HTTP headers
- [x] Accept self-signed SSL certificates
- [x] Change timeout options
- [x] Response type handling can be extended via new Protocol implementation
- [x] Fully native Swift API

## Requirements

RestEssentials works with any of the supported operating systems listed below with the version of Xcode.

- iOS 8.0+
- tvOS 9.0+
- watchOS 2.0+
- Xcode 9.0+

## Swift Version Compatibility

RestEssentials is **ONLY** compatible with Swift 4 and above. See below for a list of recommended versions for your version of Swift:
- Swift 4             -> RestEssentials 4.0.2
- Swift 3             -> RestEssentials 3.1.0
- Swift 2.3          -> Not Supported
- Swift 2.0-2.2   -> RestEssentials 2.0.0
- Swift 1             -> RestEssentials 1.0.2

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/restessentials). (Tag 'restessentials')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/restessentials).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

> **Embedded frameworks require a minimum deployment target of iOS 8**

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects and is the preferred method of installation.

Install the latest version of CocoaPods with the following command:

```bash
$ sudo gem install cocoapods
```

To integrate RestEssentials into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
    pod 'RestEssentials', '~> 4.0.2'
end
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use CocoaPods, you can integrate RestEssentials into your project manually.

#### Embedded Framework

- Add RestEssentials as a [submodule](http://git-scm.com/docs/git-submodule) by opening the Terminal, `cd`-ing into your top-level project directory, and entering the following command:

```bash
$ git submodule add https://github.com/sean7512/RestEssentials.git
```

- Open the new `RestEssentials` folder, and drag the `RestEssentials.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `RestEssentials.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.

- And that's it!

> The `RestEssentials.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

#### Source File

If you prefer to rock it old-school, RestEssentials can be integrated by adding all the Swift files located inside the `Source` directory (`Source/*.swift`) directly into your project. Note that you will no longer need to `import RestEssentials` since you are not actually loading a framework.

---

## Usage
RestEssentials is **best** used with Swift 4's native JSON support (using the Codable/Encodabe/Decodable protocols).  RestEssentials can be used with the built-in JSON parsing and support if your code doesn't use the new Codable protocol.

The use of the built-in JSON object in RestEssentials and Swift 4's Codable are interchangeable (you can post JSON and expect a Codable object back or you can post a Codable object and get any response type back).

### Making a GET Request and getting back a Swift 4 Codable object
```swift
import RestEssentials

struct HttpBinResponse: Codable {
    let url: String
}

guard let rest = RestController.make(urlString: "http://httpbin.org/get") else {
    print("Bad URL")
    return
}

rest.get(HttpBinResponse.self) { result, httpResponse in
    do {
        let response = try result.value() // response is of type HttpBinResponse
        print(response.url) // "http://httpbin.org/get"
    } catch {
        print("Error performing GET: \(error)")
    }
}
```

### Making a POST Request using a Swift 4 Codable object and getting back a Swift 4 *Codable* object
```swift
import RestEssentials

// httpbin returns json with the url and the posted data under a key called "json"
struct HttpBinResponse: Codable {
    let url: String
    let json: Car
}

struct Car: Codable {
    let make: String
    let model: String
    let year: Int
}

guard let rest = RestController.make(urlString: "http://httpbin.org") else {
    print("Bad URL")
    return
}

let myCar = Car(make: "Jeep", model: "Grand Cherokee", year: 2017)
rest.post(myCar, at: "post", responseType: HttpBinResponse.self) { result, httpResponse in
    do {
        let response = try result.value() // response is of type HttpBinResponse
        let car = response.json // car is of type Car
    } catch {
        print("Error performing GET: \(error)")
    }
}
```

### Making a GET Request and parsing the response as raw JSON (not using Swift 4's Codable)

```swift
import RestEssentials

guard let rest = RestController.make(urlString: "http://httpbin.org/get") else {
    print("Bad URL")
    return
}

rest.get(withDeserializer: JSONDeserializer()) { result, httpResponse in
    do {
        let json = try result.value()
        print(json["url"].string) // "http://httpbin.org/get"
    } catch {
        print("Error performing GET: \(error)")
    }
}
```

### Making a POST Request and parsing the response (not using Swift 4's Codable)

```swift
import RestEssentials

guard let rest = RestController.make(urlString: "http://httpbin.org") else {
    print("Bad URL")
    return
}

let postData: JSON = ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true, "key5": [1, 2, 3, 4]]
rest.post(json, at: "post") { result, httpResponse in { result, httpResponse in
    do {
        let json = try result.value()
        print(json["url"].string // "http://httpbin.org/post"
        print(json["json"]["key1"].string // "value1"
        print(json["json"]["key2"].int // 2
        print(json["json"]["key3"].double // 4.5
        print(json["json"]["key4"].bool // true
        print(json["json"]["key5"][2].numerical // 3
        print(json["json"]["key6"].string // nil
    } catch {
        print("Error performing POST: \(error)")
    }
}
```

### Making a PUT Request and parsing the response (not using Swift 4's Codable)

```swift
import RestEssentials

guard let rest = RestController.make(urlString: "http://httpbin.org/put") else {
    print("Bad URL")
    return
}

let putData: JSON = ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true]
rest.put(putData) { result, httpResponse in
    do {
        let json = try result.value()
        print(json["url"].string) // "http://httpbin.org/put"
    } catch {
        print("Error performing PUT: \(error)")
    }
}
```

### Making a GET Request for an image

```swift
import RestEssentials

guard let rest = RestController.make(urlString: "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png") else {
    print("Bad URL")
    return
}

rest.get(withDeserializer: ImageDeserializer()) { result, httpResponse in
    do {
        let img = try result.value()
        let isImage = img is UIImage // true
    } catch {
        print("Error performing GET: \(error)")
    }
}
```

### Error Handling
When attempting to retrieve the result value (```try result.value()```), any errors that occurred will be thrown here.  The errors may be one of the built-in ```NetworkingError``` types or they may be ones from Foundation (especially if you are using the ```Codable``` protocol).  The built in error definitions are below for your convenience.

```swift
/// Errors related to the networking for the `RestController`
public enum NetworkingError: Error {
    /// Indicates the server responded with an unexpected status code.
    /// - parameter Int: The status code the server respodned with.
    /// - parameter Data?: The raw returned data from the server
    case unexpectedStatusCode(Int, Data?)

    /// Indicates that the server responded using an unknown protocol.
    /// - parameter Data?: The raw returned data from the server
    case badResponse(Data?)

    /// Indicates the server's response could not be deserialized using the given Deserializer.
    /// - parameter Data: The raw returned data from the server
    case malformedResponse(Data)

    /// Inidcates the server did not respond to the request.
    case noResponse
}
```
For information on the ```Codable``` errors, you can vew Apple's documentation at https://developer.apple.com/documentation/swift/encodingerror and https://developer.apple.com/documentation/swift/decodingerror

### Other Notes
If the web service you're calling doesn't return any JSON (or you don't need to capture it), then use the `VoidDeserializer`.  If you want to return a different data type other than a Decodable, JSON, Data, or UIImage; create a new implementation of `Deserializer` and use that.

The callbacks are **NOT** guranteed to be on the main thread (or the calling thread), JSON parsing should happen in the callback and then passed back to the main thread as needed (after parsing).

There is an alternative static function to instantiate a `RestController` object: `make:URL` This variation does not return an `Optional` like the `String` version.  This is useful for easily constructing your URL with query parameters (typically for a `GET` request).

All of the operations can take an optional `RestOptions` object, which allow you to configure the expected HTTP status code, optional HTTP headers to include in the request, and the timeout on the request in seconds.

All of the operations can also take a relative path to be used.  If your `RestController` object is for *http://foo.com* you can pass in *some/relative/path*, then the request will go to *http://foo.com/some/relative/path*.  This enables you to use a single `RestController` object for all REST calls to the same host.  This **IS** the preferred behavior isntead of creating a new `RestController` for every call.

You can optionally allow the framework to accept a self-signed SSL certificate from the host using the *acceptSelfSignedCertificate* property on the `RestController` instance.  If being used on iOS 9.0+, you must properly configure App Transport Security.

## FAQ

### When should I use RestEssentials?

If you're starting a new project in Swift, and want to take full advantage of its conventions and language features, RestEssentials is a great choice. Although not as fully-featured as Alamofire, AFNetworking, or RestKit, it should satisfy your basic REST needs.  If you only need to perform standard networking options (GET, PUT, POST, DELETE), accept self-signed SSL certificates, send HTTP headers, and you are only ever dealing with JSON as input (and any data type as the output), then RestEssentials is the perfect choice!

> It's important to note that two libraries aren't mutually exclusive: RestEssentials can live in the same project as any other networking library.

### When should I use Alamofire?

Alamofire is a more fully featured networking library and is also written in Swift.  It adds support for multi-part file uploads and the ability to configure your own `URLSessionConfiguration` (which most probably won't need to do).

### When should I use AFNetworking?

AFNetworking remains the premiere networking library available for OS X and iOS, and can easily be used in Swift, just like any other Objective-C code. AFNetworking is stable and reliable, and isn't going anywhere.

Use AFNetworking for any of the following:

- UIKit extensions, such as asynchronously loading images to `UIImageView`
- Network reachability monitoring, using `AFNetworkReachabilityManager`

### When should I use RestKit?

RestKit is a very advanced library that is build ontop of AFNetworking and offers very advanced features such as automatic JSON mapping to classes.  RestKit is also an Objective-C library, but it is easily usable in your Swift projects.

* * *

## Credits

RestEssentials is owned and maintained by [Sean K](https://github.com/sean7512).

## License

RestEssentials is released under the MIT license. See LICENSE for details.
