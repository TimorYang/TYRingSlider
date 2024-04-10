//
//  TYMultiRingSlider.swift
//  TYRingSlider
//
//  Created by TeemoYang on 2024/4/9.
//

import UIKit

open class TYMultiRingSlider: TYRingSlider {

    // MARK: - Public Properties
    open var maxThumbPointCount = Int.max
    
    open var thumbPoints: [CGFloat]? {
        didSet {
            if let _thumbPoints = thumbPoints {
                if _thumbPoints.count > maxThumbPointCount {
                    thumbPointList = nil
                    assert(true, "The number of Thumb is greater than the maximum value")
                    return
                }
                thumbPointList = thumbPointsConvertToMultiPointList(from: _thumbPoints)
            }
        }
    }
    
    open var thumbImage: UIImage?
    
    open var minDistance: CGFloat?
    
    open override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if radiusOffSet > 0 {
            drawOutCircularSlider(inContext: context)
        }
        
        drawCircularSlider(inContext: context)
        
        if let _ = step {
            drawTicks(center: self.bounds.center, radius: radius)
        }
        
        if let _diskImage = diskImage {
            drawDiskImage(withImage: _diskImage, inContext: context)
        }
        
        if let _thumbPointList = thumbPointList {
            let valuesInterval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
            endThumbTintColor.setFill()
            (isHighlighted == true) ? endThumbStrokeHighlightedColor.setStroke() : endThumbStrokeColor.setStroke()
            _thumbPointList.traverse { (item:TYMultiRingPoint) in
                // draw thumb
                let itemAngle = TYRingSliderHelper.scaleToAngle(value: item.value, inInterval: valuesInterval) + TYRingSliderHelper.circleInitialAngle
                item.center = drawThumbAt(itemAngle, with: thumbImage, inContext: context, followAngle: true)
                return true
            }
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
        if let _selectedThumbPoint = selectedThumbPoint, let _thumbPointList = thumbPointList {
            moveableRange = findMoveableRange(the: _selectedThumbPoint, in: _thumbPointList)
        }
        return selectedThumb != .none
    }
    
    /**
     See superclass documentation
     */
    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard let _seletedThumbPoint = selectedThumbPoint else {
            return false
        }

        // the position of the pan gesture
        let touchPosition = touch.location(in: self)
        let startPoint = CGPoint(x: bounds.center.x, y: 0)
        print("11111: ***********开始***********")
        let oldValue = _seletedThumbPoint.value
        var value = 0.0
        if let _step = step {
            value = round(newValue(from: oldValue, touch: touchPosition, start: startPoint) /  _step) * _step
        } else {
            value = newValue(from: oldValue, touch: touchPosition, start: startPoint)
        }
        let realValue = newValue(from: oldValue, touch: touchPosition, start: startPoint)
        print("11111: oldValue: \(oldValue), realValue: \(realValue) moveableRange: \(moveableRange)")
        print("11111: oldValue: \(oldValue), newValue: \(value) moveableRange: \(moveableRange)")
        if let _minDistance = minDistance, let _moveableRange = moveableRange {
            let movementDirection = TYRingSliderHelper.determineMovementDirection(oldPoint: oldTouchPoint, newPoint: touchPosition, circleCenter: bounds.center)
            switch movementDirection {
            case .clockwise:
                /// 顺时针旋转
                print("11111: ------------开始顺时针旋转------------")
                if _seletedThumbPoint.value > _moveableRange.end {
                    if (value >= _seletedThumbPoint.value && value <= maximumValue) ||
                        (value >= minimumValue && value <= _moveableRange.end) {
                        _seletedThumbPoint.value = value
                    } 
//                    else {
//                        _seletedThumbPoint.value = _moveableRange.end
//                    }
                } else {
                    if value >= _seletedThumbPoint.value && value <= _moveableRange.end {
                        _seletedThumbPoint.value = value
                    } 
//                    else {
//                        _seletedThumbPoint.value = _moveableRange.end
//                    }
                }
                print("11111: ------------结束顺时针旋转------------")
            case .counterclockwise:
                /// 逆时针旋转
                print("11111: ------------开始逆时针旋转------------")
                if _seletedThumbPoint.value < _moveableRange.start {
                    if (value >= _moveableRange.start && value <= maximumValue) ||
                        (value >= minimumValue && value <= _seletedThumbPoint.value) {
                        _seletedThumbPoint.value = value
                    }
//                    else {
//                        _seletedThumbPoint.value = _moveableRange.start
//                    }
                } else {
                    if value >= _moveableRange.start && value <= _seletedThumbPoint.value {
                        _seletedThumbPoint.value = value
                    } 
//                    else {
//                        _seletedThumbPoint.value = _moveableRange.start
//                    }
                }
                print("11111: ------------结束逆时针旋转------------")
            case .stationary:
                print("11111: 点没有移动或在完全对称的位置")
            }
            print("11111: ***********结束***********")
        }
        oldTouchPoint = touchPosition
        sendActions(for: .valueChanged)
        return true
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
    }
    
    // MARK: - Private Method
    private func thumbPointsConvertToMultiPointList(from thumbPoints:[CGFloat]) -> TYMultiRingPointList? {
        let pointList = TYMultiRingPointList()
        for (index, item) in thumbPoints.enumerated() {
            pointList.append(value: item, isStart: index == 0, isEnd: index == thumbPoints.count - 1)
        }
        if pointList.isEmpty {
            return nil
        } else {
            return pointList
        }
    }
    
    private func thumb(for touchPosition: CGPoint) -> SelectedThumb {
        guard let _thumbPointList = thumbPointList else { return .none }
        if _thumbPointList.isEmpty {
            return .none
        } else {
            var result: SelectedThumb = .none
            _thumbPointList.traverse { (item: TYMultiRingPoint) in
                if isThumb(withCenter: item.center, containsPoint: touchPosition) {
                    result = .thumb
                    selectedThumbPoint = item
                    return false
                }
                return true
            }
            return result
        }
    }
    
    private func isThumb(withCenter thumbCenter: CGPoint, containsPoint touchPoint: CGPoint) -> Bool {
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
    
    private func arePointsTouchingOnSameCircle(point1: CGFloat, point2: CGFloat) -> Bool {
        guard let _step = step else { return false }
        if  _step > 0 {
            let interval = Interval(min: minimumValue, max: maximumValue, rounds: numberOfRounds)
            let minRadian = TYRingSliderHelper.scaleToAngle(value: _step, inInterval: interval)
            let minAngle = TYRingSliderHelper.degrees(fromRadians: minRadian)
            return TYRingSliderHelper.arePointsTouchingOnSameCircle(point1: point1, point2: point2, touchRadius: radius, minAngle: minAngle, interval: interval)
        } else {
            return false
        }
    }
    
    private func findMoveableRange(the point: TYMultiRingPoint, in pointList: TYMultiRingPointList) -> (start: CGFloat, end: CGFloat) {
        guard pointList.nodeCount != 0 else { return (CGFLOAT_MIN, CGFLOAT_MAX) }
        if pointList.nodeCount == 1 {
            return (CGFLOAT_MIN, CGFLOAT_MAX)
        }
        
        let previousPoint = point.previous!
        let nextPoint = point.next!
        var startValue = CGFLOAT_MIN
        var endValue = CGFLOAT_MAX
        if let _minDistance = minDistance {
            startValue = previousPoint.value + _minDistance > maximumValue ? minimumValue + _minDistance : previousPoint.value + _minDistance
            endValue = nextPoint.value - _minDistance < 0 ? maximumValue - _minDistance : nextPoint.value - _minDistance
        } else {
            startValue = nextPoint.value
            endValue = previousPoint.value
        }
        return (startValue, endValue)
    }
    
    // MARK: - Private Properties
    private var thumbPointList: TYMultiRingPointList?
    
    private enum SelectedThumb {
        case thumb
        case none
    }
    
    private var selectedThumb: SelectedThumb = .none
    
    private var selectedThumbPoint: TYMultiRingPoint?
    
    private var moveableRange: (start: CGFloat, end: CGFloat)?
    
    private var oldTouchPoint: CGPoint = .zero
    
    private var lastMovementDirection: TYRingSliderHelper.MovementDirection = .stationary

}
