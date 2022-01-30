# RealHTTP

RealHTTP is a lightweight yet powerful async/await based client-side HTTP library made in Swift.  
The goal of this project is to make an easy to use, effortless http client based upon all the best new Swift features.

## What you will get?

This is a simple http call in RealHTTP

```swift
let todo = try await HTTPRequest("https://jsonplaceholder.typicode.com/todos/1")
                     .fetch(Todo.self)
```
One line of code, including the automatic decode from JSON to object.  
Of course you can fully configure the request with many other parameters, we'll take a closer look below.

## What about the stubber?
Integrated stubber is perfect to write your own test suite:

That's a simple stubber which return the original request as response:

```swift        
let echoStub = HTTPStubRequest().match(urlRegex: "*").stubEcho()
HTTPStubber.shared.add(stub: echoStub)
HTTPStubber.shared.enable()
```
That's all!

## Feature Highlights

RealHTTP offers lots of features and customization you can found in our extensive documentation and test suite.  
Some of them are:

- **Async/Await** native support
- **Requests queue** built in
- Based upon **native URLSession** technology
- Advanced **retry mechanisms**
- Chainable & customizable **response validators** like Node's Express.js
- Automatic **Codable object encoding/decoding**
- **Customizable decoding** of objects

And for pro users:

- Powerful integrated **HTTP Stub** for your mocks
- **Combine** publisher adapter 
- **URI templating** system
- **Resumable download/uploads** with progress tracking
- Native **Multipart Form Data** support
- Advanced URL **connection metrics** collector
- **SSL Pinning**, Basic/Digest Auth
- **TSL Certificate** & Public Key Pinning
- **cURL** debugger

## Documentation

RealHTTP is provided with an extensive documentation.  

- [Introduction](./Documentation/1.Introduction.md)
- [Build a Request](Documentation/2.Build_Request.md)

## Test

RealHTTP has an extensive unit test suite which covers many of the standard and edge cases including request build, parameter encoding, queuing and retry strategies.  
See the XCTest suite inside `Tests/RealHTTPTests` folder.

## Requirements

RealHTTP can be installed in any platform which supports:

- iOS 13+, macOS Catalin+, watchOS 6+, tvOS 13+
- Xcode 13.2+ 
- Swift 5.5+  

## Installation

### Swift Package Manager

Aadd it as a dependency in a Swift Package, add it to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/immobiliare/RealHTTP.git", from: "1.0.0")
]
```

And add it as a dependency of your target:

```swift
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "https://github.com/immobiliare/RealHTTP.git", package: "RealHTTP")
    ])
]
```

In Xcode 11+ you can also navigate to the File menu and choose Swift Packages -> Add Package Dependency..., then enter the repository URL and version details.

### CocoaPods

RealHTTP can be installed with CocoaPods by adding pod 'RealHTTP' to your Podfile.

```ruby
pod 'RealHTTP'
```

## Powered Apps

RealHTTP was created by the amazing mobile team at ImmobiliareLabs, the Tech dept at Immobiliare.it, the first real estate site in Italy.  
We are currently using RealHTTP in all of our products.

**If you are using RealHTTP in your app [drop us a message](mailto:mobile@immobiliare.it), we'll add below**.

<a href="https://apps.apple.com/us/app/immobiiiare-it-indomio/id335948517"><img src="./Documentation/immobiliare-app.png" alt="Indomio" width="270"/></a>

## Support & Contribute

Made with ❤️ by [ImmobiliareLabs](https://github.com/orgs/immobiliare) & [Contributors](https://github.com/immobiliare/RealHTTP/graphs/contributors)

We'd love for you to contribute to RealHTTP!  
If you have any questions on how to use RealHTTP, bugs and enhancement please feel free to reach out by opening a [GitHub Issue](https://github.com/immobiliare/RealHTTP/issues).
