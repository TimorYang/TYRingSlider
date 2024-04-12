//
//  CircularControl.swift
//  TYRingSlider_Example
//
//  Created by TeemoYang on 2024/4/11.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

class CircularControl: UIControl {
    // 控件的圆心和半径
    private let centerPoint: CGPoint
    private let radius: CGFloat
    
    // a和b两个点的角度位置
    private var aAngle: CGFloat = 0.0
    private var bAngle: CGFloat = 90.0 // 示例初始值，你可以根据需要调整
    
    // 点击状态和跟随状态
    private var isDraggingA = false
    private var isABColliding = false

    override init(frame: CGRect) {
        self.centerPoint = CGPoint(x: frame.width / 2, y: frame.height / 2)
        self.radius = min(frame.width, frame.height) / 2
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // 画圆
        context.addArc(center: centerPoint, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        context.setStrokeColor(UIColor.black.cgColor)
        context.strokePath()
        
        // 画点a和点b
        drawPoint(at: aAngle, color: .red, in: context)
        drawPoint(at: bAngle, color: .blue, in: context)
    }
    
    private func drawPoint(at angle: CGFloat, color: UIColor, in context: CGContext) {
        let pointX = centerPoint.x + radius * cos(angle * .pi / 180)
        let pointY = centerPoint.y + radius * sin(angle * .pi / 180)
        let pointRect = CGRect(x: pointX - 10, y: pointY - 10, width: 20, height: 20)
        
        context.setFillColor(color.cgColor)
        context.addEllipse(in: pointRect)
        context.fillPath()
    }
    
    // 触摸事件处理，以支持拖动
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)
        
        // 检查是否触摸了a点
        if isTouchingPoint(at: aAngle, touchPoint: touchPoint) {
            isDraggingA = true
            return true
        }
        
        return false
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard isDraggingA else { return false }
        
        let touchPoint = touch.location(in: self)
        let angle = calculateAngle(for: touchPoint)
        
        // 更新a的角度，并检查是否和b碰撞
        aAngle = angle
        checkCollisionAndAdjustIfNeeded()
        
        // 重绘
        self.setNeedsDisplay()
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isDraggingA = false
    }
    
    private func isTouchingPoint(at angle: CGFloat, touchPoint: CGPoint) -> Bool {
        let pointX = centerPoint.x + radius * cos(angle * .pi / 180)
        let pointY = centerPoint.y + radius * sin(angle * .pi / 180)
        let distance = sqrt(pow(touchPoint.x - pointX, 2) + pow(touchPoint.y - pointY, 2))
        return distance <= 20 // 触摸区域半径
    }
    
    private func calculateAngle(for touchPoint: CGPoint) -> CGFloat {
        let dx = touchPoint.x - centerPoint.x
        let dy = touchPoint.y - centerPoint.y
        let angle = atan2(dy, dx) * 180 / .pi
        return angle < 0 ? angle + 360 : angle
    }
    
    private func checkCollisionAndAdjustIfNeeded() {
        // 计算角度差，并考虑环绕效果
        var deltaAngle = aAngle - bAngle
        if deltaAngle < 0 { deltaAngle += 360 }

        // 设定碰撞的阈值，例如5度以内视为碰撞
        let collisionThreshold: CGFloat = 5.0

        // 判断是否发生碰撞
        if deltaAngle < collisionThreshold || deltaAngle > (360 - collisionThreshold) {
            // 碰撞发生，根据a点的移动方向决定b点的反应
            if isDraggingA {
                // 如果a点正在被拖动，我们需要判断a点是顺时针还是逆时针移动，然后相应地调整b点的位置
                // 例如，我们可以简单地将b点的位置设置为与a点相同，表示b点跟随a点移动
                bAngle = aAngle
            }
        }
    }

}


