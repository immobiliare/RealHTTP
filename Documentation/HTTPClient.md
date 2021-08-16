# HTTP Client

[↑ DOCUMENTATION INDEX](./../README.md#documentation)

- [Introduction](#introduction)
- [Create a new client](#create-a-new-client)
- [Create a queue client](#create-a-queue-client)
- [Response Validators](#response-validators)
- [Default Response Validator](#default-response-validator)
- [Client Configuration](#client-configuration)
- [Security](#security)
    - [Configure security via SSL/TSL](#configure-security-ssltsl)
    - [Allows all certificates](#allows-all-certificates)

# Introduction

This is the client where requests are executed.  
Each client may have its configuration which includes the base URL, cookies, custom headers, caching policy and more.  

IndomioHTTP exposes 2 different clients:

- `HTTPClient`: this is the default client; network call are executed in concurrent fashion.
- `HTTPQueuedClient`: this client maintain an interval OperationQueue which allows you to have a fine grained control over concurrent operations.

[↑ INDEX](#http-client)

## Create a new client

Typically you will use the standard `HTTPClient` instance.  
In this client requests are executed concurrently and the order/priority/concurrency is managed automatically by the operation system. 

Consider a client as a way to group a set of APIs calls; these calls differs from route and parameters but shares a common set of data (base url, cookies, headers, data validators...).

Creating a client is pretty straightforward:

```swift
let myWSClient = HTTPClient(baseURL: "http://.../v1")
```

Under the hood IndomioHTTP creates an `URLSession` from the `.default` configuration.  
If you need to create a custom configuration just pass it via `configuration` argument:

```swift
let myWSClient = HTTPClient(baseURL: "http://.../v1", configuration: .ephemeral)
```

This create an ephemeral configuration.  
Built-in iOS configurations are:

- `default`: uses a persistent disk-based cache (except when the result is downloaded to a file) and stores credentials in the user’s keychain. It also stores cookies (by default) in the same shared cookie store as the `URLConnection` and `URLDownload` classes.
- `ephemeral`: similar to a default session configuration object except that the corresponding session object does not store caches, credential stores, or any session-related data to disk. Instead, session-related data is stored in RAM.
- `background`: suitable for transferring data files while the app runs in the background. A session configured with this object hands control of the transfers over to the system, which handles the transfers in a separate process. In iOS, this configuration makes it possible for transfers to continue even when the app itself is suspended or terminated.

[↑ INDEX](#http-client)

<a name="#queueclient"/>

## Create a queue client

Sometimes you want to manage the number of concurrent network operations and/or the priority of their execution.  
In this case the `HTTPQueueClient` is the client you want to use:

```swift
let client = HTTPClientQueue(maxSimultaneousRequest: 3, baseURL: "http://.../v1")
```

Each time you will run a request in a queued client it manages automatically requests based upon their priority respecting the maximum number of concurrent requests.  

> NOTE: To set the priority of a `HTTPRequest`/`HTTPRawRequest` use the `.priority` property. It allows you to manage the priority for request executed in a `HTTPQueueClient` instance and send the hint to compatible HTTP/2 endpoints (for simple `HTTPClient`s only the HTTP/2 is applied, no changes to local's sys priority queues is set).

Requests executed in `HTTPClientQueue` instances allows cancelling by calling the `cancel()` function:

```swift
req.cancel()
```

[↑ INDEX](#http-client)

<a name="#responsevalidators"/>

## Response Validators

Sometimes you need to provide your own validation rules to received data from server.  
For example you want to make a custom validation which intercept a business-logic related error and fail the request process along with this information.  

HTTP Client exposes the `validators` property, an ordered array of `HTTPResponseValidatorProtocol` conform objects you can assign to check the raw response coming from server.

This protocol require the implementation of only one method:

```swift
func validate(response: HTTPRawResponse, forRequest request: HTTPRequestProtocol) 
             -> HTTPResponseValidatorResult
```

It will be called for each raw response received for an origin request and return the appropriate action to perform:

- `.failWithError(Error)`: mark the request failed with given error.
- `.retryIfPossible`: retry the same call if origin request's `retryAttempts` limit is not reached (by default no retry is set).
- `.retryAfter(HTTPRequestProtocol)`: perform an alternate call, then again this request. This is useful for webservices which return unauthorized and you want to make a silent login before repeting previously failed request.
- `passed`: no error is throw, pass to the next validator (if any) or successfully resolve the request.

This is silly validator which intercept a specific error field into the response's body:

```swift
client.addValidator { response, request in
    guard let data = response.content?.data,
          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary,
          let errorMsg = json.value(forKey: "error") as? String, !errorMsg.isEmpty  else {
              return .passed // no error found in 'error' field of the response's body
    }
            
    let error = HTTPError(.other, message: errorMsg)
    return .failWithError(error)
}
```

`.validators` **are executed in order**; the first validator which fails interrupt the chain and set the final response of the request.  

[↑ INDEX](#toc)

<a name="#defaultvalidator"/>

## Default Response Validator

By default each client has a single validator called `HTTPDefaultValidator`; this validator makes the following standard check:

- Check if the response is an error (http error code identify an error or the network call response is an error)
- If an error is identified it also identify the error; if it's something related to network connectivity and the user set the `retryAttempts` to a non zero positive value (and the limit is not reached) it attempts to re-execute the call. Recoverable errors are the following error of the `URLError` family: `.timedOut`, `.cannotFindHost`, `.cannotConnectToHost`, `.networkConnectionLost` and `.dnsLookupFailed`.
- If it's not a recoverable error the call fail with that error.
- If no error has occurred call is okay and move on to the next validator (if any) or resolve the request.

**Empty Responses**

`HTTPDefaultValidator` also allows to deal with empty responses; by setting the `.allowsEmptyResponses` property you can decide to mark an empty response received from server as okay or as an error. By default no empty response are allowed.

You should need to remove the default validator but you may override it by creating a custom class if you need.

[↑ INDEX](#http-client)

<a name="#clientconfiguration"/>

## Client Configuration

You can configure the following properties for each client instance.

- `headers`: allows you to define (in type-safe manner) the list of HTTP Headers to set for each call you will make with the client instance.
- `timeout`: you can define a global timeout interval; if request exceed the limit time with no response from server they'll fail with `.timeout` error.
- `cachePolicy`: you can decide the cache policy to adopt; by default it uses the `.useProtocolCachePolicy`.
- `security`: you can decide to attach a security settings applied to each requested call. *See the paragraph below for more infos*.

> NOTE: All these properties are used as global settings for each request executed into the instance of the client. However you can extend/override these settings by acting on the respective properties of the `HTTPRequest` instances.

```swift
let client = HTTPClient(baseURL: "myawesomeapp.com/webservice/v1")
client.headers = HTTPHeaders([
    .userAgent: "MyAwesomeAppV1"
    "X-API-V": "1.0.1"
])
client.security = HTTPCertificatesSecurity(certificates: [certificate])
```

[↑ INDEX](#http-client)

<a name="#security"/>

## Security

<a name="#configuresecurity"/>

### Configure security (SSL/TSL)

To assign a security settings set `.security` property of `HTTPClient` (global) or `HTTPRequest` (single request); passed objects must be conform to the `HTTPSecurityProtocol` protocol which expose a challenge request.

IndomioHTTP exposes the following options:
- `HTTPCredentialSecurity`: which is based upon the URL Credentials and support Basic Auth and Digest Auth.
- `HTTPCertificatesSecurity`: which is used to support SSL pinning via certificates and public keys.

This is an example of SSL pinning:

```swift
// Load two certificates...
let cert1 = SSLCertificate(data: someData) // ... from some Data
let cert2 = SSLCertificate(fileURL: certFile) // ... from a file

// Then assign to the request (or client)
req.security = HTTPCertificatesSecurity(certificates: [cert1, cert2])
```

You load either a `Data` blob of your certificate or you can use a `SecKeyRef` if you have a public key you want to use. The `usePublicKeys` bool is whether to use the certificates for validation or the public keys.  
The public keys will be extracted from the certificates automatically if `usePublicKeys` is choosen.

This is an example of using `URLCredentials` authentication:

```swift
req.security = HTTPCredentialSecurity {
    URLCredential(user: "user", password: "password", persistence: .forSession)
}
```

[↑ INDEX](#http-client)

### Allows all certificates

Sometimes you may want to allows all certificates, especially in development environment.  This is the way to accomplish it.

```swift
req.security = HTTPCredentialSecurity { challenge in
    URLCredential(forTrust: challenge.protectionSpace.serverTrust)
}
```

[↑ INDEX](#http-client)