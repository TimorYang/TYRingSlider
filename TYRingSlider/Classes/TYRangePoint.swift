//
//  TYRangePoint.swift
//  TYRingSlider
//
//  Created by TeemoYang on 2024/4/10.
//

import UIKit

class TYRangePoint: NSObject {
    var index: Int = 0
    /// 值
    var value: CGFloat = CGFLOAT_MAX
    /// 是否是起点
    var isStart = false
    /// 是否是终点
    var isEnd = false
    
    var next: TYRangePoint?
    
    weak var previous: TYRangePoint?
    
    override var description: String {
//        return "CircularPoint(index: \(index), value: \(value), isStart: \(isStart), isEnd: \(isEnd), hasPrevious: \(previous != nil), hasNext: \(next != nil)"
        return "CircularPoint(index: \(index), value: \(value), isStart: \(isStart), isEnd: \(isEnd))"
    }
}
