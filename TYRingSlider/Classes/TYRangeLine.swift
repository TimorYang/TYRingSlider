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
    var lineType: String = ""
    var backgroundColor: UIColor = .clear
    var showThumb = false
    var next: TYRangeLine?
    weak var previous: TYRangeLine?

    
    init(start: CGFloat, end: CGFloat, lineColor: UIColor = .clear, lineType: String = "", backgroundColor: UIColor = .clear, showThumb: Bool = false) {
        self.start = start
        self.end = end
        self.lineColor = lineColor
        self.lineType = lineType
        self.backgroundColor = backgroundColor
        self.showThumb = showThumb
    }
    
    override var description: String {
        return "CircularIntervalPoint(start: \(start), end: \(end))"
    }
}
