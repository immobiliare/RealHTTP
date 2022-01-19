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

/// Common MIME types, generated from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types>.
///
/// - `aac`: AAC audio
/// - `avi`: Audio Video Interleave
/// - `octectStream`: Any kind of binary data
/// - `bmp`: Bitmap Graphics
/// - `bzip`: BZip archive
/// - `bzip2`: BZip2 archive
/// - `css`: Cascading Style Sheets (CSS)
/// - `csv`: Comma-separated values (CSV)
/// - `word`: Microsoft Word
/// - `epub`: Electronic publication (EPUB)
/// - `gzip`: GZip Compressed Archive
/// - `gif`: Graphics Interchange Format (GIF)
/// - `html`: HyperText Markup Language (HTML)
/// - `htmlUTF8`: HyperText Markup Language (HTML) with charset spec
/// - `iCal`: iCalendar format
/// - `jpeg`: JPEG images
/// - `javascript`: JavaScript
/// - `json`: JSON format
/// - `jsonUTF8`: JSON format with charset spec
/// - `midi`: Musical Instrument Digital Interface (MIDI)
/// - `mpegAudio`: MP3 audio
/// - `mpegVideo`: MPEG video
/// - `oggAudio`: OGG audio
/// - `oggVideo`: OGG video
/// - `ogg`: ogg
/// - `opusAudio`: Opus audio
/// - `openType`: OpenType font
/// - `png`: Portable Network Graphics
/// - `pdf`: Adobe Portable Document Format (PDF)
/// - `rtf`: Rich Text Format (RTF)
/// - `svg`: Scalable Vector Graphics (SVG)
/// - `swf`: Small web format (SWF) or Adobe Flash document
/// - `tar`: Tape Archive (TAR)
/// - `tiff`: Tagged Image File Format (TIFF)
/// - `mpegStream`: MPEG transport stream
/// - `ttf`: TrueType Font
/// - `text`: Text
/// - `wav`: Waveform Audio Format
/// - `webmAudio`: WEBM audio
/// - `webmVideo`: WEBM video
/// - `webp`: WEBP image
/// - `woff`: Web Open Font Format (WOFF)
/// - `woff2`: Web Open Font Format (WOFF)
/// - `xhtml`: XHTML
/// - `xml`: XML
/// - `xmlText`: XML
/// - `zip`: ZIP Archive
/// - `formUrlEncoded`: HTTP form: keys and values URL-encoded in key-value tuples separated by '&'
/// - `formDataMultipart`: HTTP form: each value is sent as a block of data
public enum HTTPContentType: String {
    case aac = "audio/aac"
    case avi = "video/x-msvideo"
    case octetStream = "application/octet-stream"
    case bmp = "image/bmp"
    case bzip = "application/x-bzip"
    case bzip2 = "application/x-bzip2"
    case css = "text/css"
    case csv = "text/csv"
    case word = "application/msword"
    case epub = "application/epub+zip"
    case gzip = "application/gzip"
    case gif = "image/gif"
    case html = "text/html"
    case htmlUTF8 = "text/html ; charset=utf-8"
    case iCal = "text/calendar"
    case jpeg = "image/jpeg"
    case javascript = "text/javascript"
    case json = "application/json"
    case jsonUTF8 = "application/json; charset=utf-8"
    case midi = "audio/midi"
    case mpegAudio = "audio/mpeg"
    case mpegVideo = "video/mpeg"
    case oggAudio = "audio/ogg"
    case oggVideo = "video/ogg"
    case ogg = "application/ogg"
    case opusAudio = "audio/opus"
    case openType = "font/otf"
    case png = "image/png"
    case pdf = "application/pdf"
    case rtf = "application/rtf"
    case svg = "image/svg+xml"
    case swf = "application/x-shockwave-flash"
    case tar = "application/x-tar"
    case tiff = "image/tiff"
    case mpegStream = "video/mp2t"
    case ttf = "font/ttf"
    case text = "text/plain"
    case wav = "audio/wav"
    case webmAudio = "audio/webm"
    case webmVideo = "video/webm"
    case webp = "image/webp"
    case woff = "font/woff"
    case woff2 = "font/woff2"
    case xhtml = "application/xhtml+xml"
    case xml = "application/xml"
    case xmlText = "text/xml"
    case zip = "application/zip"
    case formUrlEncoded = "application/x-www-form-urlencoded"
    case formDataMultipart = "multipart/form-data"
}
