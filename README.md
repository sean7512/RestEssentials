RestEssentials is an extremely lightweight REST and JSON library for Swift 2.2.

**NOTE:** RestEssentials is **NOT** compatible with the beta versions of Swift 2.3 or 3.0. RestEssentials will be updated for Swift 3.0 once it is released.

## Features

- [x] Easily perform asynchronous REST networking calls (GET, POST, PUT, PATCH, or DELETE) that works with JSON
- [x] Full JSON parsing capabilities
- [x] HTTP response validation
- [x] Send custom HTTP headers
- [x] Accept self-signed SSL certificates
- [x] Change timeout options
- [x] Fully native Swift API

## Requirements

- iOS 8.0+
- Xcode 7.0+

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

CocoaPods 0.36 adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate RestEssentials into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'RestEssentials', '~> 1.0.2'
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

### Making a GET Request and parsing the response.

```swift
import RestEssentials

guard let rest = RestController.createFromURLString("http://httpbin.org/get") else {
    print("Bad URL")
    return
}

rest.get { result, httpResponse in
    do {
        let json = try result.value()
        print(json)
        print(json["url"]?.stringValue) // "http://httpbin.org/get"
    } catch {
        print("Error performing GET: \(error)")
    }
}
```

### Making a POST Request and parsing the response.

```swift
import RestEssentials

guard let rest = RestController.createFromURLString("http://httpbin.org/post") else {
    print("Bad URL")
    return
}

def postData = JSON(dict: ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true])
try! rest.post(withJSON: postData) { result, httpResponse in
    do {
        let json = try result.value()
        print(json["url"]?.stringValue) // "http://httpbin.org/post"
        print(json["json"]?["key1"]?.stringValue) // "value1"
        print(json["json"]?["key2"]?.integerValue) // 2
        print(json["json"]?["key3"]?.doubleValue) // 4.5
        print(json["json"]?["key4"]?.boolValue) // true
    } catch {
        print("Error performing POST: \(error)")
    }
}
```

### Making a PUT Request and parsing the response.

```swift
import RestEssentials

guard let rest = RestController.createFromURLString("http://httpbin.org/put") else {
    print("Bad URL")
    return
}

def putData = JSON(dict: ["key1": "value1", "key2": 2, "key3": 4.5, "key4": true])
try! rest.put(withJSON: putData) { result, httpResponse in
    do {
        let json = try result.value()
        print(json["url"]?.stringValue) // "http://httpbin.org/put"
    } catch {
        print("Error performing PUT: \(error)")
    }
}
```

### Other Notes
If the web service you're calling doesn't return any JSON (or you don't need to capture it), then use the alternative functions: <method>IgnoringResponseData (like getIgnoringResponseData or postIgnoringResponseData).

The callbacks are **NOT** on the main thread, JSON parsing should happen in the callback and then passed back to the main thread as needed (after parsing).

Each variation of the calls can take an optional `RestOptions` object, which allow you to configure the expected status return code, optional HTTP headers to include in the request, and the timeout on the request in seconds.

Each variation also allows for a relative path to be used.  If your `RestController` object is for *http://foo.com" you can pass in *some/relative/path* as the first argument, then the request will go to *http://foo.com/some/relative/path*.  This enables you to use a single `RestController` object for all REST calls to the same host.

You can optionally allow the framework to accept a self-signed SSL certificate from the host using the *acceptSelfSignedCertificate* property.  If being used on iOS 9.0+, you must properly configure App Transport Security.

## FAQ

### When should I use RestEssentials?

If you're starting a new project in Swift, and want to take full advantage of its conventions and language features, RestEssentials is a great choice. Although not as fully-featured as Alamofire, AFNetworking, or RestKit, it should satisfy your basic REST needs.  If you only need to perform standard networking options (GET, PUT, POST, DELETE), accept self-signed SSL certificates, send HTTP headers, and you are only ever dealing with JSON (input and output), then RestEssentials is a perfect choice!

> It's important to note that two libraries aren't mutually exclusive: RestEssentials can live in the same project as any other networking library.

### When should I use Alamofire?

Alamofire is a more fully featured networking library and is also written in Swift.  It adds support for multi-part file uploads and the ability to configure your own `NSURLSessionConfiguration` (which most probably won't need to do).

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
