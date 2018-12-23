//
//  HtmlParser+Search.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/24/18.
//

import Foundation

public protocol SearchableNode {
    func find(tag:String) -> HtmlNode?
}

extension HtmlDocument : SearchableNode {
    public func find(tag:String) -> HtmlNode? {
        guard let childs = childs else {
            return nil
        }
        
        let tag = tag.lowercased()
        for child in childs {
            if let node = child._find(tag: tag) {
                return node
            }
        }
        return nil
    }
}

extension HtmlNode : SearchableNode {
    public func find(tag: String) -> HtmlNode? {
        if self.tag == tag {
            return self
        }
        
        return _find(tag: tag.lowercased())
    }
    
    fileprivate
    func _find(tag: String) -> HtmlNode? {
        if self.tag == tag {
            return self
        }
        
        guard let childs = childs else {
            return nil
        }
        
        for child in childs {
            if let node = child._find(tag: tag) {
                return node
            }
        }
        
        return nil
    }
}
