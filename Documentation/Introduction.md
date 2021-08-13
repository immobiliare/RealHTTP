# Introduction
## Introduction

IndomioHTTP provides an elegant type-safe interface to build and execute HTTP request.  
The goal of this project is to make simple and more swifty the Apple's built-in URL Loading System provided.  
At the core of our library you will found URLSession and URLSessionTask; IndomioHTTP just wrap them in a convenient and elegant box seamlessy adapts to the new Swift design goals.  

IndomioHTTP supports reactive programming by integrating Combine's publishers and subject. Future versions will also support the new Async/Await mechanism.

### Architecture

This is an overview of the library's architecture. We'll take a brief look to each component below.

#### HTTPClient

This is the client where requests are executed. Each client may have its configuration which includes the base URL, cookies, custom headers, caching policy and more.  
IndomioHTTP exposes two different kind of clients:
- `HTTPClient`: this is the default client; network call are executed in concurrent fashion.
- `HTTPQueuedClient`: this client maintain an interval OperationQueue which allows you to have a fine grained control over concurrent operation