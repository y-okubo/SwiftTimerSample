//
//  Uploader.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/15.
//

import Foundation

class Uploader: NSObject {

    struct Streams {
        let input: InputStream
        let output: OutputStream
    }

    var canWrite: Bool = false
    var timer: Timer? = nil

    lazy var session: URLSession = URLSession(configuration: .default,
                                              delegate: self,
                                              delegateQueue: .main)
    lazy var boundStreams: Streams = {
        var inputOrNil: InputStream? = nil
        var outputOrNil: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: 4096,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` will contain non-nil streams.")
        }
        // configure and open output stream
        output.delegate = self
        output.schedule(in: .current, forMode: .default)
        output.open()
        return Streams(input: input, output: output)
    }()

    func upload() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
            [weak self] timer in
            guard let self = self else { return }

            if self.canWrite {
                let message = "***** \(Date())\r\n"
                guard let messageData = message.data(using: .utf8) else { return }
                let messageCount = messageData.count
                print("write! \(messageCount)")
                let bytesWritten: Int = messageData.withUnsafeBytes() { (buffer: UnsafePointer<UInt8>) in
                    self.canWrite = false
                    return self.boundStreams.output.write(buffer, maxLength: messageCount)
                }
                print("written! \(bytesWritten)")
                if bytesWritten < messageCount {
                    // Handle writing less data than expected.
                }

                self.boundStreams.output.close()
                self.timer?.invalidate()

            } else {
                print("do not write")
            }
        }

        let url = URL(string: "https://httpbin.org/post")!
        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 10)
        request.httpMethod = "POST"
        let uploadTask = session.uploadTask(withStreamedRequest: request)
        uploadTask.resume()
    }

}

extension Uploader: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        completionHandler(boundStreams.input)
    }

    func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let response = task.response as? HTTPURLResponse else {
            return
        }
        print(task.countOfBytesReceived)
        print(response.allHeaderFields)
//        print(error)
        print("completed")
    }

}

extension Uploader: StreamDelegate {

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("call s")
        guard aStream == boundStreams.output else {
            print("mismatch")
            return
        }
        if eventCode.contains(.hasSpaceAvailable) {
            print("can write")
            canWrite = true
        }
        if eventCode.contains(.errorOccurred) {
            print("error")
        }
        print("call e")
    }

}
