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
//  Copyright ©2021 Immobiliare.it SpA.
//  Licensed under MIT License.
//

import Foundation

/// This is a list of Hypertext Transfer Protocol (HTTP) response status codes.
/// It includes codes from IETF internet standards, other IETF RFCs, other specifications,
/// and some additional commonly used codes.
/// The first digit of the status code specifies one of five classes of response;
/// an HTTP client must recognise these five classes at a minimum.
///
/// Author: Oliver Atkinson (https://gist.github.com/ollieatkinson/322338df8a5220d649ac01ff11e7de12)
///
/// ## INFORMATIONAL - 1xx
///
/// - `continue`: The server has received the request headers and the client should proceed to send the request body.
/// - `switchingProtocols`: The requester has asked the server to switch protocols and the server has agreed to do so.
/// - `processing`: This code indicates that the server has received and is processing the request,
///                 but no response is available yet.
///
/// - `none`: no response received from server.
///
/// ## SUCCESS - 2xx
///
/// - `ok`: Standard response for successful HTTP requests.
/// - `created`: The request has been fulfilled, resulting in the creation of a new resource.
/// - `accepted`: The request has been accepted for processing, but the processing has not been completed.
/// - `nonAuthoritativeInformation`: The server is a transforming proxy (e.g. a Web accelerator) that
///                                  received a 200 OK from its origin, but is returning a modified
///                                  version of the origin's response.
/// - `noContent`: The server successfully processed the request and is not returning any content.
/// - `resetContent`: The server successfully processed the request, but is not returning any content.
/// - `partialContent`: The server is delivering only part of the resource (byte serving) due to a range header sent by the client.
/// - `multiStatus`: The message body that follows is an XML message and can contain a number of
///                  separate response codes, depending on how many sub-requests were made.
/// - `alreadyReported`: The members of a DAV binding have already been enumerated in a previous
///                      reply to this request, and are not being included again.
/// - `IMUsed`: The server has fulfilled a request for the resource, and the response is a representation
///             of the result of one or more instance-manipulations applied to the current instance.
///
/// ## REDIRECTION - 3xx
///
/// - `multipleChoices`: Indicates multiple options for the resource from which the client may choose
/// - `movedPermanently`: Indicates multiple options for the resource from which the client may choose:
///                       This and all future requests should be directed to the given URI.
/// - `found`: The resource was found.
/// - `seeOther`: The response to the request can be found under another URI using a GET method.
/// - `notModified`: Indicates that the resource has not been modified since the version specified by
///                  the request headers If-Modified-Since or If-None-Match.
/// - `useProxy`: The requested resource is available only through a proxy, the address for which is provided in the response.
/// - `switchProxy`: No longer used. Originally meant "Subsequent requests should use the specified proxy.
/// - `temporaryRedirect`: The request should be repeated with another URI.
/// - `permenantRedirect`: The request and all future requests should be repeated using another URI.
///
/// ## CLIENT ERRORS - 4xx
///
/// - `badRequest`: The server cannot or will not process the request due to an apparent client error.
/// - `unauthorized`: Similar to 403 Forbidden, but specifically for use when authentication is
///                   required and has failed or has not yet been provided.
/// - `paymentRequired`: The content available on the server requires payment.
/// - `forbidden`: The request was a valid request, but the server is refusing to respond to it.
/// - `notFound`: The requested resource could not be found but may be available in the future.
/// - `methodNotAllowed`: A request method is not supported for the requested resource.
///                       e.g. a GET request on a form which requires data to be presented via POST
/// - `notAcceptable`: The requested resource is capable of generating only content not acceptable
///                    according to the Accept headers sent in the request.
/// - `proxyAuthenticationRequired`: The client must first authenticate itself with the proxy.
/// - `requestTimeout`: The server timed out waiting for the request.
/// - `conflict`: Indicates that the request could not be processed because of conflict in the request,
///               such as an edit conflict between multiple simultaneous updates.
/// - `gone`: Indicates that the resource requested is no longer available and will not be available again.
/// - `lengthRequired`: The request did not specify the length of its content, which is required by the requested resource.
/// - `preconditionFailed`: The server does not meet one of the preconditions that the requester put on the request.
/// - `payloadTooLarge`: The request is larger than the server is willing or able to process.
/// - `URITooLong`: The URI provided was too long for the server to process.
/// - `unsupportedMediaType`: The request entity has a media type which the server or resource does not support.
/// - `rangeNotSatisfiable`: The client has asked for a portion of the file (byte serving),
///                          but the server cannot supply that portion.
/// - `expectationFailed`: The server cannot meet the requirements of the Expect request-header field.
/// - `teapot`: This HTTP status is used as an Easter egg in some websites.
/// - `misdirectedRequest`: The request was directed at a server that is not able to produce a response.
/// - `unprocessableEntity`: The request was well-formed but was unable to be followed due to semantic errors.
/// - `locked`: The resource that is being accessed is locked.
/// - `failedDependency`: The request failed due to failure of a previous request (e.g., a PROPPATCH).
/// - `upgradeRequired`: The client should switch to a different protocol such as TLS/1.0, given in the Upgrade header field.
/// - `preconditionRequired`: The origin server requires the request to be conditional.
/// - `tooManyRequests`: The user has sent too many requests in a given amount of time.
/// - `requestHeaderFieldsTooLarge`: The server is unwilling to process the request because either
///                                  an individual header field, or all the header fields collectively, are too large.
/// - `noResponse`: Used to indicate that the server has returned no information to the client and closed the connection.
/// - `unavailableForLegalReasons`: A server operator has received a legal demand to deny access
///                                 to a resource or to a set of resources that includes the requested resource.
/// - `SSLCertificateError`: An expansion of the 400 Bad Request response code, used when the
///                          client has provided an invalid client certificate.
/// - `SSLCertificateRequired`: An expansion of the 400 Bad Request response code, used when a client
///                             certificate is required but not provided.
/// - `HTTPRequestSentToHTTPSPort`: An expansion of the 400 Bad Request response code,
///                                 used when the client has made a HTTP request to a port listening for HTTPS requests.
/// - `clientClosedRequest`: Used when the client has closed the request before the server could send a response.
///
/// ## SERVER ERRORS - 5xx
///
/// - `internalServerError`: A generic error message, given when an unexpected condition was encountered
///                          and no more specific message is suitable.
/// - `notImplemented`: The server either does not recognize the request method, or it lacks the ability to fulfill the request.
/// - `badGateway`: The server was acting as a gateway or proxy and received an invalid response from the upstream server.
/// - `serviceUnavailable`: The server is currently unavailable (because it is overloaded or down for maintenance).
///                         Generally, this is a temporary state.
/// - `gatewayTimeout`: The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.
/// - `HTTPVersionNotSupported`: The server does not support the HTTP protocol version used in the request.
/// - `variantAlsoNegotiates`: Transparent content negotiation for the request results in a circular reference.
/// - `insufficientStorage`: The server is unable to store the representation needed to complete the request.
/// - `loopDetected`: The server detected an infinite loop while processing the request.
/// - `notExtended`: Further extensions to the request are required for the server to fulfill it.
/// - `networkAuthenticationRequired`: The client needs to authenticate to gain network access.
///
public enum HTTPStatusCode: Int, Error {
    case none = 0

    // MARK: - Informational - 1xx
    
    case `continue` = 100
    case switchingProtocols = 101
    case processing = 102

    // MARK: - Success - 2xx
    
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case multiStatus = 207
    case alreadyReported = 208
    case IMUsed = 226

    // MARK: - Redirection - 3xx

    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case switchProxy = 306
    case temporaryRedirect = 307
    case permenantRedirect = 308

    // MARK: - Client Errors - 4xx

    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case URITooLong = 414
    case unsupportedMediaType = 415
    case rangeNotSatisfiable = 416
    case expectationFailed = 417
    case teapot = 418
    case misdirectedRequest = 421
    case unprocessableEntity = 422
    case locked = 423
    case failedDependency = 424
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests = 429
    case requestHeaderFieldsTooLarge = 431
    case noResponse = 444
    case unavailableForLegalReasons = 451
    case SSLCertificateError = 495
    case SSLCertificateRequired = 496
    case HTTPRequestSentToHTTPSPort = 497
    case clientClosedRequest = 499

    // MARK: - Server Errors - 5xx

    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case HTTPVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case notExtended = 510
    case networkAuthenticationRequired = 511
    
    // MARK: - Public Properties

    /// The class (or group) which the status code belongs to.
    public var responseType: ResponseType {
        ResponseType(httpStatusCode: self.rawValue)
    }
    
    /// Initialize an HTTPStatusCode from a URLResponse object.
    /// If no valid code can be extracted the `.none` is set.
    ///
    /// - Parameter urlResponse: url response instance
    public init?(URLResponse: URLResponse?) {
        guard let statusCode = (URLResponse as? HTTPURLResponse)?.statusCode else {
            self = .none
            return
        }
        
        self.init(rawValue: statusCode)
    }

}

// MARK: HTTPStatusCode + ResponseType

public extension HTTPStatusCode {
    
    /// The response class representation of status codes, these get grouped by their first digit.
    ///
    /// - `informal`: This class of status code indicates a provisional response,
    ///               consisting only of the Status-Line and optional headers,
    ///               and is terminated by an empty line.
    /// - `success`: This class of status codes indicates the action requested by
    ///              the client was received, understood, accepted, and processed successfully.
    /// - `redirection`: This class of status code indicates the client must take additional action to complete the request.
    /// - `clientError`: This class of status code is intended for situations in which the client seems to have erred.
    /// - `serverError`: This class of status code indicates the server failed to fulfill an apparently valid request.
    /// - `undefined`: The class of the status code cannot be resolved.
    enum ResponseType {
        case informational
        case success
        case redirection
        case clientError
        case serverError
        case undefined

        /// ResponseType by HTTP status code
        public init(httpStatusCode: Int?) {
            guard let httpStatusCode = httpStatusCode else {
                self = .undefined
                return
            }
            
            switch httpStatusCode {
                case 100 ..< 200:   self = .informational
                case 200 ..< 300:   self = .success
                case 300 ..< 400:   self = .redirection
                case 400 ..< 500:   self = .clientError
                case 500 ..< 600:   self = .serverError
                default:            self = .undefined
            }
        }
        
    }
    
}

// MARK: HTTPURLResponse + Extension

extension HTTPURLResponse {
    
    /// Status of the response as `HTTPStatusCode` object
    var status: HTTPStatusCode? {
        HTTPStatusCode(rawValue: statusCode)
    }

}
