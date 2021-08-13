# Introduction

**TABLE OF CONTENTS**

- Introduction
- Architecture Components

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
