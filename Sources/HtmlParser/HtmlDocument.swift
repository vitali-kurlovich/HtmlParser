//
//  HtmlParser.swift
//

import Foundation

public class HtmlDocument {
    public let html: Substring

    public private(set) lazy var root: HtmlNode? = {
        guard let html = htmlWithoutDoctype(self.html) else {
            return nil
        }
        return HtmlNode(html).first(tag: "html")
    }()

    public private(set) lazy var head: HtmlNode? = {
        root?.first(tag: "head")
    }()

    public private(set) lazy var body: HtmlNode? = {
        root?.first(tag: "body")
    }()

    public convenience init(_ html: String) {
        self.init(Substring(html))
    }

    public init(_ html: Substring) {
        self.html = html
    }
}
