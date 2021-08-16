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
    - [Architecture Components](./Documentation/Introduction.md#architecture)
- [HTTP Client](./Documentation/HTTPClient.md)
    - [Introduction](./Documentation/HTTPClient.md#introduction)
    - [Create a new client](./Documentation/HTTPClient.md#newclient)
    - [Create a queue client](./Documentation/HTTPClient.md#queueclient)
    - [Response Validators](./Documentation/HTTPClient.md#responsevalidators)
    - [Default Response Validator](./Documentation/HTTPClient.md#defaultvalidator)
    - [Client Configuration](./Documentation/HTTPClient.md#clientconfiguration)
    - [Security](./Documentation/HTTPClient.md#security)
        - [Configure security (SSL/TSL)](./Documentation/HTTPClient.md#configuresecurity)
        - [Allows all certificates](./Documentation/HTTPClient.md#allowsallcerts)
- [HTTP Request](./Documentation/HTTPRequest.md)
    - [Configure a Request](./Documentation/HTTPRequest.md#configurerequest)
    - [Decodable Request](./Documentation/HTTPRequest.md#decodablerequest)
    - [Chainable Configuration](./Documentation/HTTPRequest.md#chainconfiguration)
    - [Set Content](./Documentation/HTTPRequest.md#content)
        - [Set Headers](./Documentation/HTTPRequest.md#headers)
        - [Set Query Parameters](./Documentation/HTTPRequest.md#queryparams)
        - [Set JSON Body](./Documentation/HTTPRequest.md#jsonbody)
        - [Set Form URL Encoded](./Documentation/HTTPRequest.md#formurlencoded)
        - [Set Multipart Form](./Documentation/HTTPRequest.md#multipartform)
    - [Modify an URLRequest](./Documentation/HTTPRequest.md#modifyrequest)
    - [Execute Request](./Documentation/HTTPRequest.md#executerequest)
    - [Cancel Request](./Documentation/HTTPRequest.md#cancelrequest)
    - [Response Handling](./Documentation/HTTPRequest.md#responsehandling)
    - [Response Validation](./Documentation/HTTPRequest.md#responsevalidation)
    - [Upload Large Data](./Documentation/HTTPRequest.md#uploadlargedata)
        - [Upload Multi-part form with stream of file](./Documentation/HTTPRequest.md#multipartstream)
        - [Upload File Stream](./Documentation/HTTPRequest.md#filestream)
    - [Download Large Data](./Documentation/HTTPRequest.md#downloadlargedata)
    - [Track Upload/Download Progress](./Documentation/HTTPRequest.md#trackprogress)
- [Tools](./Documentation/Tools.md)
    - [Gathering/Showing Statistical Metrics](./Documentation/Tools.md#metrics)
    - [cURL Command Output](./Documentation/Tools.md#curl)
- [Network Stubber](./Documentation/Stub.md)
    - [Introduction](./Documentation/Stub.md#introduction)
    - [Stub a Request](./Documentation/Stub.md#stubrequest)
    - [Stub Matchers](./Documentation/Stub.md#stubmatchers)
        - [Custom Matcher](./Documentation/Stub.md#custommatcher)
        - [URI Matcher](./Documentation/Stub.md#urimatcher)
        - [JSON Matcher](./Documentation/Stub.md#jsonmatcher)
        - [Body Matcher](./Documentation/Stub.md#bodymatcher)
        - [URL Matcher](./Documentation/Stub.md#urlmatcher)
    - [Add Ignore Rule](./Documentation/Stub.md#addignorerule)
    - [Unhandled Rules](./Documentation/Stub.md#unhandledrules)
## Requirements

IndomioHTTP can be installed in any platform which supports Swift 5.4+ ON:

- iOS 13+  
- Xcode 12.5+  
- Swift 5.4+  

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
