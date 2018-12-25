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
        let tag = tag.lowercased()
        return body?._first(tag: tag)
    }
}

extension HtmlNode: SearchableNode {
    public
    func first(tag: String) -> HtmlNode? {
        if self.tag == tag {
            return self
        }

        return _first(tag: tag.lowercased())
    }

    internal
    func _first(tag: String) -> HtmlNode? {
        if self.tag == tag {
            return self
        }

        guard let childs = childs else {
            return nil
        }

        for child in childs {
            if let node = child._first(tag: tag) {
                return node
            }
        }

        return nil
    }
}
