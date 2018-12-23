//
//  HtmlNode.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/24/18.
//

import Foundation

public class HtmlNode  {
    public let html: Substring
    
    public convenience init(_ html: String) {
        self.init(Substring(html))
    }
    
    public init(_ html: Substring) {
        self.html = html
    }
    
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
    
    public private(set) lazy var childs: [HtmlNode]? = {
        parseChildNodes(innerHtml)
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
    
    public
    private(set) lazy var text: String? = {
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
    
    private(set) lazy var innerHtml: Substring = {
        guard let begin = html.range(of: ">") else {
            return html
        }
        
        guard let end = html.range(of: "</", options: .backwards) else {
            return html
        }
        
        return html[begin.upperBound ..< end.lowerBound]
    }()
}

internal
func parseChildNodes(_ html: Substring) -> [HtmlNode]? {
    var childs = [HtmlNode]()
    
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
                let node = HtmlNode(content)
                childs.append(node)
            }
            
        } else {
            
            
            rangeStack.append(tagBegin)
        }
        
        range = tagRange.upperBound ..< html.endIndex
    }
    
    return childs.count > 0 ? childs : nil
}


private
extension HtmlNode {
    func formatText(_ htmltext: String) -> String {
        let text = htmltext.removedMultipleWhitespacesAndNewlines().replaceHtmlCharacterEntities()
        return text
    }
}

private
let attrPattern = "\\w* *= *\\\"[^\\\"]*\\\""

private
extension HtmlNode {
    
    func parseTagAttributes(_ html: Substring) -> [String: String]? {
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
    
    func parseAttr(_ attr: Substring) -> (key: String, value: String)? {
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
