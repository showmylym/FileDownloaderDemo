//
//  ViewController.swift
//  FileDownloaderDemo
//
//  Created by leiyiming on 13/02/2017.
//  Copyright © 2017 leiyiming. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    //控件
    private var downloadButton: UIButton!
    private var pieProgressView: LYMPieProgressView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        constructDownloadButton()
        
    }

    //MARK: - Construct
    private func constructDownloadButton() {
        let buttonWidth: CGFloat = 200
        let x = (view.frame.width - buttonWidth) / 2.0
        let y = (view.frame.height - buttonWidth) / 2.0
        downloadButton = UIButton(frame: CGRect(x: x, y: y, width: buttonWidth, height: buttonWidth))
        view.addSubview(downloadButton)
        downloadButton.addTarget(self, action: #selector(downloadButtonPressed(sender:)), for: .touchUpInside)
        downloadButton.backgroundColor = UIColor.lightGray
        downloadButton.setTitle("点击下载", for: .normal)
        downloadButton.layer.cornerRadius = buttonWidth / 2.0
        downloadButton.layer.masksToBounds = true
    }
    
    //MARK: - Private methods
    private func updatePieProgressView(progress: Int64) {
        //构造饼图进度视图
        if pieProgressView == nil {
            pieProgressView = LYMPieProgressView(frame: downloadButton.bounds, progressColor: UIColor.white.withAlphaComponent(0.4))
            downloadButton.addSubview(pieProgressView!)
        }
        pieProgressView?.update(progress: CGFloat(progress) / 100)
    }

    //MARK: - Control events handler
    @objc private func downloadButtonPressed(sender: UIButton) {
        //点击后下载时禁用按钮
        downloadButton.isEnabled = false
        downloadButton.setTitle("正在下载", for: .normal)
        
        let fromServerURLStr = "https://raw.githubusercontent.com/showmylym/FileDownloaderDemo/master/QQMusic.app.zip"
        let toLocalFilePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0].appending((fromServerURLStr as NSString).lastPathComponent)
        weak var weakSelf = self
        FileDownloadUtil.startTaskDownload(from: fromServerURLStr, to: toLocalFilePath) { (taskState) in
            weakSelf?.updatePieProgressView(progress: taskState.progress)
            if taskState.isCompleted {
                weakSelf?.downloadButton.isEnabled = true
                if taskState.progress == 100 {
                    weakSelf?.downloadButton.setTitle("下载完成", for: .normal)
                } else {
                    weakSelf?.downloadButton.setTitle("下载失败", for: .normal)
                }
                //移除进度条
                weakSelf?.pieProgressView?.removeFromSuperview()
            }
        }
        
    }

}

