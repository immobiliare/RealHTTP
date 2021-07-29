//
//  IndomioNetwork
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2021 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// Common MIME types, generated from <https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types>.
public enum HTTPContentType: String {

    /// AAC audio
    case aac = "audio/aac"

    /// AVI: Audio Video Interleave
    case avi = "video/x-msvideo"

    /// Any kind of binary data
    case octetStream = "application/octet-stream"

    /// Bitmap Graphics
    case bmp = "image/bmp"

    /// BZip archive
    case bzip = "application/x-bzip"

    /// BZip2 archive
    case bzip2 = "application/x-bzip2"

    /// Cascading Style Sheets (CSS)
    case css = "text/css"

    /// Comma-separated values (CSV)
    case csv = "text/csv"

    /// Microsoft Word
    case word = "application/msword"

    /// Electronic publication (EPUB)
    case epub = "application/epub+zip"

    /// GZip Compressed Archive
    case gzip = "application/gzip"

    /// Graphics Interchange Format (GIF)
    case gif = "image/gif"

    /// HyperText Markup Language (HTML)
    case html = "text/html"

    /// iCalendar format
    case iCal = "text/calendar"

    /// JPEG images
    case jpeg = "image/jpeg"

    /// JavaScript
    case javascript = "text/javascript"

    /// JSON format
    case json = "application/json"

    /// Musical Instrument Digital Interface (MIDI)
    case midi = "audio/midi"

    /// MP3 audio
    case mpegAudio = "audio/mpeg"

    /// MPEG Video
    case mpegVideo = "video/mpeg"

    /// OGG audio
    case oggAudio = "audio/ogg"

    /// OGG video
    case oggVideo = "video/ogg"

    /// OGG
    case ogg = "application/ogg"

    /// Opus audio
    case opusAudio = "audio/opus"

    /// OpenType font
    case openType = "font/otf"

    /// Portable Network Graphics
    case png = "image/png"

    /// Adobe Portable Document Format (PDF)
    case pdf = "application/pdf"

    /// Rich Text Format (RTF)
    case rtf = "application/rtf"

    /// Scalable Vector Graphics (SVG)
    case svg = "image/svg+xml"

    /// Small web format (SWF) or Adobe Flash document
    case swf = "application/x-shockwave-flash"

    /// Tape Archive (TAR)
    case tar = "application/x-tar"

    /// Tagged Image File Format (TIFF)
    case tiff = "image/tiff"

    /// MPEG transport stream
    case mpegStream = "video/mp2t"

    /// TrueType Font
    case ttf = "font/ttf"

    /// Text
    case text = "text/plain"

    /// Waveform Audio Format
    case wav = "audio/wav"

    /// WEBM audio
    case webmAudio = "audio/webm"

    /// WEBM video
    case webmVideo = "video/webm"

    /// WEBP image
    case webp = "image/webp"

    /// Web Open Font Format (WOFF)
    case woff = "font/woff"

    /// Web Open Font Format (WOFF)
    case woff2 = "font/woff2"

    /// XHTML
    case xhtml = "application/xhtml+xml"

    /// XML
    case xml = "application/xml"

    /// XML
    case xmlText = "text/xml"

    /// ZIP archive
    case zip = "application/zip"

    // HTTP form: keys and values URL-encoded in key-value tuples separated by '&'
    case formUrlEncoded = "application/x-www-form-urlencoded"

    // HTTP form: each value is sent as a block of data
    case formDataMultipart = "multipart/form-data"
}
