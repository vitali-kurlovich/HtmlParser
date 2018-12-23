import XCTest
@testable import HtmlParser

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

final class HtmlParserTests: XCTestCase {
    
    func testHTMLTag() {
        let html = """
<t id =    "2" attr="   test ">
 text   1   2         3
 <h  >     text2     </h>

</t>
"""
        let tag = HTMLTag(html)
        
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
    
    
    func testHTMLDocument() {
        let tag = HTMLTag(htmlDoc)
        
        debugPrint(tag.tag)
    }
    
}

