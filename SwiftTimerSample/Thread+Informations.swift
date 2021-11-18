//
//  Thread+Informations.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/16.
//

import Foundation

extension Thread {
    func number() -> Int {
        return self.value(forKeyPath: "private.seqNum") as! Int
    }

    func queue() -> String {
        let name = __dispatch_queue_get_label(nil)
        return String(cString: name, encoding: .utf8)!
    }

    func label() -> String {
        if let name = self.name {
            return name
        } else {
            return "(no name)"
        }
    }
}
