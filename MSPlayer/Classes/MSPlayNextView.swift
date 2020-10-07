//
//  MSPlayNextView.swift
//  MSPlayer
//
//  Created by Mason on 2019/6/18.
//

import Foundation

public protocol MSPlayNext: UIView {
    var playNext: (() -> ())? { get set }
    func startPreparing()
    func pausePreparing()
}

open class CircleProgressImageView: UIView, MSPlayNext {
    
    public let imageView = UIImageView()
    
    open var trackLayer: CAShapeLayer
    open var progressLayer: CAShapeLayer
    open var basicAnimation: CABasicAnimation
    
    open var lineWidthAspectRatio: CGFloat = 0.1
    
    open var playNext: (() -> ())?
    
    open var circularPath: UIBezierPath {
        let radius = bounds.width / 2
        return UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
                            radius: ceil(radius - radius * lineWidthAspectRatio),
                            startAngle: -.pi / 2,
                            endAngle: 2 * .pi,
                            clockwise: true)
    }
    
    convenience public init(size: CGSize, image: UIImage?) {
        ///Set default layer and animation
        let trackLayer = CAShapeLayer()
        trackLayer.strokeColor = UIColor.gray.withAlphaComponent(0.54).cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = CAShapeLayerLineCap.round
        
        let progressLayer = CAShapeLayer()
        progressLayer.strokeColor = UIColor.white.withAlphaComponent(0.87).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = CAShapeLayerLineCap.round
        progressLayer.strokeEnd = 0
        
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = 1
        basicAnimation.duration = 5
        basicAnimation.fillMode = .forwards
        basicAnimation.isRemovedOnCompletion = false
        
        self.init(frame: CGRect(origin: CGPoint.zero, size: size),
                  image: image,
                  trackLayer: trackLayer,
                  progressLayer: progressLayer,
                  basicAnimation: basicAnimation)
    }
    
    @objc public init(frame: CGRect, image: UIImage?, trackLayer: CAShapeLayer, progressLayer: CAShapeLayer, basicAnimation: CABasicAnimation) {
        self.trackLayer = trackLayer
        self.progressLayer = progressLayer
        self.basicAnimation = basicAnimation
        super.init(frame: frame)
        
        setupViews()
        setupGestures()
        
        if let image = image {
            self.imageView.image = image
            addSubview(imageView)
            imageView.frame = self.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        self.basicAnimation.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        let radius = bounds.width / 2
        imageView.layer.cornerRadius = radius
        
        trackLayer.path = circularPath.cgPath
        trackLayer.lineWidth = ceil(radius * lineWidthAspectRatio)
        progressLayer.path = circularPath.cgPath
        progressLayer.lineWidth = ceil(radius * lineWidthAspectRatio)
    }
    
    private func setupViews() {
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
    }
    
    public func startPreparing() {
        progressLayer.add(basicAnimation, forKey: "roundCircle")
    }
    
    public func pausePreparing() {
        progressLayer.removeAnimation(forKey: "roundCircle")
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
    }
    
    @objc private func handleTap() {
        playNext?()
    }
}

extension CircleProgressImageView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // flag is true mean completed
        if flag { playNext?() }
    }
}
