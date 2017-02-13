//
//  FileDownloadUtil.swift
//  miqu
//
//  Created by leiyiming on 19/01/2017.
//  Copyright © 2017 CZK. All rights reserved.
//

import Foundation

// 全局通知定义
let NotificationFileDownloadProgress = "NotificationFileDownloadProgress"
let NotificationFileDownloadComplete = "NotificationFileDownloadComplete"

// 常量定义
let MaxFileDownloadTaskConcurrentCount = 5 //最大文件同时下载数

// 通知中携带的下载任务状态
let kDownloadTaskState = "kDownloadTaskState"
struct DownloadTaskState {
    var progress: Int64 = 0
    var isCompleted = false
    var fileURLStr = ""
}

class FileDownloadUtil: NSObject {
    static let instance = FileDownloadUtil()
    
    //操作队列
    private let queue = OperationQueue()
    
    private override init() {
        super.init()
        //最大同时进行的任务数
        queue.maxConcurrentOperationCount = MaxFileDownloadTaskConcurrentCount
        
        //TEST: 测试代码
        checkOperationCount()
    }
    
    /// 检查并更新任务的回调闭包
    ///
    /// - Parameters:
    ///   - serverURL: 下载文件的服务器URL
    ///   - downloadCallback: 下载回调
    /// - Returns: 当前是否存在这个任务。是，返回true
    class func checkAndUpdateTaskCallback(from serverURL: String,
                                           downloadCallback: ((_ state: DownloadTaskState) -> Void)?) -> Bool {
        //检查正在下载的任务队列中，是否已存在目标url任务
        for operation in instance.queue.operations {
            if let unwrapOperation = operation as? FileDownloadOperation {
                if unwrapOperation.urlStr == serverURL {
                    //正在下载的任务中有新任务的url，不予添加新任务，只修改回调闭包
                    unwrapOperation.downloadCallback = downloadCallback
                    return true
                }
            }
        }
        return false
    }
    
    ///
    /// 下载一个文件
    ///
    /// - Parameters:
    ///   - serverURL: 下载文件的服务器URL
    ///   - localFilePath: 本地将要存储的路径
    ///   - downloadCallback: 下载回调
    class func startTaskDownload(from serverURL: String,
                                 to localFilePath: String,
                                 downloadCallback: ((_ state: DownloadTaskState) -> Void)?) {
        //检查正在下载的任务队列中，是否已存在目标url任务
        if checkAndUpdateTaskCallback(from: serverURL, downloadCallback: downloadCallback) {
            return
        }
        //启动新任务
        let operation = FileDownloadOperation(urlStr: serverURL, localFilePath: localFilePath)
        operation.downloadCallback = downloadCallback
        instance.queue.addOperation(operation)
    }
    
    class func cancelTask(from serverURL: String) {
        print("即将取消一个下载任务:\(serverURL)，当前队列操作数:\(instance.queue.operationCount)")
        for operation in instance.queue.operations {
            if let unwrapOperation = operation as? FileDownloadOperation {
                if unwrapOperation.urlStr == serverURL {
                    unwrapOperation.cancel()
                }
            }
        }
        print("已取消一个下载任务:\(serverURL)，当前队列操作数:\(instance.queue.operationCount)")
    }
    
    func checkOperationCount() {
        print("当前队列操作数:\(queue.operationCount)")
        let delay5Sec = DispatchTime.now() + Double(5)
        DispatchQueue.main.asyncAfter(deadline: delay5Sec) { 
            self.checkOperationCount()
        }
    }
}



///下载任务类
class FileDownloadOperation : Operation {
    //数据
    fileprivate (set) var urlStr: String = ""
    fileprivate (set) var localFilePath: String = ""
    fileprivate var progress: Int64 = 0
    fileprivate var isDownloadCompleted = false

    //网络会话
    fileprivate (set) var session: URLSession?
    
    //任务控制
    private var isDoing = false
    private var isDone = false
    
    //回调
    fileprivate var downloadCallback: ((_ state: DownloadTaskState) -> Void)?

    
    init(urlStr: String, localFilePath: String) {
        super.init()
        self.urlStr = urlStr
        self.localFilePath = localFilePath
    }
    
    private override init() {
        super.init()
    }
    
    deinit {
        downloadCallback = nil
    }
    
    override var isAsynchronous: Bool {
        get {
            return true
        }
    }
    
    override var isFinished: Bool {
        return isDone
    }
    
    override var isExecuting: Bool {
        return isDoing
    }
    
    override func start() {
        if isCancelled {
            self.willChangeValue(forKey: "isFinished")
            isDone = true
            self.didChangeValue(forKey: "isFinished")
            return
        }
        self.willChangeValue(forKey: "isExecuting")
        isDoing = true
        self.didChangeValue(forKey: "isExecuting")
        print("准备下载文件，来自:\(urlStr)，目标路径:\(localFilePath)，是否在主线程:\(Thread.isMainThread)")
        main()
    }
    
    override func main() {
        if isCancelled {
            self.willChangeValue(forKey: "isExecuting")
            isDoing = true
            self.didChangeValue(forKey: "isExecuting")
            return
        }
        guard let url = URL(string: urlStr) else {
            return
        }
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10)
        let task = session?.downloadTask(with: request)
        task?.resume()
    }
    
    //任务需要中途停止，调用此方法
    fileprivate func stop() {
        session?.invalidateAndCancel()
        self.willChangeValue(forKey: "isExecuting")
        isDoing = false
        self.didChangeValue(forKey: "isExecuting")
        
        self.willChangeValue(forKey: "isFinished")
        isDone = true
        self.didChangeValue(forKey: "isFinished")
    }
    
}

///下载任务类回调
extension FileDownloadOperation : URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("文件下载完成:\(error?.localizedDescription ?? "")")
        stop()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if isCancelled {
            stop()
        }
        if totalBytesExpectedToWrite > 0 {
            progress = totalBytesWritten * 100 / totalBytesExpectedToWrite
            print("文件下载进度:\(progress)%，\(totalBytesWritten)/\(totalBytesExpectedToWrite)")
        } else {
            progress = 100
            print("文件期望总大小为0，无法计算下载进度")
        }
        
        DispatchQueue.main.async {
            let state = DownloadTaskState(progress: self.progress, isCompleted: self.isDownloadCompleted, fileURLStr: self.urlStr)
            self.downloadCallback?(state)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if isCancelled {
            stop()
        }
        //修改下载完毕标识
        self.isDownloadCompleted = true

        //移动文件
        let localFileURL = URL(fileURLWithPath: localFilePath)
        do {
            if FileManager.default.fileExists(atPath: localFilePath) {
                print("目标路径已存在同名文件，即将删除它")
                try? FileManager.default.removeItem(at: localFileURL)
            }
            try FileManager.default.moveItem(at: location, to: localFileURL)
            DispatchQueue.main.async {
                let state = DownloadTaskState(progress: self.progress, isCompleted: self.isDownloadCompleted, fileURLStr: self.urlStr)
                self.downloadCallback?(state)
            }
        } catch {
            print("文件下载完毕，但移动文件时出错:\(error)")
            try? FileManager.default.removeItem(at: location)
            try? FileManager.default.removeItem(atPath: localFileURL.absoluteString)
            self.progress = 0
            let state = DownloadTaskState(progress: self.progress, isCompleted: self.isDownloadCompleted, fileURLStr: self.urlStr)
            self.downloadCallback?(state)
        }
    }
 
}
