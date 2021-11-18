//
//  Uploader+MD5.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/17.
//

import Foundation
import CommonCrypto

extension Uploader {

    static func hash(url: URL) throws -> String {

        let length = 1024 * 1024 * 1024 * 1024 * 1024 * 1024

        let handle = try FileHandle(forReadingFrom: url)
        defer {
            handle.closeFile()
        }

        var context = CC_MD5_CTX()

        CC_MD5_Init(&context)

        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: length)
            if data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0.baseAddress, numericCast(data.count))
                }
                return true
            } else {
                return false
            }
        }) {}

        var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

        _ = CC_MD5_Final(&digest, &context)

        return digest.map { String(format: "%02hhx", $0) }.joined()
    }

}
