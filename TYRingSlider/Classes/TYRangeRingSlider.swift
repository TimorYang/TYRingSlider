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
            if _rangeLineList.count == 1 {
                _rangeLineList.traverse { (item: TYRangeLine) in
                    // get start angle from start value
                    var start = item.start
                    var end = item.end
                    if start == end {
                        start = minimumValue
                        end = maximumValue
                    }
                    let startAngle = TYRingSliderHelper.scaleToAngle(value: start, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                    // get end angle from end value
                    let endAngle = TYRingSliderHelper.scaleToAngle(value: end, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                    drawShadowArc(fromAngle: startAngle, toAngle: endAngle, inContext: context, withColor: trackShadowColor)
                    drawFilledArc(fromAngle: startAngle, toAngle: endAngle, inContext: context, withDiskColor: diskFillColor, withTrackColor: item.lineColor)
                    return true
                }
            } else {
                _rangeLineList.traverse { (item: TYRangeLine) in
                    // get start angle from start value
                    let startAngle = TYRingSliderHelper.scaleToAngle(value: item.start, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                    // get end angle from end value
                    let endAngle = TYRingSliderHelper.scaleToAngle(value: item.end, inInterval: interval) + TYRingSliderHelper.circleInitialAngle
                    drawShadowArc(fromAngle: startAngle, toAngle: endAngle, inContext: context, withColor: trackShadowColor)
                    drawFilledArc(fromAngle: startAngle, toAngle: endAngle, inContext: context, withDiskColor: diskFillColor, withTrackColor: item.lineColor)
                    return true
                }
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
        oldTouchPoint = touchPosition
        touchStartTime = touch.timestamp  // 记录触摸开始时间
        return selectedThumb != .none
    }
    
    /**
     See superclass documentation
     */
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard let startTime = touchStartTime else { return false }
        let touchDuration = touch.timestamp - startTime
        // 设置一个时间阈值，例如0.1秒，来确定是否继续处理
        if touchDuration <= 0.1 {
            return true
        }
        print("touchDuration: \(touchDuration < 0.1)")
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
            var value = newValue(from: oldValue, touch: touchPosition, start: startPoint)
            if value - oldValue == 0 || abs(value - oldValue) == 24 {
                // 减少没有必要的计算
                return true
            }
            if let _step = step {
                value = round(newValue(from: oldValue, touch: touchPosition, start: startPoint) /  _step) * _step
            }
            print("101010666: oldValue: \(oldValue)")
            print("101010666: newValue: \(value)")
            let movementDirection = TYRingSliderHelper.determineMovementDirection(oldPoint: oldTouchPoint, newPoint: touchPosition, circleCenter: bounds.center)
            // 因为 0 和最大值是同一个点, 所以把最大值统一当成 0 处理
            value = value == maximumValue ? minimumValue : value
            _selectedRangeLine.start = value
            if let _minDistance = minDistance {
                let pointList = lineList2PointList(from: _rangeLineList, startPoint: _selectedRangeLine, isBegin: true)
                switch movementDirection {
                case .clockwise:
                    /// 顺时针旋转
                    print("2222: ------------开始顺时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        // 运动前的旧值
                        // 目标点的值
                        // 上面两个可以找到是否跨天
                        // 当前运动的值
                        // 如果上面判断跨天了, 再根据运动的值, 判断自己在0的哪边
                        // 如果上面判断没跨天, 直接计算
                        // 运动方向
                        var movePointOldValue = oldValue
                        // 是否需要吸附, 当前连offpeak共有12条线段且摸的这个点和前一个点是重合的
                        print("3213213: 🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽")
                        print("3213213: selectLine: \(_selectedRangeLine)")
                        print("3213213: previousLine \(_selectedRangeLine.previous!)")
                        if pointList.nodeCount >= 22 {
                            let previousPoint = _firstPoint.previous!
                            let follow = shouldFollow(in: pointList)
                            print("321321: 吸附: \(follow.shouldFollow ? "✅" : "🙅🏻‍♀️")")
                            let valueIsEqual = previousPoint.value == oldValue
                            print("321321: 吸附: 是否相等: \(valueIsEqual ? "✅" : "🙅🏻‍♀️") 运动的点旧值: \(oldValue), 需要跟随点的值: \(previousPoint.value)")
                            let shouldFollow = follow.shouldFollow && valueIsEqual
                            print("3213213: 吸附: \(shouldFollow ? "✅" : "🙅🏻‍♀️")")
                            if shouldFollow {
                                print("321321: 吸附 ✅ 运动的点旧值: \(oldValue / 3600), 需要跟随点的值: \(previousPoint.value / 3600), listCount: \(follow.count)")
                                previousPoint.value = value
                            } else {
                                // 不要吸附
//                                previousPoint.value = oldValue
                                print("321321: 吸附 🙅🏻‍♀️ 运动的点旧值: \(oldValue / 3600), 需要跟随点的值: \(previousPoint.value / 3600), listCount: \(follow.count)")
                                print("321321: 吸附 🙅🏻‍♀️")
                            }
                        }
                        print("22221: 顺时针, 检测是否跨天 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻")
                        repeat {
                            let distance = index % 2 == 0 ? _minDistance : 0.0
                            let nextPoint = currentPoint.next!
                            //                            if moveDistance > 0 {
                            print("22221: index: \(index)")
                            print("22221: 顺时针, 运动点的旧值: \(movePointOldValue / 3600) 和 运动点的新值: \(currentPoint.value / 3600)")
                            // 顺时针都是 ⬆️ 趋势, 如果运动点的就值到目标点是 ⬇️ 趋势, 认为跨天
                            var isCross = false
                            if movePointOldValue > nextPoint.value {
                                isCross = true
                                print("22221: 顺时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(nextPoint.value / 3600) 跨天 ✅")
                            } else {
                                print("22221: 顺时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(nextPoint.value / 3600) 跨天 ❌")
                            }
                            // if currentPoint.value < movePointOldValue 成立
                            // currentPoint.value + max
                            if currentPoint.value < movePointOldValue {
                                currentPoint.value = currentPoint.value + maximumValue
                            }
                            print("22221: index: \(index)")
                            //                            }
                            print("22221: 顺时针, 检测是否跨天  🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚")
                            // 判断碰撞
                            let result = arePointsTouchingOnSameCircle(point: currentPoint.value, targetPoint: nextPoint.value, movementDirection: .clockwise, isCrossDay: isCross)
                            // 记录旧值
                            movePointOldValue = nextPoint.value
                            if result < distance {
                                // 4.1 发生碰撞 更新nextPointValue
                                print("133133:  发生碰撞")
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(nextPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value + distance
                                nextPoint.value = resultValue.truncatingRemainder(dividingBy: maximumValue)
                                currentPoint.value = currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
                                print("2222: 碰撞后的数据 targetPoint: \(nextPoint.value / 3600)")
                            } else {
                                currentPoint.value = currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
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
                        var pointsArray = [CGFloat]()
                        pointList.traverse { (item: TYRangePoint) in
                            pointsArray.append(item.value)
                            return true
                        }
                        let newStringRepresentation = pointsArray.map { String(Double($0 / 3600)) }.joined(separator: ", ")
                        print("3213213: 当前数据: \(newStringRepresentation)")
                        print("3213213: 🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼")
                        modifyLineList(by: pointList, selectLine: _selectedRangeLine)
                    }
                    print("2222: ------------结束顺时针旋转------------")
                case .counterclockwise:
                    /// 逆时针旋转
                    print("2222:: ------------开始逆时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        var movePointOldValue = oldValue
                        print("22221: 逆时针, 检测是否跨天 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻")
                        repeat {
                            let distance = index % 2 == 0 ? 0.0 : _minDistance
                            let previousPoint = currentPoint.previous!
                            //                            if moveDistance > 0 {
                            print("22221: index: \(index)")
                            print("22221: 逆时针, 运动点的旧值: \(movePointOldValue / 3600) 和 运动点的新值: \(currentPoint.value / 3600)")
                            // 逆时针都是 ⬇️ 趋势, 如果运动点的就值到目标点是 ⬆️ 趋势, 认为跨天
                            var isCross = false
                            var movePointDoubleOldVale = movePointOldValue
                            if movePointOldValue < previousPoint.value {
                                print("22221: 逆时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(previousPoint.value / 3600) 跨天 ✅")
                                movePointOldValue = movePointOldValue + maximumValue
                                isCross = true
                                print("22221: 逆时针, 运动点的新值: \(currentPoint.value / 3600) 和目标值: \(previousPoint.value / 3600) 跨天 ✅")
                            } else {
                                print("22221: 逆时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(previousPoint.value / 3600) 跨天 ❌")
                            }
                            print("000909090: 🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽")
                            var tmpPoint: CGFloat!
                            var isPeng = false
                            if currentPoint.value > movePointDoubleOldVale {
                                // 越过 0 线
                                tmpPoint = movePointDoubleOldVale + maximumValue - currentPoint.value
                                let newMovePointToOldMovePoint = maximumValue - currentPoint.value + movePointDoubleOldVale
                                var targetToOldMovePoint: CGFloat!
                                if isCross {
                                    targetToOldMovePoint = maximumValue - previousPoint.value + movePointDoubleOldVale
                                } else {
                                    targetToOldMovePoint = movePointDoubleOldVale - previousPoint.value
                                }
                                if newMovePointToOldMovePoint >= targetToOldMovePoint {
                                    // 相撞
                                    isPeng = true
                                }
                                print("000909090: 是否过0 ✅ tmpPoint: \(tmpPoint / 3600)")
                                print("000909090: 是否过0 ✅ 是否相撞: \(isPeng), T2M: \(targetToOldMovePoint), N2M: \(newMovePointToOldMovePoint)")
                            } else {
                                // 不过 0 线
                                tmpPoint = abs(currentPoint.value - movePointDoubleOldVale)
                                let newMovePointToOldMovePoint = movePointDoubleOldVale - currentPoint.value
                                var targetToOldMovePoint: CGFloat!
                                if isCross {
                                    targetToOldMovePoint = maximumValue - previousPoint.value + movePointDoubleOldVale
                                } else {
                                    targetToOldMovePoint = movePointOldValue - previousPoint.value
                                }
                                if newMovePointToOldMovePoint >= targetToOldMovePoint {
                                    // 相撞
                                    isPeng = true
                                }
                                print("000909090: 是否过0 ❌ tmpPoint: \(tmpPoint / 3600)")
                                print("000909090: 是否过0 ❌ 是否相撞: \(isPeng), T2M: \(targetToOldMovePoint), N2M: \(newMovePointToOldMovePoint)")
                            }
                            //                            }
                            movePointOldValue = previousPoint.value
                            if isPeng {
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(previousPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value - distance
                                previousPoint.value = resultValue < 0 ? resultValue + maximumValue : resultValue.truncatingRemainder(dividingBy: maximumValue)
                                currentPoint.value = currentPoint.value < 0 ? currentPoint.value + maximumValue : currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
                                print("2222: 碰撞后的数据 targetPoint: \(previousPoint.value / 3600)")
                            } else {
                                currentPoint.value = currentPoint.value < 0 ? currentPoint.value + maximumValue : currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
                                print("2222: 无法找到碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(previousPoint.value / 3600), distance: \(distance / 3600)")
                                break
                            }
                            currentPoint = previousPoint
                            index += 1
                        } while currentPoint !== _firstPoint.next!
                        print("22221: 逆时针, 检测是否跨天  🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚")
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
            var value = newValue(from: oldValue, touch: touchPosition, start: startPoint)
            if value - oldValue == 0 || abs(value - oldValue) == 24 {
                // 减少没有必要的计算
                return true
            }
            if let _step = step {
                value = round(newValue(from: oldValue, touch: touchPosition, start: startPoint) /  _step) * _step
            }
            print("101010666: oldValue: \(oldValue)")
            print("101010666: newValue: \(value)")
            let movementDirection = TYRingSliderHelper.determineMovementDirection(oldPoint: oldTouchPoint, newPoint: touchPosition, circleCenter: bounds.center)
            print("33333312: value: \(value)")
            value = value == maximumValue ? minimumValue : value
            _selectedRangeLine.end = value
            if let _minDistance = minDistance {
                let pointList = lineList2PointList(from: _rangeLineList, startPoint: _selectedRangeLine, isBegin: false)
                switch movementDirection {
                case .clockwise:
                    /// 顺时针旋转
                    print("2222: ------------开始顺时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        var movePointOldValue = oldValue
                        print("22221: 顺时针, 检测是否跨天 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻")
                        repeat {
                            let distance = index % 2 == 0 ? 0.0 : _minDistance
                            let nextPoint = currentPoint.next!
                            //                            if moveDistance > 0 {
                            print("22221: index: \(index)")
                            print("22221: 顺时针, 运动点的旧值: \(movePointOldValue / 3600) 和 运动点的新值: \(currentPoint.value / 3600)")
                            // 顺时针都是 ⬆️ 趋势, 如果运动点的就值到目标点是 ⬇️ 趋势, 认为跨天
                            var isCross = false
                            if movePointOldValue > nextPoint.value {
                                isCross = true
                                print("22221: 顺时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(nextPoint.value / 3600) 跨天 ✅")
                            } else {
                                print("22221: 顺时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(nextPoint.value / 3600) 跨天 ❌")
                            }
                            if currentPoint.value < movePointOldValue {
                                currentPoint.value = currentPoint.value + maximumValue
                            }
                            print("22221: index: \(index)")
                            //                            }
                            print("22221: 顺时针, 检测是否跨天  🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚")
                            let result = arePointsTouchingOnSameCircle(point: currentPoint.value, targetPoint: nextPoint.value, movementDirection: .clockwise, isCrossDay: isCross)
                            movePointOldValue = nextPoint.value
                            if result <= distance {
                                print("133133:  发生碰撞")
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(nextPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value + distance
                                nextPoint.value = resultValue.truncatingRemainder(dividingBy: maximumValue)
                                currentPoint.value = currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
                                print("2222: 碰撞后的数据 targetPoint: \(nextPoint.value / 3600)")
                            } else {
                                print("2222: 无法找到碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(nextPoint.value / 3600), distance: \(distance / 3600)")
                                currentPoint.value = currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
                                break
                            }
                            
                            print("2222: 修正后: currentPoint: \(currentPoint.value / 3600)")
                            print("2222: 修正后: nextPoint: \(nextPoint.value / 3600)")
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
                    print("2222: ------------开始逆时针旋转------------")
                    if let _firstPoint = pointList.head {
                        var currentPoint = _firstPoint
                        var index = 0
                        print("133133:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        print("2222:  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>|")
                        var movePointOldValue = oldValue
                        // 是否需要吸附, 当前连offpeak共有12条线段且摸的这个点和前一个点是重合的
                        if pointList.nodeCount >= 22 {
                            let nextPoint = _firstPoint.next!
                            let follow = shouldFollow(in: pointList)
                            print("321321: 吸附: \(follow.shouldFollow ? "✅" : "🙅🏻‍♀️")")
                            let valueIsEqual = nextPoint.value == oldValue
                            print("321321: 吸附: 是否相等: \(valueIsEqual ? "✅" : "🙅🏻‍♀️") 运动的点旧值: \(oldValue), 需要跟随点的值: \(nextPoint.value)")
                            let shouldFollow = follow.shouldFollow && valueIsEqual
                            if shouldFollow {
                                print("321321: 吸附 ✅ 运动的点旧值: \(oldValue / 3600), 需要跟随点的值: \(nextPoint.value / 3600), listCount: \(follow.count)")
                                nextPoint.value = currentPoint.value
                            } else {
                                // 不要吸附
                                print("321321: 吸附 🙅🏻‍♀️ 运动的点旧值: \(oldValue / 3600), 需要跟随点的值: \(nextPoint.value / 3600), listCount: \(follow.count)")
                                print("321321: 吸附 🙅🏻‍♀️")
                            }
                        }
                        print("22221: 逆时针, 检测是否跨天 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻")
                        repeat {
                            let distance = index % 2 == 0 ? _minDistance : 0.0
                            let previousPoint = currentPoint.previous!
                            //                            if moveDistance > 0 {
                            print("22221: index: \(index)")
                            print("22221: 逆时针, 运动点的旧值: \(movePointOldValue / 3600) 和 运动点的新值: \(currentPoint.value / 3600)")
                            // 逆时针都是 ⬇️ 趋势, 如果运动点的就值到目标点是 ⬆️ 趋势, 认为跨天
                            var isCross = false
                            var movePointDoubleOldVale = movePointOldValue
                            if movePointOldValue < previousPoint.value {
                                movePointOldValue = movePointOldValue + maximumValue
                                isCross = true
                                print("22221: 逆时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(previousPoint.value / 3600) 跨天 ✅")
                            } else {
                                print("22221: 逆时针, 运动点的旧值: \(movePointOldValue / 3600) 和目标值: \(previousPoint.value / 3600) 跨天 ❌")
                            }
                            print("000909090: 🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽")
                            var tmpPoint: CGFloat!
                            var isPeng = false
                            if currentPoint.value > movePointDoubleOldVale {
                                // 越过 0 线
                                tmpPoint = movePointDoubleOldVale + maximumValue - currentPoint.value
                                let newMovePointToOldMovePoint = maximumValue - currentPoint.value + movePointDoubleOldVale
                                var targetToOldMovePoint: CGFloat!
                                if isCross {
                                    targetToOldMovePoint = maximumValue - previousPoint.value + movePointDoubleOldVale
                                } else {
                                    targetToOldMovePoint = movePointDoubleOldVale - previousPoint.value
                                }
                                if newMovePointToOldMovePoint >= targetToOldMovePoint {
                                    // 相撞
                                    isPeng = true
                                }
                                print("000909090: 是否过0 ✅ tmpPoint: \(tmpPoint / 3600)")
                                print("000909090: 是否过0 ✅ 是否相撞: \(isPeng), T2M: \(targetToOldMovePoint), N2M: \(newMovePointToOldMovePoint)")
                            } else {
                                // 不过 0 线
                                tmpPoint = abs(currentPoint.value - movePointDoubleOldVale)
                                let newMovePointToOldMovePoint = movePointDoubleOldVale - currentPoint.value
                                var targetToOldMovePoint: CGFloat!
                                if isCross {
                                    targetToOldMovePoint = maximumValue - previousPoint.value + movePointDoubleOldVale
                                } else {
                                    targetToOldMovePoint = movePointOldValue - previousPoint.value
                                }
                                if newMovePointToOldMovePoint >= targetToOldMovePoint {
                                    // 相撞
                                    isPeng = true
                                }
                                print("000909090: 是否过0 ❌ tmpPoint: \(tmpPoint / 3600)")
                                print("000909090: 是否过0 ❌ 是否相撞: \(isPeng), T2M: \(targetToOldMovePoint), N2M: \(newMovePointToOldMovePoint)")
                            }
                            print("22221: index: \(index)")
                            movePointOldValue = previousPoint.value
                            if isPeng {
                                print("2222: 发生碰撞 currentPoint: \(currentPoint.value / 3600), targetPoint: \(previousPoint.value / 3600), distance: \(distance / 3600)")
                                let resultValue = currentPoint.value - distance
                                previousPoint.value = resultValue < 0 ? resultValue + maximumValue : resultValue.truncatingRemainder(dividingBy: maximumValue)
                                currentPoint.value = currentPoint.value < 0 ? currentPoint.value + maximumValue : currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
                                print("2222: 碰撞后的数据 targetPoint: \(previousPoint.value / 3600)")
                            } else {
                                currentPoint.value = currentPoint.value < 0 ? currentPoint.value + maximumValue : currentPoint.value.truncatingRemainder(dividingBy: maximumValue)
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
        touchStartTime = nil
        super.endTracking(touch, with: event)
    }


    // MARK: - Helpers
    open func thumb(for touchPosition: CGPoint) -> SelectedThumb {
        var result: SelectedThumb = .none
        if let _rangeLineList = rangeLineList {
            _rangeLineList.traverse { (item: TYRangeLine) in
                if item.showThumb {
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
            var list = [TYRingSliderTimeRange]()
            lineList.traverse { (item: TYRangeLine) in
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
                            tmp.lineType = NSLocalizedString("off_peak", comment: "Off-peak")
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
                            tmp.lineType = NSLocalizedString("off_peak", comment: "Off-peak")
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
            list.sort{ $0.start! < $1.start! }
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
    
    private func arePointsTouchingOnSameCircle(point: CGFloat, targetPoint: CGFloat,  movementDirection:TYRingSliderHelper.MovementDirection, isCrossDay: Bool) -> CGFloat {
        let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
        return TYRingSliderHelper.arePointsTouchingOnSameCircle(point: point, targetPoint: targetPoint, movementDirection: movementDirection, interval: interval, isCrossDay: isCrossDay)
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
    
    private func checkPoints(with pointsList: TYRangePointList, movementDirection: MovementDirection) {
        var newPointsArray = [CGFloat]()
        pointsList.traverse { (item: TYRangePoint) in
            newPointsArray.append(item.value)
            return true
        }
        let testResult = isCircularlySorted(numbers: newPointsArray, direction: movementDirection)
        print("checkPoints: 🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻🔻")
        let newStringRepresentation = newPointsArray.map { String(Double($0 / 3600)) }.joined(separator: ", ")
        print("checkPoints:  \(newStringRepresentation)|")
        print("checkPoints: 当前数据是否正常: \(testResult)")
        print("checkPoints: 🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚🔚")
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
    
    private func shouldFollow(in pointList: TYRangePointList) -> (shouldFollow: Bool, count: Int) {
        let count = getAllTimeListCount(pointList: pointList)
        if count > 12 {
            print("shouldFollow: 是否需要吸附: ✅")
            return (true, count)
        } else {
            print("shouldFollow: 是否需要吸附: ❌")
            return (false, count)
        }
    }
    
    private func getAllTimeListCount(pointList: TYRangePointList) -> Int {
        let startPoint = pointList.head!
        var current = startPoint
        var freeCount = 0
        let isStart = startPoint.isStart
        print("222112112: 🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽🔽")
        repeat {
            if isStart {
                // 找到 终点 和下一个起点
                let end = current.next!
                let next = current.next!.next!
                print("222112112: end: \(end.value / 3600), next: \(next.value / 3600), 差值: \(abs(end.value - next.value))")
                if abs(end.value - next.value) > 0 {
                    freeCount += 1
                }
                current = next
            } else {
                let end = current
                let next = current.next!
                print("222112112: end: \(end.value / 3600), next: \(next.value / 3600), 差值: \(abs(end.value - next.value))")
                if abs(end.value - next.value) > 0 {
                    freeCount += 1
                }
                current = next.next!
            }
        } while current != startPoint
        print("222112112: freeCount: \(freeCount), points: \(pointList.nodeCount / 2)")
        print("222112112: 🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼🔼")
        return freeCount + pointList.nodeCount / 2
    }
    
    public enum MovementDirection {
        case clockwise
        case counterclockwise
        case stationary
    }
    
    private var touchStartTime: TimeInterval?

}

extension TYRangeRingSlider {
    
    public func isCircularlySorted(numbers: [CGFloat], direction: MovementDirection) -> Bool {
        let n = numbers.count
        if n <= 1 { return true }

        var ascCount = 0
        var descCount = 0
        for i in 0..<n {
            let next = (i + 1) % n
            if numbers[next] > numbers[i] {
                ascCount += 1
            } else if numbers[next] < numbers[i] {
                descCount += 1
            }
        }

        switch direction {
        case .clockwise:
            // Clockwise: One descending (from max to min) and the rest ascending
            return descCount == 1
        case .counterclockwise:
            // Counterclockwise: One ascending (from min to max) and the rest descending
            return ascCount == 1
        default:
            return true
        }
    }
}
