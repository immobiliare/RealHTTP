# HTTP Request

- Configure a Request
- Decodable Request
- Chainable Configuration
- Set Content
    - Set Headers
    - Set Query Parameters
    - Set JSON Body
    - Set Form URL Encoded
    - Set Multipart Form
- Modify an URLRequest
- Execute Request
- Cancel Request
- Response Handling
- Response Validation
- Upload Large Data
    - Upload Multi-part form with stream of file
    - Upload File Stream
- Download Large Data
- Track Upload/Download Progress

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

## Decodable Request (Custom and Codable)

`HTTPRequest` has a generics which defines what kind of object should return at the end of the network call. Every object which is conform to the `HTTPDecodableResponse` protocol can be returned as output of the request.

`HTTPDecodableResponse` declare the following function:

```swift
public protocol HTTPDecodableResponse {
    static func decode(_ response: HTTPRawResponse) -> Result<Self, Error>
}
```

Implementing this method in your own object you can parse the raw response from a request and transform it to your desidered business object.  

This is an example which use SwiftyJSON to decode an `User` struct; this is very useful when your decoding must be heavily customized and the use of Codable is not suggested:

```swift
import SwiftyJSON

struct User: HTTPDecodableResponse {
    public let userID: String
    public let name: String
    public let email: String

    static func decode(_ response: HTTPRawResponse) -> Result<Self, Error> {
        let json = JSON(response.content.data)
        guard let userID = json["userid"].string else {
            return .failure(.other, "Cannot decode User, missing required userid")
        }

        let user = User(userID: userID, name: json["name"].stringValue, email: json["email"].stringValue)
        return .success(user)
    }

}
```

Of course if you don't need to customize your parsing methods, IndomioHTTP also support `Codable` by default.  
Any object conform to `Codable` protocol can be assigned to `HTTPRequest` and its decoding is made automatically:

```swift
struct User: Codable {
    public let userID: String
    public let name: String
    public let email: String
}
```

so in both cases you can just run your request:

```swift
HTTPRequest<User>().method(.post).route("agents/login").json("user": user, "pwd": pwd).onResult { result in
    switch result {
        case .success(let user):
            print("Logged as \(user.email)")
        case .failure(let error):
            print("Failed with error: \(error.localizedDescription))
    }
}
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

## Set Content

IndomioHTTP also provides a variety of methods to configure the content of a request; built in services includes:

- JSON body configuration
- Form URL Encoded
- Query Parameters (in URL)
- Multipart Form Data / File Upload
### Set Headers

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

## Modify an URLRequest

When IndomioHTTP create an `URLRequest` for an `HTTPRequest` in a client you may have the need to make some further changes.  
In order to accomplish it you can provide a custom callback to `urlRequestModifier`:

```swift
let req = HTTPRequest<SomeObj>(...)
req.urlRequestModifier = { urlRequest in
    // urlRequest is received as inout object you can modify
}
```

## Execute Request

Once your request has configured you can use `run` functions to execute it.  
There are 3 different mode to execute a request:

- `run(in: HTTPClientProtocol)`: execute the request inside the session of an `HTTPClient` instance.
- `runSync(in: HTTPClientProtocol)`: run the call synchronously (blocking the caller thread, useful for testing purpose) inside the session of an `HTTPClient` instance.

The same methods are also available when you don't need of a client and you want to execute them into the `HTTPClient.shared` instance:

- `run()`
- `runSync()`

> NOTE: `*sync()` versions block the caller thread

## Cancel Request

You can cancel a request at anytime, while it's in progress or in queue by using the `cancel()` function.

```swift
let largeDownload = HTTPRawRequest().resourceAtURL("https://speed.hetzner.de/100MB.bin").onResponse { raw in
    // You'll receive .cancelled error from here
}.onProgress { progress in
    print("\(progress.percentage)% downloaded")
}.run()

...

// At any time during the execution
largeDownload.cancel()
```

For large downloads you can choose to cancel the operation by also producing resumable data you can use to resume the download later:

```swift
largeDownload.cancel(byProducingResumeData: true, { resumableData in
    // resumable data are produced asynchronously.
})
```

To resume your download in a later moment just pass that data:

```swift
HTTPRawRequest().resourceAtURL("https://speed.hetzner.de/100MB.bin", resumeData: resumableData).onProgress { progress in
    // you will receive a progress state instance of `HTTPProgress`
    //  with `resumedOffset` instance, then a series of data with progression as usual.
    print("\(progress.percentage)% downloaded")
}.run()
```

> NOTE: On some versions of all Apple platforms (iOS 10 - 10.2, macOS 10.12 - 10.12.2, tvOS 10 - 10.1, watchOS 3 - 3.1.1), resumeData is broken on background URLSessionConfigurations. There's an underlying bug in the resumeData generation logic where the data is written incorrectly and will always fail to resume the download. For more information about the bug and possible workarounds, please see this Stack Overflow post.
## Response Handling

You can monitor 3 different data from a request:

- The **raw response** (`HTTPRawResponse`) which contains all the data received from server (including metrics data)
- The **result object** (specified `HTTPDecodableResponse` conform object) which contains decoded data from server (or `nil` if an error has occurred).
- The **progress** of upload/download: for large data set you can monitor the progress of the operation (via `progress` property, an `HTTPProgress` object).

Each observer is basically a callback called by the request.  

You can add a new observer via callbacks or using the Combine's publishers (it's up to you!):

```swift
req.run(in: client)
   .onResult { result in
        // Deal with Result<YourObject,Error>
    }.onResponse { raw in
        // deal with HTTPRawResponse
    }.onProgress { progress in
        // called multiple times with updated HTTProgress
    }
```

Each callback also require a `queue` parameter which define the `DispatchQueue` where the callback must be executed. If not specified, as in the example above, the `.main` queue is used.  
Callback can be chained multiple times, so you can call `onResult` for the same request in different point of codes and you will get the result automatically.

You can also use the Combine's publishers.

This track the decoded object:

```swift
// Execute the request (if needed) and create the publisher to get decoded result
req.resultPublisher(in: client).sink { result in
    switch result {
        case .success(let obj):
            // decoded object
        case .failure(let err):
            // error occurred
    }
}.store(in: &...)
```

This track the raw response:

```swift
req.responsePublisher(in: client).sink { rawResponse in
    // deal with raw response         
}.store(in: &...)
```

You can also monitor the `progress` property which is a `@Published` object:

```swift
req.$progress.sink { progress in
     print("Progress: \(progress?.percentage ?? 0)%")
}.store(in: &...)
```

## Response Validation

You have two way to perform response validation of a request.  
The first one is to provide a custom implementation of the `HTTPDecodableResponse` protocol which is used to transform an `HTTPRawResponse` received from server to a valid object.

The second one is centralized at client level and uses the ordered list of `validators` which are conform to `HTTPResponseValidatorProtocol` protocol. To learn more about this method see the "HTTP Client" section of the documentation.

## Upload Large Data

When sending relatively small amounts of data to a server using JSON or URL encoded parameters data you don't need to setup anything.  

If you need to send much larger amounts of data from Data in memory, a file URL, or an InputStream, we suggest setting the appropriate `.largeData` options for `transferMode` property (or via `mode()` function).

```swift
let data: Data = ...
let client: HTTPClient = ...

let req = HTTPRequest<FormResponse>()
          .method(.post)
          .data(data, transferAs: .largeData)

req.resultPublisher(in: client).sink { result in
    // ...
}.
```

By setting the `transferMode = .largeData` you will be also able to track the progress of the operation via `onProgress` callback or observing chnages in `@Published progress` property (via combine).

Sometimes you may prefer to use stream to send large amount of data without loading them in memory.

### Upload Multi-part form with stream of file

This is an example of multipart form which send the content of a file as stream so we don't need to load all the contents in memory. Contents are read during the stream from local memory to the remote endpoint.

```swift
let req = HTTPRawRequest<FormResponse>()
          .method(.post)
          .multipart({
              // add file from a stream resource
              $0.add(fileStream: URL(fileURLWithPath: "<filePath>"), headers: [...])
          })
```

> NOTE: You can also add raw `InputStream`, `Data` or key/value strings. See the `add()` function of the `MultipartFormData` object for more info.

### Upload File Stream

Sometimes you want to send large amount of data with a request and you would avoid to put them in memory and send it as body. In this case you can use the `stream()` functions of the `HTTPRequest` to keep your program responsive.

```swift
let fileURL = URL(fileURLWithPath: "../bigFile.txt")
HTTPRawRequest(.post)
              .stream(fileURL: fileURL).run(in: client).onResponse {
    // Deal with result
}
```

Stream also support raw `Data` via `stream(data: )` function.

## Download Large Data

To download large data from an URL or track the progress of download you can use `resourceAtURL()` function:

```swift
HTTPRawRequest()
    .resourceAtURL("https://speed.hetzner.de/100MB.bin")
    .onResponse { raw in
        print("Completed")
    }.onProgress { prog in
        print(prog.percentage)
    }
    .run()
```

In fact it just a shortcut to set the `transferMode = .largeData` and route to the absolute URL passed.

## Track Upload/Download Progress

On `.largeData` `transferMode` requests you can also add an observer to monitor the progress of download/upload.  
The following example add a `onProgress` callback which is called when a new update is available.

```swift
HTTPRawRequest()
    .resourceAtURL("https://speed.hetzner.de/100MB.bin")
    }.onProgress { prog in
        print(prog.percentage)
    }
```

returning object is an `HTTProgress` instance with the following properties:

- `info`: return a `Progress` system object with the data of the operation.
- `percentage`: a float (0..1) with the percentage of completion.
- `kind`: identify if the operation is an `upload` or `download`.
- `resumedOffset`: when a resume operation is ready an instance of the `HTTProgress` may also contains a valid non nil value with the value resumed.