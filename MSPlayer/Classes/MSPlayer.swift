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
    func msPlayer(_ player: MSPlayer, definitionIndexDidChange index: Int, definition: MSPlayerResourceDefinition?)
    func msPlayer(_ player: MSPlayer, updateProgress sliderValue: Float, total: TimeInterval)

}

public extension MSPlayerDelegate {
    //For optional
    func msPlayer(_ player: MSPlayer, definitionIndexDidChange index: Int, definition: MSPlayerResourceDefinition?) { }
}

open class MSPlayer: MSGestureView {
    
    // Event sending by delegate and closure
    open weak var delegate: MSPlayerDelegate?
    /// fired when tap backButton, fullScrren to unFullScreen, unFullScreen to pop
    open var backBlock: ((Bool) -> Void)?
    
    open var videoId: String? {
        return getCurrentResourceDefinition()?.videoId
    }
    /// Resource contains mutiple resource definitions
    open var currentDefinitionIndex = 0 {
        didSet {
            if oldValue != currentDefinitionIndex {
                self.delegate?.msPlayer(self, definitionIndexDidChange: currentDefinitionIndex, definition: currentResource?.definitions[exist: currentDefinitionIndex])
            }
        }
    }
    open var currentResource: MSPlayerResource?
    fileprivate var resource: MSPlayerResource! {
        didSet {
            self.currentResource = resource
        }
    }
    
    //UI
    open var avPlayer: AVPlayer? {
        return playerLayerView?.player
    }
    open var playerLayerView: MSPlayerLayerView?
    open var controlView: MSPlayerControlView!
    fileprivate var customControlView: MSPlayerControlView?
    var userConstraint = [NSLayoutConstraint]()
    
    //MARK: - 可以設定此參數決定畫面比例
    open var aspectRatio: MSPM.AspectRatio? {
        didSet {
            self.playerLayerView?.aspectRatio = self.aspectRatio ?? .default
        }
    }
    
    /// AVLayerVideoGravityType
    open var videoGravity = convertFromAVLayerVideoGravity(AVLayerVideoGravity.resizeAspect) {
        didSet {
            self.playerLayerView?.videoGravity = AVLayerVideoGravity(rawValue: videoGravity).rawValue
        }
    }
    
    open var isPlaying: Bool {
        get {
            return playerLayerView?.isPlaying ?? false
        }
    }
    
    // status
    public private(set) var isFullScreen: Bool = false
    open var isSeeking = false {
        didSet {
            if isSeeking != oldValue {
                self.playerLayerView?.isNowSeeking = self.isSeeking
            }
        }
    }
    /// if nowSeekingCount > 0, means there is other seeking, so isSeeking will be true
    open var nowSeekingCount = 0 {
        didSet {
            // 當有別的seekingAction時，不要把isSeeking關掉，關掉的話，每0.5秒會更新進度條，所以會把進度條跳回去
            self.isSeeking = nowSeekingCount == 0 ? false: true
        }
    }
    
    /// 進度滑桿值 - ControlView變更時一併變更MSPlayer的值
    open var progressSliderValue: Float = 0.0 {
        didSet {
            self.delegate?.msPlayer(self, updateProgress: progressSliderValue, total: totalDuration)
        }
    }
    
    // time status
    /// 滑動起始時影片時間
    fileprivate var horizontalBeginTime: TimeInterval = 0
    /// 滑動累積值 (平滑時，總共增加多少時間、總共減少多少時間) (base on current time)
    fileprivate var sumTime: TimeInterval = 0
    public private(set) var totalDuration: TimeInterval = 0
    public private(set) var currentPosition: TimeInterval = 0
    fileprivate var shouldSeekTo: TimeInterval = 0
    fileprivate var isUserSliding = false
    fileprivate var isUserMoveSlider = false
    fileprivate var isPauseByUser = false
    open private(set) var isPlayToTheEnd = false
    
    /**
     If you want to create MSPlayer with custom control in storyBoard.
     create a subclass and override this method
     
     - return: costom control which you want to use
     */
    open class func storyBoardCustomControl() -> MSPlayerControlView? {
        return nil
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let customControlView = MSPlayer.storyBoardCustomControl() {
            self.customControlView = customControlView
        }
        initUI()
        addObserver()
        preparePlayer()
    }
    
    public convenience init() {
        self.init(customControlView: nil)
    }
    
    @objc public init(customControlView: MSPlayerControlView?) {
        super.init(frame: CGRect.zero)
        self.customControlView = customControlView
        initUI()
        addObserver()
        preparePlayer()
    }
    
    // MARK: - init UI
    private func initUI() {
        self.backgroundColor = UIColor.black
        setControlView()
    }
    
    private func setControlView() {
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
    }
    
    private func preparePlayer() {
        playerLayerView = MSPlayerLayerView()
        playerLayerView?.videoGravity = AVLayerVideoGravity(rawValue: videoGravity).rawValue
        if let playerLayerView = playerLayerView {
            insertSubview(playerLayerView, at: 0)
        }
        playerLayerView?.delegate = self
        controlView.showLoader()
    }
    
    private func resetSetting() {
        isPauseByUser = false
        isPlayToTheEnd = false
        
        controlView.timeSlider.value = 0.0
        
        playerLayerView?.resetPlayer()
    }
    
    // MARK: - Public functions
    
    /**
     Play
     
     - parameter resource: media resource
     - parameter startIndex: starting definition index, default start with the first definition
     */
    open func setVideoBy(_ resource: MSPlayerResource, startIndex: Int = 0) {
        // Store Resource
        self.resource = resource
        changeResourceDefinitionBy(index: startIndex)
    }
    
    /**
     change resourceDefinitionIndex
     
     parameter: - when isPlayNext is true, auto play video
    */
    open func changeResourceDefinitionBy(index: Int, isPlayNext: Bool = false) {
        resetSetting()
        currentDefinitionIndex = index
        controlView.prepareUI(for: resource,
                              selected: index)
        guard let currentDefinition = getCurrentResourceDefinition() else {
            // zeroin definitionIndex and restart
            if index != 0 {
                changeResourceDefinitionBy(index: 0)
            } else {
                self.delegate?.msPlayer(self, stateDidChange: .notSetUrl)
            }
            return
        }
        
        // if user is set 'notAutoPlay', then set the cover
        if MSPlayerConfig.shouldAutoPlay {
            controlView.hideCover()
        } else {
            // show cover need to close the loader. if not, loader is on the cover, that's bad
            controlView.hideLoader()
            controlView.showCover(urlRequest: currentDefinition.coverURLRequest,
                                  coverImage: currentDefinition.coverImage)
        }
        
        // 設定 playerAsset
        playerLayerView?.setAVURLAsset(asset: currentDefinition.avURLAsset)
        //如果是播下一集，則重頭開始
        if isPlayNext {
            autoPlay()
            return
        }
        
        // 若使用者有給影片 id，則去coreData看，是否有上次的觀看時間點
        if let videoId = currentDefinition.videoId {
            let coreDataManager = MSCoreDataManager.shared
            coreDataManager.loadVideoTimeRecordWith(videoId) { [weak self] (lastWatchTime) in
                guard let self = self else { return }
                if let lastWatchTime = lastWatchTime {
                    self.shouldSeekTo = floor(lastWatchTime)
                    self.seek(lastWatchTime) {
                        self.autoPlay()
                    }
                } else {
                    self.autoPlay()
                }
            }
        } else {
            self.autoPlay()
        }
    }
    
    /**
     auto start playing, call at viewWillAppear, see more at pause
     */
    open func autoPlay() {
        if !isPauseByUser && !isPlayToTheEnd && MSPlayerConfig.shouldAutoPlay {
            play()
        } else if isPauseByUser && MSPlayerConfig.shouldAutoPlay {
            pause()
        } else {
            // show cover and do nothing to player
            return
        }
    }
    /**
     play
     */
    open func play() {
        if resource == nil { return }
        isPauseByUser = false
        playerLayerView?.play()
        controlView.hidePlayCover()
        controlView.hideCover()
        controlView.changePlayButtonState(isSelected: true)
    }
    /**
     Pause
     
     - parameter allow: should allow to response 'autoPlay' function
     */
    open func pause() {
        if !isPlayToTheEnd {
            recordCurrentTime()
            isPauseByUser = true
            playerLayerView?.pause()
            // show play cover
            if controlView.centerPlayBtnImageView.isHidden {
                controlView.showPlayCover()
                controlView.hideLoader()
            }
            controlView.changePlayButtonState(isSelected: false)
        }
    }
    /**
     seek
     
     - parameter to: target time
     */
    open func seek(_ targetTime: TimeInterval, completion: (() -> ())? = nil) {
        playerLayerView?.seek(to: targetTime, completion: completion)
    }
    
    open func seekByAddValue(_ value: Int) {
        guard let playerItem = playerLayerView?.playerItem else { return }
        
        self.sumTime = currentPosition + TimeInterval(value)
        let totalTime = playerItem.duration
        // 防止出現NAN
        if totalTime.timescale == 0 { return }
        let totalDuration = TimeInterval(totalTime.value) / TimeInterval(totalTime.timescale)
        // modify sumTime value
        if (sumTime >= totalDuration) {
            sumTime = floor(totalDuration - 1.0)
        } else if sumTime <= 0{
            sumTime = 0
        }
        isUserSliding = false
        isUserMoveSlider = false
        isPlayToTheEnd = false
        nowSeekingCount += 1
        seek(self.sumTime, completion: { [weak self] in
            guard let self = self else { return }
            self.play()
            self.nowSeekingCount -= 1
        })
    }
    /**
     get current resource Definition
    */
    open func getCurrentResourceDefinition() -> MSPlayerResourceDefinition? {
        return resource.definitions[exist: currentDefinitionIndex]
    }
    
    /**
     update UI to fullScreen
     */
    open func updateUI(_ isFullScreen: Bool) {
        controlView.updateUI(for: isFullScreen)
    }
    /**
     increase volume with step, default step 0.1
     
     - parameter step: step
     */
    open func addVolume(step: Float = 0.1) {
        let systemManager = SystemSettingManager.shared
        systemManager.getVolumeController().changeVolumeBy(step)
    }
    /**
     decrease volume with step, default step 0.1
     
     - parameter step: step
     */
    open func reduceVolume(step: Float = 0.1) {
        let systemManager = SystemSettingManager.shared
        systemManager.getVolumeController().changeVolumeBy(-step)
    }
    // Close ControlView
    open func closeControlViewAndRemoveGesture() {
        controlView.isHidden = true
        disableGesture()
    }
    
    open func openControlViewAndSetGesture() {
        controlView.isHidden = false
        resumeGesture()
    }
    
    // Change ControlView backButton image
    open func changeControlViewBackButtonImage(toDown: Bool) {
        if toDown {
            controlView.changeBackImageToDownImage()
        } else {
            controlView.changeDownImageToBackImage()
        }
    }
    
    open override func horizontalPanEvent(_ state: PanDirection.PanState) {
        // 播放結束時，手勢忽略
        guard playerLayerView?.state != .playedToTheEnd else { return }
        
        super.horizontalPanEvent(state)
        switch state {
        case .began(let location):
            nowSeekingCount += 1
            
            if let _ = playerLayerView?.player {
                let nowTime = totalDuration * Double(progressSliderValue)
                // 分母不用 timeScale是因為timeScale有時候會跳到1000000000有時候又會跳到1
                horizontalBeginTime = TimeInterval(nowTime) / TimeInterval(1)
                sumTime = horizontalBeginTime
            }
            
            // is pan location.y at bottomMaskView then move slider
            if location.y > controlView.bottomMaskView.frame.minY {
                isUserMoveSlider = true
            }
        case .changed(let value):
            horizontalMoved(value)
        case .ended:
            if MSPlayerConfig.enablePlaytimeGestures {
                controlView.hideSeekToView()
                isUserSliding = false
                isUserMoveSlider = false
                isPlayToTheEnd = false
                if isPlayToTheEnd {
                    isPlayToTheEnd = false
                    seek(sumTime, completion: { [weak self] in
                        guard let self = self else { return }
                        self.play()
                        self.nowSeekingCount -= 1 //當有別的seekingAction時，不要把isSeeking關掉，關掉的話，每0.5秒會更新進度條，所以會把進度條跳回去
                    })
                } else {
                    seek(sumTime, completion: { [weak self] in
                        guard let self = self else { return }
                        self.autoPlay()
                        self.nowSeekingCount -= 1
                    })
                }
            }
        }
    }
    
    open override func verticalPanEvent(_ state: PanDirection.PanState, location: PanDirection.PanLocation) {
        super.verticalPanEvent(state, location: location)
        
        // 播放結束時，手勢忽略
        guard playerLayerView?.state != .playedToTheEnd else { return }
        
        switch state {
        case .began, .ended: break
        case .changed(let value):
            var adjustValue: CGFloat = 0.0
            if value < 0 {
                adjustValue = -0.015
            } else if value > 0 {
                adjustValue = 0.015
            } else {
                return
            }
            
            let systemManager = SystemSettingManager.shared
            switch location {
            case .right:
                if MSPlayerConfig.enableVolumeGestures {
                    let changeValue = -(Float(adjustValue) * MSPlayerConfig.playerVolumeChangeRate)
                    systemManager.getVolumeController().changeVolumeBy(changeValue)
                }
            case .left:
                if MSPlayerConfig.enableBrightnessGestures {
                    let changeBrightnessValue = -(adjustValue * MSPlayerConfig.playerBrightnessChangeRate)
                    systemManager.getBrightnessController().changeBrightnessByValue(changeBrightnessValue)
                }
            case .mid: break
            }
        }
    }
    
    private func horizontalMoved(_ value: CGFloat) {
        if (!MSPlayerConfig.enablePlaytimeGestures) { return }
        
        isUserSliding = true
        if let playerItem = playerLayerView?.playerItem {
            // 每次滑動需要疊加時間，通過一定的比例，使滑動一直處於統一水平
            if isUserMoveSlider {
                // 如果是移動滑桿，則按照他滑動的距離去決定他滑動的進度條多少
                sumTime = sumTime + TimeInterval(value) / 100.0 * (TimeInterval(totalDuration)/400)
            } else {
                // 如果是滑動螢幕，則進度條慢慢前進，總時間越短，totalDurationAdjustParameter也會越小，避免移動過快
                let totalDurationAdjustParameter = (TimeInterval(totalDuration) / 400) < 0.5 ? 0.5: (TimeInterval(totalDuration) / 400)
                sumTime = sumTime + TimeInterval(value) / 100 * 0.4 * MSPlayerConfig.playerPanSeekRate * totalDurationAdjustParameter
            }
            let totalTime = playerItem.duration
            
            // 防止出現NAN
            if totalTime.timescale == 0 { return }
            
            let totalDuration = TimeInterval(totalTime.value) / TimeInterval(totalTime.timescale)
            if (sumTime >= totalDuration) {
                sumTime = floor(totalDuration - 1.0)
            } else if sumTime <= 0{
                sumTime = 0
            }
            
            controlView.showSeekToView(to: sumTime,
                                       total: totalDuration,
                                       isAdd: sumTime > horizontalBeginTime)
        }
    }
    
    private func recordCurrentTime() {
        if let videoId = videoId, MSPM.shared().openRecorder {
            let currentTime = floor(totalDuration * Double(progressSliderValue))
            let coreDataManager = MSCoreDataManager.shared
            coreDataManager.saveVideoTimeRecordWith(videoId, videoTime: currentTime)
        }
    }
    
    open func fullScreenButtonPressed() {
        controlView.updateUI(for: !isFullScreen)
        if isFullScreen {
            isFullScreen = false
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue,
                                      forKey: "orientation")
            delegate?.msPlayer(self, orientChanged: isFullScreen)
            
        } else {
            //先清除現在orientation的值
            //有可能Device是landscape進來(此時statusbar的orientation是portrait)，所以在按下切換全螢幕時
            //有可能我改的UIDevice的orientation值，改前跟改後都是一樣的 例如我landscapeRight進來
            //然後我又UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            //這樣系統並不知道要轉方向
            //所以我必須先修改目前的值，接著在改回來，讓系統知道需要變更方向(我猜值有改動的狀況下才會通知系統轉方向)
            if let videoSize = self.playerLayerView?.videoSize , videoSize.height >  videoSize.width {
                isFullScreen = true
                updateUI(isFullScreen)
                delegate?.msPlayer(self, orientChanged: isFullScreen)
            } else {
                isFullScreen = true
                switch UIDevice.current.orientation {
                case .landscapeLeft:
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                default:
                    UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                }
                
            }
         
        }
    }
    
    @objc fileprivate func onOrientationChanged() {
        self.isFullScreen = UIApplication.shared.statusBarOrientation.isLandscape
        self.updateUI(isFullScreen)
        self.delegate?.msPlayer(self, orientChanged: isFullScreen)
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onOrientationChanged),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayerView?.frame = self.bounds
        self.controlView.frame = self.bounds
    }
    
    /**
     prepare to dealloc player, call at View or Controllers deinit funciton.
     */
    open func prepareToDealloc() {
        if isPlayToTheEnd {
            controlView.hidePlayToTheEndView()
        }
        playerLayerView?.prepareToDeinit()
        controlView.prepareToDealloc()
    }
    
    // MARK: - 生命週期
    deinit {
        recordCurrentTime()
        playerLayerView?.pause()
        playerLayerView?.prepareToDeinit()
        NotificationCenter.default.removeObserver(self)
        print(classForCoder, "dealloc")
    }
}

extension MSPlayer: MSPlayerLayerViewDelegate {
    
    public func msPlayer(player: MSPlayerLayerView, playerIsPlaying playing: Bool) {
        controlView.playStateDidChange(isPlaying: playing)
        delegate?.msPlayer(self, isPlaying: playing)
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
        print(state)
        switch state {
        case .readyToPlay:
            autoPlay()
        case .bufferFinished:
            autoPlay()
        case .playedToTheEnd:
            isPlayToTheEnd = true
        case .error(let error):
            // Handle wrong URL
            controlView.hideCover()
            controlView.hideLoader()
            player.prepareToDeinit()
            print("MSPlayer Error:", error)
        default: break
        }
        delegate?.msPlayer(self, stateDidChange: state)
    }
    
    public func msPlayer(player: MSPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        MSPlayerConfig.log("playTimeDidChange - \(currentTime) - \(totalTime)")
        delegate?.msPlayer(self, playTimeDidChange: currentTime, total: totalTime)
        
        currentPosition = currentTime
        totalDuration = totalTime
        
        // 因為在seeking的當下，影片還會再跑，影片跑的時候我們不希望更新影片的時間，而是根據他滑到哪裡就顯示到哪
        if isUserSliding || isSeeking {
            
        } else {
            if !isPlayToTheEnd {
                controlView.hidePlayToTheEndView()
            }
            
            controlView.playTimeDidChange(currentTime: currentTime, totalTime: totalTime)
            controlView.totalDuration = totalDuration
        }
    }
}

extension MSPlayer: MSPlayerControlViewDelegate {
    
    public func controlView(_ controlView: MSPlayerControlView, didChooseDefinition index: Int) {
        changeResourceDefinitionBy(index: index, isPlayNext: true)
    }
    
    public func controlView(_ controlView: MSPlayerControlView, didPress button: UIButton) {
        
        if let action = MSPM.ButtonType(rawValue: button.tag) {
            switch action {
            case .back:
                backBlock?(isFullScreen)
                if isFullScreen {
                    // 如果是全螢幕則跳出全螢幕
                    fullScreenButtonPressed()
                } else {
                    // 如果不是全螢幕則popFromNav
                    playerLayerView?.prepareToDeinit()
                }
            case .playAndPause:
                if button.isSelected {
                    pause()
                } else {
                    if isPlayToTheEnd {
                        seek(0, completion: { [weak self] in
                            self?.play()
                        })
                        controlView.hidePlayToTheEndView()
                        isPlayToTheEnd = false
                    } else if let state = playerLayerView?.state {
                        switch state {
                        case .error:
                            // play next definition
                            changeResourceDefinitionBy(index: currentDefinitionIndex + 1)
                        default: break
                        }
                    }
                    play()
                }
            case .replay:
                isPlayToTheEnd = false
                seek(0, completion: { [weak self] in
                    self?.play()
                })
            case .fullScreen:
                fullScreenButtonPressed()
            }
        }
    }
    
    public func controlView(_ controlView: MSPlayerControlView, slider: UISlider, onSlider event: UIControl.Event) {
        if playerLayerView!.state == .notSetUrl { return }
        switch event {
        case .touchDown:
            playerLayerView?.onTimeSliderBegan()
            isUserSliding = true
            nowSeekingCount += 1
        case .touchUpInside:
            isUserSliding = false
            let target = totalDuration * Double(slider.value) - Double(slider.value == 1.0 ? 1.0: 0.0)
            if isPlayToTheEnd {
                isPlayToTheEnd = false
                seek(target, completion: { [weak self] in
                    self?.nowSeekingCount -= 1
                    self?.play()
                })
                controlView.hidePlayToTheEndView()
            } else {
                seek(target, completion: { [weak self] in
                    self?.nowSeekingCount -= 1
                    self?.autoPlay()
                })
            }
        default:
            break
        }
    }
    
    public func controlView(_ controlView: MSPlayerControlView, didChange playBackRate: Float) {
        playerLayerView?.player?.rate = playBackRate
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVLayerVideoGravity(_ input: AVLayerVideoGravity) -> String {
    return input.rawValue
}
