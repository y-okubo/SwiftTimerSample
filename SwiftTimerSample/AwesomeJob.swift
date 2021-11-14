//
//  AwesomeJob.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Foundation

class AwesomeJob: NSObject, Job {
    
    @objc dynamic var state: State
    var cancelledState: State?
    var isCancelled: Bool = false
    var dispatchQueue: DispatchQueue
    var operationQueue: OperationQueue
    var retry: DispatchWorkItem?
    var awesomeSomethings: [AwesomeSomething] = []

    override init() {
        self.state = StartState.shared
        self.dispatchQueue = DispatchQueue(label: "background", qos: .background, attributes: [.concurrent], autoreleaseFrequency: .workItem, target: nil)
        self.operationQueue = OperationQueue()
        self.operationQueue.maxConcurrentOperationCount = 2
        super.init()
    }

    deinit {
        print("deinit job")
    }
    
    func changeState(nextState: State?) {
        guard let nextState = nextState else {
            print("no state")
            return
        }

        print("\(self.state.name) -> \(nextState.name)")
        self.state = nextState
        self.state.didEnter(self)
    }
    
    func resume() {
        guard self.state is StartState || self.state is SuspendState else {
            print("running")
            return
        }

        self.dispatchQueue.sync {
            self.isCancelled = false
        }

        self.dispatchQueue.async {
            if let cancelledState = self.cancelledState {
                self.changeState(nextState: cancelledState)
            } else {
                self.executeState()
            }
        }
    }
    
    func cancel() {
        self.dispatchQueue.sync {
            self.isCancelled = true
            self.retry?.cancel()
            self.operationQueue.cancelAllOperations()
            self.cancelledState = self.state
            self.changeState(nextState: SuspendingState.shared)
        }
    }
    
    func changeNextState() {
        self.changeState(nextState: self.state.nextState)
    }

    func executeState() {
        switch self.state {
        case is StartState:
            self.didStart()
        case is StartingState:
            self.didStarting()
        case is RunningState:
            self.didRunning()
        case is SuspendingState:
            self.didSuspending()
        case is SuspendState:
            self.didSuspend()
        case is StoppingState:
            self.didStopping()
        case is StopState:
            self.didStop()
        default:
            print("unexpected state")
        }
    }
    
}

extension AwesomeJob {

    func didStart() {
        print("start process s")
        for i in (0..<50) {
            awesomeSomethings.append(AwesomeSomething(i + 1000))
        }
        changeNextState()
        print("start process e")
    }

    func didStarting() {
        print("starting process s")
        self.accessHardToReachNetworks()
        print("starting process e")
    }

    func didRunning() {
        print("running process s")

        for (i, something) in self.awesomeSomethings.enumerated() {
            if something.result != 0 {
                continue
            }

            let operation = AwesomeOperation(name: "operation \(i)", something: something)
            operation.completionBlock = {
                something.result = operation.random
                print("complete \(operation.name!): \(operation.something.result)")
            }
            operationQueue.addOperation(operation)
        }

        operationQueue.waitUntilAllOperationsAreFinished()

        print("ok")

        if !self.isCancelled {
            changeNextState()
        }

        print("running process e")
    }

    func didStopping() {
        print("stopping process s")
        self.accessHardToReachNetworks()
        print("stopping process e")
    }

    func didStop() {
        print("stop process s")
        changeNextState()
        print("stop process e")
    }

    func didSuspending() {
        print("suspending process s")
        self.retry?.cancel()
        changeNextState()
        print("suspending process e")
    }

    func didSuspend() {
        print("suspend process s")
        changeNextState()
        print("suspend process e")
    }

    @objc func accessHardToReachNetworks() {
        let n = Int.random(in: 1 ... 10)

        if n == 10 {
            print("success (n = \(n))")
            changeNextState()
            return
        } else {
            print("failure (n = \(n))")
        }

        self.retry = DispatchWorkItem() { [unowned self] in
            guard let item = self.retry else {
                return
            }

            if item.isCancelled {
                print("retry cancelled")
                return
            }

            self.accessHardToReachNetworks()
        }

        self.dispatchQueue.asyncAfter(deadline: .now() + 1.0, execute: self.retry!)
    }

}
