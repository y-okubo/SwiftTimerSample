//
//  UploaderTests.swift
//  SwiftTimerSampleTests
//
//  Created by Yuki Okubo on 2021/11/15.
//

import XCTest

class UploaderTests: XCTestCase {

    var fileURL: URL?

    override func setUpWithError() throws {
        self.fileURL = Bundle(for: type(of: self)).url(forResource: "Lena", withExtension: "tif")
    }

    func testHash() throws {
        let digest = try Uploader.hash(url: self.fileURL!)
        XCTAssertEqual(digest, "7278246cf26b76e0ca398e7f739b527e")
    }

}
