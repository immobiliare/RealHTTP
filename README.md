# RealHTTP

RealHTTP is a lightweight yet powerful async/await based client-side HTTP library made in Swift.  
The goal of this project is to make an easy to use, effortless http client based upon all the best new Swift features.

## What you will get?

This is a simple http call in RealHTTP

```swift
let todo: Todo? = try await HTTPRequest("https://jsonplaceholder.typicode.com/todos/1").fetch(Todo.self)
```
One line of code, including the automatic decode from JSON to object.  
Of course you can fully configure the request with many other parameters, that's just a silly example.

## What's about the stubber?
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
- **URI templating** system
- **Resumable download/uploads** with progress tracking
- Native **Multipart Form Data** support
- Advanced URL **connection metrics** collector
- **SSL Pinning**, Basic/Digest Auth
- **TSL Certificate** & Public Key Pinning
- **cURL** debugger
