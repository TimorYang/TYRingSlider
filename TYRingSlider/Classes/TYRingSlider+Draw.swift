//
//  TYRingSlider+Draw.swift
//  Pods
//
//  Created by Hamza Ghazouani on 21/10/2016.
//
//

import UIKit

extension TYRingSlider {
    
    /**
     Draw arc with stroke mode (Stroke) or Disk (Fill) or both (FillStroke) mode
     FillStroke used by default
     
     - parameter arc:           the arc coordinates (origin, radius, start angle, end angle)
     - parameter lineWidth:     the with of the circle line (optional) by default 2px
     - parameter mode:          the mode of the path drawing (optional) by default FillStroke
     - parameter context:       the context
     
     */
    internal static func drawArc(withArc arc: Arc, lineWidth: CGFloat = 2, mode: CGPathDrawingMode = .fillStroke, inContext context: CGContext) {
        
        let circle = arc.circle
        let origin = circle.origin
        
        UIGraphicsPushContext(context)
        context.beginPath()
        
        context.setLineWidth(lineWidth)
        context.setLineCap(CGLineCap.butt)
        context.addArc(center: origin, radius: circle.radius, startAngle: arc.startAngle, endAngle: arc.endAngle, clockwise: false)
        context.move(to: CGPoint(x: origin.x, y: origin.y))
        context.drawPath(using: mode)
        
        UIGraphicsPopContext()
    }
    
    /**
     Draw disk using arc coordinates
     
     - parameter arc:     the arc coordinates (origin, radius, start angle, end angle)
     - parameter context: the context
     */
    internal static func drawDisk(withArc arc: Arc, inContext context: CGContext) {

        let circle = arc.circle
        let origin = circle.origin

        UIGraphicsPushContext(context)
        context.beginPath()

        context.setLineWidth(0)
        context.addArc(center: origin, radius: circle.radius, startAngle: arc.startAngle, endAngle: arc.endAngle, clockwise: false)
        context.addLine(to: CGPoint(x: origin.x, y: origin.y))
        context.drawPath(using: .fill)

        UIGraphicsPopContext()
    }

    // MARK: drawing instance methods
    internal func drawOutCircularSlider(inContext context: CGContext) {
        UIColor.clear.setFill()
        diskColor.setStroke()
        let circle = Circle(origin: bounds.center, radius: self.radius + radiusOffSet * 0.5)
        let outSliderArc = Arc(circle: circle, startAngle: TYRingSliderHelper.circleMinValue, endAngle: TYRingSliderHelper.circleMaxValue)
        TYRingSlider.drawArc(withArc: outSliderArc, lineWidth: radiusOffSet, inContext: context)
    }

    /// Draw the circular slider
    internal func drawCircularSlider(inContext context: CGContext) {
        
        diskColor.setFill()
        trackColor.setStroke()

        let circle = Circle(origin: bounds.center, radius: self.radius)
        let sliderArc = Arc(circle: circle, startAngle: TYRingSliderHelper.circleMinValue, endAngle: TYRingSliderHelper.circleMaxValue)
        TYRingSlider.drawArc(withArc: sliderArc, lineWidth: backtrackLineWidth, inContext: context)
    }

    /// draw Filled arc between start an end angles
    internal func drawFilledArc(fromAngle startAngle: CGFloat, toAngle endAngle: CGFloat, inContext context: CGContext) {
        diskFillColor.setFill()
        trackFillColor.setStroke()

        let circle = Circle(origin: bounds.center, radius: self.radius)
        let arc = Arc(circle: circle, startAngle: startAngle, endAngle: endAngle)
        
        // fill Arc
        TYRingSlider.drawDisk(withArc: arc, inContext: context)
        // stroke Arc
        TYRingSlider.drawArc(withArc: arc, lineWidth: lineWidth, mode: .stroke, inContext: context)
    }
    
    internal func drawFilledArc(fromAngle startAngle: CGFloat, toAngle endAngle: CGFloat, inContext context: CGContext, withDiskColor diskColor: UIColor, withTrackColor trackColor: UIColor) {
        diskColor.setFill()
        trackColor.setStroke()
        
        let circle = Circle(origin: bounds.center, radius: self.radius)
        let arc = Arc(circle: circle, startAngle: startAngle, endAngle: endAngle)
        
        // fill Arc
        TYRingSlider.drawDisk(withArc: arc, inContext: context)
        // stroke Arc
        TYRingSlider.drawArc(withArc: arc, lineWidth: lineWidth, mode: .stroke, inContext: context)
    }
    
    internal func drawDiskImage(withImage image: UIImage, inContext context: CGContext) {
        UIGraphicsPushContext(context)
        context.beginPath()
        let imageSize = CGSize(width: (radius - lineWidth * 0.5 - diskImageOffset) * 2, height: (radius - lineWidth * 0.5 - diskImageOffset) * 2)
        let imageFrame = CGRect(x: bounds.center.x - (imageSize.width / 2), y: bounds.center.y - (imageSize.height / 2), width: imageSize.width, height: imageSize.height)
        image.draw(in: imageFrame)
        UIGraphicsPopContext()
    }

    internal func drawShadowArc(fromAngle startAngle: CGFloat, toAngle endAngle: CGFloat, inContext context: CGContext) {
        trackShadowColor.setStroke()

        let origin = CGPoint(x: bounds.center.x + trackShadowOffset.x, y: bounds.center.y + trackShadowOffset.y)
        let circle = Circle(origin: origin, radius: self.radius)
        let arc = Arc(circle: circle, startAngle: startAngle, endAngle: endAngle)

        // stroke Arc
        TYRingSlider.drawArc(withArc: arc, lineWidth: lineWidth, mode: .stroke, inContext: context)
    }
    
    internal func drawShadowArc(fromAngle startAngle: CGFloat, toAngle endAngle: CGFloat, inContext context: CGContext, withColor color: UIColor) {
        color.setStroke()

        let origin = CGPoint(x: bounds.center.x + trackShadowOffset.x, y: bounds.center.y + trackShadowOffset.y)
        let circle = Circle(origin: origin, radius: self.radius)
        let arc = Arc(circle: circle, startAngle: startAngle, endAngle: endAngle)

        // stroke Arc
        TYRingSlider.drawArc(withArc: arc, lineWidth: lineWidth, mode: .stroke, inContext: context)
    }

    /**
     Draw the thumb and return the coordinates of its center
     
     - parameter angle:   the angle of the point in the main circle
     - parameter image:   the image of the thumb, if it's nil we use a disk (circle), the default value is nil
     - parameter context: the context
     
     - returns: return the origin point of the thumb
     */
    @discardableResult
    internal func drawThumbAt(_ angle: CGFloat, with image: UIImage? = nil, inContext context: CGContext, followAngle isFollowAngle: Bool = false) -> CGPoint {
        let circle = Circle(origin: bounds.center, radius: self.radius + self.thumbOffset)
        var thumbOrigin = TYRingSliderHelper.endPoint(fromCircle: circle, angle: angle)
        
        if let image = image {
            if isFollowAngle {
                let imageWidth = radius
                let imageHeight = radius
                
                let x = bounds.center.x + imageWidth * cos(angle)
                let y = bounds.center.y + imageHeight * sin(angle)
                thumbOrigin = CGPoint(x: x, y: y)
                return drawThumb(withImage: image, thumbOrigin: thumbOrigin, inContext: context, angle: angle)
            } else {
                return drawThumb(withImage: image, thumbOrigin: thumbOrigin, inContext: context)
            }
        }
        
        // Draw a disk as thumb
        let thumbCircle = Circle(origin: thumbOrigin, radius: thumbRadius)
        let thumbArc = Arc(circle: thumbCircle, startAngle: TYRingSliderHelper.circleMinValue, endAngle: TYRingSliderHelper.circleMaxValue)

        TYRingSlider.drawArc(withArc: thumbArc, lineWidth: thumbLineWidth, inContext: context)
        return thumbOrigin
    }
    
    internal func drawThumbAt(_ angle: CGFloat, with image: UIImage? = nil, inContext context: CGContext) -> CGPoint {
        let circle = Circle(origin: bounds.center, radius: self.radius + self.thumbOffset)
        let thumbOrigin = TYRingSliderHelper.endPoint(fromCircle: circle, angle: angle)
        
        if let image = image {
            return drawThumb(withImage: image, thumbOrigin: thumbOrigin, inContext: context)
        }
        
        // Draw a disk as thumb
        let thumbCircle = Circle(origin: thumbOrigin, radius: thumbRadius)
        let thumbArc = Arc(circle: thumbCircle, startAngle: TYRingSliderHelper.circleMinValue, endAngle: TYRingSliderHelper.circleMaxValue)

        TYRingSlider.drawArc(withArc: thumbArc, lineWidth: thumbLineWidth, inContext: context)
        return thumbOrigin
    }

    /**
     Draw thumb using image and return the coordinates of its center

     - parameter image:   the image of the thumb
     - parameter angle:   the angle of the point in the main circle
     - parameter context: the context
     
     - returns: return the origin point of the thumb
     */
    @discardableResult
    private func drawThumb(withImage image: UIImage, thumbOrigin: CGPoint, inContext context: CGContext) -> CGPoint {
        UIGraphicsPushContext(context)
        context.beginPath()
        let imageSize = image.size
        let imageFrame = CGRect(x: thumbOrigin.x - (imageSize.width / 2), y: thumbOrigin.y - (imageSize.height / 2), width: imageSize.width, height: imageSize.height)
        image.draw(in: imageFrame)
        UIGraphicsPopContext()

        return thumbOrigin
    }
    
    
    @discardableResult
    private func drawThumb(withImage image: UIImage, thumbOrigin: CGPoint, inContext context: CGContext, angle: CGFloat) -> CGPoint {
        UIGraphicsPushContext(context)
        // 保存当前上下文状态
        context.saveGState()
        // 图片尺寸
        let imageSize = image.size
        // 计算图片应当被绘制的框架，但考虑到下面的变换，我们将这个框架设置为原点周围
        let imageFrame = CGRect(x: -imageSize.width / 2, y: -imageSize.height / 2, width: imageSize.width, height: imageSize.height)
        let adjustedAngle = angle + CGFloat.pi / 2
        // 将绘图上下文的原点移到图片的目标中心
        context.translateBy(x: thumbOrigin.x, y: thumbOrigin.y)
        // 根据需要旋转上下文
        context.rotate(by: adjustedAngle)
        // 旋转后，将图片绘制在以(图片中心为原点的)适当位置
        image.draw(in: imageFrame)
        // 恢复上下文状态
        context.restoreGState()
        UIGraphicsPopContext()
        return thumbOrigin
    }
    
    internal func drawTicks(center: CGPoint, radius: CGFloat) {
        guard let _step = step else { return }
        // 绘制参数
        let tickLength: CGFloat = stepTickLength == nil ? 5 : stepTickLength! // 分钟刻度长度
        let tickWidth: CGFloat = stepTickWidth == nil ? 2 : stepTickWidth! // 刻度线宽
        let tickColor: UIColor = stepTickColor == nil ? .white : stepTickColor! // 分钟刻度颜色
        
        let number = Int(maximumValue / _step)

        // 获取图形上下文
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // 遍历所有60个刻度（每分钟一个刻度）
        for i in 0..<number {
            let angle = CGFloat(i) * (2 * .pi / CGFloat(number)) // 每个刻度的角度
            let startRadius = radius - tickLength * 0.5
            let endRadius = radius + tickLength * 0.5

            // 计算起点和终点
            let startPoint = CGPoint(x: center.x + startRadius * cos(angle), y: center.y + startRadius * sin(angle))
            let endPoint = CGPoint(x: center.x + endRadius * cos(angle), y: center.y + endRadius * sin(angle))

            // 设置绘制属性
            context.setStrokeColor(tickColor.cgColor)
            context.setLineWidth(tickWidth)
            context.setLineCap(.round)

            // 绘制刻度
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
        }
    }

}
