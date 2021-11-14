//
//  RunningState.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class RunningState: NSObject, State {
    
    static let shared = RunningState()
    
    var name: String {
        String(describing: type(of: self))
    }

    var nextState: State? {
        StoppingState.shared
    }

    private override init() {}

    func didEnter(_ context: Job) {
        context.executeState()
    }

}
