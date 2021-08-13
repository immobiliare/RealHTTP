# Introduction

TOC:

- Introduction
- Architecture Components
- HTTP Client 
    - Create a new client
    - Create a queue client
    - Configure data validators
## Introduction

IndomioHTTP provides an elegant type-safe interface to build and execute HTTP request.  
The goal of this project is to make simple and more swifty the Apple's built-in URL Loading System provided.  

At the core of our library you will found URLSession and URLSessionTask; IndomioHTTP just wrap them in a convenient and elegant box seamlessy adapts to the new Swift design goals.  
No additional dependencies are part of the package.

IndomioHTTP supports reactive programming by integrating Combine's publishers and subject. Future versions will also support the new Async/Await mechanism.

## Architecture Components

IndomioHTTP defines the following main structures.

For **HTTP Client**:

- **HTTP Client**: the container where requests are executed (`HTTPClient` and `HTTPQueueClient`).
- **HTTP Request**: defines a request along with its parameters, data and decode options. IndomioHTTP allows you to automatically define a decoder for data or simply get the raw response (`HTTPRequest<Object>` and `HTTPRawRequest`).
- **HTTP Response**: defines the raw response coming from server. This object encapsulate the data, result of validations and metrics informations (`HTTPRawResponse`).

for **HTTP Stub**:

- **HTTP Stubber**: the central class you use to configure how the stubber works. Here you can enable/disable stubbing, add/remove ignore (`HTTPStubIgnoreRule`) and stub requests.
- **HTTP Stub Request**: a stub request (`HTTPStubRequest`) contains the trigger which is evaluated for any request's url by the stubber. If the stubber match the rules (called *matchers*) then the associated response (`HTTPStubResponse`) is send back to the url session.
- **HTTP Stub Response**: for each HTTP method of a stub request you can define a different response (`HTTPStubResponse`). The response contains the body, headers, cookies, redirect and all the other parameters you can stub.

Along with these structures you've also other support data types which you will see while you'll use the library itself. Each class is fully documented.
## HTTP Client

This is the client where requests are executed.  
Each client may have its configuration which includes the base URL, cookies, custom headers, caching policy and more.  

IndomioHTTP exposes 2 different clients:

- `HTTPClient`: this is the default client; network call are executed in concurrent fashion.
- `HTTPQueuedClient`: this client maintain an interval OperationQueue which allows you to have a fine grained control over concurrent operations.
### Create a new client

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

### Create a queue client

Sometimes you want to manage the number of concurrent network operations and/or the priority of their execution.  
In this case the `HTTPQueueClient` is the client you want to use:

```swift
let client = HTTPClientQueue(maxSimultaneousRequest: 3, baseURL: "http://.../v1")
```

Each time you will run a request 

### Configure Data Validators
