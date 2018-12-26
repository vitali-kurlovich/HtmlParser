//
//  HtmlNode+Iterator.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/26/18.
//

import Foundation

public
struct HtmlNodeIterator: IteratorProtocol {
    public
    typealias Element = HtmlNode

    private
    var node: HtmlNode?

    private
    var iterator: Array<HtmlNode>.Iterator?

    init(_ node: HtmlNode) {
        self.node = node
    }

    public
    mutating func next() -> HtmlNode? {
        if let node = self.node {
            iterator = node.nodes?.makeIterator()
            self.node = nil
            return node
        }

        return iterator?.next()
    }
}

extension HtmlNode: Sequence {
    public
    typealias Iterator = HtmlNodeIterator

    public
    func makeIterator() -> HtmlNodeIterator {
        return HtmlNodeIterator(self)
    }
}
