//
//  Uploader.swift
//  SwiftTimerSample
//
//  Created by Yuki Okubo on 2021/11/15.
//

import Foundation
import CommonCrypto

class Uploader: NSObject {

    struct Streams {
        let input: InputStream
        let output: OutputStream
    }

    var canWrite: Bool = false
    var fileURL: URL
    var writeTimer: Timer? = nil
    var pollingTimer: Timer? = nil
    var delegateQueue = OperationQueue()
    var mainQueue = DispatchQueue(label: "Uploader.main", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: .global(qos: .default))
    var pollingQueue = DispatchQueue(label: "Uploader.polling", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    var writeQueue = DispatchQueue(label: "Uploader.write", qos: .background, attributes: [], autoreleaseFrequency: .workItem, target: nil)
    var pollingWorkItem: DispatchWorkItem = DispatchWorkItem {}
    var writeWorkItem: DispatchWorkItem = DispatchWorkItem {}

    lazy var session: URLSession = URLSession(configuration: .default,
                                              delegate: self,
                                              delegateQueue: delegateQueue)
    lazy var stream: Streams = {
        var inputOrNil: InputStream? = nil
        var outputOrNil: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: 512,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` will contain non-nil streams.")
        }

        output.delegate = self
        return Streams(input: input, output: output)
    }()

    override init() {
        self.fileURL = Bundle(for: type(of: self)).url(forResource: "Iroha", withExtension: "txt")!

        super.init()

        self.delegateQueue.maxConcurrentOperationCount = 4
        self.delegateQueue.name = "Uploader.delegate"

        self.pollingWorkItem = DispatchWorkItem { [weak self] in
            print("thread: \(Thread.current.number()) queue: \(Thread.current.queue())")

            guard let self = self else {
                print("self is nil in thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
                return
            }

            self.stream.output.schedule(in: .current, forMode: .common)
            self.stream.output.open()

            self.pollingTimer = Timer(timeInterval: 1.0, repeats: true) { _ in
                print("thread: \(Thread.current.number()) queue: \(Thread.current.queue())")

                if self.pollingWorkItem.isCancelled == true {
                    self.pollingTimer?.invalidate()
                    self.pollingTimer = nil
                }
            }

            RunLoop.current.add(self.pollingTimer!, forMode: .common)
            print("polling runloop run")
            RunLoop.current.run()
            print("polling runloop stop")
        }

        self.writeWorkItem = DispatchWorkItem { [weak self] in
            print("thread: \(Thread.current.number()) queue: \(Thread.current.queue())")

            guard let self = self else {
                print("self is nil in thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
                return
            }

            self.writeTimer = Timer(timeInterval: 1.0, repeats: true) { _ in
                var totalBytesWritten: Int = 0
//                let blockSize = 131072 // 128KB
//                let blockSize = 1024 // 1KB
                let blockSize = 512

                if !self.canWrite {
                    print("can't write thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
                    return
                }

                do {
                    let handle = try FileHandle(forReadingFrom: self.fileURL)
                    defer {
                        handle.closeFile()
                    }

                    while autoreleasepool(invoking: {
                        let data = handle.readData(ofLength: blockSize)
                        if data.count > 0 {
                            let bytesWritten: Int = data.withUnsafeBytes() { buffer in
                                return self.stream.output.write(buffer, maxLength: data.count)
                            }

                            print("bytesWritten \(bytesWritten)")

                            if bytesWritten < data.count {
                                print("error")
                            }

                            totalBytesWritten += bytesWritten
                            print("totalBytesWritten: \(totalBytesWritten)")

                            return true // continue
                        } else {
                            return false // break
                        }
                    }) {}
                } catch {
                    print(error)
                }

                self.canWrite = false
                self.stream.output.close()
                print("close stream")
                self.writeTimer?.invalidate()
            }

            RunLoop.current.add(self.writeTimer!, forMode: .common)
            print("write runloop run")
            RunLoop.current.run()
            print("write runloop stop")
            self.writeTimer = nil
        }
    }

    func upload() {
        writeQueue.async(execute: writeWorkItem)
        pollingQueue.async(execute: pollingWorkItem)
        mainQueue.async {
            print("thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
            let url = URL(string: "http://localhost:8080/put")!
            var request = URLRequest(url: url,
                                     cachePolicy: .reloadIgnoringLocalCacheData,
                                     timeoutInterval: 10)
            request.httpMethod = "PUT"
            let uploadTask = self.session.uploadTask(withStreamedRequest: request)

            uploadTask.resume()
        }
    }

}

extension Uploader: URLSessionTaskDelegate {

    // MARK: - Handling Task Life Cycle Changes

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let response = task.response as? HTTPURLResponse else {
            return
        }

        print("URLSessionTaskDelegate.didCompleteWithError() thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
        print(response.allHeaderFields)
        print("status code: \(response.statusCode)")

        self.pollingWorkItem.cancel()

        if let error = error {
            print(error.localizedDescription)
        }
    }

    // MARK: - Working with Upload Tasks

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        print("totalBytesSent: \(totalBytesSent) totalBytesExpectedToSend: \(totalBytesExpectedToSend) URLSessionTaskDelegate thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        print("URLSessionTaskDelegate.needNewBodyStream() thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
        completionHandler(stream.input)
    }

    // MARK: - Handling Delayed and Waiting Tasks

//    func urlSession(_ session: URLSession,
//                    task: URLSessionTask,
//                    willBeginDelayedRequest request: URLRequest,
//                    completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
//
//
//    }
//
//    func urlSession(_ session: URLSession,
//                    taskIsWaitingForConnectivity task: URLSessionTask) {
//
//    }

}

extension Uploader: URLSessionDataDelegate {

    // MARK: - Handling Task Life Cycle Changes

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("URLSessionDataDelegate.completionHandler() thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didBecome streamTask: URLSessionStreamTask) {
        print("URLSessionDataDelegate.didBecome() thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
    }

    // MARK: - Receiving Data

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
//        print(String(data: data, encoding: .utf8)!)
        print("URLSessionDataDelegate.didReceive() thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
      do {
            let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let d = dic?["data"] as! String
            print("data.lengthOfBytes: \(d.lengthOfBytes(using: .utf8))")
        } catch {
            print(error.localizedDescription)
        }

    }

    // MARK: - Handling Caching

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @escaping (CachedURLResponse?) -> Void) {
        print("URLSessionDataDelegate.willCacheResponse() thread: \(Thread.current.number()) queue: \(Thread.current.queue())")
        completionHandler(nil)
    }

}

extension Uploader: StreamDelegate {

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("StreamDelegate.\(#function) thread: \(Thread.current.number()) queue: \(Thread.current.queue())")

        guard aStream == stream.output else {
            print("mismatch")
            return
        }

        switch eventCode {
        case .openCompleted:
            print("openCompleted")
        case .hasBytesAvailable:
            print("hasBytesAvailable")
        case .hasSpaceAvailable:
            print("canWrite")
            canWrite = true
        case .errorOccurred:
            if let error = aStream.streamError {
                print(error.localizedDescription)
            }
        case .endEncountered:
            print("endEncountered")
        default:
            print("unexpected")
        }
    }

}
