import XCTest
@testable import HtmlParser

// <!DOCTYPE html>
// <meta charset="utf-8" />

private let htmlDoc = """

<html>
<head>

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
        
        let tagH = tag.childs!.first!
        XCTAssertEqual(tagH.tag, "h")
        
        XCTAssertEqual(tagH.text, " text2 ")
        
        XCTAssertNil(tagH.attributes)
        XCTAssertNil(tagH.childs)
        
    }
    
    func testHtmlNode() {
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
        let header = doc.head
        
        let childs = doc.childs
         XCTAssertNotNil(childs)
        XCTAssertNotNil(header)
        
        XCTAssertEqual( doc.head?.find(tag: "title")?.text, "HTML Document" )
       // debugPrint(tag.tag)
    }
    
}

