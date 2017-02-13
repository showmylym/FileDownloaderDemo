//
//  LYMPieProgressView.swift
//  miqu
//
//  Created by leiyiming on 21/01/2017.
//  Copyright © 2017 CZK. All rights reserved.
//

import Foundation
import UIKit

class LYMPieProgressView: UIView {
    
    //数据
    private (set) var progressValue: CGFloat = 0
    private (set) var progressColor: UIColor!
    
    //初始化方法
    init(frame: CGRect, progressColor: UIColor) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        self.progressColor = progressColor
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///更新进度
    func update(progress value: CGFloat) {
        progressValue = value
        //更新界面
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let radius = rect.width / 2
        //先用透明背景填充
        context.addArc(center: center, radius: radius, startAngle: -CGFloat(M_PI / 2), endAngle: CGFloat(M_PI + M_PI / 2), clockwise: true)
        context.setFillColor(UIColor.clear.cgColor)
        context.fill(bounds)
        
        //画圆
        context.addArc(center: center, radius: radius, startAngle: -CGFloat(M_PI / 2), endAngle: -CGFloat(M_PI / 2) + CGFloat(M_PI * 2) * progressValue, clockwise: false)
        context.addLine(to: center)
        context.setFillColor(progressColor.cgColor)
        context.fillPath()
    }
    
}
