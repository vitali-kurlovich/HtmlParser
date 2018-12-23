//
//  String+Extention.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/24/18.
//

import Foundation


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

internal
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

internal
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

internal
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

