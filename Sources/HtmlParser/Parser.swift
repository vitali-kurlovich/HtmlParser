//
//  Parser.swift
//  HtmlParser
//
//  Created by Vitali Kurlovich on 12/25/18.
//

import Foundation

private
let tagsWithoutClosed = ["area",
                         "base", "basefont", "br",
                         "col",
                         "source",
                         "embed",
                         "frame",
                         "hr",
                         "img", "input",
                         "link",
                         "meta",
                         "param",
                         "track"]

private
let tagsWithoutClosedSet: Set<Substring> = {
    var tags = [Substring]()
    tags.reserveCapacity(tagsWithoutClosed.count * 3)
    for tag in tagsWithoutClosed {
        tags.append(Substring(tag))
        tags.append(Substring(tag.uppercased()))
        tags.append(Substring(tag.capitalized))
    }
    return Set(tags)
}()

internal
func htmlTag(_ string: Substring) -> Substring {
    guard var tagBegin = string.range(of: "<"),
        let tagEnd = string.range(of: ">", options: [], range: tagBegin.upperBound ..< string.endIndex)
    else {
        return ""
    }

    let tagBeginClosed = tagBegin.lowerBound ..< string.index(after: tagBegin.upperBound)
    if string[tagBeginClosed] == "</" {
        tagBegin = tagBeginClosed
    }

    let range = tagBegin.upperBound ..< tagEnd.upperBound
    guard let whiteSpaceRange = string.range(of: " ", options: [], range: range) else {
        let tag = string[tagBegin.upperBound ..< tagEnd.lowerBound]
        return tag
    }

    let tag = string[tagBegin.upperBound ..< whiteSpaceRange.lowerBound]
    return tag
}

internal
func htmlWithoutDoctype(_ html: Substring) -> Substring? {
    var range = html.startIndex ..< html.endIndex
    guard let tagBegin = html.range(of: "<", options: [], range: range) else {
        return nil
    }
    range = tagBegin.upperBound ..< html.endIndex

    guard let tagEnd = html.range(of: ">", options: [], range: range) else {
        return nil
    }
    let tagRange = tagBegin.lowerBound ..< tagEnd.upperBound

    let tag = html[tagRange]

    if tag.hasPrefix("<!DOCTYPE") {
        return html[tagEnd.upperBound ..< html.endIndex]
    }
    return html
}

internal
func parseChild(_ html: Substring) -> [Substring] {
    var range = html.startIndex ..< html.endIndex
    var childs = [Substring]()
    var rangeStack = [Range<Substring.Index>]()
    rangeStack.reserveCapacity(8)

    while let tagBegin = html.range(of: "<", options: [], range: range) {
        range = tagBegin.upperBound ..< html.endIndex
        guard let tagEnd = html.range(of: ">", options: [], range: range) else {
            return childs
        }

        let tagRange = tagBegin.lowerBound ..< tagEnd.upperBound

        let tag = html[tagRange]

        rangeStack.append(tagRange)
        range = tagEnd.upperBound ..< html.endIndex

        if tag.hasSuffix("/>") {
            assert(rangeStack.count > 0)
            guard let begin = rangeStack.popLast() else {
                continue
            }

            if rangeStack.count == 1 {
                let childRange = begin.lowerBound ..< tagRange.upperBound
                let content = html[childRange]
                childs.append(content)
            }

            if rangeStack.count == 0 {
                return childs
            }
            continue
        }

        if tag.hasPrefix("</") {
            assert(rangeStack.count > 1)
            _ = rangeStack.popLast()

            guard let begin = rangeStack.popLast() else {
                continue
            }

            if rangeStack.count == 1 {
                let childRange = begin.lowerBound ..< tagRange.upperBound
                let content = html[childRange]
                childs.append(content)
            }

            if rangeStack.count == 0 {
                return childs
            }

            continue
        }

        if tag.hasPrefix("<!--") {
            assert(rangeStack.count > 0)
            guard let tagBegin = rangeStack.popLast() else {
                continue
            }

            range = tagBegin.upperBound ..< html.endIndex

            if tag.hasSuffix("-->") {
                if rangeStack.count == 1 {
                    childs.append(tag)
                }
                continue
            }

            guard let tagEnd = html.range(of: "-->", options: [], range: range) else {
                continue
            }

            range = tagEnd.upperBound ..< html.endIndex
            if rangeStack.count == 1 {
                let tagRange = tagBegin.lowerBound ..< tagEnd.upperBound
                let node = html[tagRange]
                childs.append(node)
            }
            continue
        }

        let tagName = htmlTag(tag)

        if tagsWithoutClosedSet.contains(tagName) {
            guard let tagBegin = html.range(of: "<", options: [], range: range) else {
                assert(rangeStack.count > 0)
                _ = rangeStack.popLast()

                if rangeStack.count == 1 {
                    childs.append(tag)
                }

                continue
            }

            let tagBeginClosed = tagBegin.lowerBound ..< html.index(after: tagBegin.upperBound)

            guard html[tagBeginClosed] == "</" else {
                assert(rangeStack.count > 0)
                _ = rangeStack.popLast()
                if rangeStack.count == 1 {
                    childs.append(tag)
                }
                continue
            }

            let searchRange = tagBegin.upperBound ..< html.endIndex
            guard let tagEnd = html.range(of: ">", options: [], range: searchRange) else {
                assert(rangeStack.count > 0)
                _ = rangeStack.popLast()

                if rangeStack.count == 1 {
                    childs.append(tag)
                }
                continue
            }

            let tagRange = tagBegin.lowerBound ..< tagEnd.upperBound

            let nextTag = html[tagRange]
            let nextTagName = htmlTag(nextTag)

            if tagName == nextTagName {
                assert(rangeStack.count > 0)
                _ = rangeStack.popLast()

                if rangeStack.count == 1 {
                    childs.append(tag)
                }

                range = tagRange.upperBound ..< html.endIndex

                continue
            }
        }
    }

    return childs
}
