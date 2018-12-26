//
//  HtmlParser+Search.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/24/18.
//

import Foundation

public
protocol SearchableNode {
    func first(tag: String) -> HtmlNode?
}

extension HtmlDocument: SearchableNode {
    public
    func first(tag: String) -> HtmlNode? {
        return body?.first(tag: tag)
    }

    public
    func first(id: String) -> HtmlNode? {
        return body?.first(id: id)
    }

    public
    func first(name: String) -> HtmlNode? {
        return body?.first(name: name)
    }
}

extension HtmlNode: SearchableNode {
    public
    func first(tag: String) -> HtmlNode? {
        if self.tag == tag {
            return self
        }

        let tag = tag.lowercased()

        return first { (node) -> Bool in
            node.tag == tag
        }
    }

    public
    func first(id: String) -> HtmlNode? {
        if self.id == id {
            return self
        }

        return first { (node) -> Bool in
            node.id == id
        }
    }

    public
    func first(name: String) -> HtmlNode? {
        if self.name == name {
            return self
        }

        return first { (node) -> Bool in
            node.name == name
        }
    }
}
