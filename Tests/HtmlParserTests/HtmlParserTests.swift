import XCTest
@testable import HtmlParser

//
// <meta charset="utf-8" />

private let htmlDoc = """
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <title>HTML Document</title>
    </head>
    <body>
        <p>
            <b>This text is bold, <i> that is italic </i>.</b>
        </p>
    </body>
</html>
"""


// <!DOCTYPE html>
private let htmlDocSimple = """

<html>
    <head>
        <meta charset="utf-8" />
        <title>HTML Document</title>
    </head>
    <body>
        <p>
            <b>This text is bold, <i> that is italic </i>.</b>
        </p>
    </body>
</html>
"""

final class HtmlParserTests: XCTestCase {
    func testHtmlTag() {
        var tag = Substring("<br attr>")
        var result =  htmlTag(tag)
        
        XCTAssertEqual(result, "br")
        
        tag = Substring("</br>")
        result =  htmlTag(tag)
        XCTAssertEqual(result, "br")
    }
    
    
    func testParseChild() {
        let childs  = parseChild(Substring(htmlDocSimple))
        XCTAssertEqual(childs.count , 2)
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
        
        XCTAssertEqual(tag.attributes, ["id": "2", "attr":"   test "])
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
        let doc = HtmlDocument(htmlDocSimple)
        
        //print(htmlDoc)
        let root = doc.root
         XCTAssertNotNil(root?.childs)
         XCTAssertEqual(root?.childs?.count, 2)
        
//        let head = doc.head
//        XCTAssertNotNil(head)
        
        
       // XCTAssertEqual( doc.head?.first(tag: "title")?.text, "HTML Document" )
       // debugPrint(tag.tag)
    }
    
}

