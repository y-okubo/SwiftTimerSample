//
//  SuspendingState.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class SuspendingState: NSObject, State {

    static let shared = SuspendingState()

    var name: String {
        String(describing: type(of: self))
    }

    var nextState: State? {
        SuspendState.shared
    }

    private override init() {}

    func didEnter(_ context: Job) {
        context.executeState()
    }

}
