//
//  IndomioHTTP
//
//  Created by the Mobile Team @ ImmobiliareLabs
//  Email: mobile@immobiliare.it
//  Web: http://labs.immobiliare.it
//
//  Copyright ©2022 Immobiliare.it SpA. All rights reserved.
//  Licensed under MIT License.
//
//  ============================================
//  The following implementation was created by:
//  Kyle Fuller <https://github.com/kylef>
//  for URITemplate
//  <https://github.com/kylef/URITemplate.swift>

import Foundation

/// A data structure to represent an RFC6570 URI template.
public struct URITemplate: RawRepresentable, CustomStringConvertible,
                           Equatable, Hashable,
                           ExpressibleByStringLiteral,
                           ExpressibleByExtendedGraphemeClusterLiteral,
                           ExpressibleByUnicodeScalarLiteral {
    public let rawValue: String
    
    /// The underlying URI template
    public var template: String {
        return rawValue
    }
    
    var regex: NSRegularExpression {
        let expression: NSRegularExpression?
        do {
            expression = try NSRegularExpression(pattern: "\\{([^\\}]+)\\}", options: NSRegularExpression.Options(rawValue: 0))
        } catch let error as NSError {
            fatalError("Invalid Regex \(error)")
        }
        return expression!
    }
    
    var operators: [Operator] {
        return [
            StringExpansion(),
            ReservedExpansion(),
            FragmentExpansion(),
            LabelExpansion(),
            PathSegmentExpansion(),
            PathStyleParameterExpansion(),
            FormStyleQueryExpansion(),
            FormStyleQueryContinuation()
        ]
    }
    
    /// Initialize a URITemplate with the given template
    public init(template: String) {
        self.rawValue = template
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        rawValue = value
    }
    
    public typealias UnicodeScalarLiteralType = StringLiteralType
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        rawValue = value
    }
    
    public init(stringLiteral value: StringLiteralType) {
        rawValue = value
    }
    
    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(String.self)
    }
    
    /// Returns a description of the URITemplate
    public var description: String {
        return template
    }
    
    public func hash(into hasher: inout Hasher) {
        template.hash(into: &hasher)
    }
    
    /// Returns the set of keywords in the URI Template
    public var variables: [String] {
        let expressions = regex.matches(template).map { expression -> String in
            // Removes the { and } from the expression
            return String(expression[expression.index(after: expression.startIndex)..<expression.index(before: expression.endIndex)])
        }
        
        return expressions.map { expression -> [String] in
            var expression = expression
            
            for cOperator in self.operators {
                if let currentOperator = cOperator.op {
                    if expression.hasPrefix(currentOperator) {
                        expression = String(expression[expression.index(after: expression.startIndex)...])
                        break
                    }
                }
            }
            
            return expression.components(separatedBy: ",").map { component in
                if component.hasSuffix("*") {
                    return String(component[..<component.index(before: component.endIndex)])
                } else {
                    return component
                }
            }
        }.reduce([], +)
    }
    
    /// Expand template as a URI Template using the given variables
    public func expand(_ variables: [String: Any]) -> String {
        return regex.substitute(template) { string in
            var expression = String(string[string.index(after: string.startIndex)..<string.index(before: string.endIndex)])
            let firstCharacter = String(expression[..<expression.index(after: expression.startIndex)])
            
            var cOperator = self.operators.filter {
                if let cOp = $0.op {
                    return cOp == firstCharacter
                }
                
                return false
            }.first
            
            if cOperator != nil {
                expression = String(expression[expression.index(after: expression.startIndex)...])
            } else {
                cOperator = self.operators.first
            }
            
            let rawExpansions = expression.components(separatedBy: ",").map { vari -> String? in
                var variable = vari
                var prefix: Int?
                
                if let range = variable.range(of: ":") {
                    prefix = Int(String(variable[range.upperBound...]))
                    variable = String(variable[..<range.lowerBound])
                }
                
                let explode = variable.hasSuffix("*")
                
                if explode {
                    variable = String(variable[..<variable.index(before: variable.endIndex)])
                }
                
                if let value: Any = variables[variable] {
                    return cOperator!.expand(variable, value: value, explode: explode, prefix: prefix)
                }
                
                return cOperator!.expand(variable, value: nil, explode: false, prefix: prefix)
            }
            
            let expansions = rawExpansions.reduce([], { (accumulator, expansion) -> [String] in
                if let expansion = expansion {
                    return accumulator + [expansion]
                }
                
                return accumulator
            })
            
            if expansions.count > 0 {
                return cOperator!.prefix + expansions.joined(separator: cOperator!.joiner)
            }
            
            return ""
        }
    }
    
    // swiftlint:disable identifier_name
    func regexForVariable(_ variable: String, op: Operator?) -> String {
        if op != nil {
            return "(.*)"
        } else {
            return "([A-z0-9%_\\-]+)"
        }
    }
    
    func regexForExpression(_ expression: String) -> String {
        var expression = expression
        
        let op = operators.filter {
            $0.op != nil && expression.hasPrefix($0.op!)
        }.first
        
        if op != nil {
            expression = String(expression[expression.index(after: expression.startIndex)..<expression.endIndex])
        }
        
        let regexes = expression.components(separatedBy: ",").map { variable -> String in
            return self.regexForVariable(variable, op: op)
        }
        
        return regexes.joined(separator: (op ?? StringExpansion()).joiner)
    }
    
    var extractionRegex: NSRegularExpression? {
        // swiftlint:disable force_try
        let regex = try! NSRegularExpression(pattern: "(\\{([^\\}]+)\\})|[^(.*)]", options: NSRegularExpression.Options(rawValue: 0))
        
        let pattern = regex.substitute(self.template) { expression in
            if expression.hasPrefix("{") && expression.hasSuffix("}") {
                let startIndex = expression.index(after: expression.startIndex)
                let endIndex = expression.index(before: expression.endIndex)
                return self.regexForExpression(String(expression[startIndex..<endIndex]))
            } else {
                return NSRegularExpression.escapedPattern(for: expression)
            }
        }
        
        do {
            return try NSRegularExpression(pattern: "^\(pattern)$", options: NSRegularExpression.Options(rawValue: 0))
        } catch _ {
            return nil
        }
    }
    
    /// Extract the variables used in a given URL
    public func extract(_ url: String) -> [String: String]? {
        if let expression = extractionRegex {
            let input = url as NSString
            let range = NSRange(location: 0, length: input.length)
            let results = expression.matches(in: url, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
            
            if let result = results.first {
                var extractedVariables: [String: String] = [:]
                
                for (index, variable) in variables.enumerated() {
                    let range = result.range(at: index + 1)
                    let value = NSString(string: input.substring(with: range)).removingPercentEncoding
                    extractedVariables[variable] = value
                }
                
                return extractedVariables
            }
        }
        
        return nil
    }
}

extension URITemplate: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(template)
    }
}

/// Determine if two URITemplate's are equivalent
public func ==(lhs: URITemplate, rhs: URITemplate) -> Bool {
    return lhs.template == rhs.template
}

// MARK: Extensions

extension NSRegularExpression {
    
    func substitute(_ string: String, block: ((String) -> (String))) -> String {
        let oldString = string as NSString
        let range = NSRange(location: 0, length: oldString.length)
        var newString = string as NSString
        
        let matches = self.matches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
        for match in Array(matches.reversed()) {
            let expression = oldString.substring(with: match.range)
            let replacement = block(expression)
            newString = newString.replacingCharacters(in: match.range, with: replacement) as NSString
        }
        
        return newString as String
    }
    
    func matches(_ string: String) -> [String] {
        let input = string as NSString
        let range = NSRange(location: 0, length: input.length)
        let results = self.matches(in: string, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: range)
        
        return results.map { result -> String in
            return input.substring(with: result.range)
        }
    }
}

extension String {
    func percentEncoded() -> String {
        return addingPercentEncoding(withAllowedCharacters: CharacterSet.URITemplate.unreserved)!
    }
}

// MARK: Operators

protocol Operator {
    /// Operator
    var op: String? { get }
    
    /// Prefix for the expanded string
    var prefix: String { get }
    
    /// Character to use to join expanded components
    var joiner: String { get }
    
    func expand(_ variable: String, value: Any?, explode: Bool, prefix: Int?) -> String?
}

class BaseOperator {
    
    var joiner: String { return "," }
    
    func expand(_ variable: String, value: Any?, explode: Bool, prefix: Int?) -> String? {
        if let value = value {
            if let values = value as? [String: Any] {
                return expand(variable: variable, value: values, explode: explode)
            } else if let values = value as? [Any] {
                return expand(variable: variable, value: values, explode: explode)
            // swiftlint:disable unused_optional_binding
            } else if let _ = value as? NSNull {
                return expand(variable: variable)
            } else {
                return expand(variable: variable, value: "\(value)", prefix: prefix)
            }
        }
        
        return expand(variable: variable)
    }
    
    // Point to overide to expand a value (i.e, perform encoding)
    func expand(value: String) -> String {
        return value
    }
    
    // Point to overide to expanding a string
    func expand(variable: String, value: String, prefix: Int?) -> String {
        if let prefix = prefix {
            let valueCount = value.count
            if valueCount > prefix {
                let index = value.index(value.startIndex, offsetBy: prefix, limitedBy: value.endIndex)
                return expand(value: String(value[..<index!]))
            }
        }
        
        return expand(value: value)
    }
    
    // Point to overide to expanding an array
    func expand(variable: String, value: [Any], explode: Bool) -> String? {
        let joiner = explode ? self.joiner : ","
        return value.map { self.expand(value: "\($0)") }.joined(separator: joiner)
    }
    
    // Point to overide to expanding a dictionary
    func expand(variable: String, value: [String: Any], explode: Bool) -> String? {
        let joiner = explode ? self.joiner : ","
        let keyValueJoiner = explode ? "=" : ","
        let elements = value.map({ (key, value) -> String in
            let expandedKey = self.expand(value: key)
            let expandedValue = self.expand(value: "\(value)")
            return "\(expandedKey)\(keyValueJoiner)\(expandedValue)"
        })
        
        return elements.joined(separator: joiner)
    }
    
    // Point to overide when value not found
    func expand(variable: String) -> String? {
        return nil
    }
}

/// RFC6570 (3.2.2) Simple String Expansion: {var}
class StringExpansion: BaseOperator, Operator {
    var op: String? { return nil }
    var prefix: String { return "" }
    override var joiner: String { return "," }
    
    override func expand(value: String) -> String {
        return value.percentEncoded()
    }
}

/// RFC6570 (3.2.3) Reserved Expansion: {+var}
class ReservedExpansion: BaseOperator, Operator {
    var op: String? { return "+" }
    var prefix: String { return "" }
    override var joiner: String { return "," }
    
    override func expand(value: String) -> String {
        return value.addingPercentEncoding(withAllowedCharacters: CharacterSet.uriTemplateReservedAllowed)!
    }
}

/// RFC6570 (3.2.4) Fragment Expansion {#var}
class FragmentExpansion: BaseOperator, Operator {
    var op: String? { return "#" }
    var prefix: String { return "#" }
    override var joiner: String { return "," }
    
    override func expand(value: String) -> String {
        return value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
    }
}

/// RFC6570 (3.2.5) Label Expansion with Dot-Prefix: {.var}
class LabelExpansion: BaseOperator, Operator {
    var op: String? { return "." }
    var prefix: String { return "." }
    override var joiner: String { return "." }
    
    override func expand(value: String) -> String {
        return value.percentEncoded()
    }
    
    override func expand(variable: String, value: [Any], explode: Bool) -> String? {
        if value.count > 0 {
            return super.expand(variable: variable, value: value, explode: explode)
        }
        
        return nil
    }
}

/// RFC6570 (3.2.6) Path Segment Expansion: {/var}
class PathSegmentExpansion: BaseOperator, Operator {
    var op: String? { return "/" }
    var prefix: String { return "/" }
    override var joiner: String { return "/" }
    
    override func expand(value: String) -> String {
        return value.percentEncoded()
    }
    
    override func expand(variable: String, value: [Any], explode: Bool) -> String? {
        if value.count > 0 {
            return super.expand(variable: variable, value: value, explode: explode)
        }
        
        return nil
    }
}

/// RFC6570 (3.2.7) Path-Style Parameter Expansion: {;var}
class PathStyleParameterExpansion: BaseOperator, Operator {
    var op: String? { return ";" }
    var prefix: String { return ";" }
    override var joiner: String { return ";" }
    
    override func expand(value: String) -> String {
        return value.percentEncoded()
    }
    
    override func expand(variable: String, value: String, prefix: Int?) -> String {
        let valueCount = value.count
        if valueCount > 0 {
            let expandedValue = super.expand(variable: variable, value: value, prefix: prefix)
            return "\(variable)=\(expandedValue)"
        }
        
        return variable
    }
    
    override func expand(variable: String, value: [Any], explode: Bool) -> String? {
        let joiner = explode ? self.joiner : ","
        let expandedValue = value.map {
            let expandedValue = self.expand(value: "\($0)")
            
            if explode {
                return "\(variable)=\(expandedValue)"
            }
            
            return expandedValue
        }.joined(separator: joiner)
        
        if !explode {
            return "\(variable)=\(expandedValue)"
        }
        
        return expandedValue
    }
    
    override func expand(variable: String, value: [String: Any], explode: Bool) -> String? {
        let expandedValue = super.expand(variable: variable, value: value, explode: explode)
        
        if let expandedValue = expandedValue {
            if !explode {
                return "\(variable)=\(expandedValue)"
            }
        }
        
        return expandedValue
    }
}

/// RFC6570 (3.2.8) Form-Style Query Expansion: {?var}
class FormStyleQueryExpansion: BaseOperator, Operator {
    var op: String? { return "?" }
    var prefix: String { return "?" }
    override var joiner: String { return "&" }
    
    override func expand(value: String) -> String {
        return value.percentEncoded()
    }
    
    override func expand(variable: String, value: String, prefix: Int?) -> String {
        let expandedValue = super.expand(variable: variable, value: value, prefix: prefix)
        return "\(variable)=\(expandedValue)"
    }
    
    override func expand(variable: String, value: [Any], explode: Bool) -> String? {
        if value.count > 0 {
            let joiner = explode ? self.joiner : ","
            let expandedValue = value.map {
                let expandedValue = self.expand(value: "\($0)")
                
                if explode {
                    return "\(variable)=\(expandedValue)"
                }
                
                return expandedValue
            }.joined(separator: joiner)
            
            if !explode {
                return "\(variable)=\(expandedValue)"
            }
            
            return expandedValue
        }
        
        return nil
    }
    
    override func expand(variable: String, value: [String: Any], explode: Bool) -> String? {
        if value.count > 0 {
            let expandedVariable = self.expand(value: variable)
            let expandedValue = super.expand(variable: variable, value: value, explode: explode)
            
            if let expandedValue = expandedValue {
                if !explode {
                    return "\(expandedVariable)=\(expandedValue)"
                }
            }
            
            return expandedValue
        }
        
        return nil
    }
}

/// RFC6570 (3.2.9) Form-Style Query Continuation: {&var}
class FormStyleQueryContinuation: BaseOperator, Operator {
    var op: String? { return "&" }
    var prefix: String { return "&" }
    override var joiner: String { return "&" }
    
    override func expand(value: String) -> String {
        return value.percentEncoded()
    }
    
    override func expand(variable: String, value: String, prefix: Int?) -> String {
        let expandedValue = super.expand(variable: variable, value: value, prefix: prefix)
        return "\(variable)=\(expandedValue)"
    }
    
    override func expand(variable: String, value: [Any], explode: Bool) -> String? {
        let joiner = explode ? self.joiner : ","
        let expandedValue = value.map {
            let expandedValue = self.expand(value: "\($0)")
            
            if explode {
                return "\(variable)=\(expandedValue)"
            }
            
            return expandedValue
        }.joined(separator: joiner)
        
        if !explode {
            return "\(variable)=\(expandedValue)"
        }
        
        return expandedValue
    }
    
    override func expand(variable: String, value: [String: Any], explode: Bool) -> String? {
        let expandedValue = super.expand(variable: variable, value: value, explode: explode)
        
        if let expandedValue = expandedValue {
            if !explode {
                return "\(variable)=\(expandedValue)"
            }
        }
        
        return expandedValue
    }
    
}

private extension CharacterSet {
    
    struct URITemplate {
        static let digits = CharacterSet(charactersIn: "0"..."9")
        static let genDelims = CharacterSet(charactersIn: ":/?#[]@")
        static let subDelims = CharacterSet(charactersIn: "!$&'()*+,;=")
        static let unreservedSymbols = CharacterSet(charactersIn: "-._~")
        
        static let unreserved = {
            return alpha.union(digits).union(unreservedSymbols)
        }()
        
        static let reserved = {
            return genDelims.union(subDelims)
        }()
        
        static let alpha = { () -> CharacterSet in
            let upperAlpha = CharacterSet(charactersIn: "A"..."Z")
            let lowerAlpha = CharacterSet(charactersIn: "a"..."z")
            return upperAlpha.union(lowerAlpha)
        }()
    }
    
    static let uriTemplateReservedAllowed = {
        return URITemplate.unreserved.union(URITemplate.reserved)
    }()
    
}
