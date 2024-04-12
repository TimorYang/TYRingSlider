//
//  TYRangeLine.swift
//  TYRingSlider
//
//  Created by TeemoYang on 2024/4/10.
//

import UIKit

class TYRangeLine: NSObject {
    var start: CGFloat = CGFLOAT_MAX
    var end: CGFloat = CGFLOAT_MAX
    var startThumbCenter: CGPoint = CGPoint.zero
    var endThumbCenter: CGPoint = CGPoint.zero
    var lineColor: UIColor = .clear
    var showThumb = false
    var next: TYRangeLine?
    weak var previous: TYRangeLine?

    
    init(start: CGFloat, end: CGFloat, lineColor: UIColor = .clear, showThumb: Bool = false) {
        self.start = start
        self.end = end
        self.lineColor = lineColor
        self.showThumb = showThumb
    }
    
    override var description: String {
        return "CircularIntervalPoint(start: \(start), end: \(end))"
    }
}
