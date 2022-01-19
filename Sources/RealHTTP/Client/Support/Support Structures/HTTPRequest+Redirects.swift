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

// MARK: - HTTPRedirectAction

/// Action to follow for a redirect request.
/// - `refuse`: refuse redirection.
/// - `follow`: follow redirection to specified request by using the proposed URLSession urlrequesdt.
/// - `followCopy`: follow redirection and
public enum HTTPRedirectAction {
    case refuse
    case follow(URLRequest)
}

// MARK: - HTTPRedirectFollow

/// Follow redirects mechanism mode.
/// - `follow`: follow the redirect with the default new urlrequest.
///             new request has a different url but not maintain the original method/body/headers.
/// - `followCopy`: follow the redirect with the new urlrequest proposed
///                 which has the same method/body/headers of the original one.
public enum HTTPRedirectFollow {
    case follow
    case followCopy
}

// MARK: - HTTPTransferMode

/// Describe what kind of data you are expecting from the server for a response.
/// This used to identify what kind of `URLSessionTask` subclass we should use.
///
/// - `default`:  Data tasks are intended for short, often interactive requests from your app to a server.
///               Data tasks can return data to your app one piece at a time after each piece of data is received,
///               or all at once through a completion handler.
///               Because data tasks do not store the data to a file, they are not supported in background sessions.
/// - `largeData`: Directly writes the response data to a temporary file.
///            It supports background downloads when the app is not running.
///            Download tasks retrieve data in the form of a file, and support background downloads while the app is not running.
public enum HTTPTransferMode {
    case `default`
    case largeData
}
