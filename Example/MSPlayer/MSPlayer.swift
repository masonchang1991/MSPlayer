//
//  MSPlayer.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/23.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import MediaPlayer

/// MSPlayerDelegate to observe player state
public protocol MSPlayerDelegate: class {
    func msPlayer(_ player: MSPlayer, stateDidChange state: MSPM.State)
    func msPlayer(_ player: MSPlayer, loadTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func msPlayer(_ player: MSPlayer, playTimeDidChange current: TimeInterval, total: TimeInterval)
    func msPlayer(_ player: MSPlayer, isPlaying: Bool)
    func msPlayer(_ player: MSPlayer, orientChanged isFullScreen: Bool)
}

open class MSPlayer: UIView {
    
    open var backToParent: (() -> ())?
    
    enum MSPanDirection: Int {
        case horizontal = 0
        case vertical = 1
    }
    
    private var videoId: String? = nil
    open weak var delegate: MSPlayerDelegate?
    open var playerLayerView: MSPlayerLayerView?
    fileprivate var controlView: MSPlayerControlView!
    fileprivate var customControlView: MSPlayerControlView?
    open var currentResource: MSPlayerResource?
    fileprivate var currentDefinition = 0
    fileprivate var resource: MSPlayerResource! {
        didSet {
            self.currentResource = resource
        }
    }
    open var avPlayer: AVPlayer? {
        return playerLayerView?.player
    }
    
    /// Gesture to change volume / brightness
    open var panGesture: UIPanGestureRecognizer?
    
    /// AVLayerVideoGravityType
    open var videoGravity = AVLayerVideoGravityResizeAspectFill {
        didSet {
           self.playerLayerView?.videoGravity = videoGravity
        }
    }
    
    open var isPlaying: Bool {
        get {
            return playerLayerView?.isPlaying ?? false
        }
    }
    
    // Closure
    /// fired when play time changed
    open var playTimeDidChange: ((TimeInterval, TimeInterval) -> Void)?
    /// fired when play state changed
    open var playStateDidChange: ((Bool) -> Void)?
    /// fired when tap backButton, fullScrren to unFullScreen, unFullScreen to pop
    open var backBlock: ((Bool) -> Void)?
    open var showBlock: ((Bool) -> Void)?
    
    // status
    fileprivate var isFullScreen: Bool {
        get {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    open var isSeeking = false {
        didSet {
            self.playerLayerView?.isNowSeeking = self.isSeeking
        }
    }
    /// if nowSeekingCount > 0, means there is other seeking, so isSeeking will be true
    open var nowSeekingCount = 0 {
        didSet {
            // 當有別的seekingAction時，不要把isSeeking關掉，關掉的話，每0.5秒會更新進度條，所以會把進度條跳回去
            self.isSeeking = nowSeekingCount == 0 ? false: true
        }
    }
    
    /// Adjust the value of pan to seek
    open var panToSeekRate: Double {
      return MSPlayerConfig.playerPanSeekRate
    }
    /// 滑動方向
    fileprivate var panDirection: MSPlayer.MSPanDirection = .horizontal
    /// 進度滑桿值 - ControlView變更時一併變更MSPlayer的值
    open var progressSliderValue: Float = 0.0
    /// 音量滑桿
    fileprivate var volumeViewSlider: UISlider!
    
    fileprivate let playerAnimationDuration: Double = MSPlayerConfig.playerAnimationDuration
    fileprivate let playerControlBarAutoFadeOutDuration: Double = MSPlayerConfig.playerControlBarAutoFadeOutDuration
    
    // time status
    /// 滑動起始時影片時間
    fileprivate var horizontalBeginTime: TimeInterval = 0
    /// 滑動累積值 (平滑時，總共增加多少時間、總共減少多少時間) (base on current time)
    fileprivate var sumTime: TimeInterval = 0
    fileprivate var totalDuration: TimeInterval = 0
    fileprivate var currentPosition: TimeInterval = 0
    fileprivate var shouldSeekTo: TimeInterval = 0
    fileprivate var isURLSet = false
    fileprivate var isSliderSliding = false
    fileprivate var isUserMoveSlider = false
    fileprivate var isVolume = false
    fileprivate var isMaskShowing = false
    fileprivate var isSlowed = false
    fileprivate var isMirrored = false
    fileprivate var isPlayToTheEnd = false
    fileprivate var isPauseByUser = false {
        didSet {
            if isPauseByUser {
                playerLayerView?.pause()
            } else {
                playerLayerView?.play()
            }
        }
    }
    // 畫面比例
    fileprivate var aspectRatio: MSPM.AspectRatio = .default
    // cache is playing result to improve callback performance
    fileprivate var isPlayingCache: Bool? = nil
    
    // UI
    var userConstraint = [NSLayoutConstraint]()
    
    // MARK: - Public functions
    
    /**
     Play
     
     - parameter resource: media resource
     - parameter definitionIndex: starting definition index, default start with the first definition
    */
    open func setVideoBy(_ resource: MSPlayerResource, definitionIndex: Int = 0, videoIdForRecord: String? = nil) {
        isURLSet = false
        self.resource = resource
        self.videoId = videoIdForRecord
        currentDefinition = definitionIndex
        controlView.prepareUI(for: resource,
                              selected: definitionIndex)
        
        if MSPlayerConfig.shouldAutoPlay {
            controlView.hideCover()
            isURLSet = true
            let asset = resource.definitions[definitionIndex]
            playerLayerView?.playAsset(asset: asset.avURLAsset)
            if videoId != nil {
                let coreDataManager = MSCoreDataManager()
                coreDataManager.loadVideoTimeRecordWith(videoId!) { (lastWatchTime) in
                    if let lastWatchTime = lastWatchTime {
                        self.seek(lastWatchTime) {
                            self.autoPlay()
                        }
                    }
                }
            }
        } else {
            controlView.showCover(url: resource.coverURL)
            controlView.hideLoader()
        }
    }
    /**
     auto start playing, call at viewWillAppear, see more at pause
    */
    open func autoPlay() {
        if !isPauseByUser && isURLSet && !isPlayToTheEnd {
             play()
        }
    }
    
    /**
     play
    */
    open func play() {
        if resource == nil {
            return
        }
        if !isURLSet {
            let asset = resource.definitions[currentDefinition]
            playerLayerView?.playAsset(asset: asset.avURLAsset)
            controlView.hideCover()
            isURLSet = true
        }
        isPauseByUser = false
        controlView.hidePlayCover()
    }
    
    /**
    Pause
 
    - parameter allow: should allow to response 'autoPlay' function
    */
    open func pause(autoPlay allow: Bool = false) {
        recordCurrentTime()
        isPauseByUser = !allow
        // show play cover
        if controlView.playCoverImageView.isHidden {
            controlView.showPlayCover()
        }
    }
    
    /**
     seek
     
     - parameter to: target time
    */
    open func seek(_ targetTime: TimeInterval, completion: (() -> ())? = nil) {
        playerLayerView?.seek(to: targetTime, completion: completion)
    }
    
    /**
     update UI to fullScreen
    */
    open func updateUI(_ isFullScreen: Bool) {
        controlView.updateUI(for: isFullScreen)
        self.updateFrame()
    }
    
    /**
     increase volume with step, default step 0.1
 
     - parameter step: step
    */
    open func addVolume(step: Float = 0.1) {
        self.volumeViewSlider.value += step
    }
    
    /**
     decrease volume with step, default step 0.1
     
     - parameter step: step
    */
    open func reduceVolume(step: Float = 0.1) {
        self.volumeViewSlider.value -= step
    }
    
    // Close ControlView
    open func closeControlViewAndRemoveGesture() {
        self.controlView.isHidden = true
        self.removeGesture()
    }
    
    open func openControlViewAndSetGesture() {
        self.controlView.isHidden = false
        self.setGesture()
    }
    
    /**
     prepare to dealloc player, call at View or Controllers deinit funciton.
     */
    open func prepareToDealloc() {
        playerLayerView?.prepareToDeinit()
        controlView.prepareToDealloc()
    }
    
    func recordCurrentTime() {
        if videoId != nil && MSPM.shared().openRecorder {
            let currentTime = self.totalDuration * Double(self.progressSliderValue)
            let coreDataManager = MSCoreDataManager()
            coreDataManager.saveVideoTimeRecordWith(videoId!, videoTime: currentTime)
        }
    }
    
    /**
     If you want to create MSPlayer with custom control in storyBoard.
     create a subclass and override this method
 
     - return: costom control which you want to use
    */
    open class func storyBoardCustomControl() -> MSPlayerControlView? {
        return nil
    }
    
    // MARK: - Action response
    
    @objc fileprivate func panDirection(_ pan: UIPanGestureRecognizer) {
        // 播放結束時，手勢忽略
        guard playerLayerView?.state != .playedToTheEnd else { return }
        
        // 根據在view上pan的位置，確定是條音量還是亮度
        let locationPoint = pan.location(in: self)
        
        // 根據上次跟這次的移動，算出滑動速度以及方向
        // 水平移動更改進度條，垂直移動更改音量或亮度
        let velocityPoint = pan.velocity(in: self)
        
        switch pan.state {
        case .began:
            
            // 使用絕對值來判斷移動的方向
            let x = fabs(velocityPoint.x)
            let y = fabs(velocityPoint.y)
            
            // horizontal
            if x > y {
                self.panDirection = .horizontal
                self.nowSeekingCount += 1
                print("began nowSeekingCount:", self.nowSeekingCount)
                
                if (playerLayerView?.player) != nil {
                    let nowTime = self.totalDuration * Double(self.progressSliderValue)
                    // 分母不用 timeScale是因為timeScale有時候會跳到1000000000有時候又會跳到1
                    self.horizontalBeginTime = TimeInterval(nowTime) / TimeInterval(1)
                    self.sumTime = self.horizontalBeginTime
                }
                
                // is pan location.y at bottomMaskView then move slider
                if locationPoint.y > self.controlView.bottomMaskView.frame.minY {
                    self.isUserMoveSlider = true
                }
            } else {
                // vertical
                self.panDirection = .vertical
                if locationPoint.x > self.bounds.size.width / 2 {
                    self.isVolume = true
                } else {
                    self.isVolume = false
                }
            }
            
        case .changed:
            switch self.panDirection {
            case .horizontal:
                self.horizontalMoved(velocityPoint.x)
            case .vertical:
                var changeValue: CGFloat = 0.0
                if velocityPoint.y < 0 {
                    changeValue = -0.0125
                } else if velocityPoint.y > 0 {
                    changeValue = 0.0125
                } else {
                    // Do nothing in velocityPoint.y == 0
                }
                self.verticalMoved(changeValue)
            }
            
        case .ended:
            
            // 移動結束也需要判斷垂直還是平移
            // 像是水平移動結束時，要快進到指定位置，如果這裡沒有判斷，當我們調整音量完後，會出現屏幕跳動的Bug
            switch self.panDirection {
            case .horizontal:
                if MSPlayerConfig.enablePlaytimeGestures {
                    controlView.hideSeekToView()
                    isSliderSliding = false
                    isUserMoveSlider = false
                    if isPlayToTheEnd {
                        isPlayToTheEnd = false
                        seek(self.sumTime, completion: {
                            self.play()
                            self.nowSeekingCount -= 1
                            print("end isPlayToEnd nowSeekingCount:", self.nowSeekingCount)
                            // 當有別的seekingAction時，不要把isSeeking關掉，關掉的話，每0.5秒會更新進度條，所以會把進度條跳回去
                        })
                    } else {
                        seek(self.sumTime, completion: {
                            self.autoPlay()
                            self.nowSeekingCount -= 1
                            print("end not isPlayToEnd nowSeekingCount:", self.nowSeekingCount)
                        })
                    }
                }
            case .vertical:
                self.isVolume = false
            }
        default:
            break
        }
    }
    
    fileprivate func verticalMoved(_ value: CGFloat) {
        if self.isVolume {
            if MSPlayerConfig.enableVolumeGestures {
                DispatchQueue.main.async {
                    self.volumeViewSlider.value = AVAudioSession.sharedInstance().outputVolume - (Float(value) * MSPlayerConfig.playerVolumeChangeRate)
                }
            }
        } else if MSPlayerConfig.enableBrightnessGestures {
            UIScreen.main.brightness -= (value * MSPlayerConfig.playerBrightnessChangeRate)
        }
    }
    
    fileprivate func horizontalMoved(_ value: CGFloat) {
        if (!MSPlayerConfig.enablePlaytimeGestures) { return }
        
        isSliderSliding = true
        if let playerItem = playerLayerView?.playerItem {
            // 每次滑動需要疊加時間，通過一定的比例，使滑動一直處於統一水平
            if isUserMoveSlider {
                // 如果是移動滑桿，則按照他滑動的距離去決定他滑動的進度條多少
              self.sumTime = self.sumTime + TimeInterval(value) / 100.0 * (TimeInterval(self.totalDuration)/400)
            } else {
                // 如果是滑動螢幕，則進度條慢慢前進，總時間越短，totalDurationAdjustParameter也會越小，避免移動過快
                let totalDurationAdjustParameter = (TimeInterval(self.totalDuration) / 400) < 0.5 ? 0.5: (TimeInterval(self.totalDuration) / 400)
                self.sumTime = self.sumTime + TimeInterval(value) / 100 * 0.4 * panToSeekRate * totalDurationAdjustParameter
            }
            let totalTime = playerItem.duration
           
            // 防止出現NAN
            if totalTime.timescale == 0 { return }
            
            let totalDuration = TimeInterval(totalTime.value) / TimeInterval(totalTime.timescale)
            if (self.sumTime >= totalDuration) {
                self.sumTime = totalDuration - 1.0
            } else if self.sumTime <= 0{
                self.sumTime = 0
            }
            
            controlView.showSeekToView(to: sumTime, total: totalDuration, isAdd: self.sumTime > self.horizontalBeginTime)
        }
    }
    
    @objc fileprivate func onOrientationChanged() {
        self.updateUI(isFullScreen)
        delegate?.msPlayer(self, orientChanged: isFullScreen)
    }
    
    fileprivate func fullScreenButtonPressed() {
        controlView.updateUI(for: !self.isFullScreen)
        if isFullScreen {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue,
                                      forKey: "orientation")
            UIApplication.shared.setStatusBarHidden(false, with: .fade)
            UIApplication.shared.statusBarOrientation = .portrait
        } else {
            self.translatesAutoresizingMaskIntoConstraints = false
            //先清除現在orientation的值
            //有可能Device是landscape進來(此時statusbar的orientation是portrait)，所以在按下切換全螢幕時
            //有可能我改的UIDevice的orientation值，改前跟改後都是一樣的 例如我landscapeRight進來
            //然後我又UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            //這樣系統並不知道要轉方向
            //所以我必須先修改目前的值，接著在改回來，讓系統知道需要變更方向(我猜值有改動的狀況下才會通知系統轉方向)
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
                UIApplication.shared.statusBarOrientation = .landscapeRight
            default:
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                UIApplication.shared.setStatusBarHidden(false, with: .fade)
                UIApplication.shared.statusBarOrientation = .landscapeRight
            }
        }
    }
    
    private func updateFrame() {
        if isFullScreen && MSPlayerConfig.fullScreenIgnoreConstraint {
            self.translatesAutoresizingMaskIntoConstraints = true
            self.frame = UIScreen.main.bounds
            self.layoutIfNeeded()
        } else if self.translatesAutoresizingMaskIntoConstraints {
            self.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    // MARK: - 生命週期
    deinit {
        recordCurrentTime()
        print("MSPlayer dealloc")
        playerLayerView?.pause()
        playerLayerView?.prepareToDeinit()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let customControlView = MSPlayer.storyBoardCustomControl() {
            self.customControlView = customControlView
        }
        initUI()
        initUIData()
        configureVolume()
        preparePlayer()
    }

    public convenience init() {
        self.init(customControlView: nil)
    }
    
    public init(customControlView: MSPlayerControlView?) {
        super.init(frame: CGRect.zero)
        self.customControlView = customControlView
        initUI()
        initUIData()
        configureVolume()
        preparePlayer()
    }
    
    // MARK: - init UI
    fileprivate func initUI() {
        self.backgroundColor = UIColor.black
        
        if let customView = customControlView {
            controlView = customView
        } else {
            controlView = MSPlayerControlView()
        }
        self.userConstraint = self.constraints
        addSubview(controlView)
        controlView.updateUI(for: isFullScreen)
        controlView.delegate = self
        controlView.player = self
        
        controlView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        controlView.addConstraintWithOther(self, anchorTypes: [.edge2Edge])
        setGesture()
    }
    
    fileprivate func setGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panDirection(_:)))
        self.addGestureRecognizer(panGesture!)
    }
    
    fileprivate func removeGesture() {
        if panGesture != nil {
            self.removeGestureRecognizer(panGesture!)
        }
    }
    
    fileprivate func initUIData() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onOrientationChanged),
                                               name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation,
                                               object: nil)
    }
    
    fileprivate func configureVolume() {
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                self.volumeViewSlider = slider
            }
        }
    }
    
    fileprivate func preparePlayer() {
        playerLayerView = MSPlayerLayerView()
        playerLayerView?.videoGravity = videoGravity
        insertSubview(playerLayerView!, at: 0)
        
        playerLayerView?.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        playerLayerView?.addConstraintWithOther(self, anchorTypes: [.edge2Edge])
        playerLayerView?.delegate = self
        controlView.showLoader()
        self.layoutIfNeeded()
    }
}

extension MSPlayer: MSPlayerLayerViewDelegate {
    
    public func msPlayer(player: MSPlayerLayerView, playerIsPlaying playing: Bool) {
        controlView.playStateDidChange(isPlaying: playing)
        delegate?.msPlayer(self, isPlaying: playing)
        playStateDidChange?(player.isPlaying)
    }
    
    public func msPlayer(player: MSPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        MSPlayerConfig.log("loadTimeDidChange - \(loadedDuration) - \(totalDuration)")
        controlView.loadedTimeDidChange(loadedDuration: loadedDuration, totalDuration: totalDuration)
        delegate?.msPlayer(self, loadTimeDidChange: loadedDuration, totalDuration: totalDuration)
        controlView.totalDuration = totalDuration
        self.totalDuration = totalDuration
    }
    
    public func msPlayer(player: MSPlayerLayerView, playerStateDidChange state: MSPM.State) {
        MSPlayerConfig.log("playerStateDidChange - \(state)")
        
        controlView.playerStateDidChange(state: state)
        switch state {
        case .readyToPlay:
            if !isPauseByUser {
                play()
            }
            if shouldSeekTo != 0 {
                seek(shouldSeekTo, completion: {
                    if !self.isPauseByUser {
                        self.play()
                    } else {
                        self.pause()
                    }
                })
            }
        case .bufferFinished:
            autoPlay()
        case .playedToTheEnd:
            isPlayToTheEnd = true
        case .error:
            // Handle wrong URL
            print("MSPlayer Error url")
        default:
            break
        }
        delegate?.msPlayer(self, stateDidChange: state)
    }
    
    public func msPlayer(player: MSPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        MSPlayerConfig.log("playTimeDidChange - \(currentTime) - \(totalTime)")
        delegate?.msPlayer(self, playTimeDidChange: currentTime, total: totalTime)
        self.currentPosition = currentTime
        totalDuration = totalTime
        if isSliderSliding || self.isSeeking {
            return
        }
        
        controlView.playTimeDidChange(currentTime: currentTime, totalTime: totalTime)
        controlView.totalDuration = totalDuration
        playTimeDidChange?(currentTime, totalTime)
    }
}

extension MSPlayer: MSPlayerControlViewDelegate {
    
    public func controlView(_ controlView: MSPlayerControlView, didChooseDefinition index: Int) {
        shouldSeekTo = currentPosition
        playerLayerView?.resetPlayer()
        currentDefinition = index
        playerLayerView?.playAsset(asset: resource.definitions[index].avURLAsset)
    }
    
    public func controlView(_ controlView: MSPlayerControlView, didPress button: UIButton) {
        if let action = MSPM.ButtonType(rawValue: button.tag) {
            switch action {
            case .back:
                backBlock?(isFullScreen)
                if isFullScreen {
                    // 如果是全螢幕則跳出全螢幕
                    fullScreenButtonPressed()
                } else if MSPM.shared().isUsingFloatingControl {
                    MSFloatingController.shared().shrink()
                } else {
                    // 如果不是全螢幕則popFromNav
                    playerLayerView?.prepareToDeinit()
                }
                
            case .play:
                if button.isSelected {
                    pause()
                } else {
                    if isPlayToTheEnd {
                        seek(0, completion: {
                            self.play()
                        })
                        controlView.hidePlayToTheEndView()
                        isPlayToTheEnd = false
                    }
                    play()
                }
            case .replay:
                isPlayToTheEnd = false
                seek(0, completion: {
                    self.play()
                })
            case .fullScreen:
                fullScreenButtonPressed()
                
            default:
                print("error unhandled action")
            }
        }
    }
    
    public func controlView(_ controlView: MSPlayerControlView, slider: UISlider, onSlider event: UIControlEvents) {
        if playerLayerView!.state == .notSetUrl { return }
        switch event {
        case .touchDown:
            playerLayerView?.onTimeSliderBegan()
            isSliderSliding = true
            self.nowSeekingCount += 1
        case .touchUpInside:
            isSliderSliding = false
            let target = self.totalDuration * Double(slider.value) - Double(slider.value == 1.0 ? 1.0: 0.0)
            if isPlayToTheEnd {
                isPlayToTheEnd = false
                seek(target, completion: {
                    self.nowSeekingCount -= 1
                    self.play()
                })
                controlView.hidePlayToTheEndView()
            } else {
                seek(target, completion: {
                    self.nowSeekingCount -= 1
                    self.autoPlay()
                })
            }
        default:
            break
        }
    }
    
    // not set
//    public func controlView(_ controlView: MSPlayerControlView, didChange aspectRatio: MSPM.AspectRatio) {
//        self.playerLayerView?.aspectRatio = self.aspectRatio
//    }
    
    public func controlView(_ controlView: MSPlayerControlView, didChange playBackRate: Float) {
        self.playerLayerView?.player?.rate = playBackRate
    }
}
























