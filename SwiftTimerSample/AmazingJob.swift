//
//  AmazingJob.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/14.
//

import Foundation

class AmazingJob: Job {

    var state: State
    var cancelledState: State?
    var isCancelled: Bool = false
    var dispatchGroup: DispatchGroup?
    var dispatchQueue: DispatchQueue?
    var operationQueue: OperationQueue?
    var retry: DispatchWorkItem?

    init() {
        self.state = StartState.shared
    }

    deinit {
        print("deinit")
    }

    func changeState(nextState: State) {
        print("\(String(describing: type(of: self.state))) -> \(String(describing: type(of: nextState)))")
        self.state = nextState
    }

    func resume() {
        guard self.state is StartState || self.state is SuspendState else {
            print("running!")
            return
        }
        
        self.dispatchGroup = DispatchGroup()
        self.dispatchQueue = DispatchQueue(label: "background", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)

        // 考察：意図的に待ちを入れる必要がありスマートではない（待ちをなくしたいという本来の目的を達成できない）

        let workItems = [
            DispatchWorkItem(block: { self.startProcess() }),
            DispatchWorkItem(block: { self.startingProcess() }),
            DispatchWorkItem(block: { self.runningProcess() }),
            DispatchWorkItem(block: { self.stoppingProcess() }),
            DispatchWorkItem(block: { self.stopProcess() })
        ]

        for workItem in workItems {
            dispatchQueue!.async(group: self.dispatchGroup!, execute: workItem)
        }

        dispatchGroup!.notify(queue: .main) {
            print("All Process Done!")
        }

        self.isCancelled = false

//        if let cancelledState = self.cancelledState {
//            self.changeState(nextState: cancelledState)
//        } else {
//            self.state.perform(self)
//        }
    }

    func cancel() {
        self.isCancelled = true
        self.cancelledState = self.state
        self.changeState(nextState: SuspendingState.shared)
        self.dispatchQueue = nil
        self.operationQueue?.cancelAllOperations()
        self.operationQueue = nil
    }

    func changeNextState() {
        switch self.state {
        case is StartState:
            self.changeState(nextState: StartingState.shared)
        case is StartingState:
            self.changeState(nextState: RunningState.shared)
        case is RunningState:
            self.changeState(nextState: StoppingState.shared)
        case is SuspendingState:
            self.changeState(nextState: SuspendState.shared)
        case is SuspendState:
            break
        case is StoppingState:
            self.changeState(nextState: StopState.shared)
        case is StopState:
            break
        default:
            print("unexpected state")
        }
    }

    func executeState() {
        switch self.state {
        case is StartState:
            self.startProcess()
        case is StartingState:
            self.startingProcess()
        case is RunningState:
            self.runningProcess()
        case is SuspendingState:
            self.suspendingProcess()
        case is SuspendState:
            self.suspendProcess()
        case is StoppingState:
            self.stoppingProcess()
        case is StopState:
            self.stopProcess()
        default:
            print("unexpected state")
        }
    }

}

extension AmazingJob {

    func startProcess() {
        print("start process s")
        changeNextState()
        print("start process e")
    }

    func startingProcess() {
        print("starting process s")
        self.timerProcess()
        print("starting process e")
    }

    func runningProcess() {
        print("running process s")
        self.timerProcess()
        print("running process e")
    }

    func stoppingProcess() {
        print("stopping process s")
        self.timerProcess()
        print("stopping process e")
    }

    func stopProcess() {
        print("stop process s")
        changeNextState()
        print("stop process e")
    }

    func suspendingProcess() {
        print("suspending process s")
        self.retry?.cancel()
        changeNextState()
        print("suspending process e")
    }

    func suspendProcess() {
        print("suspend process s")
        changeNextState()
        print("suspend process e")
    }

    @objc func timerProcess() {
        print("call main thread: \(Thread.isMainThread)")

        let n = Int.random(in: 1 ... 10)
        let timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerProcess), userInfo: nil, repeats: false)

        if n == 10 {
            print("success (n = \(n))")
            timer.invalidate()
            changeNextState()
            return
        } else {
            print("failure (n = \(n))")
        }

        RunLoop.current.add(timer, forMode: .common)
        RunLoop.current.run()
    }

}
