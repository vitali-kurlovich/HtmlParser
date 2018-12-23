//
//  HtmlParser.swift
//

import Foundation



public class HtmlDocument {
    public let html: Substring
    
    public private(set) lazy var root: HtmlNode? = {
        return find(tag: "html")
    }()
    
    public private(set) lazy var head: HtmlNode? = {
        return root?.find(tag: "head")
    }()
    
    public private(set) lazy var body: HtmlNode? = {
        return root?.find(tag: "body")
    }()
    
    internal
    lazy var childs : [HtmlNode]? = {
        return parseChildNodes(html)
    }()
    
    public convenience init(_ html: String) {
        self.init(Substring(html))
    }
    
    public init(_ html: Substring) {
        self.html = html
    }
}


