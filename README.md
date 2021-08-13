# IndomioHTTP

IndomioHTTP is a lightweight yet powerful client-side HTTP library.  
Our goal is make an easy to use and effortless http client for Swift.

## Feature Highlights

- Sync/Async & Queued Requests
- Chainable Request/Responses
- Combine Support (Async/Await in progress)
- Retry/timeout control
- URI Template support for parameter's build
- URL/JSON Parameter Encoding
- Multipart file upload along with form values
- Built-in JSON decoding via Codable
- Elegant & Type-Safe request builder
- Upload/Download progress tracker
- Readable URL Metrics tracker
- Export cURL request description
- SSL Pinning
- Basic/Digest Authentication via URLCredentials
- TSL Certificate and Public Key Pinning
- HTTP Chainable Response Validators
- Built-in advanced HTTP Stubber

## Simple HTTP Client

This is how you can make a simple http request:

```swift
let client = HTTPClient(baseURL: "https://official-joke-api.appspot.com")
let joke = HTTPRequest<User>(.get, "/random_jokes")
           .json(["category": category, "count": countJokes])
req.resultPublisher(in: client).sink { joke in
    // decoded Joke object
}
```

If you don't want to use Combine you can also switch seamlessy to promise-like chaianable callbacks. This how you can capture both decoded and raw response:

```swift
joke.run(in: client)
    .response { joke in
        // decoded object
    }.rawResponse { rawResponse in
        // raw response
    }
```

If you don't need to make custom clients but you want to specify for each request an absolute URL you can execute your requests into the shared `HTTPClient` instance. Request are easier to compose:

```swift
HTTPRequest("https://official-joke-api.appspot.com/random_joke").run().setResult { joke in
    // decoded object
}
```

## Simple HTTP Stubber

IndomioHTTP also offer a built-in http stubber useful to mock your network calls for unit testing.  
This is a simple URI matching stub:

```swift
var stubLogin = HTTPStubRequest()
                .match(URI: "https://github.com/malcommac/{repository}")
                .stub(for: .post, delay: 5, json: mockLoginJSON))

HTTPStubber.shared.add(stub: stubLogin)
HTTPStubber.shared.enable()
```

HTTPStubber also support different matchers (regex matcher for url/body, URI template matcher, JSON matcher and more).  
This is an example to match Codable entity for a stub:

```swift
var stubLogin = HTTPStubRequest()
               .match(object: User(userID: 34, fullName: "Mark"))
               .stub(for: .post, delay: 5, json: mockLoginJSON)
```

## ... And More!

But there's lots more features you can use with IndomioHTTP. 
Check out the Documentation section below to learn more!

## Documentation

- [Introduction](./Documentation/Introduction.md)
    - Making Requests
    - Response Handling
    - Response Validation
    - Response Chaining
- HTTP
    - HTTP Methods
    - Parameters & Encoding
    - HTTP Headers
    - Authentication
 - Large Data
     - Downloading to file
    - Uploading to server
 - Tools
     - Obtain Metrics
     - Print Metrics on screen
     - cURL command export
- Advanced
    - HTTPQueue Client
    - Sync Requests
    - Retring Calls
    - Deserializing
- Stub
    - Introduction
    - Add a new stubber request
        - Configure request
        - Create Matcher
        - Built-in Matchers
    - Add ignore rule
## Requirements

IndomioHTTP can be installed in any platform which supports Swift 5.4+ ON:

iOS 13+  
Xcode 12.5+  
Swift 5.4+  

## Installation

To use IndomioHTTP in your project you can use Swift Package Manager (our primary choice) or CocoaPods.

### Swift Package Manager

Aadd it as a dependency in a Swift Package, add it to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/immobiliare/IndomioHTTP.git", from: "1.0.0")
]
```

And add it as a dependency of your target:

```swift
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "https://github.com/immobiliare/IndomioHTTP.git", package: "IndomioHTTP")
    ])
]
```

In Xcode 11+ you can also navigate to the File menu and choose Swift Packages -> Add Package Dependency..., then enter the repository URL and version details.

### CocoaPods

IndomioHTTP can be installed with CocoaPods by adding pod 'IndomioHTTP' to your Podfile.

```ruby
pod 'IndomioHTTP'
```
<a name="#powered"/>

## Powered Apps

IndomioHTTP was created by the amazing mobile team at ImmobiliareLabs, the Tech dept at Immobiliare.it, the first real estate site in Italy.  
We are currently using IndomioHTTP in all of our products.

**If you are using IndomioHTTP in your app [drop us a message](mailto://mobile@immobiliare.it), we'll add below**.

<a name="#support"/>

## Support & Contribute

<p align="center">
Made with ❤️ by <a href="https://github.com/orgs/immobiliare">ImmobiliareLabs</a> and <a href="https://github.com/immobiliare/IndomioHTTP/graphs/contributors">Contributors</a>
<br clear="all">
</p>

We'd love for you to contribute to IndomioHTTP!  
If you have any questions on how to use IndomioHTTP, bugs and enhancement please feel free to reach out by opening a [GitHub Issue](https://github.com/immobiliare/IndomioHTTP/issues).

<a name="#license"/>

## License

IndomioHTTP is licensed under the MIT license.  
See the [LICENSE](./LICENSE) file for more information.
