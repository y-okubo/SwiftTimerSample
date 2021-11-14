//
//  StartState.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class StartState: NSObject, State {
    
    static let shared = StartState()

    var name: String {
        String(describing: type(of: self))
    }

    var nextState: State? {
        StartingState.shared
    }
    
    private override init() {}

    func didEnter(_ context: Job) {
        context.executeState()
    }

}
