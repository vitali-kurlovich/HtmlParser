//
//  HtmlParser.swift
//

import Foundation

private
let attrPattern = "\\w* *= *\\\"[^\\\"]*\\\""

private
let htmlEntities = ["&nbsp;": " ",
                    "&lt;": "<",
                    "&gt;": ">",
                    "&amp;": "&",
                    "&quot;": "\"",
                    "&apos;": "'",
                    "&cent;": "¢",
                    "&pound;": "£",
                    "&yen;": "¥",
                    "&euro;": "€",
                    "&copy;": "©",
                    "&reg;": "®"]

public class HTMLDocument {
    public let html: Substring
    
    public private(set) lazy var header: HTMLTag? = {
        return nil
    }()
    
    public private(set) lazy var body: HTMLTag? = {
        return nil
    }()
    
    private
    lazy var childs : [HTMLTag]? = {
        return parseChilds(html)
    }()
    
    public convenience init(_ html: String) {
        self.init(Substring(html))
    }
    
    public init(_ html: Substring) {
        self.html = html
    }
}

public class HTMLTag : Equatable {
    
    public static func == (lhs: HTMLTag, rhs: HTMLTag) -> Bool {
        return lhs.html == rhs.html
    }
    
    public let html: Substring
    
    public private(set) lazy var childs: [HTMLTag]? = {
        parseChilds(innerHtml)
    }()
    
    public private(set) lazy var attributes: [String: String]? = {
        let sTag = "<" + tag
        guard let start = html.range(of: sTag, options: [.caseInsensitive]),
            let end = html.range(of: ">") else {
                return nil
        }
        
        let tagHtml = html[start.upperBound ..< end.lowerBound]
        return parseTagAttributes(tagHtml)
    }()
    
    public private(set) lazy var text: String? = {
        var text = ""
        
        var range = html.startIndex ..< html.endIndex
        
        while let begin = html.range(of: ">", options: [], range: range) {
            range = begin.upperBound ..< html.endIndex
            
            guard let end = html.range(of: "<", options: [], range: range) else {
                return text.count > 0 ? formatText(text) : nil
            }
            
            range = end.upperBound ..< html.endIndex
            
            let t = html[begin.upperBound ..< end.lowerBound]
            if t.isWhitespace {
                continue
            }
            
            text.append(contentsOf: t)
        }
        
        return text.count > 0 ? formatText(text) : nil
    }()
    
    public convenience init(_ html: String) {
        self.init(Substring(html))
    }
    
    public init(_ html: Substring) {
        self.html = html
    }
    
    private(set) lazy var innerHtml: Substring = {
        guard let begin = html.range(of: ">") else {
            return html
        }
        
        guard let end = html.range(of: "</", options: .backwards) else {
            return html
        }
        
        return html[begin.upperBound ..< end.lowerBound]
    }()
    
    private(set) lazy var tag: String = {
        guard let tagRange = html.range(of: "<"),
            let range = html.range(of: ">", options: [], range: tagRange.upperBound ..< html.endIndex)
            else {
                return ""
        }
        
        guard let whiteSpaceRange = html.range(of: " ", options: [], range: tagRange.upperBound ..< range.upperBound) else {
            let tag = html[tagRange.upperBound ..< range.lowerBound]
            return String(tag)
        }
        
        let tag = html[tagRange.upperBound ..< whiteSpaceRange.lowerBound]
        
        return String(tag).lowercased()
    }()
    
    private func formatText(_ htmltext: String) -> String {
        let text = htmltext.removedMultipleWhitespacesAndNewlines().replaceHtmlCharacterEntities()
        return text
    }
    
    
    
    private func parseTagAttributes(_ html: Substring) -> [String: String]? {
        guard html.count > 0,
            let _ = html.rangeOfCharacter(from: CharacterSet.alphanumerics) else {
                return nil
        }
        
        var attributes = [String: String]()
        
        var range = html.startIndex ..< html.endIndex
        
        while let attrRange = html.range(of: attrPattern, options: [.regularExpression, .caseInsensitive], range: range) {
            range = attrRange.upperBound ..< html.endIndex
            
            guard let attr = parseAttr(html[attrRange.lowerBound ..< attrRange.upperBound]) else {
                continue
            }
            
            attributes[attr.key] = attr.value
        }
        
        return attributes.count > 0 ? attributes : nil
    }
    
    private func parseAttr(_ attr: Substring) -> (key: String, value: String)? {
        guard let range = attr.range(of: "=") else {
            return nil
        }
        
        let key = attr[attr.startIndex ..< range.lowerBound].trimmingCharacters(in: CharacterSet.whitespaces)
        
        let valueRange = range.upperBound ..< attr.endIndex
        guard let beginValueRange = attr.range(of: "\"", options: [], range: valueRange) else {
            return nil
        }
        
        guard let endValueRange = attr.range(of: "\"", options: .backwards, range: valueRange) else {
            return nil
        }
        
        let value = attr[beginValueRange.upperBound ..< endValueRange.lowerBound]
        
        return (key: key, value: String(value))
    }
}

private
func parseChilds(_ html: Substring) -> [HTMLTag]? {
    var childs = [HTMLTag]()
    
    var range = html.startIndex ..< html.endIndex
    var rangeStack = [Range<Substring.Index>]()
    rangeStack.reserveCapacity(8)
    while let tagBegin = html.range(of: "<", options: [], range: range) {
        let tagRange = tagBegin.lowerBound ..< html.index(after: tagBegin.upperBound)
        let tag = html[tagRange]
        
        if tag == "</" {
            assert(rangeStack.count > 0)
            
            guard let begin = rangeStack.popLast(), rangeStack.count == 0 else {
                range = tagRange.upperBound ..< html.endIndex
                continue
            }
            
            let searchRange = tagRange.upperBound ..< html.endIndex
            if let end = html.range(of: ">", options: [], range: searchRange) {
                let content = html[begin.lowerBound ..< end.upperBound]
                let htmlTag = HTMLTag(content)
                childs.append(htmlTag)
            }
            
        } else {
            rangeStack.append(tagBegin)
        }
        
        range = tagRange.upperBound ..< html.endIndex
    }
    
    return childs.count > 0 ? childs : nil
}

private
extension StringProtocol {
    var isWhitespace: Bool {
        let dropedSet = CharacterSet.whitespacesAndNewlines
        
        for char in self {
            let charScalars = char.unicodeScalars
            guard charScalars.count == 1,
                let scalar = charScalars.first,
                dropedSet.contains(scalar) else {
                    return false
            }
        }
        
        return true
    }
    
    func range(_ set: CharacterSet, range: Range<Self.Index>? = nil) -> Range<Self.Index>? {
        var findRange = startIndex ..< endIndex
        
        if let range = range {
            findRange = range
        }
        
        var start: Self.Index?
        for index in indices[findRange] {
            let char = self[index]
            
            let charScalars = char.unicodeScalars
            if charScalars.count == 1,
                let scalar = charScalars.first,
                set.contains(scalar) {
                if start == nil {
                    start = index
                }
                
            } else {
                if let start = start {
                    return start ..< index
                }
                
                continue
            }
        }
        
        if let start = start {
            return start ..< findRange.upperBound
        }
        
        return nil
    }
}

private
extension StringProtocol {
    func removedMultipleWhitespacesAndNewlines() -> String {
        var range = startIndex ..< endIndex
        var result = ""
        result.reserveCapacity(count)
        
        while let r = self.range(CharacterSet.whitespacesAndNewlines, range: range) {
            let sub = self[range.lowerBound ..< r.lowerBound]
            result.append(contentsOf: sub)
            result.append(contentsOf: " ")
            
            range = r.upperBound ..< range.upperBound
        }
        
        let sub = self[range.lowerBound ..< self.endIndex]
        result.append(contentsOf: sub)
        
        return result
    }
}

private
extension String {
    func replaceHtmlCharacterEntities() -> String {
        guard contains("&") else {
            return self
        }
        
        var result = ""
        result.reserveCapacity(count)
        var range = startIndex ..< endIndex
        
        while let r = self.range(of: "&", options: [], range: range) {
            let subRange = range.lowerBound ..< r.lowerBound
            
            range = r.lowerBound ..< range.upperBound
            var flag = false
            for (key, value) in htmlEntities {
                if let r = self.range(of: key, options: [], range: range) {
                    if r.lowerBound == range.lowerBound {
                        result.append(contentsOf: self[subRange])
                        result.append(value)
                        range = r.upperBound ..< range.upperBound
                        flag = true
                        break
                    }
                }
            }
            
            guard flag else {
                result.append(contentsOf: self[subRange.lowerBound ..< r.upperBound])
                range = r.upperBound ..< range.upperBound
                continue
            }
        }
        if range.lowerBound < range.upperBound {
            result.append(contentsOf: self[range])
        }
        return result
    }
}

