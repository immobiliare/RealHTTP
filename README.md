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

- [1 - Introduction](./Documentation/1.Introduction.md)
- [2 - Build & Execute a Request](./Documentation/2.Build_Request.md#build--execute-a-request)
  - [Initialize a Request](./Documentation/2.Build_Request.md#initialize-a-request)
    - [Standard](./Documentation/2.Build_Request.md#standard)
    - [URI Template](./Documentation/2.Build_Request.md#uri-template)
    - [Builder Pattern](./Documentation/2.Build_Request.md#builder-pattern)
  - [Setup Query Parameters](./Documentation/2.Build_Request.md#setup-query-parameters)
  - [Setup Headers](./Documentation/2.Build_Request.md#setup-headers)
  - [Setup Request Body](./Documentation/2.Build_Request.md#setup-request-body)
    - [URL Query Parameters](./Documentation/2.Build_Request.md#url-query-parameters)
    - [Raw Data & Stream](./Documentation/2.Build_Request.md#raw-data--stream)
    - [Plain Strings](./Documentation/2.Build_Request.md#plain-strings)
    - [JSON Data](./Documentation/2.Build_Request.md#json-data)
    - [Multipart-Form-Data](./Documentation/2.Build_Request.md#multipart-form-data)
  - [The HTTP Client](./Documentation/2.Build_Request.md#the-http-client)
    - [Shared Client](./Documentation/2.Build_Request.md#shared-client)
    - [Custom Client](./Documentation/2.Build_Request.md#custom-client)
  - [Execute a Request](./Documentation/2.Build_Request.md#execute-a-request)
  - [Modify a Request](./Documentation/2.Build_Request.md#modify-a-request)
  - [Cancel a Request](./Documentation/2.Build_Request.md#cancel-a-request)
  - [The HTTP Response](./Documentation/2.Build_Request.md#the-http-response)
    - [Decode using Codable & Custom Decoding](./Documentation/2.Build_Request.md#decode-using-codable--custom-decoding)
    - [Decode Raw JSON using JSONSerialization](./Documentation/2.Build_Request.md#decode-raw-json-using-jsonserialization)
- [3 - Advanced HTTP Client](./Documentation/3.Advanced_HTTPClient.md#advanced-http-client)
  - [Why using a custom HTTPClient](./Documentation/3.Advanced_HTTPClient.md#why-using-a-custom-httpclient)
  - [Validate Responses: Validators](./Documentation/3.Advanced_HTTPClient.md#validate-responses-validators)
    - [Approve the response](./Documentation/3.Advanced_HTTPClient.md#approve-the-response)
    - [Fail with error](./Documentation/3.Advanced_HTTPClient.md#fail-with-error)
    - [Retry with strategy](./Documentation/3.Advanced_HTTPClient.md#retry-with-strategy)
  - [The Default Validator](./Documentation/3.Advanced_HTTPClient.md#the-default-validator)
  - [Custom Validators](./Documentation/3.Advanced_HTTPClient.md#custom-validators)
  - [Retry After [Another] Call](./Documentation/3.Advanced_HTTPClient.md#retry-after-another-call)
- [4 - Handle Large Data Request](./Documentation/4.Handle_LargeData_Requests.md#handle-large-data-request)
  - [Track Progress](./Documentation/4.Handle_LargeData_Requests.m#track-progress)
  - [Cancel Downloads with resumable data](./Documentation/4.Handle_LargeData_Requests.md#cancel-downloads-with-resumable-data)
  - [Resume Downloads](./Documentation/4.Handle_LargeData_Requests.md#resume-downloads)
- [Other Debugging Tools](5.Other_Debugging_Tools.md#other-debugging-tools)
  - [cURL Command Output](5.Other_Debugging_Tools.md#curl-command-output)
  - [Monitor Connection Metrics](5.Other_Debugging_Tools.md#monitor-connection-metrics)
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
