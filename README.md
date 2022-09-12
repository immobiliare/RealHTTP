<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./Documentation/assets/realhttp-dark.png" width="350">
  <img alt="logo-library" src="./Documentation/assets/realhttp-light.png" width="350">
</picture>
</p>

[![Swift](https://img.shields.io/badge/Swift-5.3_5.4_5.5_5.6-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.3_5.4_5.5_5.6-Orange?style=flat-square)
[![Platform](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20Linux-4E4E4E.svg?colorA=28a745)](#installation)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/RealHTTP.svg?style=flat-square)](https://img.shields.io/cocoapods/v/RealHTTP.svg)

RealHTTP is a lightweight yet powerful async-based HTTP library made in Swift.  
This project aims to make an easy-to-use, effortless HTTP client based on all the best new Swift features.

## What will you get?

Below is a simple HTTP call in RealHTTP.

```swift
let todo = try await HTTPRequest("https://jsonplaceholder.typicode.com/todos/1")
           .fetch(Todo.self)
```
One line of code, including the automatic decode from JSON to object.  

Of course, you can fully configure the request with many other parameters. Take a look here:

```swift
let req = HTTPRequest {
  // Setup default params
  $0.url = URL(string: "https://.../login")!
  $0.method = .post
  $0.timeout = 15

  // Setup some additional settings
  $0.redirectMode = redirect
  $0.maxRetries = 4
  $0.headers = HTTPHeaders([
    .init(name: .userAgent, value: myAgent),
    .init(name: "X-API-Experimental", value: "true")
  ])
   
  // Setup URL query params & body
  $0.addQueryParameter(name: "full", value: "1")
  $0.addQueryParameter(name: "autosignout", value: "30")
  $0.body = .json(["username": username, "pwd": pwd])
}
let _ = try await req.fetch()
```

The code is fully type-safe.

## What about the stubber?
Integrated stubber is perfect to write your own test suite:

That's a simple stubber which return the original request as response:

```swift     
let echoStub = HTTPStubRequest().match(urlRegex: "*").stubEcho()
HTTPStubber.shared.add(stub: echoStub)
HTTPStubber.shared.enable()
```

Of course you can fully configure your stub with rules (regex, URI template and more):

```swift
// This is a custom stubber for any post request.
var stub = HTTPStubRequest()
      .stub(for: .post, { response in
        response.responseDelay = 5
        response.headers = HTTPHeaders([
          .contentType: HTTPContentType.bmp.rawValue,
          .contentLength: String(fileSize,
        ])
        response.body = fileContent
      })
HTTPStubber.shared.add(stub: stub)
```

That's all!

## Feature Highlights

RealHTTP offers lots of features and customization you can find in our extensive documentation and test suite.  
Some of them are:

- **Async/Await** native support
- **Requests queue** built-in
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

RealHTTP provides an extensive documentation.  

- [**1 - Introduction**](./Documentation/1.Introduction.md)
- [**2 - Build & Execute a Request**](./Documentation/2.Build_Request.md#build--execute-a-request)
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
- [**3 - Advanced HTTP Client**](./Documentation/3.Advanced_HTTPClient.md#advanced-http-client)
   - [Why using a custom HTTPClient](./Documentation/3.Advanced_HTTPClient.md#why-using-a-custom-httpclient)
   - [Validate Responses: Validators](./Documentation/3.Advanced_HTTPClient.md#validate-responses-validators)
      - [Approve the response](./Documentation/3.Advanced_HTTPClient.md#approve-the-response)
      - [Fail with error](./Documentation/3.Advanced_HTTPClient.md#fail-with-error)
      - [Retry with strategy](./Documentation/3.Advanced_HTTPClient.md#retry-with-strategy)
   - [The Default Validator](./Documentation/3.Advanced_HTTPClient.md#the-default-validator)
   - [Alt Request Validator](./Documentation/3.Advanced_HTTPClient.md#alt-request-validator)
   - [Custom Validators](./Documentation/3.Advanced_HTTPClient.md#custom-validators)
   - [Retry After [Another] Call](./Documentation/3.Advanced_HTTPClient.md#retry-after-another-call)
- [**4 - Handle Large Data Request**](./Documentation/4.Handle_LargeData_Requests.md#handle-large-data-request)
   - [Track Progress](./Documentation/4.Handle_LargeData_Requests.m#track-progress)
   - [Cancel Downloads with resumable data](./Documentation/4.Handle_LargeData_Requests.md#cancel-downloads-with-resumable-data)
   - [Resume Downloads](./Documentation/4.Handle_LargeData_Requests.md#resume-downloads)
- [**5 - Security Options**](./Documentation/5.Security_Options.md#security-options)
   - [Configure security (SSL/TSL)](./Documentation/5.Security_Options.md#configure-security-ssltsl)
   - [Self-Signed Certificates](./Documentation/5.Security_Options.md#self-signed-certificates)
- [**6 - Other Debugging Tools**](./Documentation/6.Other_Debugging_Tools.md#other-debugging-tools)
   - [cURL Command Output](./Documentation/6.Other_Debugging_Tools.md#curl-command-output)
   - [Monitor Connection Metrics](./Documentation/6.Other_Debugging_Tools.md#monitor-connection-metrics)
- [**7 - HTTP Stubber**](./Documentation/7.Stubber.md#http-stubber)
   - [Using HTTPStubber in your unit tests](./Documentation/7.Stubber.md#using-httpstubber-in-your-unit-tests)
   - [Stub a Request](./Documentation/7.Stubber.md#stub-a-request)
   - [Stub Matchers](./Documentation/7.Stubber.md#stub-matchers)
      - [Echo Matcher](./Documentation/7.Stubber.md#echo-matcher)
      - [Dynamic Matcher](./Documentation/7.Stubber.md#dynamic-matcher)
      - [URI Matcher](./Documentation/7.Stubber.md#uri-matcher)
      - [JSON Matcher](./Documentation/7.Stubber.md#json-matcher)
      - [Body Matcher](./Documentation/7.Stubber.md#body-matcher)
      - [URL Matcher](./Documentation/7.Stubber.md#url-matcher)
      - [Custom Matcher](./Documentation/7.Stubber.md#custom-matcher)
   - [Add Ignore Rule](./Documentation/7.Stubber.md#add-ignore-rule)
   - [Unhandled Rules](./Documentation/7.Stubber.md#unhandled-rules)
   - [Bad and down network](./Documentation/7.Stubber.md#bad-and-down-network)
      - [Simulate Network Conditions](./Documentation/7.Stubber.md#simulate-network-conditions)
      - [Simulate a down network](./Documentation/7.Stubber.md#simulate-a-down-network)
         
## API Reference

RealHTTP is fully documented at source-code level. You'll get autocomplete with doc inside XCode for free; moreover you can read the full Apple's DoCC Documentation automatically generated thanks to [**Swift Package Index**](https://swiftpackageindex.com) Project from here:

👉 [API REFERENCE](https://swiftpackageindex.com/immobiliare/RealHTTP)
## Test Suite

RealHTTP has an extensive unit test suite covering many standard and edge cases, including request build, parameter encoding, queuing, and retries strategies.  
See the XCTest suite inside `Tests/RealHTTPTests` folder.

## Requirements

RealHTTP can be installed on any platform which supports:

- iOS 13+, macOS Catalina+, watchOS 6+, tvOS 13+
- Xcode 13.2+ 
- Swift 5.5+  

## Installation

### Swift Package Manager

Add it as a dependency in a Swift Package, and add it to your Package. Swift:

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

The fantastic mobile team at ImmobiliareLabs created RealHTTP.
We are currently using RealHTTP in all of our products.

**If you are using RealHTTP in your app [drop us a message](mailto:mobile@immobiliare.it)**.

## Support & Contribute

Made with ❤️ by [ImmobiliareLabs](https://github.com/orgs/immobiliare) & [Contributors](https://github.com/immobiliare/RealHTTP/graphs/contributors)

We'd love for you to contribute to RealHTTP!  
If you have questions about using RealHTTP, bugs, and enhancement, please feel free to reach out by opening a [GitHub Issue](https://github.com/immobiliare/RealHTTP/issues).

<a href="https://apps.apple.com/us/app/immobiiiare-it-indomio/id335948517"><img src="./Documentation/assets/immobiliarelabs.png" alt="Indomio" width="200"/></a>