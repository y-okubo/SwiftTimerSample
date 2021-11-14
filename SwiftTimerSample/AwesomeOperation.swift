//
//  AwesomeOperation.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class AwesomeOperation: Operation {

    enum State {
        case ready, executing, finished
    }

    var something: AwesomeSomething
    var random: Int

    private var state: State = .ready {
        willSet {
            willChangeValue(forKey: #keyPath(Operation.isExecuting))
            willChangeValue(forKey: #keyPath(Operation.isFinished))
            willChangeValue(forKey: #keyPath(Operation.isReady))
        }
        didSet {
            didChangeValue(forKey: #keyPath(Operation.isExecuting))
            didChangeValue(forKey: #keyPath(Operation.isFinished))
            didChangeValue(forKey: #keyPath(Operation.isReady))
        }
    }

    init(name: String, something: AwesomeSomething) {
        self.something = something
        self.random = 0
        super.init()
        self.name = name
    }

    override var isConcurrent: Bool {
        return true
    }

    override var isAsynchronous: Bool {
        return true
    }

    override var isReady: Bool {
        return state == .ready && super.isReady
    }

    override var isExecuting: Bool {
        return state == .executing
    }

    override var isFinished: Bool {
        return state == .finished
    }

    override func start() {
        if self.isCancelled {
            print("canceling...\(self.name!)")
            self.state = .finished
            return
        }

        self.state = .executing

        Thread.sleep(forTimeInterval: Double.random(in: 0.1 ... 1.0))

        self.random = Int.random(in: self.something.number ... 10000)

        self.state = .finished
    }

    override func cancel() {
        super.cancel()

        if isExecuting {
            state = .finished
        }

        print("cancel \(self.name!)")
    }
}
