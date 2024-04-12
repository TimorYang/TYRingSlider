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
    open var showThumb = false
    
    public init(start: CGFloat? = nil, end: CGFloat? = nil, lineColor: UIColor = .clear, showThumb: Bool = false) {
        self.start = start
        self.end = end
        self.lineColor = lineColor
        self.showThumb = showThumb
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
            setNeedsDisplay()
        }
        get {
            if let _rangeLineList = rangeLineList {
                return rangeLineList2TimeRangeList(from: _rangeLineList)
            }
            return nil
        }
    }
    
    open var minDistance: CGFloat?
    
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
    }
    
    // MARK: User interaction methods
    
    /**
     See superclass documentation
     */
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sendActions(for: .editingDidBegin)
        // the position of the pan gesture
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
        switch selectedThumb {
        case .startThumb:
            let oldValue = _selectedRangeLine.start
            var value = 0.0
            if let _step = step {
                value = round(newValue(from: oldValue, touch: touchPosition, start: startPoint) /  _step) * _step
            } else {
                value = newValue(from: oldValue, touch: touchPosition, start: startPoint)
            }
            _selectedRangeLine.start = value
            if let _minDistance = minDistance {
                let movementDirection = TYRingSliderHelper.determineMovementDirection(oldPoint: oldTouchPoint, newPoint: touchPosition, circleCenter: bounds.center)
                let pointList = lineList2PointList(from: _rangeLineList, startPoint: _selectedRangeLine, isBegin: true)
                switch movementDirection {
                case .clockwise:
                    /// 顺时针旋转
                    print("2222: ------------开始顺时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        repeat {
                            let distance = index % 2 == 0 ? _minDistance - 0.01 : 0.01
                            let previousPoint = currentPoint.previous!
                            let nextPoint = currentPoint.next!
                            let result = arePointsTouchingOnSameCircle(point1: currentPoint.value, start: previousPoint.value, end: nextPoint.value, movementDirection: .clockwise, distance: distance)
                            if result {
                                print("133133:  发生碰撞")
                                print("2222: 发生碰撞 currentPoint: \(currentPoint), nextPoint: \(nextPoint)")
                                nextPoint.value = currentPoint.value + distance <= maximumValue ? currentPoint.value + distance : currentPoint.value + distance - maximumValue
                            } else {
                                print("2222: 无法找到碰撞")
                                break
                            }
                            currentPoint = nextPoint
                            index += 1
                        } while currentPoint !== _firstPoint
                        print("133133:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("133133:  ")
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("2222: ------------结束顺时针旋转------------")
                case .counterclockwise:
                    /// 逆时针旋转
                    print("999666: ------------开始逆时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        repeat {
                            let distance = index % 2 == 0 ? 0.01 : _minDistance - 0.01
                            let previousPoint = currentPoint.previous!
                            let nextPoint = currentPoint.next!
                            let result = arePointsTouchingOnSameCircle(point1: currentPoint.value, start: previousPoint.value, end: nextPoint.value, movementDirection: .counterclockwise, distance: distance)
                            if result {
                                previousPoint.value = currentPoint.value >= distance ? currentPoint.value - distance : currentPoint.value - distance + maximumValue
                            } else {
                                break
                            }
                            currentPoint = previousPoint
                            index += 1
                        } while currentPoint !== _firstPoint
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("999666: ------------结束逆时针旋转------------")
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
            _selectedRangeLine.end = value
            if let _minDistance = minDistance {
                let movementDirection = TYRingSliderHelper.determineMovementDirection(oldPoint: oldTouchPoint, newPoint: touchPosition, circleCenter: bounds.center)
                let pointList = lineList2PointList(from: _rangeLineList, startPoint: _selectedRangeLine, isBegin: false)
                switch movementDirection {
                case .clockwise:
                    /// 顺时针旋转
                    print("2222: ------------开始顺时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        repeat {
                            let distance = index % 2 == 0 ? 0.01 : _minDistance - 0.01
                            let previousPoint = currentPoint.previous!
                            let nextPoint = currentPoint.next!
                            let result = arePointsTouchingOnSameCircle(point1: currentPoint.value, start: previousPoint.value, end: nextPoint.value, movementDirection: .clockwise, distance: distance)
                            if result {
                                print("133133:  发生碰撞")
                                print("2222: 发生碰撞 currentPoint: \(currentPoint), nextPoint: \(nextPoint)")
                                nextPoint.value = currentPoint.value + distance <= maximumValue ? currentPoint.value + distance : currentPoint.value + distance - maximumValue
                            } else {
                                print("2222: 无法找到碰撞")
                                break
                            }
                            currentPoint = nextPoint
                            index += 1
                        } while currentPoint !== _firstPoint
                        print("133133:  |<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                        print("133133:  ")
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("2222: ------------结束顺时针旋转------------")
                case .counterclockwise:
                    /// 逆时针旋转
                    print("999666: ------------开始逆时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        repeat {
                            let distance = index % 2 == 0 ? _minDistance - 0.01 : 0.01
                            let previousPoint = currentPoint.previous!
                            let nextPoint = currentPoint.next!
                            let result = arePointsTouchingOnSameCircle(point1: currentPoint.value, start: previousPoint.value, end: nextPoint.value, movementDirection: .counterclockwise, distance: distance)
                            if result {
                                previousPoint.value = currentPoint.value >= distance ? currentPoint.value - distance : currentPoint.value - distance + maximumValue
                            } else {
                                break
                            }
                            currentPoint = previousPoint
                            index += 1
                        } while currentPoint !== _firstPoint
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("999666: ------------结束逆时针旋转------------")
                case .stationary:
                    print("101010666: 点没有移动或在完全对称的位置")
                }
            }
        case .none:
            print("none")
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
    
    // MARK: - Private Method
    private func rangeLineList2TimeRangeList(from lineList: TYRangeLineList) -> [TYRingSliderTimeRange]? {
        var list = [TYRingSliderTimeRange]()
        lineList.traverse { (item: TYRangeLine) in
            let tmp = TYRingSliderTimeRange()
            tmp.start = item.start
            tmp.end = item.end == maximumValue ? 0 : item.end
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
            let point = TYRangeLine(start: item.start!, end: item.end!, lineColor: item.lineColor, showThumb: item.showThumb)
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
    
    private func arePointsTouchingOnSameCircle(point1: CGFloat, start: CGFloat, end: CGFloat,  movementDirection:TYRingSliderHelper.MovementDirection, distance: CGFloat?) -> Bool {
        guard let _distance = distance else { return false }
        let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
        return TYRingSliderHelper.arePointsTouchingOnSameCircle(point1: point1, start: start, end: end, movementDirection: movementDirection, distance: _distance, interval: interval)
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
                    result.append(value: item.end, isStart: false, isEnd: true)
                    lastValue = item.start
                } else {
                    result.append(value: item.start, isStart: true, isEnd: false)
                    result.append(value: item.end, isStart: false, isEnd: false)
                }
            } else if loop == lineList.count {
                if begin == true {
                    result.append(value: item.start, isStart: false, isEnd: false)
                    result.append(value: item.end, isStart: false, isEnd: true)
                } else {
                    result.append(value: item.start, isStart: false, isEnd: false)
                    result.append(value: item.end, isStart: false, isEnd: false )
                }
            } else {
                result.append(value: item.start, isStart: false, isEnd: false)
                result.append(value: item.end, isStart: false, isEnd: false)
            }
            loop+=1
            return true
        }
        if let _lastValue = lastValue {
            result.append(value: _lastValue, isStart: true, isEnd: false)
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
    
    // MARK: - Private Properties
    private var rangeLineList: TYRangeLineList?
    
    /**
     * Interval point
     */
    fileprivate var selectedRangeLine: TYRangeLine?
    
    private var oldTouchPoint: CGPoint = .zero

}
