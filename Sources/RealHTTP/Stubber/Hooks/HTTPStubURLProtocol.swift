//
//  RealHTTP
//  Lightweight Async/Await Network Layer/Stubber for Swift
//
//  Created & Maintained by Mobile Platforms Team @ ImmobiliareLabs.it
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Authors:
//   - Daniele Margutti <hello@danielemargutti.com>
//
//  Copyright ©2022 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

public class HTTPStubURLProtocol: URLProtocol {
    
    /// This class support only certain common type of schemes.
    private static let supportedSchemes = ["http", "https"]
    
    /// For delayed responses.
    private var responseWorkItem: DispatchWorkItem?
    
    public override var task: URLSessionTask? {
      urlSessionTask
    }
    
    private var urlSessionTask: URLSessionTask?

    // MARK: - Overrides
    
    /// The following call is called when a new request is about to being executed.
    /// The following stub subclass supports only certain schemes, http and https so we
    /// want to reply affermative (and therefore manage it) only for these schemes.
    /// When false other registered protocol classes are queryed to respond.
    ///
    /// - Parameter request: request to validate.
    /// - Returns: Bool
    public override class func canInit(with request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme,
              Self.supportedSchemes.contains(scheme) else {
            return false
        }
        
        // Pass filter for ignore urls
        return HTTPStubber.shared.shouldHandle(request)
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    public override class func requestIsCacheEquivalent(_ requestA: URLRequest, to requestB: URLRequest) -> Bool {
        false
    }
    
    init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
      super.init(request: task.currentRequest!, cachedResponse: cachedResponse, client: client)
      self.urlSessionTask = task
    }

    public override func startLoading() {
        var request = self.request
        
        // Get the cookie storage that applies to this request.
        var cookieStorage = HTTPCookieStorage.shared
        if let session = task?.value(forKey: "session") as? URLSession,
           let configurationCookieStorage = session.configuration.httpCookieStorage {
            cookieStorage = configurationCookieStorage
        }
        
        // Get the cookies that apply to this URL and add them to the request headers.
        if let url = request.url, let cookies = cookieStorage.cookies(for: url) {
            if request.allHTTPHeaderFields == nil {
                request.allHTTPHeaderFields = [String: String]()
            }
            request.allHTTPHeaderFields!.merge(HTTPCookie.requestHeaderFields(with: cookies)) { (current, _) in
                current
            }
        }
        
        // Find the stubbed response for this request.
        guard  let httpMethod = request.method,
               let matchedRequest = HTTPStubber.shared.suitableStubForRequest(request),
               let stubProvider = matchedRequest.responses[httpMethod],
               let stubResponse = stubProvider.response(forURLRequest: request, matchedStub: matchedRequest)?.adaptForRequest(request),
               request.url != nil else {
            // If not found we throw an error
            client?.urlProtocol(self, didFailWithError: HTTPStubberErrors.matchStubNotFound(request))
            return
        }
        
        switch stubResponse.responseTime {
        case .immediate:
            finishRequest(request, withStub: stubResponse, cookies: cookieStorage)
        case .delayedBy(let interval):
            self.responseWorkItem = DispatchWorkItem(block: { [weak self] in
                self?.finishRequest(request, withStub: stubResponse, cookies: cookieStorage)
            })
            DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).asyncAfter(deadline: .now() + interval,
                                                                                     execute: responseWorkItem!)
        case .withSpeed(let speed):
            let data = stubResponse.body?.data ?? Data()
            let inputStream = InputStream(data: data)

            inputStream.open()

            guard data.count > 0, inputStream.hasBytesAvailable else {
                self.client?.urlProtocol(self, didLoad: Data())
                inputStream.close()
                return
            }

            streamData(inputStream, forRequest: request, forStub: stubResponse, speed: speed) { error in
                inputStream.close()
                if let error = error {
                    self.client?.urlProtocol(self, didFailWithError: error)
                } else {
                    self.client?.urlProtocolDidFinishLoading(self)
                }
            }
        }
    }
    
    public override func stopLoading() {
        responseWorkItem?.cancel()
    }
    
    // MARK: - Private Functions
    
    private func streamData(_ inputStream: InputStream,
                            forRequest request: URLRequest, forStub stub: HTTPStubResponse,
                            speed: HTTPConnectionSpeed,
                            completion: @escaping ((Error?) -> Void)) {
        
        // Compute timing data once and for all for this stub.
        var timingInfo = HTTPStubStreamTiming()
        // Bytes send each 'slotTime' seconds = Speed in KB/s * 1000 * slotTime in seconds
        timingInfo.chunkSizePerSlot = (fabs(speed.value) * 1000) * timingInfo.slotTime
        
        // This is needed in case we computed a non-integer chunkSizePerSlot, to avoid cumulative errors
        let cumulativeChunkSizeAfterRead = timingInfo.cumulativeChunkSize + timingInfo.chunkSizePerSlot
        let chunkSizeToRead = Int(floor(cumulativeChunkSizeAfterRead) - floor(timingInfo.cumulativeChunkSize))
        timingInfo.cumulativeChunkSize = cumulativeChunkSizeAfterRead
        
        if chunkSizeToRead == 0 { // Nothing to read at this pass, but probably later
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + timingInfo.slotTime) {
                self.streamData(inputStream, forRequest: request, forStub: stub, speed: speed, completion: completion)
            }
        } else {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: chunkSizeToRead)
            let bytesRead = inputStream.read(buffer, maxLength: chunkSizeToRead)
            defer {
                buffer.deallocate()
            }
            
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                print("Sending \(data.count) bytes...")
                // Wait for 'slotTime' seconds before sending the chunk.
                //
                // NOTE
                // If `bytesRead < chunkSizePerSlot` (because we are near the EOF),
                // adjust slotTime proportionally to the bytes remaining
                DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + timingInfo.slotTime) {
                    self.client?.urlProtocol(self, didLoad: data)
                    self.streamData(inputStream, forRequest: request, forStub: stub, speed: speed, completion: completion)
                }
            } else {
                // NOTE
                // We may also arrive here with no error if we were just at the end of the stream (EOF)
                // In that case, `hasBytesAvailable` did return true (because at the limit of OEF) but nothing
                // were read (because EOF).
                // In this case `inputStream.streamError` will be `nil` so that's okay, we'll return no error.
                completion(inputStream.streamError)
            }
        }
    }
    
    private func finishRequest(_ request: URLRequest, withStub stubResponse: HTTPStubResponse, cookies: HTTPCookieStorage) {
        let url = request.url!
        let headers = stubResponse.headers.asDictionary
        let cookiesToSet = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
        cookies.setCookies(cookiesToSet, for: request.url!, mainDocumentURL: url)

        if let failureError = stubResponse.failError { // request should fail with given error
            client?.urlProtocol(self, didFailWithError: failureError)
            return
        }
        
        let statusCode = stubResponse.statusCode
        let response = HTTPURLResponse(url: url,
                                       statusCode: statusCode.rawValue,
                                       httpVersion: nil,
                                       headerFields: headers)
        
        // Handle redirects
        let isRedirect =
            statusCode.responseType == .redirection &&
            (statusCode != .notModified && statusCode != .useProxy)
        
        if isRedirect, let location = stubResponse.body?.data?.redirectLocation {
            // Includes redirection call to client.
            // A redirect to the client must contain `Location:<URL>` inside the body.
            var redirect = URLRequest(url: location)
            if let cookiesInRedirect = cookies.cookies(for: url) {
                redirect.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookiesInRedirect)
            }
            client?.urlProtocol(self, wasRedirectedTo: redirect, redirectResponse: response!)
        }
        
        // Send response
        client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        if let data = stubResponse.body?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
}

// MARK: - HTTPStubStreamTiming

internal struct HTTPStubStreamTiming {
    
    /// The default slot interval, must be > 0.
    /// We will send a chunk of the data from the stream each 'slotTime' seconds.
    /// This value is 0.25 seconds.
    static let defaultSlotTime: TimeInterval = 0.25
    
    // MARK: - Private Properties
    
    var slotTime: TimeInterval
    var chunkSizePerSlot: Double = 0.0
    var cumulativeChunkSize: Double = 0.0
    
    // MARK: - Initialization
    
    init(slotTime: TimeInterval = HTTPStubStreamTiming.defaultSlotTime) {
        self.slotTime = slotTime
    }
    
}
