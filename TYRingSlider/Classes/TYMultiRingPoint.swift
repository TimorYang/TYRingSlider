//
//  TYMultiRingPoint.swift
//  TYRingSlider
//
//  Created by TeemoYang on 2024/4/9.
//

import UIKit

class TYMultiRingPoint: NSObject {
    /// 值
    var value: CGFloat = CGFLOAT_MAX
    /// 位置
    var center: CGPoint = CGPoint.zero
    /// 是否是起点
    var isStart = false
    /// 是否是终点
    var isEnd = false
    
    var next: TYMultiRingPoint?
    
    weak var previous: TYMultiRingPoint?
    
    override var description: String {
        return "CircularPoint(value: \(value), isStart: \(isStart), isEnd: \(isEnd), hasPrevious: \(previous != nil), hasNext: \(next != nil)"
    }
}
