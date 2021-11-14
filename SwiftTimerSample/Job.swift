//
//  Job.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/14.
//

import Foundation

@objc protocol Job {
    var isCancelled: Bool { get }
    var state: State { get }

    func executeState()
    func resume()
    func cancel()
}
