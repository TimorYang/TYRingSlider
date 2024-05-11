//
//  TYRangeRingSlider.swift
//  Pods
//
//  Created by Hamza Ghazouani on 25/10/2016.
//
//

import UIKit

open class TYRingSliderTimeRange: NSObject {
    open var start: CGFloat? // 起始时间
    open var end: CGFloat? // 结束时间
    open var lineColor = UIColor.clear // 填充颜色
    open var lineType: String = ""
    open var backgroundColor = UIColor.clear
    open var showThumb = false
    
    public init(start: CGFloat? = nil, end: CGFloat? = nil, lineColor: UIColor = .clear, lineType: String = "", backgroundColor: UIColor = .clear, showThumb: Bool = false) {
        self.start = start
        self.end = end
        self.lineColor = lineColor
        self.lineType = lineType
        self.backgroundColor = backgroundColor
        self.showThumb = showThumb
    }
    
    open override var description: String {
        return "TYRingSliderTimeRange(start: \(start), end: \(end), lineColor: \(lineColor), lineType: \(lineType), showThumb: \(showThumb)"
    }
}

/**
 A visual control used to select a range of values (between start point and the end point) from a continuous range of values.
 RangeCircularSlider use the target-action mechanism to report changes made during the course of editing:
 ValueChanged, EditingDidBegin and EditingDidEnd
 */
open class TYRangeRingSlider: TYRingSlider {

    public enum SelectedThumb {
        case startThumb
        case endThumb
        case none

        var isStart: Bool {
            return  self == SelectedThumb.startThumb
        }
        var isEnd: Bool {
            return  self == SelectedThumb.endThumb
        }
    }

    // MARK: Changing the Slider’s Appearance
    
    /**
     * The color used to tint start thumb
     * Ignored if the startThumbImage != nil
     *
     * The default value of this property is the groupTableViewBackgroundColor.
     */
    @IBInspectable
    open var startThumbTintColor: UIColor = UIColor.groupTableViewBackground
    
    /**
     * The color used to tint the stroke of the start thumb
     * Ignored if the startThumbImage != nil
     *
     * The default value of this property is the green color.
     */
    @IBInspectable
    open var startThumbStrokeColor: UIColor = UIColor.green
    
    /**
     * The stroke highlighted color of start thumb
     * The default value of this property is blue color
     */
    @IBInspectable
    open var startThumbStrokeHighlightedColor: UIColor = UIColor.purple
    
    
    /**
     * The image of the end thumb
     * Clears any custom color you may have provided for end thumb.
     *
     * The default value of this property is nil
     */
    open var startThumbImage: UIImage?
    
    
    // MARK: Accessing the Slider’s Value Limits
    
    open var timeRangeList: [TYRingSliderTimeRange]? {
        set {
            if let _timeRangeList = newValue {
                rangeLineList = timeRangeList2RangeLineList(from: _timeRangeList)
            } else {
                rangeLineList = nil
            }
        }
        get {
            if let _rangeLineList = rangeLineList {
                return rangeLineList2TimeRangeList(from: _rangeLineList)
            }
            return nil
        }
    }
    
    open var minDistance: CGFloat?

    open var enable: Bool {
        get {
            return _enable
        }
        set {
            if _enable != newValue { // 检查值是否改变
                _enable = newValue  // 更新私有存储属性
                setNeedsDisplay()   // 做一些操作，例如重绘
            }
        }
    }
    
    // MARK: public method
    open func allTimeRangeList() -> [TYRingSliderTimeRange]? {
        if let _rangeLineList = rangeLineList {
            return rangeLineList2TimeRangeList(from: _rangeLineList, includeFreeTime: true)
        }
        return nil
    }
    
    // MARK: private properties / methods
    
    /**
     * The center of the start thumb
     * Used to know in which thumb is the user gesture
     */
    fileprivate var startThumbCenter: CGPoint = CGPoint.zero
    
    /**
     * The center of the end thumb
     * Used to know in which thumb is the user gesture
     */
    fileprivate var endThumbCenter: CGPoint = CGPoint.zero
    
    /**
     * The last touched thumb
     * By default the value is none
     */
    fileprivate var selectedThumb: SelectedThumb = .none
    
    fileprivate var _enable: Bool = true // 私有存储属性
    
    /**
     Checks if the touched point affect the thumb
     
     The point affect the thumb if :
     The thumb rect contains this point
     Or the angle between the touched point and the center of the thumb less than 15°
     
     - parameter thumbCenter: the center of the thumb
     - parameter touchPoint:  the touched point
     
     - returns: true if the touched point affect the thumb, false if not.
     */
    internal func isThumb(withCenter thumbCenter: CGPoint, containsPoint touchPoint: CGPoint) -> Bool {
        // the coordinates of thumb from its center
        let rect = CGRect(x: thumbCenter.x - thumbRadius, y: thumbCenter.y - thumbRadius, width: thumbRadius * 2, height: thumbRadius * 2)
        if rect.contains(touchPoint) {
            return true
        }
        
        let angle = TYRingSliderHelper.angle(betweenFirstPoint: thumbCenter, secondPoint: touchPoint, inCircleWithCenter: bounds.center)
        let degree =  TYRingSliderHelper.degrees(fromRadians: angle)
        
        // tolerance 15°
        let isInside = degree < 15 || degree > 345
        return isInside
    }
    
    // MARK: - Override methods
    public override init(frame: CGRect) {
        super .init(frame: frame)
        self.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    // MARK: Drawing
    
    /**
     See superclass documentation
     */
    override open func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if radiusOffSet > 0 {
            drawOutCircularSlider(inContext: context)
        }
        
        drawCircularSlider(inContext: context)
        
        let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
        if let _rangeLineList = rangeLineList {
            _rangeLineList.traverse { (item: TYRangeLine) in
                // get start angle from start value
                let startAngle = TYRingSliderHelper.scaleToAngle(value: item.start, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                // get end angle from end value
                let endAngle = TYRingSliderHelper.scaleToAngle(value: item.end, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                drawShadowArc(fromAngle: startAngle, toAngle: endAngle, inContext: context, withColor: trackShadowColor)
                drawFilledArc(fromAngle: startAngle, toAngle: endAngle, inContext: context, withDiskColor: diskFillColor, withTrackColor: item.lineColor)
                
                return true
            }
            
            if let _ = step {
                drawTicks(center: self.bounds.center, radius: radius)
            }
            
            _rangeLineList.traverse { (item: TYRangeLine) in
                // get start angle from start value
                let startAngle = TYRingSliderHelper.scaleToAngle(value: item.start, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                // get end angle from end value
                let endAngle = TYRingSliderHelper.scaleToAngle(value: item.end, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                if item.showThumb {
                    // end thumb
                    endThumbTintColor.setFill()
                    (isHighlighted == true && selectedThumb == .endThumb) ? endThumbStrokeHighlightedColor.setStroke() : endThumbStrokeColor.setStroke()
                    item.endThumbCenter = drawThumbAt(endAngle, with: endThumbImage, inContext: context, followAngle: true)
                    
                    // start thumb
                    startThumbTintColor.setFill()
                    (isHighlighted == true && selectedThumb == .startThumb) ? startThumbStrokeHighlightedColor.setStroke() : startThumbStrokeColor.setStroke()
                    item.startThumbCenter = drawThumbAt(startAngle, with: startThumbImage, inContext: context, followAngle: true)
                }
                return true
            }
        } else {
            if let _ = step {
                drawTicks(center: self.bounds.center, radius: radius)
            }
        }
        
        if let _diskImage = diskImage {
            drawDiskImage(withImage: _diskImage, inContext: context)
        }
        
        if _enable == false {
            let startAngle = TYRingSliderHelper.scaleToAngle(value: 0, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
            // get end angle from end value
            let endAngle = TYRingSliderHelper.scaleToAngle(value: maximumValue, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
            drawDisableDisk(fromAngle: startAngle, toAngle: endAngle, inContext: context)
        }
    }
    
    // MARK: User interaction methods
    
    /**
     See superclass documentation
     */
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sendActions(for: .editingDidBegin)
        // the position of the pan gesture
        if enable == false {
            return false
        }
        let touchPosition = touch.location(in: self)
        selectedThumb = thumb(for: touchPosition)

        return selectedThumb != .none
    }
    
    /**
     See superclass documentation
     */
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard selectedThumb != .none else {
            return false
        }
        
        guard let _selectedRangeLine = selectedRangeLine else {
            return false
        }
        
        guard let _rangeLineList = rangeLineList else {
            return false
        }

        // the position of the pan gesture
        let touchPosition = touch.location(in: self)
        let startPoint = CGPoint(x: bounds.center.x, y: 0)
        let movementDirection = TYRingSliderHelper.determineMovementDirection(oldPoint: oldTouchPoint, newPoint: touchPosition, circleCenter: bounds.center)
        switch selectedThumb {
        case .startThumb:
            let oldValue = _selectedRangeLine.start
            var value = 0.0
            if let _step = step {
                value = round(newValue(from: oldValue, touch: touchPosition, start: startPoint) /  _step) * _step
            } else {
                value = newValue(from: oldValue, touch: touchPosition, start: startPoint)
            }
            if movementDirection == .clockwise {
                value = value == maximumValue ? minimumValue : value
            } else if movementDirection == .counterclockwise {
                value = value == minimumValue ? maximumValue : value
            }
            _selectedRangeLine.start = value
            if let _minDistance = minDistance {
                let pointList = lineList2PointList(from: _rangeLineList, startPoint: _selectedRangeLine, isBegin: true)
                switch movementDirection {
                case .clockwise:
                    /// 顺时针旋转
                    updatePointsCrossDayStatus(in: pointList, changedPointIndex: 0, movementDirection: .clockwise)
                    print("2222: ------------开始顺时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        repeat {
                            let distance = index % 2 == 0 ? _minDistance : 0.0
                            let nextPoint = currentPoint.next!
                            let result = arePointsTouchingOnSameCircle(point: currentPoint.value, targetPoint: nextPoint.value, movementDirection: .clockwise, distance: distance, isCrossDay: currentPoint.isCross && nextPoint.isCross)
                            if result {
                                print("133133:  发生碰撞")
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(nextPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value + distance <= maximumValue ? currentPoint.value + distance : currentPoint.value + distance - maximumValue
                                nextPoint.value = resultValue == maximumValue ? minimumValue : resultValue
                                print("2222: 碰撞后的数据 targetPoint: \(nextPoint.value / 3600)")
                                updatePointsCrossDayStatus(in: pointList, changedPointIndex: nextPoint.index, movementDirection: .clockwise)
                            } else {
                                print("2222: 无法找到碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(nextPoint.value / 3600), distance: \(distance / 3600)")
                                break
                            }
                            currentPoint = nextPoint
                            index += 1
                        } while currentPoint !== _firstPoint.previous!
                        print("2222:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("2222:  ")
                        print("133133:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("133133:  ")
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("2222: ------------结束顺时针旋转------------")
                case .counterclockwise:
                    /// 逆时针旋转
                    updatePointsCrossDayStatus(in: pointList, changedPointIndex: 0, movementDirection: .counterclockwise)
                    print("2222:: ------------开始逆时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        repeat {
                            let distance = index % 2 == 0 ? 0.0 : _minDistance
                            let previousPoint = currentPoint.previous!
                            let result = arePointsTouchingOnSameCircle(point: currentPoint.value, targetPoint: previousPoint.value, movementDirection: .counterclockwise, distance: distance, isCrossDay: currentPoint.isCross && previousPoint.isCross)
                            if result {
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(previousPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value >= distance ? currentPoint.value - distance : currentPoint.value - distance + maximumValue
                                previousPoint.value = resultValue == minimumValue ? maximumValue : resultValue
                                print("2222: 碰撞后的数据 targetPoint: \(previousPoint.value / 3600)")
                                updatePointsCrossDayStatus(in: pointList, changedPointIndex: previousPoint.index, movementDirection: .counterclockwise)
                            } else {
                                print("2222: 无法找到碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(previousPoint.value / 3600), distance: \(distance / 3600)")
                                break
                            }
                            currentPoint = previousPoint
                            index += 1
                        } while currentPoint !== _firstPoint.next!
                        print("2222:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("2222:  ")
                        print("133133:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("133133:  ")
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("2222:: ------------结束逆时针旋转------------")
                case .stationary:
                    print("101010666: 点没有移动或在完全对称的位置")
                }
            }
        case .endThumb:
            let oldValue = _selectedRangeLine.end
            var value = 0.0
            if let _step = step {
                value = round(newValue(from: oldValue, touch: touchPosition, start: startPoint) /  _step) * _step
            } else {
                value = newValue(from: oldValue, touch: touchPosition, start: startPoint)
            }
            if movementDirection == .clockwise {
                value = value == maximumValue ? minimumValue : value
            } else if movementDirection == .counterclockwise {
                value = value == minimumValue ? maximumValue : value
            }
            print("33333312: value: \(value)")
            _selectedRangeLine.end = value
            if let _minDistance = minDistance {
                let pointList = lineList2PointList(from: _rangeLineList, startPoint: _selectedRangeLine, isBegin: false)
                switch movementDirection {
                case .clockwise:
                    /// 顺时针旋转
                    updatePointsCrossDayStatus(in: pointList, changedPointIndex: 0, movementDirection: .clockwise)
                    print("2222: ------------开始顺时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        repeat {
                            let distance = index % 2 == 0 ? 0.0 : _minDistance
                            let nextPoint = currentPoint.next!
                            let result = arePointsTouchingOnSameCircle(point: currentPoint.value, targetPoint: nextPoint.value, movementDirection: .clockwise, distance: distance, isCrossDay: currentPoint.isCross && nextPoint.isCross)
                            if result {
                                print("133133:  发生碰撞")
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(nextPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value + distance <= maximumValue ? currentPoint.value + distance : currentPoint.value + distance - maximumValue
                                nextPoint.value = resultValue == maximumValue ? minimumValue : resultValue
                                print("2222: 碰撞后的数据 targetPoint: \(nextPoint.value / 3600)")
                                updatePointsCrossDayStatus(in: pointList, changedPointIndex: nextPoint.index, movementDirection: .clockwise)
                            } else {
                                print("2222: 无法找到碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(nextPoint.value / 3600), distance: \(distance / 3600)")
                                break
                            }
                            currentPoint = nextPoint
                            index += 1
                        } while currentPoint !== _firstPoint.previous!
                        print("2222:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("2222:  ")
                        print("133133:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("133133:  ")
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("2222: ------------结束顺时针旋转------------")
                case .counterclockwise:
                    /// 逆时针旋转
                    updatePointsCrossDayStatus(in: pointList, changedPointIndex: 0, movementDirection: .counterclockwise)
                    print("2222: ------------开始逆时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        repeat {
                            let distance = index % 2 == 0 ? _minDistance : 0.0
                            let previousPoint = currentPoint.previous!
                            let result = arePointsTouchingOnSameCircle(point: currentPoint.value, targetPoint: previousPoint.value, movementDirection: .counterclockwise, distance: distance, isCrossDay: currentPoint.isCross && previousPoint.isCross)
                            if result {
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(previousPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value >= distance ? currentPoint.value - distance : currentPoint.value - distance + maximumValue
                                previousPoint.value = resultValue == minimumValue ? maximumValue : resultValue
                                print("2222: 碰撞后的数据 targetPoint: \(previousPoint.value / 3600)")
                                updatePointsCrossDayStatus(in: pointList, changedPointIndex: previousPoint.index, movementDirection: .counterclockwise)
                            } else {
                                print("2222: 无法找到碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(previousPoint.value / 3600), distance: \(distance / 3600)")
                                break
                            }
                            currentPoint = previousPoint
                            index += 1
                        } while currentPoint !== _firstPoint.next!
                        print("2222:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("2222:  ")
                        print("133133:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("133133:  ")
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("2222: ------------结束逆时针旋转------------")
                case .stationary:
                    print("101010666: 点没有移动或在完全对称的位置")
                }
            }
        case .none:
            print("2222: none")
        }
        
        oldTouchPoint = touchPosition
        sendActions(for: .valueChanged)
        return true
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
    }


    // MARK: - Helpers
    open func thumb(for touchPosition: CGPoint) -> SelectedThumb {
        var result: SelectedThumb = .none
        if let _rangeLineList = rangeLineList {
            _rangeLineList.traverse { (item: TYRangeLine) in
                if isThumb(withCenter: item.startThumbCenter, containsPoint: touchPosition) {
                    result = .startThumb
                    selectedRangeLine = item
                    print("找到控制点了 - 起点")
                    return false
                } else if isThumb(withCenter: item.endThumbCenter, containsPoint: touchPosition) {
                    result = .endThumb
                    selectedRangeLine = item
                    print("找到控制点了 - 终点")
                    return false
                }
                return true
            }
        }
        return result
    }
    
    // MARK: - Action
    @objc private func actionForTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        guard let _rangeLineList = rangeLineList else { return }
        if _enable == false {
            return
        }
        let touchPoint = sender.location(in: self)
        var targetItem:TYRangeLine?
        _rangeLineList.traverse { (item: TYRangeLine) in
            if (isPointInArcCentered(touchPoint, item.start, item.end)) {
                targetItem = item
                return false
            }
            return true
        }
        if let _targetItem = targetItem {
            _rangeLineList.traverse { (item: TYRangeLine) in
                item.showThumb = false
                return true
            }
            _targetItem.showThumb = true
            setNeedsDisplay()
            sendActions(for: .valueChanged)
        }
    }
    
    // MARK: - Private Method
    private func rangeLineList2TimeRangeList(from lineList: TYRangeLineList, includeFreeTime: Bool = false) -> [TYRingSliderTimeRange]? {
        if includeFreeTime == false {
            return rangeLineList2TimeRangeList(from: lineList)
        } else {
            var minStart = maximumValue
            var targetLine: TYRangeLine?
            lineList.traverse { (item: TYRangeLine) in
                if minStart >= item.start {
                    minStart = item.start
                    targetLine = item
                }
                return true
            }
            var list = [TYRingSliderTimeRange]()
            lineList.traverse(from: targetLine!, forward: true) { (item: TYRangeLine) in
                let tmp = TYRingSliderTimeRange()
                tmp.start = item.start
                tmp.end = item.end == maximumValue ? 0 : item.end
                tmp.lineColor = item.lineColor
                tmp.lineType = item.lineType
                tmp.backgroundColor = item.backgroundColor
                tmp.showThumb = item.showThumb
                list.append(tmp)
                
                // 判断结尾和开始有没有间距
                if let _nextLine = item.next {
                    if _nextLine.start > item.end {
                        if _nextLine.start - item.end > 0 {
                            // 加一段 off picke 的
                            let tmp = TYRingSliderTimeRange()
                            tmp.start = item.end
                            tmp.end = _nextLine.start
                            tmp.lineColor = UIColor(red: 0.45, green: 0.78, blue: 0.54, alpha: 1)
                            tmp.lineType = NSLocalizedString("offpeak", comment: "Off-peak")
                            tmp.backgroundColor = .white
                            list.append(tmp)
                        }
                    } else if _nextLine.start < item.end  {
                        if maximumValue - item.end + _nextLine.start > 0 {
                            // 加一段 off picke 的
                            let tmp = TYRingSliderTimeRange()
                            tmp.start = item.end
                            tmp.end = _nextLine.start
                            tmp.lineColor = UIColor(red: 0.45, green: 0.78, blue: 0.54, alpha: 1)
                            tmp.lineType = NSLocalizedString("offpeak", comment: "Off-peak")
                            tmp.backgroundColor = .white
                            list.append(tmp)
                        }
                    }
                }
                return true
            }
            if list.count == 0 {
                return nil
            }
            return list
        }
    }
    
    private func rangeLineList2TimeRangeList(from lineList: TYRangeLineList) -> [TYRingSliderTimeRange]? {
        var list = [TYRingSliderTimeRange]()
        lineList.traverse { (item: TYRangeLine) in
            let tmp = TYRingSliderTimeRange()
            tmp.start = item.start
            tmp.end = item.end == maximumValue ? 0 : item.end
            tmp.lineColor = item.lineColor
            tmp.lineType = item.lineType
            tmp.backgroundColor = item.backgroundColor
            list.append(tmp)
            return true
        }
        if list.count == 0 {
            return nil
        }
        return list
    }
    
    private func timeRangeList2RangeLineList(from timeRangeList: [TYRingSliderTimeRange]) -> TYRangeLineList? {
        let result = TYRangeLineList()
        for item in timeRangeList {
            print("timeRangeList2RangeLineList: \(item)")
            let point = TYRangeLine(start: item.start!, end: item.end!, lineColor: item.lineColor, lineType: item.lineType, backgroundColor: item.backgroundColor, showThumb: item.showThumb)
            result.append(node: point)
        }
        if result.isEmpty {
            return nil
        }
        return result
    }
    
    private func arePointsTouchingOnSameCircle(point1: CGFloat, point2: CGFloat, distance: CGFloat?) -> Bool {
        guard let _distance = distance else { return false }
        let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
        let minRadian = TYRingSliderHelper.scaleToAngle(value: _distance, inInterval: interval)
        let minAngle = TYRingSliderHelper.degrees(fromRadians: minRadian)
        return TYRingSliderHelper.arePointsTouchingOnSameCircle(point1: point1, point2: point2, touchRadius: radius, minAngle: minAngle, interval: interval)
    }
    
    private func arePointsTouchingOnSameCircle(point1: CGFloat, point2: CGFloat, movementDirection:TYRingSliderHelper.MovementDirection, distance: CGFloat?) -> Bool {
        guard let _distance = distance else { return false }
        let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
        let minRadian = TYRingSliderHelper.scaleToAngle(value: _distance, inInterval: interval)
        let minAngle = TYRingSliderHelper.degrees(fromRadians: minRadian)
        return TYRingSliderHelper.arePointsTouchingOnSameCircle(point1: point1, point2: point2, movementDirection: movementDirection, touchRadius: radius, minAngle: 0, interval: interval)
    }
    
    private func arePointsTouchingOnSameCircle(point: CGFloat, targetPoint: CGFloat,  movementDirection:TYRingSliderHelper.MovementDirection, distance: CGFloat?, isCrossDay: Bool) -> Bool {
        guard let _distance = distance else { return false }
        let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
        return TYRingSliderHelper.arePointsTouchingOnSameCircle(point: point, targetPoint: targetPoint, movementDirection: movementDirection, distance: _distance, interval: interval, isCrossDay: isCrossDay)
    }
    
    private func lineList2PointList(from lineList: TYRangeLineList, startPoint target:TYRangeLine, isBegin begin: Bool ) -> TYRangePointList {
        let result = TYRangePointList()
        var lastValue: CGFloat? = nil
        var loop = 1
        print("666: -------------point start-------------)")
        lineList.traverse(from: target, forward: true) { (item: TYRangeLine) in
            print("666: \(item)")
            if loop == 1 {
                if begin == false {
                    result.append(value: item.end, isStart: false, isEnd: true, isCross: false, lineTag: loop)
                    lastValue = item.start
                } else {
                    result.append(value: item.start, isStart: true, isEnd: false, isCross: false, lineTag: loop)
                    result.append(value: item.end, isStart: false, isEnd: false, isCross: false, lineTag: loop)
                }
            } else if loop == lineList.count {
                if begin == true {
                    result.append(value: item.start, isStart: false, isEnd: false, isCross: false, lineTag: loop)
                    result.append(value: item.end, isStart: false, isEnd: true, isCross: false, lineTag: loop)
                } else {
                    result.append(value: item.start, isStart: false, isEnd: false, isCross: false, lineTag: loop)
                    result.append(value: item.end, isStart: false, isEnd: false, isCross: false, lineTag: loop)
                }
            } else {
                result.append(value: item.start, isStart: false, isEnd: false, isCross: false, lineTag: loop)
                result.append(value: item.end, isStart: false, isEnd: false, isCross: false, lineTag: loop)
            }
            loop+=1
            return true
        }
        if let _lastValue = lastValue {
            result.append(value: _lastValue, isStart: true, isEnd: false, isCross: false, lineTag: 1)
        }
        print("666: -------------point end-------------)")
        print("666: -------------start-------------)")
        result.traverse { (item: TYRangePoint) in
            print("666: \(item)")
            return true
        }
        print("666: -------------end-------------)")
        return result
    }
    
    private func updatePointsCrossDayStatus(in pointList: TYRangePointList, changedPointIndex:Int, movementDirection: MovementDirection) {
        // 一直在变动的点不参与计算
        guard let _head = pointList.head else {
            return
        }
        
        var changedPoint: TYRangePoint!
        pointList.traverse { (item: TYRangePoint) in
            if item.index == changedPointIndex {
                changedPoint = item
                return false
            }
            return true
        }
        
        var pointsArray = [TYRangePoint]()
        // 清除跨天标记
        pointList.traverse { (item: TYRangePoint) in
            item.isCross = false
            pointsArray.append(item)
            return true
        }
        
        print("280280: ------start--------")
        
        var crossPointArray = [TYRangePoint]()
        var currentNode = _head
        print("240240: -------------start-------------)")
        if movementDirection == .clockwise {
            // 按升序
            repeat {
                // 进行比较
                if currentNode == changedPoint {
                    // 手触摸的点不参与计算
                } else {
                    var nextNode = currentNode.next!
                    if nextNode == changedPoint {
                        nextNode = nextNode.next!
                    }
                    if currentNode.value > nextNode.value {
                        // 认为跨 0
                        crossPointArray.append(currentNode)
                        crossPointArray.append(nextNode)
                    }
                }
                // 移动到下一个节点
                currentNode = currentNode.next!
            } while currentNode !== _head // 当再次到达起始节点时停止
        } else {
            // 按降序
            repeat {
                // 进行比较
                if currentNode == changedPoint {
                    // 手触摸的点不参与计算
                } else {
                    var previousNode = currentNode.previous!
                    if previousNode == changedPoint {
                        previousNode = previousNode.previous!
                    }
                    if currentNode.value < previousNode.value {
                        // 认为跨 0
                        crossPointArray.append(currentNode)
                        crossPointArray.append(previousNode)
                    }
                }
                // 移动到下一个节点
                currentNode = currentNode.previous!
            } while currentNode !== _head // 当再次到达起始节点时停止
        }
        print("240240: -------------end-------------)")
        if crossPointArray.count >= 2 {
            let tmpArray = crossPointArray.suffix(2)
            var realCrossPointArray = [TYRangePoint]()
            print("260260: -------------start-------------)")
            let first = crossPointArray.first!
            let end = crossPointArray.last!
            let distance = abs(first.index - end.index)
            print("260260: \(distance)")
            print("260260: -------------end-------------)")
            if  distance == 1 || distance == pointList.nodeCount - 1 {
                for item in tmpArray {
                    item.isCross = true
                    realCrossPointArray.append(item)
                }
            } else {
                print("中间存在其他点")
                if movementDirection == .clockwise {
                    // 第一个需要和第二个比较
                    if changedPoint.value > changedPoint.next!.value {
                        // 异常数据,这个时候,任务 最后一个和被间隔的才是跨 0 的
                        changedPoint.previous!.isCross = true
                        changedPoint.isCross = true
                        realCrossPointArray.append(changedPoint.previous!)
                        realCrossPointArray.append(changedPoint)
                    } else {
                        // 正常数据, 最后一个和第一个比较, 看结果
                        if changedPoint.previous!.value > changedPoint.value { // 这就是跨 0 了
                            changedPoint.previous!.isCross = true
                            changedPoint.isCross = true
                            realCrossPointArray.append(changedPoint.previous!)
                            realCrossPointArray.append(changedPoint)
                        } else {
                            changedPoint.isCross = true
                            changedPoint.next!.isCross = true
                            realCrossPointArray.append(changedPoint)
                            realCrossPointArray.append(changedPoint.next!)
                        }
                    }
                } else {
                    if changedPoint.value >= 0 && changedPoint.value <= changedPoint.next!.value {
                        changedPoint.previous!.isCross = true
                        changedPoint.isCross = true
                        realCrossPointArray.append(changedPoint.previous!)
                        realCrossPointArray.append(changedPoint)
                    } else if changedPoint.value >= changedPoint.previous!.value && changedPoint.value <= maximumValue {
                        changedPoint.isCross = true
                        changedPoint.next!.isCross = true
                        realCrossPointArray.append(changedPoint)
                        realCrossPointArray.append(changedPoint.next!)
                    } else {
                        // 异常数据,这个时候,任务 最后一个和第一个才是跨 0 的
                        print("250250: 异常数据)")
                        changedPoint.previous!.isCross = true
                        changedPoint.isCross = true
                        realCrossPointArray.append(changedPoint.previous!)
                        realCrossPointArray.append(changedPoint)
                    }
                }
            }
            // 特殊情况 算出来的两个点都在 0 点上, 第二个点和第二个点的下一个,算跨 0 的区间
            let realFirstPoint = realCrossPointArray.first!
            let realSecondPoint = realCrossPointArray.last!
            if realFirstPoint.value == 0 && realSecondPoint.value == 0 {
                realFirstPoint.isCross = false
                if movementDirection == .clockwise {
                    realSecondPoint.next!.isCross = true
                } else {
                    realSecondPoint.previous!.isCross = true
                }
            }
        }
        if movementDirection == .counterclockwise {
            print("250250: ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓)")
            print("250250: -------------start-------------)")
            pointList.traverse { (item: TYRangePoint) in
                print("250250: \(item), changedIndex: \(changedPointIndex)")
                return true
            }
            print("250250: -------------end-------------)")
            for item in crossPointArray {
                print("260260: \(item)")
            }
            print("250250: ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑)")
        }
        
        
        /*
        // 排序
        var pointArray = [TYRangePoint]()
        pointList.traverse { (item: TYRangePoint) in
            pointArray.append(item)
            return true
        }
        // 这里一定是 >= 2 的
        if pointArray.count >= 2 {
            pointArray.sort { $0.value < $1.value }
            // 寻找异常的两个点
            var isBigger = false
            var comparePoint = pointArray.first!
            for (index, item) in pointArray.enumerated() {
                if index == 0 {
                    continue
                }
                if (comparePoint.value > item.value) {
                    isBigger = true
                    comparePoint.isCross = true
                    item.isCross = true
                    break
                } else {
                    item.isCross = false
                    comparePoint = item
                }
            }
            
            if isBigger == false {
                // 循环数组没找到, 就判断首尾
                let firstPoint = pointArray.first!
                if firstPoint.value != 0 {
                    if comparePoint.value > firstPoint.value {
                        comparePoint.isCross = true
                        firstPoint.isCross = true
                        isBigger = true
                    }
                }
            }
            
            print("250250: -------------point end-------------)")
            print("250250: -------------start-------------)")
            for item in pointArray {
                print("250250: \(item)")
            }
            print("250250: -------------end-------------)")
        }
         */
    }
    
    private func modifyLineList(by pointList: TYRangePointList, selectLine line: TYRangeLine) {
        var currentLine = line
        print("2341: @@@@@@@@@@@@@@@@@旧值开始@@@@@@@@@@@@@@@@@")
        currentLine = line
        repeat {
            print("2341: |__ \(currentLine)")
            currentLine = currentLine.next!
        } while currentLine != line
        print("2341: @@@@@@@@@@@@@@@@@旧值结束@@@@@@@@@@@@@@@@@")
        
        currentLine = line
        var startPoint = pointList.findFirstNode()!
        var currentPoint = startPoint
        repeat {
            if currentPoint.isStart {
                currentLine.start = currentPoint.value
                currentLine.end = currentPoint.next!.value
                currentPoint = currentPoint.next!.next!
            } else if currentPoint.isEnd {
                currentLine.start = currentPoint.previous!.value
                currentLine.end = currentPoint.value
                currentPoint = currentPoint.next!
            } else {
                currentLine.start = currentPoint.value
                currentLine.end = currentPoint.next!.value
                currentPoint = currentPoint.next!.next!
            }
            currentLine = currentLine.next!
        } while currentLine != line
        print("2341: @@@@@@@@@@@@@@@@@新值开始@@@@@@@@@@@@@@@@@")
        currentLine = line
        repeat {
            print("2341: |__ \(currentLine)")
            currentLine = currentLine.next!
        } while currentLine != line
        print("2341: @@@@@@@@@@@@@@@@@新值结束@@@@@@@@@@@@@@@@@")
    }
    
    private func isPointInArcCentered(_ point: CGPoint, _ start: CGFloat, _ end: CGFloat) -> Bool {
        
        let innerRadius = radius - lineWidth / 2
        let outerRadius = radius + lineWidth / 2
        
        // 计算点到圆心的距离
        let distanceToCenter = hypot(point.x - bounds.center.x, point.y - bounds.center.y)
        
        // 检查点是否在内圆和外圆之间
        guard distanceToCenter >= innerRadius && distanceToCenter <= outerRadius else {
            return false
        }
        
        // 计算点相对于圆心的角度
        let angle = atan2(point.y - bounds.center.y, point.x - bounds.center.x)
        let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
        let startAngle = TYRingSliderHelper.scaleToAngle(value: start, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
        // get end angle from end value
        let endAngle = TYRingSliderHelper.scaleToAngle(value: end, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
        // 将角度转换为0到2π之间的值
        let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle
        
        let normalizedStartAngle = startAngle < 0 ? startAngle + 2 * .pi : startAngle
        let normalizedEndAngle = endAngle < 0 ? endAngle + 2 * .pi : endAngle
        
        // 判断点的角度是否在弧线的角度范围内
        if normalizedStartAngle < normalizedEndAngle {
            return normalizedAngle >= normalizedStartAngle && normalizedAngle <= normalizedEndAngle
        } else {
            return normalizedAngle >= normalizedStartAngle || normalizedAngle <= normalizedEndAngle
        }
    }
    
    // MARK: - Private Properties
    private var rangeLineList: TYRangeLineList? {
        didSet {
            setNeedsDisplay()
            sendActions(for: .valueChanged)
        }
    }
    
    /**
     * Interval point
     */
    fileprivate var selectedRangeLine: TYRangeLine?
    
    private var oldTouchPoint: CGPoint = .zero
    
    private var tapGestureRecognizer: UITapGestureRecognizer {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(actionForTapGestureRecognizer(_:)))
        return gestureRecognizer
    }
    
    
    public static func testArePointsTouchingOnSameCircle(point: CGFloat, targetPoint: CGFloat, movementDirection:MovementDirection, distance: CGFloat) -> Bool {
        var result = false
        if movementDirection == .clockwise {
            // 不讨论回到原点的问题. point < targetPoint 恒成立, 所以当 point >= targetPoint 就认为碰撞或者越过了
            // 如果 point < targePoint 说明跨越了0点, 所以targePoint需要偏移
            let targetPoint = targetPoint < point ? targetPoint + 86400 : targetPoint
            // 基于distance 计算 targetPoint
            let newTargetPoint = targetPoint - distance >= 0 ? targetPoint - distance : 86400 + targetPoint - distance
            result = point >= newTargetPoint
        } else if movementDirection == .counterclockwise {
            // 不讨论回到原点的问题. point > targetPoint 恒成立, 所以 当point <= targetPoint 就认为碰撞或者越过了
            // 如果 point < targePoint 说明跨越了0点, 所以targePoint需要偏移
            let targetPoint = targetPoint > point ? targetPoint - 86400 : targetPoint
            // 基于distance 计算 targetPoint
            let newTargetPoint = targetPoint + distance <= 86400 ? targetPoint + distance : targetPoint + distance - 86400
            result = point <= newTargetPoint
        }
        return result
    }
    
    public enum MovementDirection {
        case clockwise
        case counterclockwise
        case stationary
    }

}
