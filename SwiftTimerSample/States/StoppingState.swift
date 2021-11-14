//
//  StoppingState.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class StoppingState: NSObject, State {
    
    static let shared = StoppingState()
    
    var name: String {
        String(describing: type(of: self))
    }

    var nextState: State? {
        StopState.shared
    }

    private override init() {}

    func didEnter(_ context: Job) {
        context.executeState()
    }

}
