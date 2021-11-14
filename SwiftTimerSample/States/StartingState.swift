//
//  StartingState.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class StartingState: NSObject, State {
    
    static let shared = StartingState()
    
    var name: String {
        String(describing: type(of: self))
    }

    var nextState: State? {
        RunningState.shared
    }

    private override init() {}

    func didEnter(_ context: Job) {
        context.executeState()
    }

}
