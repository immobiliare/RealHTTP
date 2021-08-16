# Network Stubber

- Introduction
- Stub a Request
- Stub Matchers
    - Custom Matcher
    - URI Matcher
    - JSON Matcher
    - Body Matcher
    - URL Matcher
- Add Ignore Rule
- Unhandled Rules

## Introduction

IndomioHTTP also includes a Stub Engine allowing you to stub any HTTP/HTTPS using `URLConnection` or `URLSession`. That includes any request made from IndomioHTTP or any other library.

To activate and configure the stubber you need to use the `HTTPStubber.shared` instance:

```swift
HTTPStubber.shared.enable() // enable the stubber
```

Once you have done you can disable it:

```swift
HTTPStubber.shared.disable()
```

## Stub a Request

To stub a request, first you need to create a `HTTPStubRequest` and `HTTPStubResponse`.  
You then register this stub with IndomioHTTP and tell it to intercept network requests by calling the `enable()` method.

An `HTTPStubRequest` describe what kind of triggers should be matched for activating the stub request; a single trigger is called matcher which is an entity conforms to `HTTPStubMatcherProtocol`.  
Only when all `matchers` of a stub request are validated the stub is used to mock the request; in this case the associated response are used.  
You can specify a different `HTTPStubResponse` for each HTTP Method (ie. a different response for GET and POST on the same trigger).

```swift
var stub = HTTPStubRequest()
           .match(urlRegex: "http://www.google.com/+") // stub any url for google domain
           .stub(for: .post, delay: 5, json: jsonData) // stub the post with json data and delay
           .stub(for: .put, error: internalError) // stub error for put

// Add to the stubber
HTTPStubber.shared.add(stub: stub)
```

The following example use the URL Regex Matcher to match any url of the google domain.  
The stub return
- a `jsonData` for `POST` requests with a delay of the response of 5 seconds
- an `internalError` for any `PUT` request

an `HTTPStubResponse` is an object associated to a `HTTPStubRequest` for a particular HTTP Method. Each object can be configured to return custom data such as:

- `statusCode`: the HTTP Status Code
- `contentType`: the content-type header of the response
- `failError`: when specified a non nil error the `Error` is stubbed as response
- `body`: the body of the response
- `headers`: headers to return with the response
- `cachePolicy`: cache policy to trigger for resposne
- `responseDelay`: delay interval in seconds before responding to a triggere request. Very useful for testing.

While you can use any of the shortcuts in `HTTPStubRequest`'s `stub(...)` functions to set coincise `HTTPStubResponse` you can also provide a complete object to specify the properties above:

```swift
var stub = HTTPStubRequest()
           .stub(for: .post, { response in
                // Builder function allows you to specifiy any property of the
                // HTTPStubResponse object for this http method.
                response.responseDelay = 5
                response.headers = HTTPHeaders([
                    .contentType: HTTPContentType.bmp.rawValue,
                    .contentLength: String(fileSize,
                ])
                response.body = fileContent
            })
```

## Stub Matchers

There are different stub matchers you can chain for a single stub request.

> NOTE: `matchers` are evaluated with AND operator, not OR. So all matchers must be verified in order to trigger the relative request.

### Custom Matcher

You can create your custom matcher and add it to the `matchers` of a stub request. It must be conform to the `HTTPStubMatcherProtocol` protocol:

```swift
public protocol HTTPStubMatcherProtocol {
    func matches(request: URLRequest, for source: HTTPMatcherSource) -> Bool
}
```

When you are ready use `add()` to add the rule:

```swift
struct MyCustomMatcher: HTTPStubMatcherProtocol { ... } // implement your logic

stub.match(MyCustomMatcher()) // add to the matcher of a request
```

Sometimes you may not want to create a custom object to validate your matcher (`HTTPStubCustomMatcher`):

```swift
var stub = HTTPStubRequest()
           .match({ req, source in
              req.headers[.userAgent] == "customAgent"
           })
           .stub(...)
```

The following stub is triggered when headers of the request is `customAgent`.

### URI Matcher

IndomioHTTP allows you to define an URI matcher (`HTTPStubURITemplateMatcher`) which is based upon the [URI Template RFC](https://tools.ietf.org/html/rfc6570) - it uses the [URITemplate project by Kyle Fuller](https://github.com/kylef/URITemplate.swift).

```swift
var stub = HTTPStubRequest()
           .match(URI: "https://github.com/kylef/{repository}")
           .stub(...)
```

The uri function takes a URL or path which can have a URI Template.
Such as the following:

- https://github.com/kylef/WebLinking.swift
- https://github.com/kylef/{repository}
- /kylef/{repository}
- /kylef/URITemplate.swift

### JSON Matcher

Say you're POSTing a JSON to your server, you could make your stub match a particular value like this:

```swift
var stub = HTTPStubRequest()
           .match(object: User(userID: 34, fullName: "Mark"))
```

It will match the JSON representation of an `User` struct with `userID=34` and `fullName=Mark` without representing the raw JSON but just passing the `Codable` struct!  
It uses the `HTTPStubJSONMatcher` matcher.

### Body Matcher

Using the `HTTPStubBodyMatcher` you can match the body of a request which should be equal to a particular value in order to trigger the relative stub request:

```swift
let bodyToCheck: Data = ...
var stub = HTTPStubRequest()
           .match(body: bodyToCheck)
           .stub(...)
```

### URL Matcher

The URL matcher `HTTPStubURLMatcher` is a simple version of the regular expression matcher which check the equality of an URL by including or ignoring the query parameters:

```swift
var stub = HTTPStubRequest()
           .match(URL: "http://myws.com/login", options: .ignoreQueryParameters)
```

It will match URLs by ignoring any query parameter like `http://myws.com/login?username=xxxx` or `http://myws.com/login?username=yyyy&lock=1`.

## Add Ignore Rule

You can add ignoring rule to the `HTTPStubber.shared` in order to ignore and pass through some URLs.  
An ignore rule is an object of type `HTTPStubIgnoreRule` which contains a list of `matchers`: when all matchers are verified the stub is valid and the request is ignored.  It works like stub request for response but for ignores.

```swift
HTTPStubber.shared.add(ignoreURL: "http://www.apple.com", options: [.ignorePath, .ignoreQueryParameters])
```

You can use all the matchers described above even for rules.

## Unhandled Rules

You can choose how IndomioHTTP must deal with stub not found. You have two options:

 - `optout`: only URLs registered wich matches the matchers are ignored for mocking.
            - Registered mocked URL: mocked.
             - Registered ignored URL: ignored by the stubber, default process is applied as if the stubber is disabled.
             - Any other URL: Raises an error.
 - `optin`: Only registered mocked URLs are mocked, all others pass through.
             - Registered mocked URL: mocked.
             - Any other URL: ignored by the stubber, default process is applied as if the stubber is disabled.

To set the behaviour:

```swift
HTTPStubber.shared.unhandledMode = .optin // enable optin mode
```