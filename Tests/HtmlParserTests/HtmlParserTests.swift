@testable import HtmlParser
import XCTest

private let htmlDoc = """
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <title>HTML Document</title>
    </head>
    <body>
        <p>
            <!--This is a comment. Comments are not displayed in the browser-->
            <b>This text is bold, <i> that is italic </i>.</b>
        </p>
        <script type="text/javascript">
            <!--
function displayMsg() {
alert("Hello World!")
}
            //-->
        </script>

        <img src="first.gif" alt="Smiley face" height="42" width="42">
        <!--This is a comment.-->
        <div id = "images">
            <b>Bold text <br> new line </b>
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

        // print(htmlDoc)
        let root = doc.root
        XCTAssertNotNil(root?.childs)
        XCTAssertEqual(root?.childs?.count, 2)

        let head = doc.head
        XCTAssertEqual(head?.childs?.count, 2)

        let meta = head?.first(tag: "meta")
        let charset = meta?.attributes?["charset"]
        XCTAssertEqual(charset, "utf-8")

        let title = head?.first(tag: "title")
        XCTAssertEqual(title?.text, "HTML Document")

        let body = doc.body
        XCTAssertEqual(body?.childs?.count, 5)

        let img = doc.first(tag: "img")
        let src = img?.attributes?["src"]
        XCTAssertEqual(src, "first.gif")
    }
}
