# Tools

## Gathering/Showing Statistical Metrics

IndomioHTTP gathers `URLSessionTaskMetrics` statistics for every `HTTPRequest`. `URLSessionTaskMetrics` encapsulate detailed information about the underlying network connection and request and response timing.  
These informations maybe a really useful sources to see bottlenecks in your comunication or gather statistics of network usage.

You can found these information inside the `HTTPRawResponse`'s `metrics` property. It return a `HTTPRequestMetrics` instance with the following info:

- `task`: origin `URLSessionTask` of the metrics.
- `redirectCount` number of redirects before obtaining the response.
- `taskInterval` total time spent executing the task.
- `metrics`: a list of transaction metrics entries.

Each item of the `metrics` can be expanded in `HTTPMetric.Stage` object which describes the kind of the operation (`domainLookup`, `connect`, `secureConnection`, `request`, `server`, `response`, `total`) along with the respective `interval` (start, end and duration).

This kind of data can be tricky to read so IndomioHTTP allows you to print a console-friendly graphical representation using the `render()` function:

```swift
HTTPRawRequest().resourceAtURL("http://ipv4.download.thinkbroadband.com/5MB.zip").onResponse { response in
    response.metrics?.render()
}
```

Print the following result type:

```sh
IndomioHTTP.HTTPRawResponse
Task ID: 1 lifetime: 1898.5ms redirects: 1
GET http://ipv4.download.thinkbroadband.com/5MB.zip -> 302 text/html, through network-load
protocol: http/1.1 proxy: false reusedconn: false
domain lookup     |############################################                                    |  92.0ms
connect           |                                             ###########################        |  54.0ms
request           |                                                                       #        |   0.3ms
server            |                                                                       #########|  15.4ms
response          |                                                                               #|   1.4ms
                                                                                             total   167.8ms
GET http://80.17.2.213:80/data/004e9b7b6a0017c7/ipv4.download.thinkbroadband.com/5MB.zip -> 200 application/zip, through network-load
protocol: http/1.1 proxy: false reusedconn: false
domain lookup     |                                                                                |   0.0ms
connect           |#                                                                               |  17.0ms
request           |#                                                                               |   0.1ms
server            |####                                                                            |  43.7ms
response          |   #############################################################################|1473.0ms                        
```

## cURL Command Output

Debugging platform issues can be frustrating.  
IndomioHTTP allows you to produce the equivalent cURL representation of any `HTTPRequest` instance for easy debugging.

```swift
let client: HTTPClientProtocol = ...
let request =  HTTPRawRequest().resourceAtURL("http://...")

// Print the cURL representation of the request
print(request.cURLDescription(whenIn: client))
```

This should produce:

```sh
$ curl -v \
	-X GET \
	-H "Accept-Language: en;q=1.0, it-US;q=0.9" \
	-H "User-Agent: HTTPDemo/1.0 (com.danielemargutti.HTTPDemo; build:1; iOS 14.5.0) IndomioHTTP/0.9.0" \
	-H "Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8" \
	"http://ipv4.download.thinkbroadband.com/5MB.zip"
```