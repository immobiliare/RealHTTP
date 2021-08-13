# IndomioHTTP

IndomioHTTP is a lightweight yet powerful client-side HTTP library.  
Our goal is make an easy to use and effortless http client for Swift.

## Feature Highlights

- Sync/Async & Queued Requests
- Elegant Request Builder with Chainable Response
- Combine Support *(soon Async/Await!)*
- Retry/timeout, Validators Control
- URI Template support for parameter's build
- URL/JSON, Multipart Form/File Upload
- JSON decoding via Codable
- Upload/Download progress tracker
- URL Metrics Tracker
- cURL Description
- SSL Pinning, Basic/Digest Authentication
- TSL Certificate and Public Key Pinning
- Advanced HTTP Stub

## Simple HTTP Client

Making an async http request is easier than ever:

```swift
HTTPRequest<Joke>("https://official-joke-api.appspot.com/random_joke").run().onResult { joke in
    // decoded Joke object instance
}
```

In this case you are executing a request inside the shared `HTTPClient`, a shared client which manage your requests.  
Sometimes you may need to a more fined grained control.  
Therefore you can create a custom `HTTPClient` to execute all your's webservice network calls sharing a common configuration (headers, cookies, authentication etc.) using the `run(in:)` method.


```swift
let jokeAPIClient = HTTPClient(baseURL: "https://official-joke-api.appspot.com")
let jokesReq = HTTPRequest<User>(.get, "/random_jokes")
               .json(["category": category, "count": countJokes]) // json parameter encoding!

// Instead of callbacks we can also use Combine RX publishers.
jokesReq.resultPublisher(in: jokeAPIClient).sink { joke in
    // decoded Joke object
}

// Get only the raw server response
jokesReq.responsePublisher(in: ).sink { raw in
    // raw response (with metrics, raw data...)
}
```

You can use it with regular callbacks, combine publishers and soon with async/await's Tasks.

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

## ... and more!

But there's lots more features you can use with IndomioHTTP.  
Check out the Documentation section below to learn more!

## Documentation

- [Introduction](./Documentation/Introduction.md)
    - Architecture Components
    - HTTP Client
        - Introduction
        - Create a new client
        - Create a queue client
        - Configure data validators
        - The default validator (`HTTPDefaultValidator`)
        - Client basic configuration
        - Security settings (SSL/TSL)
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

## Authors

- [Daniele Margutti](https://github.com/malcommac)

## License

IndomioHTTP is licensed under the MIT license.  
See the [LICENSE](./LICENSE) file for more information.
