//
//  TYRingSlider+Math.swift
//  Pods
//
//  Created by Hamza Ghazouani on 21/10/2016.
//
//

import UIKit

// MARK: - Internal Structures
internal struct Interval {
    var min: CGFloat = 0.0
    var max: CGFloat = 0.0
    var rounds: Int
    
    init(min: CGFloat, max: CGFloat, rounds: Int = 1) {
        assert(min <= max && rounds > 0, NSLocalizedString("Illegal interval", comment: ""))
        
        self.min = min
        self.max = max
        self.rounds = rounds
    }
}

internal struct Circle {
    var origin = CGPoint.zero
    var radius: CGFloat = 0
    
    init(origin: CGPoint, radius: CGFloat) {
        assert(radius >= 0, NSLocalizedString("Illegal radius value", comment: ""))
        
        self.origin = origin
        self.radius = radius
    }
}

internal struct Arc {
    
    var circle = Circle(origin: CGPoint.zero, radius: 0)
    var startAngle: CGFloat = 0.0
    var endAngle: CGFloat = 0.0
    
    init(circle: Circle, startAngle: CGFloat, endAngle: CGFloat) {
        
        self.circle = circle
        self.startAngle = startAngle
        self.endAngle = endAngle
    }
}

// MARK: - Internal Extensions
internal extension CGVector {
    
    /**
     Calculate the vector between two points
     
     - parameter source:      the source point
     - parameter end:       the destination point
     
     - returns: returns the vector between source and the end point
     */
    init(sourcePoint source: CGPoint, endPoint end: CGPoint) {
        let dx = end.x - source.x
        let dy = end.y - source.y
        self.init(dx: dx, dy: dy)
    }
    
    func dotProduct(_ v: CGVector) -> CGFloat {
        let dotProduct = (dx * v.dx) + (dy * v.dy)
        return dotProduct
    }
    
    func determinant(_ v: CGVector) -> CGFloat {
        let determinant = (v.dx * dy) - (dx * v.dy)
        return determinant
    }
    
    static func dotProductAndDeterminant(fromSourcePoint source: CGPoint, firstPoint first: CGPoint, secondPoint second: CGPoint) -> (dotProduct: Float, determinant: Float) {
        let u = CGVector(sourcePoint: source, endPoint: first)
        let v = CGVector(sourcePoint: source, endPoint: second)
        
        let dotProduct = u.dotProduct(v)
        let determinant = u.determinant(v)
        return (Float(dotProduct), Float(determinant))
    }
}

internal extension CGRect {
    
    // get the center of rect (bounds or frame)
    var center: CGPoint {
        get {
            let center = CGPoint(x: midX, y: midY)
            return center
        }
    }
}

// MARK: - Internal Helper
internal class TYRingSliderHelper {
    
    @nonobjc static let circleMinValue: CGFloat = 0
    @nonobjc static let circleMaxValue: CGFloat = CGFloat(2 * Double.pi)
    @nonobjc static let circleInitialAngle: CGFloat = -CGFloat(Double.pi / 2)
    
    public enum MovementDirection {
        case clockwise
        case counterclockwise
        case stationary
    }
    
    /**
     Convert angle from radians to degrees
     
     - parameter value: radians value
     
     - returns: degree value
     */
    internal static func degrees(fromRadians value: CGFloat) -> CGFloat {
        return value * 180.0 / CGFloat(Double.pi)
    }
    
    /**
     Returns the angle AÔB of an circle
     
     - parameter firstPoint:  the first point
     - parameter secondPoint: the second point
     - parameter center:      the center of the circle
     
     - returns: Returns the angle AÔB of an circle
     */
    internal static func angle(betweenFirstPoint firstPoint: CGPoint, secondPoint: CGPoint, inCircleWithCenter center: CGPoint) -> CGFloat {
        /*
         we get the angle by using two vectors
         http://www.vitutor.com/geometry/vec/angle_vectors.html
         https://www.mathsisfun.com/geometry/unit-circle.html
         https://en.wikipedia.org/wiki/Dot_product
         https://en.wikipedia.org/wiki/Determinant
         */
        
        let uv = CGVector.dotProductAndDeterminant(fromSourcePoint: center, firstPoint: firstPoint, secondPoint: secondPoint)
        let angle = atan2(uv.determinant, uv.dotProduct)
        
        // change the angle interval
        let newAngle = (angle < 0) ? -angle : Float(Double.pi * 2) - angle
        
        return CGFloat(newAngle)
    }
    
    /**
     Given a specific angle, returns the coordinates of the end point in the circle
     
     - parameter circle: the circle
     - parameter angle:  the angle value
     
     - returns: the coordinates of the end point
     */
    internal static func endPoint(fromCircle circle: Circle, angle: CGFloat) -> CGPoint {
        /*
         to get coordinate from angle of circle
         https://www.mathsisfun.com/polar-cartesian-coordinates.html
         */
        
        let x = circle.radius * cos(angle) + circle.origin.x // cos(α) = x / radius
        let y = circle.radius * sin(angle) + circle.origin.y // sin(α) = y / radius
        let point = CGPoint(x: x, y: y)
        
        return point
    }
    
    /**
     Scale the value from an interval to another
     
     For example if the value is 0.5 and the interval is [0, 1]
     the new value is equal to 4 in the new interval [0, 8]
     
     - parameter value:       the value
     - parameter source:      the old interval
     - parameter destination: the new interval
     
     - returns: the value in the new interval
     */
    internal static func scaleValue(_ value: CGFloat, fromInterval source: Interval, toInterval destination: Interval) -> CGFloat {
        // If the value is equal to the min or the max no need to calculate
        switch value {
        case source.min:
            return destination.min
        case source.max:
            return destination.max
        default:
            let sourceRange = (source.max - source.min) / CGFloat(source.rounds)
            let destinationRange = (destination.max - destination.min) / CGFloat(destination.rounds)
            let scaledValue = source.min + (value - source.min).truncatingRemainder(dividingBy: sourceRange)
            let newValue =  (((scaledValue - source.min) * destinationRange) / sourceRange) + destination.min
            
            return  newValue
        }
    }
    
    /**
     Scale the value from the initial interval to circle interval
     The angle interval  is [0, 2π]
     
     For example if the value is 0.5 and the interval is [0, 1]
     the angle value is equal to π
     
     @see value(inInterval: fromAngle:)
     
     - parameter aValue:      the original value
     - parameter oldIntreval: the original interval
     
     - returns: the angle value
     */
    internal static func scaleToAngle(value aValue: CGFloat, inInterval oldInterval: Interval) -> CGFloat {
        let angleInterval = Interval(min: circleMinValue , max: circleMaxValue)
        
        let angle = scaleValue(aValue, fromInterval: oldInterval, toInterval: angleInterval)
        return angle
    }
    
    /**
     Scale the value from the circle interval to the new interval
     The angle interval is [0, 2π]
     
     For example if the value is π and the interval is [0, 2π]
     the new value is equal to 1 in the interval [0, 2]
     
     - parameter newInterval: the new interval
     - parameter angle:       the angle value
     
     - returns: the value in the new interval 
     */
    internal static func value(inInterval newInterval: Interval, fromAngle angle: CGFloat) -> CGFloat {
        let angleIntreval = Interval(min: circleMinValue , max: circleMaxValue)
        let value = scaleValue(angle, fromInterval: angleIntreval, toInterval: newInterval)
        
        return value
    }
    
    internal static func delta(in interval: Interval, for angle: CGFloat, oldValue: CGFloat) -> CGFloat {
        let angleIntreval = Interval(min: circleMinValue , max: circleMaxValue)
        
        let oldAngle = scaleToAngle(value: oldValue, inInterval: interval)
        let deltaAngle = self.angle(from: oldAngle, to: angle)
        
        return scaleValue(deltaAngle, fromInterval: angleIntreval, toInterval: interval)
    }
    
    /**
     * Length (angular) of a shortest way between two angles.
     * It will be in range [-π/2, π/2], where sign means dir (+ for clockwise, - for counter clockwise).
     */
    private static  func angle(from alpha: CGFloat, to beta: CGFloat) -> CGFloat {
        let halfValue = circleMaxValue/2
        // Rotate right
        let offset = alpha >= halfValue ? circleMaxValue - alpha : -alpha
        let offsetBeta = beta + offset
        
        if offsetBeta > halfValue {
            return offsetBeta - circleMaxValue
        }
        else {
            return offsetBeta
        }
    }
    
    internal static func determineMovementDirection(oldPoint: CGPoint, newPoint: CGPoint, circleCenter: CGPoint) -> MovementDirection {
        // 角度正规化到0到360度
        let newAngle = atan2(newPoint.y - circleCenter.y, newPoint.x - circleCenter.x).radiansToDegrees()
        let oldAngle = atan2(oldPoint.y - circleCenter.y, oldPoint.x - circleCenter.x).radiansToDegrees()
        
        // 计算角度变化
        var angleChange = newAngle - oldAngle
        
        // 角度差调整为-180到180度之间，以便判断方向
        if angleChange > 180 {
            angleChange -= 360
        } else if angleChange < -180 {
            angleChange += 360
        }
        
        // 根据角度变化判断方向
        if angleChange > 0 {
            print("5555: 顺时针")
            return .clockwise
        } else if angleChange < 0 {
            print("5555: 逆时针")
            return .counterclockwise
        } else {
//            print("5555: 不动")
            return .stationary
        }
    }

    /// 判断两个同圆上的点是否触碰
    /// - Parameters:
    ///   - angle1: 第一个点的角度位置（单位：度）
    ///   - angle2: 第二个点的角度位置（单位：度）
    ///   - touchRadius: 两个点的触碰半径（单位：度），假设两点有相同的触碰半径
    /// - Returns: 如果两点触碰返回true，否则返回false
    internal static func arePointsTouchingOnSameCircle(point1: CGFloat, point2: CGFloat, touchRadius: CGFloat, minAngle: CGFloat, interval: Interval) -> Bool {
        let angle1 = TYRingSliderHelper.degrees(fromRadians: TYRingSliderHelper.scaleToAngle(value: point1, inInterval: interval) + TYRingSliderHelper.circleInitialAngle)
        // get end angle from end value
        let angle2 = TYRingSliderHelper.degrees(fromRadians: TYRingSliderHelper.scaleToAngle(value: point2, inInterval: interval) + TYRingSliderHelper.circleInitialAngle)
        // 计算两点之间的最小角度差
        let angleDifference = min(abs(angle1 - angle2), 360 - abs(angle1 - angle2))
        let result = angleDifference <= minAngle
        print("113113: angle1: \(angle1), angle2: \(angle2), result:\(result)")
        return result
    }
    
    internal static func arePointsTouchingOnSameCircle(point1: CGFloat, point2: CGFloat, movementDirection:MovementDirection, touchRadius: CGFloat, minAngle: CGFloat, interval: Interval) -> Bool {
        // 临界点
        let boundaryPoint = TYRingSliderHelper.degrees(fromRadians: 2.0 * Double.pi)
        let angle1 = TYRingSliderHelper.degrees(fromRadians: TYRingSliderHelper.scaleToAngle(value: point1, inInterval: interval))
        // get end angle from end value
        let angle2 = TYRingSliderHelper.degrees(fromRadians: TYRingSliderHelper.scaleToAngle(value: point2, inInterval: interval))
        var result = false
        if movementDirection == .clockwise { // 顺时针 angle1 < angle2
//            if angle1 <= angle2 {
//            }
            result = angle1 - angle2 >= minAngle
//            else {
//                result = angle1 - boundaryPoint - angle2 >= minAngle
//            }
        } else if movementDirection == .counterclockwise {
            if angle1 >= angle2 {
                result = angle1 - angle2 <= minAngle
            } else {
                result = angle1 - (boundaryPoint - angle2) <= minAngle
            }
        }
        print("123123: angle1: \(angle1), angle2: \(angle2), minAngle: \(minAngle), result:\(result)")
        return result
    }
    
    internal static func arePointsTouchingOnSameCircle(point1: CGFloat, start: CGFloat, end: CGFloat, movementDirection:MovementDirection, distance: CGFloat, interval: Interval) -> Bool {
        let point = point1
        // 临界点
        let start = start == interval.min ? interval.max : start
        let end = end == interval.max ? 0 : end
        let boundaryPoint = interval.max
        var result = false
        var targetPoint = point
        // 先判断 start 和 end 是否跨天
        if start <= end { // 不跨天
            if movementDirection == .clockwise {
                targetPoint = end
                let length = targetPoint - point
                result = length <= distance
            } else if movementDirection == .counterclockwise {
                targetPoint = start
                let length = point - targetPoint
                result = length <= distance
            }
        } else {
            if movementDirection == .clockwise {
                if boundaryPoint - point > boundaryPoint - start { // 过 0 点
                    targetPoint = end
                    let length = targetPoint - point
                    result = length <= distance
                } else { // 没有过 0 点
                    targetPoint = end
                    let length = boundaryPoint - point + targetPoint
                    result = length <= distance
                }
            } else if movementDirection == .counterclockwise {
                targetPoint = start
                if point - interval.min > end - interval.min { // 没过 0 点
                    let length = point - targetPoint
                    result = length <= distance
                } else {
                    let length = point + interval.max - targetPoint
                    result = length <= distance
                }
            }
        }
        print("133133: start: \(start), end: \(end), point: \(point), targetPoint: \(targetPoint), result:\(result)")
        return result
    }
}

extension Double {
    func radiansToDegrees() -> Double {
        return self * 180 / .pi
    }
}
