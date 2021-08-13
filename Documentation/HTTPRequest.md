# HTTP Request

- Introduction
- Run Requests
- Configure a Request
- Chainable Configuration
    - Set Request Headers
    - Set Request Content
    - Set Query Parameters
    - Set JSON Body
    - Set Form URL Encoded
    - Set Multipart Form

## Introduction

IndomioHTTP provides a variety of convenience methods for making HTTP requests.  
At the simplest, just provide a String that can be converted into a URL:

```swift
HTTPRequest("https://httpbin.org/get").run().onResponse { result in
    print(result.content.data) // print the body
}
```

If you plan to create a group of request for a same web service we suggest creating an `HTTPClient` instance where you will `run()` the requests. It allows you to manage your session easily along with its configuration.

You can create 2 kind of requests:
- `HTTPRawRequest`: you can use it if you don't need to use the automatic data decoder which transform a raw response in an object (like for example using Codable protocol or a custom one). This request just return the `HTTPRawResponse` object.
- `HTTPRequest<Object: HTTPDecodableResponse>`: allows you to directly perform the call and execute parsing to return a valid businnes object.

> NOTE: Both the objects have the same properties and methods (in fact the first one is just a typealias for `HTTPRequest<HTTPRawResponse>`).

## Run Requests

To execute a request you can use the `run()` function. 
There are 3 different mode to execute a request:

- `run(in: HTTPClientProtocol)`: execute the request inside the session of an `HTTPClient` instance.
- `runSync(in: HTTPClientProtocol)`: run the call synchronously (blocking the caller thread, useful for testing purpose) inside the session of an `HTTPClient` instance.

The same methods are also available when you don't need of a client and you want to execute them into the `HTTPClient.shared` instance:

- `run()`
- `runSync()`

> NOTE: `*sync()` versions block the caller thread

## Configure a Request

Request can be configure by using chainable functions or directly by setting their properties.  
By default you can init for a `HTTPRequest` using no parameters or one of the following options:

```swift
// Empty init (use chainable functions to configure the object)
init()
// Standard init with HTTP Method and route
init(_ method: HTTPMethod = .get, _ route: String = "")
// Initialization with URI template
init(_ method: HTTPMethod = .get, URI template: String, variables: [String: Any])
```

- `method`: specify the `HTTPMethod` ([RFC 7231 §4.3](https://tools.ietf.org/html/rfc7231#section-4.3)) you need to execute the call (if not specified `.get` is used)
- `route`: this is the URL of the request. If you are using a custom `HTTPClient` you can set the path to your service (ie. `/login/user` and the full path will be composed along with the client's `baseURL`). You can also set the full URL in order to avoid composition (ie. `http://myws.com/login/user`).

```swift
let client = HTTPClient(baseURL: "https://official-joke-api.appspot.com")
let request = HTTPRequest(.post, "new/joke")

request.run(in: client) // url is composed as https://official-joke-api.appspot.com/new/joke
```

If you want you can init a new request by using the URI Template too (conform to [RFC6570](ttps://tools.ietf.org/html/rfc6570)):

```swift
let req = HTTPRawRequest(.get, URI: "http://www.apple.com/{type}/{value}", 
                         variables: ["type": "mac", "value": 15]) // expand variables
req.run() // execute with absolute url in shared client
```

## Chainable Configuration

`HTTPRequest` can be configured by using chainable configurations; several methods allows you to make a chain to configure parameters of the request:

```swift
let client = HTTPClient(baseURL: "https://myws.com/service/v2")
let req = HTTPRequest<User>()
            .method(.post) // set HTTP to POST
            .maxRetries(3) // if connection error occurred it retry for a max of 3 times
            .route("/agents/login") // compose the url with baseURL of the client
            .json(["username": user, "password": pwed]) // JSON encoding parameterss

req.run(in: client).onResult { result in
    switch result {
    case .success(let user):
        // do something with decoded User instance
    case .failure(let error):
        // an error occurred
    }
}
```

The following methods allows you to configure every aspect of the request (all methods return `Self` to allows chain):

- `method(HTTPMethod)` to set the appropriate `HTTPMethod` for the request.
- `route(String)` to set the route (relative/absolute) to the web service.
- `timeout(TimeInterval)` to set the timeout of the call.
- `maxRetries(Int)` to set the maximum number of retries to make if recoverable error has found.
- `security(HTTPSecurityProtocol)` to attach security settings to the request.
- `header(HTTPHeaderField, String)` to add/replace an existing header field (type safe, `HTTPHeaderField`).
- `headers()` to create a builder callback to configure in a single call all the headers of the call.

## Set Request Headers

Headers can be set one by line:

```swift
req.header(.acceptLanguage, "it-it") // set Accept-Language
   .header(.contentEncoding, "utf-8") // set Content-Encoding
```

or via builder callback:

```swift
req.headers {
    $0[.acceptLanguage] = "it-it"
    $0[.userAgent] = "my-agent"
    $0[.contentEncoding] = "utf-8"
}
```

All `HTTPHeader`s field are available under the `HTTPHeaderField` enum.  
If you need to set a custom field not available into the list just pass a `String` as key:

```swift
req.header("X-MyHeader", "SomeValue")
// or
req.headers {
    $0["X-MyHeader"] = "SomeValue"
}
```

## Set Request Content

IndomioHTTP provides a variety of methods to configure the content of a request; built in services includes:

- JSON body configuration
- Form URL Encoded
- Query Parameters
- Multipart Form Data / File Upload

### Set Query Parameters

Setting query parameters which are added to the composed URL (`baseURL` + `route` or just absolute `route`) is pretty easy with the `query()` function:

```swift
let client = HTTPClient(baseURL: "https://myws.com/service/v2")
let req = HTTPRequest<Search>()
          .method(.post)
          .route("/search")
          .query(["type": "poi", "max": 5, "date": Date(), "disabled": false])
```

It produces the following POST request:

```
https://myws.com/service/v2/search?date=2021-08-13%2013%3A55%3A42%20%2B0000&disabled=0&max=5&type=poi
```

As you can see IndomioHTTP provides to you automatic object conversion and parameter encoding. The encoding process is made by an instance of `URLParametersData` generated for you.  
You can configure this object anytime by setting the following options:

- `arrayEncoding: ArrayEncodingStyle`: by default array values are encoded via `key[]=value` brackets. You can also choose `.noBrackets` to avoid this behaviour.
- `boolEncoding: BoolEncodingStyle`: by default boolean values are transformed to numbers (`.asNumbers`: `1` for `true`, `0` for `false`). You can also use `.asLiterals` to convert them in strings `true/false`.

To configure these parameters you need to replace `query()` with

```swift
let req = HTTPRequest<Search>(.post, "/search")
          .query(...)
          .queryEncodingStyle(array: .noBrackets, bool: .asLiterals) // set the encoding style
```

### Set JSON Body

Most of the time you need to pass some JSON data inside the body of the requests. IndomioHTTP offer the `json()` method to pass JSON data.

`json()` method accepts two kind of data:
- `Any` which is converted via `JSONSerialization` to a valid json structure.
- Any `Codable` object which is converted via `JSONEncoder` to a valid json structure.

```swift
let req = HTTPRequest<User>()
            .method(.post)
            .json(["username": user, "password": pwd])
```

or if your object is conform to `Codable`:

```swift
struct User: Codable { // User conforms to Codable
    var username: String
    var pwd: String
}

// somewhere...
let user = User(username: "markdelillo", pwd: "mypass")
let req = HTTPRequest<User>()
          .method(.post)
          .json(user) // automatically convert in a json body
```

### Set Form URL Encoded

If you need to send a Form URL Encoded data (`application/x-www-form-urlencoded`) you can use the `formURLEncoded()` function:

```swift
let req = HTTPRequest<User>()
            .method(.post)
            .formURLEncoded(["username": user, "password": pwd, "p": 1, "p2": 3])
```

Data will be automatically converted to x-ww-form-urlencoded for you.

### Set Multipart Form

IndomioHTTP also support Multipart Form Data. All the stuff of the multipart format are handled automatically by the library (boundary identifier included!); you just need to put your data in.  

Usually you may call `multipart()` function which accept a `MultipartFormData` object or offer a builder functions to configure the content of a new multipart form created for you:

```swift
let req = HTTPRequest<FormResponse>()
          .method(.post)
          .multipart {
                $0.add(fileURL: fileURL, name: myFileName) // attach file from URL
                $0.add(string: "bug", name: "report_type") // attach simple key/values
                $0.add(data: someData, name: "binary_data") // attach raw binary data
                $0.add(stream: stream, name: "blob") // support InputStream content
          }
```