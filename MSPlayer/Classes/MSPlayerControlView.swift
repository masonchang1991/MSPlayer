//
//  MSPlayerControlView.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView

public protocol MSPlayerControlViewDelegate: class {
    /**
     call when control view choose a definition
     
     - parameter controlView: control view
     - parameter index: index of definition
     */
    func controlView(_ controlView: MSPlayerControlView, didChooseDefinition index: Int)
    /**
     call when control view pressed an button
     
     - parameter controlView: control view
     - parameter button:  button type
     */
    func controlView(_ controlView: MSPlayerControlView, didPress button: UIButton)
    /**
     call when slider action trigged
     
     - parameter controlView: control view
     - parameter slider: progress slider
     - parameter event:  action
     */
    func controlView(_ controlView: MSPlayerControlView, slider: UISlider, onSlider event: UIControl.Event)
    /**
     call when needs to change playback rate
     
     - parameter controlView: control view
     - parameter rate:        playback rate
     */
    func controlView(_ controlView: MSPlayerControlView, didChangeVideoPlaybackRate rate: Float)
}

// optional protocol func
extension MSPlayerControlViewDelegate {
    public func controlView(_ controlView: MSPlayerControlView, didChangeVideoPlaybackRate rate: Float) { }
}

open class MSPlayerControlView: UIView {
    
    open weak var delegate: MSPlayerControlViewDelegate?
    open weak var player: MSPlayer?
    
    // MARK: Variables
    open var resource: MSPlayerResource?
    open var selectedIndex = 0
    
    open var totalDuration: TimeInterval = 0
    open var delayItem: DispatchWorkItem?
    
    var playerLastState: MSPM.State = .notSetUrl
    
    // MARK: UI Components
    /// main views which contains the topMaskView and BottomMaskView
    open var isMaskShowing = true
    open var isFullScreen = false {
        didSet {
            if !notFoundLabel.isHidden {
                DispatchQueue.main.async {
                    self.notFoundLabel.center = self.center
                    self.notFoundLabel.setNeedsLayout()
                }
            }
        }
    }
    
    // UI
    open var mainMaskView = UIView()
    open var topMaskView = UIView()
    open var bottomMaskView = UIView()
    
    /// ImageView to show "play" cover when "pause", like ads or somethings
    open var centerPlayBtnImageView = UIImageView()
    /// ImageView to show video cover
    open var videoCoverImageView = UIImageView()
    /// top views
    open var backButton = UIButton(type: .custom)
    /// buttom view
    open var totalTimeLabel = UILabel()
    /// Progress slider
    open var timeSlider = MSTimeSlider()
    /// load progress view
    open var progressView = UIProgressView()
    open var playButton = UIButton(type: .custom)
    /// Error Label
    open var notFoundLabel = UILabel()
    open var fullScreenButton = UIButton(type: .custom)
    /// Activity Indector for loading
    open lazy var loadingIndector: NVActivityIndicatorView = {
        let isCurrentLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let screenRatioOrientationParameter: CGFloat = isCurrentLandscape ? screenHeight/screenWidth : 1.0
        let frame = CGRect(x: 0,
                           y: 0,
                           width: 30 * MSPM.screenRatio * screenRatioOrientationParameter,
                           height: 30 * MSPM.screenRatio * screenRatioOrientationParameter)
        let loadingView = NVActivityIndicatorView(frame: frame)
        return loadingView
    }()
    
    open var seekToView = UIView()
    open var seekToViewImage = UIImageView()
    open var seekToLabel = UILabel()
    
    open var replayButton = UIButton(type: .custom)
    /// Gesture used to show / hide control view
    open var tapGesture: UITapGestureRecognizer!
    /// Gesture used to play / stop avplayer
    open var doubleTapGesture: UITapGestureRecognizer!
    // current Time and total time
    open var totalTime: TimeInterval = 0.0
    open var currentTime: TimeInterval = 0.0
    
    // MARK: - handle player state change
    /**
     call on when play time changed, update duration here
     
     - parameter currentTime: current play time
     - parameter totalTime: total duration
     
     */
    open func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {
        self.totalTime = totalTime
        self.currentTime = currentTime
        changeSliderAndLabelValueBy(to: currentTime, total: totalTime)
    }
    
    /**
     call on load duration changed, update load progressView here
     
     - parameter loadedDuration: loaded duration
     - parameter totalDuration: total duration
     */
    open func loadedTimeDidChange(loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        progressView.setProgress(Float(loadedDuration) / Float(totalDuration), animated: true)
    }
    
    open func playerStateDidChange(state: MSPM.State) {
        switch state {
        case .readyToPlay:
            hideUrlWrongLabel()
            hideLoader()
        case .buffering:
            showLoader()
        case .bufferFinished:
            hideLoader()
        case .playedToTheEnd:
            if !(player?.isSeeking ?? false) {
                playButton.isSelected = false
                showPlayToTheEndView()
                controlViewAnimation(isShow: true)
                cancelAutoFadeOutAnimation()
            }
        case .error:
            showUrlWrong()
        default:
            break
        }
        playerLastState = state
    }
    
    /**
     call when user use the slide to seek function
     
     - parameter toSeconds:      target time
     - parameter totalDuration: total duration of the video
     - parameter isAdd:         isAdd
     */
    open func showSeekToView(to seconds: TimeInterval, total duration: TimeInterval, isAdd: Bool) {
        seekToView.isHidden = false
        seekToLabel.text = FormatDisplay.formatSecondsToString(seconds)
        
        let rotate = isAdd ? 0: CGFloat(Double.pi)
        seekToViewImage.transform = CGAffineTransform(rotationAngle: rotate)
        
        changeSliderAndLabelValueBy(to: seconds, total: duration)
    }
    
    private func changeSliderAndLabelValueBy(to seconds: TimeInterval, total duration: TimeInterval) {
        let targetTime = FormatDisplay.formatSecondsToString(seconds)
        timeSlider.value = Float(seconds / duration)
        player?.progressSliderValue = timeSlider.value
        totalTimeLabel.text = targetTime + "/" + FormatDisplay.formatSecondsToString(totalTime)
    }
    
    // MARK: - UI update related function
    /**
     Update UI details when player set with the resource
     
     - parameter resource: video resouce
     - parameter index: default definition's index
     */
    open func prepareUI(for resource: MSPlayerResource, selected index: Int) {
        self.resource = resource
        self.selectedIndex = index
        autoFadeOutControlViewWithAnimation()
    }
    
    open func playStateDidChange(isPlaying: Bool) {
        autoFadeOutControlViewWithAnimation()
        playButton.isSelected = isPlaying
    }
    
    /**
     auto fade out controlView with animation
     */
    open func autoFadeOutControlViewWithAnimation() {
        cancelAutoFadeOutAnimation()
        delayItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.videoCoverImageView.isHidden {
                self.controlViewAnimation(isShow: false)
            }
        }
        if let item = delayItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + MSPlayerConfig.animateDelayTimeInterval,
                                          execute: item)
        }
    }
    
    /**
     cancel auto fade out controlView with animation
     */
    open func cancelAutoFadeOutAnimation() {
        guard let delayItem = delayItem else { return }
        delayItem.cancel()
    }
    
    /**
     Implement of the controlView animation, override if need's custom animation
     
     - parameter isShow: is to show the controlView
     */
    open func controlViewAnimation(isShow: Bool) {
        if self.playerLastState != .playedToTheEnd {
            let otherAlpha: CGFloat = isShow ? MSPlayerConfig.otherMaskViewShowAlpha : 0.0
            let mainAlpha: CGFloat = isShow ? MSPlayerConfig.mainMaskViewShowAlpha : 0.0
            self.isMaskShowing = isShow
            
            UIView.animate(withDuration: MSPlayerConfig.controlViewAnimationDuration, animations: {
                self.topMaskView.alpha = otherAlpha
                self.bottomMaskView.alpha = otherAlpha
                
                self.mainMaskView.backgroundColor = UIColor.black.withAlphaComponent(mainAlpha)
                if !isShow {
                    self.replayButton.isHidden = true
                }
                self.layoutIfNeeded()
            }, completion: { (_) in
                if isShow {
                    self.autoFadeOutControlViewWithAnimation()
                }
            })
        }
    }
    
    /**
     Implement of the UI update when screen orient changed
     
     - parameter fullScreen: is for full screen
     */
    open func updateUI(for fullScreen: Bool) {
        isFullScreen = fullScreen
        fullScreenButton.isSelected = fullScreen
        
        if fullScreen {
            // rawValue == 2 mean none so notShowTopMaskView
            if MSPlayerConfig.topBarShowInCase.rawValue == 2 {
                topMaskView.isHidden = true
            } else {
                topMaskView.isHidden = false
            }
        } else {
            if MSPlayerConfig.topBarShowInCase.rawValue >= 1 {
                topMaskView.isHidden = true
            } else {
                topMaskView.isHidden = false
            }
        }
    }
    
    /**
     Call when video play to the end, override if you need custom UI or animation when played to the end
     */
    open func showPlayToTheEndView() {
        replayButton.isHidden = false
    }
    
    open func hidePlayToTheEndView() {
        replayButton.isHidden = true
    }
    
    open func showLoader() {
        loadingIndector.isHidden = false
        loadingIndector.startAnimating()
    }
    
    open func hideLoader() {
        loadingIndector.isHidden = true
    }
    
    open func hideSeekToView() {
        seekToView.isHidden = true
    }
    
    open func showCoverWithLink(_ cover: String) {
        showCover(url: URL(string: cover))
    }
    
    open func hideCover() {
        videoCoverImageView.isHidden = true
    }
    
    func changePlayButtonState(isSelected: Bool) {
        playButton.isSelected = isSelected
    }
    
    open func showCover(url: URL?, urlHeaders: [String: String]? = nil) {
        guard let url = url else { return }
        controlViewAnimation(isShow: false)
        DispatchQueue.global(qos: .default).async {
            let urlSessionConfiguration = URLSessionConfiguration.default
            urlSessionConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            urlSessionConfiguration.timeoutIntervalForRequest = 15.0
            urlSessionConfiguration.timeoutIntervalForResource = 15.0
            let urlSession = URLSession(configuration: urlSessionConfiguration)
            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = urlHeaders
            urlSession.dataTask(with: request, completionHandler: { (data, response, error) in
                DispatchQueue.main.async {
                    if let dataUnwrapped = data {
                        self.videoCoverImageView.isHidden = false
                        self.videoCoverImageView.image = UIImage(data: dataUnwrapped)
                    } else {
                        self.videoCoverImageView.image = nil
                    }
                    self.hideLoader()
                }
            }).resume()
        }
    }
    
    open func showPlayCover() {
        if !MSPlayerConfig.playCoverImageViewNeedHidden {
            self.centerPlayBtnImageView.isHidden = false
        }
    }
    
    open func hidePlayCover() {
        self.centerPlayBtnImageView.isHidden = true
    }
    
    open func showUrlWrong() {
        hideLoader()
        notFoundLabel.isHidden = false
        notFoundLabel.text = MSPlayerConfig.urlWrongLabelText
        notFoundLabel.sizeToFit()
        notFoundLabel.center = center
        notFoundLabel.textColor = UIColor.white
        addSubview(notFoundLabel)
    }
    
    open func hideUrlWrongLabel() {
        notFoundLabel.isHidden = true
    }
    
    open func prepareToDealloc() {
        delayItem = nil
    }
    
    // MARK: - Action Response
    /**
     Call when some action button pressed
     
     - parameter button: action button
     */
    @objc open func onButtonPressed(_ button: UIButton) {
        autoFadeOutControlViewWithAnimation()
        if let type = MSPM.ButtonType(rawValue: button.tag) {
            switch type {
            case .playAndPause:
                if playerLastState == .playedToTheEnd {
                    hidePlayToTheEndView()
                }
                if !videoCoverImageView.isHidden {
                    //MARK: - 再有封面圖的狀態下，強制變成pause狀態，點擊封面成為播放的指令
                    button.isSelected = false
                }
            case .replay:
                hidePlayToTheEndView()
            default: break
            }
        }
        delegate?.controlView(self, didPress: button)
    }
    
    /**
     Call when the tap gesture tapped
     
     - parameter gesture: tap gesture
     */
    @objc open func onTapGestureTapped(_ gesture: UITapGestureRecognizer) {
        if playerLastState == .playedToTheEnd { return }
        controlViewAnimation(isShow: !isMaskShowing)
    }
    
    @objc open func doubleTapGestureTapped(_ gesture: UITapGestureRecognizer) {
        if playerLastState == .playedToTheEnd { return }
        playButton.sendActions(for: .touchUpInside)
    }
    
    // play icon image action
    open func setupPlayCoverImageViewGesture() {
        let tapToPlay = UITapGestureRecognizer(target: self,
                                               action: #selector(playCoverPress))
        centerPlayBtnImageView.isUserInteractionEnabled = true
        centerPlayBtnImageView.addGestureRecognizer(tapToPlay)
    }
    
    open func setupMaskImageViewGesture() {
        let tapToPlay = UITapGestureRecognizer(target: self,
                                               action: #selector(playCoverPress))
        videoCoverImageView.isUserInteractionEnabled = true
        videoCoverImageView.addGestureRecognizer(tapToPlay)
    }
    
    @objc open func playCoverPress() {
        playButton.sendActions(for: .touchUpInside)
    }
    
    // MARK: - handle UI slider actions
    @objc func progressSliderTouchBegan(_ sender: UISlider) {
        delegate?.controlView(self, slider: sender, onSlider: .touchDown)
    }
    
    @objc func progressSliderValueChanged(_ sender: UISlider) {
        hidePlayToTheEndView()
        cancelAutoFadeOutAnimation()
        let currentTime = floor(Double(sender.value) * totalDuration)
        changeSliderAndLabelValueBy(to: currentTime, total: totalTime)
        delegate?.controlView(self, slider: sender, onSlider: .valueChanged)
    }
    
    @objc func progressSliderTouchEnded(_ sender: UISlider) {
        autoFadeOutControlViewWithAnimation()
        delegate?.controlView(self, slider: sender, onSlider: .touchUpInside)
    }
    
    fileprivate func onReplyButtonPressed() {
        replayButton.isHidden = true
    }
    
    // MARK: - Init
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUIComponents()
        setupUIConstraint()
        customizeUIComponents()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUIComponents()
        setupUIConstraint()
        customizeUIComponents()
    }
    
    func changeBackImageToDownImage() {
        backButton.setImage(MSPlayerConfig.downButtonImage, for: .normal)
        MSPlayerConfig.isUseBackImage = false
    }
    
    func changeDownImageToBackImage() {
        backButton.setImage(MSPlayerConfig.backButtonImage, for: .normal)
        MSPlayerConfig.isUseBackImage = true
    }
    
    open func setupUIComponents() {
        let isCurrentLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let screenRatioOrientationParameter: CGFloat = isCurrentLandscape ? screenHeight/screenWidth : 1.0
        
        // Main mask view
        addSubview(mainMaskView)
        mainMaskView.addSubview(topMaskView)
        mainMaskView.addSubview(bottomMaskView)
        mainMaskView.addSubview(loadingIndector)
        centerPlayBtnImageView.image = MSPlayerConfig.playCoverImage
        mainMaskView.addSubview(centerPlayBtnImageView)
        
        hidePlayCover()
        setupPlayCoverImageViewGesture()
        
        bottomMaskView.backgroundColor = MSPlayerConfig.bottomMaskBackgroundColor
        mainMaskView.insertSubview(videoCoverImageView, at: 0)
        videoCoverImageView.contentMode = .scaleAspectFill
        setupMaskImageViewGesture()
        mainMaskView.clipsToBounds = true
        mainMaskView.backgroundColor = MSPlayerConfig.mainMaskBackgroundColor
        
        // Top Views
        topMaskView.addSubview(backButton)
        backButton.tag = MSPM.ButtonType.back.rawValue
        if MSPlayerConfig.isUseBackImage {
            backButton.setImage(MSPlayerConfig.backButtonImage, for: .normal)
        } else {
            backButton.setImage(MSPlayerConfig.downButtonImage, for: .normal)
        }
        backButton.imageView?.tintColor = MSPlayerConfig.backButtonImageViewTintColor
        backButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        
        // Bottom views
        bottomMaskView.addSubview(playButton)
        bottomMaskView.addSubview(totalTimeLabel)
        bottomMaskView.addSubview(progressView)
        bottomMaskView.addSubview(timeSlider)
        bottomMaskView.addSubview(fullScreenButton)
        
        playButton.tag = MSPM.ButtonType.playAndPause.rawValue
        playButton.setImage(MSPlayerConfig.playButtonImage, for: .normal)
        playButton.setImage(MSPlayerConfig.pauseButtonImage, for: .selected)
        playButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        playButton.imageView?.contentMode = .scaleAspectFit
        
        totalTimeLabel.textColor = MSPlayerConfig.totalTimeTextColor
        totalTimeLabel.font = UIFont(name: "PingFangSC-Medium",
                                     size: 10.0 * MSPM.screenRatio * screenRatioOrientationParameter)
        totalTimeLabel.text = "00:00/00:00"
        totalTimeLabel.textAlignment = .center
        
        timeSlider.maximumValue = 1.0
        timeSlider.minimumValue = 0.0
        timeSlider.value        = 0.0
        timeSlider.setThumbImage(MSPlayerConfig.sliderThumbImage, for: .normal)
        timeSlider.maximumTrackTintColor = MSPlayerConfig.sliderMaxTrackTintColor
        timeSlider.minimumTrackTintColor = MSPlayerConfig.sliderMinTrackTintColor
        
        timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)),
                             for: .touchDown)
        timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)),
                             for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)),
                             for: [.touchUpInside, .touchCancel, .touchDragExit])
        
        progressView.tintColor = MSPlayerConfig.progressViewTintColor
        progressView.trackTintColor = MSPlayerConfig.progressViewTrackTintColor
        
        fullScreenButton.tag = MSPM.ButtonType.fullScreen.rawValue
        fullScreenButton.setImage(MSPlayerConfig.fullScreenButtonImage, for: .normal)
        fullScreenButton.setImage(MSPlayerConfig.endFullScreenButtonImage, for: .selected)
        fullScreenButton.addTarget(self,
                                   action: #selector(onButtonPressed(_:)),
                                   for: .touchUpInside)
        
        loadingIndector.type =  MSPlayerConfig.loaderType
        loadingIndector.color = MSPlayerConfig.loaderTintColor
        
        // view to show when slide to seek
        addSubview(seekToView)
        seekToView.addSubview(seekToViewImage)
        seekToView.addSubview(seekToLabel)
        
        seekToLabel.font = UIFont.systemFont(ofSize: 13 * MSPM.screenRatio * screenRatioOrientationParameter)
        seekToLabel.textColor = MSPlayerConfig.seekToLabelTextColor
        
        seekToView.backgroundColor = MSPlayerConfig.seekToViewBackgroundColor
        seekToView.layer.cornerRadius = MSPlayerConfig.seekToViewCornerRadius
        seekToView.layer.masksToBounds = true
        seekToView.isHidden = true
        
        seekToViewImage.image = MSPlayerConfig.seekToViewImage
        
        addSubview(replayButton)
        replayButton.isHidden = true
        replayButton.setImage(MSPlayerConfig.replayButtonImage, for: .normal)
        replayButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        replayButton.tag = MSPM.ButtonType.replay.rawValue
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGestureTapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGestureTapped(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.require(toFail: doubleTapGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(doubleTapGesture)
    }
    
    open func setupUIConstraint() {
        let isCurrentLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let screenRatioOrientationParameter: CGFloat = isCurrentLandscape ? screenHeight/screenWidth : 1.0
        
        // Main mask view
        mainMaskView.translatesAutoresizingMaskIntoConstraints = false
        mainMaskView.addConstraintWithOther(self, anchorTypes: [.edge2Edge])
        
        videoCoverImageView.translatesAutoresizingMaskIntoConstraints = false
        videoCoverImageView.addConstraintWithOther(mainMaskView, anchorTypes: [.edge2Edge])
        
        centerPlayBtnImageView.translatesAutoresizingMaskIntoConstraints = false
        centerPlayBtnImageView.addConstraintWithOther(mainMaskView, anchorTypes: [.width2Width(Double(1.0 / 7.0), priority: 1000),
                                                                              .height2Width(Double(1.0 / 7.0), priority: 1000),
                                                                              .centerX2CenterX(0, priority: 1000),
                                                                              .centerY2CenterY(0, priority: 1000)])
        //MARK: - maybe you would rotate screen before I get statusbar height
        // so change isStatusBarHidden to false to get statusBarHeight and restore to origin
        let statusBarIsHidden = UIApplication.shared.isStatusBarHidden
        UIApplication.shared.isStatusBarHidden = false
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        UIApplication.shared.isStatusBarHidden = statusBarIsHidden
        
        topMaskView.translatesAutoresizingMaskIntoConstraints = false
        topMaskView.addConstraintWithOther(mainMaskView, anchorTypes: [.top2Top(statusBarHeight, priority: 1000),
                                                                       .leading2Leading(0, priority: 1000),
                                                                       .trailing2Trailing(0, priority: 1000),
                                                                       .height(statusBarHeight + 37, priority: 1000)])
        bottomMaskView.translatesAutoresizingMaskIntoConstraints = false
        bottomMaskView.addConstraintWithOther(mainMaskView, anchorTypes: [.bottom2Bottom(0, priority: 1000),
                                                                          .leading2Leading(0, priority: 1000),
                                                                          .trailing2Trailing(0, priority: 1000),
                                                                          .height2Width(Double(30.0 / 375.0 * screenRatioOrientationParameter), priority: 900)])
        bottomMaskView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40.0).isActive = true
        
        // Top Views
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addConstraintWithOther(mainMaskView, anchorTypes: [.width(30 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000),
                                                                      .height(30 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000),
                                                                      .leading2Leading(15 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000)])
        backButton.addConstraintWithOther(topMaskView, anchorTypes: [.top2Top(0, priority: 1000)])
        
        // Bottom Views
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.addConstraintWithOther(bottomMaskView, anchorTypes: [.height2Height(24.0 / 32.0, priority: 1000),
                                                                        .width2Height(24.0 / 32.0, priority: 1000),
                                                                        .leading2Leading(10, priority: 1000),
                                                                        .centerY2CenterY(0, priority: 1000)])
        
        fullScreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullScreenButton.addConstraintWithOther(bottomMaskView, anchorTypes: [.height2Height(24.0 / 32.0, priority: 1000),
                                                                              .width2Height(24.0 / 32.0, priority: 1000),
                                                                              .centerY2CenterY(0, priority: 1000),
                                                                              .trailing2Trailing(-15, priority: 1000)])
        
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.addConstraintWithOther(playButton, anchorTypes: [.centerY2CenterY(0, priority: 1000)])
        totalTimeLabel.addConstraintWithOther(fullScreenButton, anchorTypes: [.trailing2Leading(-5, priority: 1000)])
        
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        timeSlider.addConstraintWithOther(bottomMaskView, anchorTypes: [.centerY2CenterY(0, priority: 1000),
                                                                        .height2Height(30.0 / 32.0, priority: 1000)])
        timeSlider.addConstraintWithOther(playButton, anchorTypes: [.leading2Trailing(10, priority: 999)])
        timeSlider.addConstraintWithOther(totalTimeLabel, anchorTypes: [.trailing2Leading(-10, priority: 1000)])
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.addConstraintWithOther(playButton, anchorTypes: [.centerY2CenterY(0, priority: 1000)])
        progressView.addConstraintWithOther(timeSlider, anchorTypes: [.leading2Leading(0, priority: 1000),
                                                                      .trailing2Trailing(0, priority: 1000)])
        progressView.addConstraintWithOther(bottomMaskView, anchorTypes: [.height2Height(2.0 / 32.0 , priority: 1000)])
        
        loadingIndector.translatesAutoresizingMaskIntoConstraints = false
        loadingIndector.addConstraintWithOther(mainMaskView, anchorTypes: [.centerX2CenterX(0, priority: 1000),
                                                                           .centerY2CenterY(0, priority: 1000)])
        
        // view to show when slide to seek
        seekToView.translatesAutoresizingMaskIntoConstraints = false
        seekToView.addConstraintWithOther(self, anchorTypes: [.centerX2CenterX(0, priority: 1000),
                                                              .centerY2CenterY(0, priority: 1000),
                                                              .width(100 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000),
                                                              .height(40 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000)])
        
        seekToViewImage.translatesAutoresizingMaskIntoConstraints = false
        seekToViewImage.addConstraintWithOther(seekToView, anchorTypes: [.leading2Leading(15 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000),
                                                                         .centerY2CenterY(0, priority: 1000),
                                                                         .height(15 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000),
                                                                         .width(25 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000)])
        
        seekToLabel.translatesAutoresizingMaskIntoConstraints = false
        seekToLabel.addConstraintWithOther(seekToViewImage, anchorTypes: [.leading2Trailing(10, priority: 1000)])
        seekToLabel.addConstraintWithOther(seekToView, anchorTypes: [.centerY2CenterY(0, priority: 1000)])
        
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        replayButton.addConstraintWithOther(mainMaskView, anchorTypes: [.centerX2CenterX(0, priority: 1000),
                                                                        .centerY2CenterY(0, priority: 1000),
                                                                        .height(50 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000),
                                                                        .width(50 * MSPM.screenRatio * screenRatioOrientationParameter, priority: 1000)])
    }
    
    /// Add Customize functions here
    open func customizeUIComponents() {
        
    }
    
    deinit {
        print(classForCoder, "dealloc")
    }
}
