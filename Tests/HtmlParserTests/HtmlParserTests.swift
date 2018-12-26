@testable import HtmlParser
import XCTest

private let htmlDoc = """

<!DOCTYPE html>

<html>
    <head>
        <meta charset="utf-8" id = "a" />
        <title id = "b">HTML Document</title>
    </head>
    <body>
        <p >
            <!--This is a comment. Comments are not displayed in the browser-->
            <b >This text is bold, <i> that is italic </i>.</b>
        </p>
        <script type="text/javascript">
// <p>
// <b><a href = "link:\\site">Link</a></b>
// </p>

var br = 3
var div = 6
if 3<br || div> {}
var a = 5

if a <div {
}
function displayMsg() {
alert("Hello World!")
}

        </script>

        <img src="first.gif" alt="Smiley face" height="42" width="42" >
        <!--This is a comment.-->
        <div id = "images">
            <b  >Bold text <br> new line </b>
                <img src="second.gif"/>
            <p>
                <img src="third.gif"></img>
            </p>
        </div>
    </body>
</html>
"""

final class HtmlParserTests: XCTestCase {
    func testHtmlTag() {
        var tag = Substring("<br attr>")
        var result = htmlTag(tag)

        XCTAssertEqual(result, "br")

        tag = Substring("</br>")
        result = htmlTag(tag)
        XCTAssertEqual(result, "br")
    }

    func testHtmlNode() {
        let html = """
        <t id =    "2" attr="   test ">
         text   1   2         3
         <h  >     text2     </h>

        </t>
        """
        let tag = HtmlNode(html)

        XCTAssertEqual(tag.tag, "t")
        XCTAssertEqual(tag.text, " text 1 2 3 text2 ")

        XCTAssertEqual(tag.attributes, ["id": "2", "attr": "   test "])
        XCTAssertEqual(tag.childs?.count, 1)

        let tagH = tag.childs?.first
        XCTAssertEqual(tagH?.tag, "h")

        XCTAssertEqual(tagH?.text, " text2 ")

        XCTAssertNil(tagH?.attributes)
        XCTAssertNil(tagH?.childs)
    }

    func testHtmlNode2() {
        let html = """
        <head>
        <title>HTML Document</title>
        </head>
        """
        let node = HtmlNode(html)
        XCTAssertEqual(node.tag, "head")
        XCTAssertEqual(node.text, "HTML Document")

        let childs = node.childs
        XCTAssertEqual(childs?.count, 1)

        let title = childs?.first
        XCTAssertEqual(title?.tag, "title")
        XCTAssertEqual(title?.text, "HTML Document")
    }

    func testHtmlMetaNode() {
        let html = """
        <head>
        <title>HTML Document</title>
        <meta charset="utf-8" />
        </head>
        """
        let node = HtmlNode(html)
        XCTAssertEqual(node.tag, "head")
        XCTAssertEqual(node.text, "HTML Document")

        let childs = node.childs
        XCTAssertEqual(childs?.count, 2)

        let title = childs?.first
        XCTAssertEqual(title?.tag, "title")
        XCTAssertEqual(title?.text, "HTML Document")

        let meta = childs?.last
        XCTAssertEqual(meta?.tag, "meta")
    }

    func testHTMLDocument() {
        let doc = HtmlDocument(htmlDoc)

        let root = doc.root
        XCTAssertNotNil(root?.childs)
        XCTAssertEqual(root?.childs?.count, 2)

        let head = doc.head
        XCTAssertEqual(head?.childs?.count, 2)
        XCTAssertEqual(head?.nodesCount(ignoreComment: true), 2)
        XCTAssertEqual(head?.nodesCount(ignoreComment: false), 2)

        XCTAssertEqual(head?.nodes?[0].tag, "meta")
        XCTAssertEqual(head?.nodes?[1].tag, "title")

        let meta = head?.first(tag: "meta")
        let charset = meta?.attributes?["charset"]
        XCTAssertEqual(charset, "utf-8")

        let title = head?.first(tag: "title")
        XCTAssertEqual(title?.text, "HTML Document")

        let body = doc.body
        XCTAssertEqual(body?.childs?.count, 5)
        XCTAssertEqual(body?.nodesCount(ignoreComment: false), 13)
        XCTAssertEqual(body?.nodesCount(ignoreComment: true), 11)

        XCTAssertEqual(body?.nodes?[0].tag, "p")
        XCTAssertEqual(body?.nodes?[1].tag, "b")
        XCTAssertEqual(body?.nodes?[2].tag, "i")
        XCTAssertEqual(body?.nodes?[3].tag, "script")
        XCTAssertEqual(body?.nodes?[4].tag, "img")
        XCTAssertEqual(body?.nodes?[5].tag, "div")
        XCTAssertEqual(body?.nodes?[6].tag, "b")
        XCTAssertEqual(body?.nodes?[7].tag, "br")
        XCTAssertEqual(body?.nodes?[8].tag, "img")
        XCTAssertEqual(body?.nodes?[9].tag, "p")
        XCTAssertEqual(body?.nodes?[10].tag, "img")

        var iterator = body?.makeIterator()

        XCTAssertEqual(iterator?.next()?.tag, "body")
        XCTAssertEqual(iterator?.next()?.tag, "p")
        XCTAssertEqual(iterator?.next()?.tag, "b")
        XCTAssertEqual(iterator?.next()?.tag, "i")
        XCTAssertEqual(iterator?.next()?.tag, "script")
        XCTAssertEqual(iterator?.next()?.tag, "img")
        XCTAssertEqual(iterator?.next()?.tag, "div")
        XCTAssertEqual(iterator?.next()?.tag, "b")
        XCTAssertEqual(iterator?.next()?.tag, "br")
        XCTAssertEqual(iterator?.next()?.tag, "img")
        XCTAssertEqual(iterator?.next()?.tag, "p")
        XCTAssertEqual(iterator?.next()?.tag, "img")
        XCTAssertNil(iterator?.next())

        let img = doc.first(tag: "img")
        let src = img?.attributes?["src"]
        XCTAssertEqual(src, "first.gif")

        let script = body?.first(tag: "script")
        XCTAssertEqual(script?.type, "text/javascript")

        let div = body?["div"]
        XCTAssertEqual(div?.id, "images")

        let images = body?["#images"]
        XCTAssertEqual(images?.tag, "div")
    }
}
