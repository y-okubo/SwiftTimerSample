//
//  ViewController.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/13.
//

import Cocoa

class ViewController: NSViewController {

    @objc var job: Job?
    var observation: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func resume(_ sender: Any) {
        print("resume")

        if self.job == nil {
            self.job = AwesomeJob()
        }

        self.observation = self.observe(\.job?.state, options: [.old, .new]) { object, change in
            guard let newValue = change.newValue as? State else {
                return
            }
            print("✨️✨️✨️ \(newValue.name) ✨️✨️✨️")
        }

        self.job!.resume()
    }

    @IBAction func cancel(_ sender: Any) {
        print("cancel")

        if let job = self.job {
            if job.isCancelled {
                self.job = nil
                self.observation = nil
            } else {
                job.cancel()
            }
        }
    }

}

