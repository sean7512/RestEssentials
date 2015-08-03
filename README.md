RestEssentials is an extremely lightweight REST and JSON library for Swift.

## Features

- [x] Easily perform asynchronous REST networking calls that works with JSON
- [x] Full JSON parsing capabilities
- [x] HTTP Response Validation

## Requirements

- iOS 7.0+
- Xcode 7.0 (currently beta 4)

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/restessentials). (Tag 'restessentials')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/restessentials).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

> **Embedded frameworks require a minimum deployment target of iOS 8**
>
> To use RestEssentials with a project targeting iOS 7, you must include all Swift files located inside the `Source` directory directly in your project. See the ['Source File'](#source-file) section for additional instructions.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.

CocoaPods 0.36 adds supports for Swift and embedded frameworks. You can install it with the following command:

```bash
$ gem install cocoapods
```

Integration with CocoaPods is coming soon!

### Manually

If you prefer not to use either of the aforementioned dependency managers, you can integrate RestEssentials into your project manually.

#### Embedded Framework

- Add RestEssentials as a [submodule](http://git-scm.com/docs/git-submodule) by opening the Terminal, `cd`-ing into your top-level project directory, and entering the following command:

```bash
$ git submodule add https://github.com/sean7512/RestEssentials.git
```

- Open the new `RestEssentials` folder, and drag the `RestEssentials.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `RestEssentials.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.

- And that's it!

> The `RestEssentials.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

#### Source File

For application targets that do not support embedded frameworks, such as iOS 7, RestEssentials can be integrated by adding all the Swift files located inside the `Source` directory (`Source/*.swift`) directly into your project. Note that you will no longer need to `import RestEssentials` since you are not actually loading a framework.

---

## Usage

### Making a Request

## Credits

RestEssentials is owned and maintained by the [Sean K](https://github.com/sean7512).

## License

RestEssentials is released under the MIT license. See LICENSE for details.
