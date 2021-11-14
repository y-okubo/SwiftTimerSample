//
//  SuspendState.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class SuspendState: NSObject, State {

    static let shared = SuspendState()

    var name: String {
        String(describing: type(of: self))
    }

    var nextState: State? {
        nil
    }

    private override init() {}

    func didEnter(_ context: Job) {
        context.executeState()
    }

}
