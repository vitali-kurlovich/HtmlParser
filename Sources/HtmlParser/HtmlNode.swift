//
//  HtmlNode.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/24/18.
//

import Foundation

public class HtmlNode {
    public let html: Substring

    public convenience init(_ html: String) {
        self.init(Substring(html))
    }

    public init(_ html: Substring) {
        self.html = html
    }

    private(set) lazy var tag: String = {
        htmlTag(html).lowercased()
    }()

    public private(set) lazy var childs: [HtmlNode]? = {
        parseChildNodes(html)
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

    public private(set) lazy var id: String? = {
        attributes?["id"]
    }()

    public private(set) lazy var type: String? = {
        attributes?["type"]
    }()

    public private(set) lazy var name: String? = {
        attributes?["name"]
    }()

    public private(set) lazy var value: String? = {
        attributes?["value"]
    }()
}

extension HtmlNode {
    public subscript(tag: String) -> HtmlNode? {
        let tag = tag.lowercased()
        return _first(tag: tag)
    }
}

internal
func parseChildNodes(_ html: Substring) -> [HtmlNode]? {
    let childs = parseChild(html)
    if childs.count == 0 {
        return nil
    }

    var nodes = [HtmlNode]()
    nodes.reserveCapacity(childs.count)
    for child in childs {
        let node = HtmlNode(child)
        nodes.append(node)
    }

    return nodes
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
