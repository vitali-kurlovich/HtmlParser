//
//  HtmlNode.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/24/18.
//

import Foundation

extension HtmlNode {
    public
    func nodes(ignoreComment: Bool) -> [HtmlNode]? {
        guard let childs = childs else {
            return nil
        }

        let count = nodesCount(ignoreComment: ignoreComment)

        guard count > 0 else {
            return nil
        }

        var nodes = [HtmlNode]()
        nodes.reserveCapacity(count)

        for child in childs {
            if !(ignoreComment && child.isComment) {
                nodes.append(child)
            }
            guard let childNodes = child.nodes(ignoreComment: ignoreComment) else {
                continue
            }
            nodes.append(contentsOf: childNodes)
        }

        return nodes
    }

    internal
    func nodesCount(ignoreComment: Bool = true) -> Int {
        guard let childs = childs else {
            return 0
        }

        let count = ignoreComment ? childs.reduce(0) { (count, node) -> Int in
            return count + (node.isComment ? 0 : 1)
        } : childs.count

        return childs.reduce(count) { (count, node) -> Int in
            count + node.nodesCount(ignoreComment: ignoreComment)
        }
    }
}

public
final class HtmlNode {
    public let html: Substring

    public convenience init(_ html: String) {
        self.init(Substring(html))
    }

    public init(_ html: Substring) {
        self.html = html
    }

    private(set) lazy var isComment: Bool = {
        guard let tagBegin = html.range(of: "<") else {
            return false
        }

        let tag = html[tagBegin.lowerBound ..< html.endIndex]
        return tag.hasPrefix("<!--")
    }()

    private(set) lazy var isScript: Bool = {
        isScriptTag(htmlTag(self.html))
    }()

    private(set) lazy var tag: String = {
        if isComment {
            return ""
        }
        return htmlTag(html).lowercased()
    }()

    public
    private(set) lazy var childs: [HtmlNode]? = {
        if !isComment {
            return parseChildNodes(html)
        }
        return nil
    }()

    public
    lazy var nodes: [HtmlNode]? = { self.nodes(ignoreComment: true) }()

    public private(set) lazy var attributes: [String: String]? = {
        if isComment {
            return nil
        }
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
        if isComment || isScript {
            return nil
        }

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
    public subscript(key: String) -> HtmlNode? {
        if key.hasPrefix("#") {
            return first(id: String(key.dropFirst()))
        }

        return first(tag: key)
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
