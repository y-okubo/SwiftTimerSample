//
//  State.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

@objc protocol State {

    var name: String { get }
    var nextState: State? { get }

    func didEnter(_ context: Job)

}
