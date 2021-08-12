# IndomioHTTP

IndomioHTTP is a lightweight yet powerful client-side HTTP library.  
Our goal is make an easy to use and effortless http client for Swift.

## Features

- Sync/Async & Queued Requests
- Chainable Request/Responses
- Combine Support (Async/Await in progress)
- Retry/timeout control
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

## What You Get

This is how you can make a simple http request:

```swift
let client = HTTPClient(baseURL: "...")
let login = HTTPRequest<User>(.post, "/login")
            .json(["username": username, "password": pwd])
login.run(in: client).response { loggedUser in
    // do something
}
```