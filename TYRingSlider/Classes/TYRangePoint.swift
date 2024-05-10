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
    
    var isCross = false
    
    var lineTag: Int = -1
    
    var next: TYRangePoint?
    
    weak var previous: TYRangePoint?
    
    override var description: String {
//        return "CircularPoint(index: \(index), value: \(value), isStart: \(isStart), isEnd: \(isEnd), hasPrevious: \(previous != nil), hasNext: \(next != nil)"
//        return "CircularPoint(index: \(index), value: \(value), isCross: \(isCross), isStart: \(isStart), isEnd: \(isEnd), lineTag: \(lineTag)"
        return "CircularPoint(index: \(index), value: \(value / 3600.0), isCross: \(isCross), lineTag: \(lineTag)"
    }
}
