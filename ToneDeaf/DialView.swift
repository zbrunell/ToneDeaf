// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import UIKit

class DialView: UIView {
    
    var needleLayer: CAShapeLayer!
    var dialImageView: UIImageView!
    var lastBounds: CGRect = .zero
    var isDark: Bool {
        return darkMode.isDarkMode
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        // Redraws the dial only when its size changes so the needle position is not reset.
        super.layoutSubviews()
        
        // Only redraw if bounds actually changed-- prevents resetting needle
        guard bounds != lastBounds else { return }
        lastBounds = bounds
        
        subviews.forEach { $0.removeFromSuperview() }
        needleLayer?.removeFromSuperlayer()
        drawDialImage()
        drawNeedle()
    }
    
    // MARK: - Dial Face
    
    func drawDialImage() {
        // Draws the dial face, including colored pitch zones, tick marks, and center pivot using geometry
        let size = bounds.size
        guard size.width > 0 && size.height > 0 else { return }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 10
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            
            let outerRing = UIBezierPath(arcCenter: center,
                                         radius: radius,
                                         startAngle: .pi,
                                         endAngle: 0,
                                         clockwise: true)
            UIColor.systemIndigo.withAlphaComponent(0.3).setStroke()
            outerRing.lineWidth = 12
            outerRing.stroke()
            
            drawArcSegment(ctx: ctx.cgContext, center: center, radius: radius - 18,
                           start: .pi,        end: .pi * 1.35, color: UIColor.systemYellow.withAlphaComponent(0.8))
            drawArcSegment(ctx: ctx.cgContext, center: center, radius: radius - 18,
                           start: .pi * 1.35, end: .pi * 1.65, color: UIColor.systemGreen.withAlphaComponent(0.9))
            drawArcSegment(ctx: ctx.cgContext, center: center, radius: radius - 18,
                           start: .pi * 1.65, end: .pi * 2,    color: UIColor.systemBlue.withAlphaComponent(0.8))
            
            drawTickMarks(ctx: ctx.cgContext, center: center, radius: radius)
            
            let pivotPath = UIBezierPath(arcCenter: center, radius: 10,
                                         startAngle: 0, endAngle: .pi * 2, clockwise: true)
            UIColor.systemIndigo.setFill()
            pivotPath.fill()
        }
        
        dialImageView = UIImageView(image: image)
        dialImageView.frame = bounds
        dialImageView.contentMode = .scaleAspectFit
        dialImageView.backgroundColor = .clear
        addSubview(dialImageView)
    }
    
    func drawArcSegment(ctx: CGContext, center: CGPoint, radius: CGFloat,
                        start: CGFloat, end: CGFloat, color: UIColor) {
        // Draws one colored arc segment on the dial
        let arc = UIBezierPath(arcCenter: center, radius: radius,
                               startAngle: start, endAngle: end, clockwise: true)
        color.setStroke()
        arc.lineWidth = 8
        arc.stroke()
    }
    
    func drawTickMarks(ctx: CGContext, center: CGPoint, radius: CGFloat) {
        // Draws major and minor tick marks across the semicircle.
        let totalTicks = 12
        for i in 0...totalTicks {
            let angle = CGFloat.pi + CGFloat(i) * CGFloat.pi / CGFloat(totalTicks)
            let isMajor = (i == 0 || i == totalTicks / 2 || i == totalTicks)
            let tickLength: CGFloat = isMajor ? 16 : 8
            let tickWidth: CGFloat  = isMajor ? 2.5 : 1.5
            
            let outerX = center.x + (radius - 4) * cos(angle)
            let outerY = center.y + (radius - 4) * sin(angle)
            let innerX = center.x + (radius - 4 - tickLength) * cos(angle)
            let innerY = center.y + (radius - 4 - tickLength) * sin(angle)
            
            let tick = UIBezierPath()
            tick.move(to: CGPoint(x: outerX, y: outerY))
            tick.addLine(to: CGPoint(x: innerX, y: innerY))
            let tickColor = isDark ? UIColor.white : UIColor.black
            tickColor.withAlphaComponent(isMajor ? 0.9 : 0.4).setStroke()
            tick.lineWidth = tickWidth
            tick.stroke()
        }
    }
    
    // MARK: - Needle
    func drawNeedle() {
        // Creates the needle layer and anchors it at the center pivot for rotation.func drawNeedle() {
        let size = bounds.size
        guard size.width > 0 && size.height > 0 else { return }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let needleLength = min(size.width, size.height) / 2 - 30
        
        needleLayer = CAShapeLayer()
        needleLayer.bounds = CGRect(x: 0, y: 0, width: 20, height: needleLength)
        needleLayer.position = center
        needleLayer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 10, y: needleLength))
        path.addLine(to: CGPoint(x: 10, y: 0))
        
        needleLayer.path = path.cgPath
        needleLayer.strokeColor = isDark ? UIColor.white.cgColor: UIColor.black.cgColor
        needleLayer.lineWidth = 3
        needleLayer.lineCap = .round
        
        layer.addSublayer(needleLayer)
    }
    
    // MARK: - Public API
    
    func setNeedle(centsOff: Float) {
        // Converts cents offset into a clamped rotation angle and animates the needle
        guard needleLayer != nil else { return }
        
        let clamped = max(-50, min(50, centsOff))
        let angle = CGFloat(clamped / 50.0) * (.pi / 2)
        
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = needleLayer.presentation()?.value(forKeyPath: "transform.rotation.z") ?? 0
        animation.toValue = angle
        animation.duration = 0.15
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        needleLayer.add(animation, forKey: "needleRotation")
        needleLayer.setValue(angle, forKeyPath: "transform.rotation.z")
    }
    func updateNeedleColor() {
        // Updates needle color when dark mode changes
        guard needleLayer != nil else { return }
        needleLayer.strokeColor = isDark ? UIColor.white.cgColor : UIColor.black.cgColor
    }
}
