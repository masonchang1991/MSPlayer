//
//  MSPlayerLayerView.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/18.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public protocol MSPlayerLayerViewDelegate: class {
    func msPlayer(player: MSPlayerLayerView ,playerStateDidChange state: MSPM.State)
    func msPlayer(player: MSPlayerLayerView ,loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func msPlayer(player: MSPlayerLayerView ,playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
    func msPlayer(player: MSPlayerLayerView ,playerIsPlaying playing: Bool)
}

open class MSPlayerLayerView: UIView {
    
    open weak var  delegate: MSPlayerLayerViewDelegate?
    /// video seekTime default set 0
    open var seekTime = 0
    /// is user is seeking
    open var isNowSeeking = false
    /// playerItem 播放屬性
    open var playerItem: AVPlayerItem? {
        didSet {
            onPlayerItemChange()
        }
    }
    /// 播放屬性
    open lazy var player: AVPlayer? = {
        if let item = self.playerItem {
            let player = AVPlayer(playerItem: item)
            return player
        }
        return nil
    }()
    /// VideoGravity
    open var videoGravity = AVLayerVideoGravityResizeAspectFill {
        didSet {
            self.playerLayer?.videoGravity = videoGravity
            print("")
        }
    }
    
    open var isPlaying: Bool = false {
        didSet {
            if oldValue != isPlaying {
                delegate?.msPlayer(player: self, playerIsPlaying: isPlaying)
            }
        }
    }
    
    var aspectRatio: MSPM.AspectRatio = .default {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    // 計時器
    var timer: Timer?
    fileprivate var urlAsset: AVURLAsset?
    fileprivate var lastPlayerItem: AVPlayerItem?
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var volumViewSlider: UISlider!
    /// 播放器狀態
    internal fileprivate(set) var state = MSPM.State.notSetUrl {
        didSet {
            if state != oldValue {
                delegate?.msPlayer(player: self,
                                   playerStateDidChange: state)
            }
        }
    }
    /// 是否為全螢幕
    fileprivate var isFullScreen = false
    /// 是否鎖定屏幕方向
    fileprivate var isLocked = false
    /// 是否在調整音量
    fileprivate var isVolume = false
    /// 是否在播放本地文件
    fileprivate var isLocalVideo = false
    fileprivate var sliderLastValue: Float = 0.0
    /// 是否要重播
    fileprivate var repeatToPlay = false
    fileprivate var playDidEnd = false
    // playbackBufferEmpty會反覆進入，因此在BufferingOneSecond延時播放執行完之前再調用bufferingSomeSecond都忽略
    // 僅在bufferingSomeSecond裡面使用
    fileprivate var isBuffering = false
    fileprivate var hasReadyToPlay = false
    fileprivate var shouldSeekTo: TimeInterval = 0
    
    // MARK: - Actions
    open func playURL(url: URL) {
        let asset = AVURLAsset(url: url)
        playAsset(asset: asset)
    }
    
    open func playAsset(asset: AVURLAsset) {
        urlAsset = asset
        onSetVideoAsset()
        play()
    }
    // MARK: - 設置 Video URL
    fileprivate func onSetVideoAsset() {
        repeatToPlay = false
        playDidEnd = false
        configPlayer()
    }
    
    fileprivate func configPlayer() {
        player?.removeObserver(self, forKeyPath: "rate")
        playerItem = AVPlayerItem(asset: urlAsset!)
        player = AVPlayer(playerItem: playerItem!)
        player!.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
        
        playerLayer?.removeFromSuperlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.videoGravity = videoGravity
        layer.addSublayer(playerLayer!)
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    open func play() {
        if let player = player {
            // play with sound in slience mode
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch {
                // TODO: Error handle
                print("error")
            }
            player.play()
            setupTimer()
            isPlaying = true
        }
    }
    
    open func pause() {
        player?.pause()
        isPlaying = false
        timer?.fireDate = Date.distantFuture
    }
    
    // MARK: - KVO
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let item = object as? AVPlayerItem, let keyPath = keyPath {
            if item == self.playerItem {
                switch keyPath {
                case "status":
                    if player?.status == AVPlayerStatus.readyToPlay {
                        self.state = .buffering
                        if shouldSeekTo != 0 {
                            print("MSPlayerLayer | Should seek to \(shouldSeekTo)")
                            seek(to: shouldSeekTo, completion: {
                                self.shouldSeekTo = 0
                                self.hasReadyToPlay = true
                                self.state = .readyToPlay
                            })
                        } else {
                            self.hasReadyToPlay = true
                            self.state = .readyToPlay
                        }
                    } else if player?.status == AVPlayerStatus.failed {
                        self.state = .error
                    }
                    
                case "loadedTimeRanges":
                    // 計算緩沖進度
                    if let timeInterVarl    = self.availableDuration() {
                        let duration        = item.duration
                        let totalDuration   = CMTimeGetSeconds(duration)
                        delegate?.msPlayer(player: self,
                                           loadedTimeDidChange: timeInterVarl,
                                           totalDuration: totalDuration)
                    }
                    
                case "playbackBufferEmpty":
                    // 緩沖為空的時候
                    if self.playerItem!.isPlaybackBufferEmpty {
                        self.state = .buffering
                        self.bufferingSomeSecond()
                    }
                case "playbackLikelyToKeepUp":
                    if item.isPlaybackBufferEmpty {
                        if state != .bufferFinished && hasReadyToPlay {
                            self.state = .bufferFinished
                            self.playDidEnd = true
                        }
                    }
                default:
                    break
                }
            }
        }
        
        if keyPath == "rate" {
            updateStatus()
        }
    }
    
    /**
     緩沖進度
     - returns: 緩沖進度
     */
    fileprivate func availableDuration() -> TimeInterval? {
        if let loadedTimeRanges = player?.currentItem?.loadedTimeRanges,
            let first = loadedTimeRanges.first {
            let timeRange = first.timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSecound = CMTimeGetSeconds(timeRange.duration)
            let result = startSeconds + durationSecound
            return result
        }
        return nil
    }
    /**
     缓冲比较差的时候
     */
    fileprivate func bufferingSomeSecond() {
        self.state = .buffering
        // playbackBufferEmpty會反覆進入，因此在bufferingOneSecond延時播放執行完之前再調用bufferingSomeSecond都忽略
        
        if isBuffering {
            return
        }
        isBuffering = true
        // 需要先暫停一下下後再播放，否則網路狀況不好的時候時間在走，聲音會出不來
        player?.pause()
        let popTime = DispatchTime.now() + Double(Int64( Double(NSEC_PER_SEC) * 1.0 )) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) {
            // 如果執行了play還是沒有播放，代表還沒有緩存好，則再次緩存一段時間
            self.isBuffering = false
            if let item = self.playerItem {
                if !item.isPlaybackLikelyToKeepUp {
                    self.bufferingSomeSecond()
                } else {
                    // 如果此時用戶暫停了，則不在需要開啟播放
                    self.state = MSPM.State.bufferFinished
                }
            }
        }
    }
    
    // MARK: - layoutSubviews
    override open func layoutSubviews() {
        super.layoutSubviews()
        switch self.aspectRatio {
        case .default:
            DispatchQueue.main.async {
                self.playerLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.playerLayer?.frame  = self.bounds
            }
        case .sixteen2NINE:
            self.playerLayer?.videoGravity = "AVLayerVideoGravityResize"
            self.playerLayer?.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.width/(16/9))
        case .four2THREE:
            self.playerLayer?.videoGravity = "AVLayerVideoGravityResize"
            let width = self.bounds.height * 4 / 3
            self.playerLayer?.frame = CGRect(x: (self.bounds.width - width)/2,
                                             y: 0,
                                             width: width,
                                             height: self.bounds.height)
        }
    }
    
    open func resetPlayer() {
        // 初始化状态变量
        self.playDidEnd = false
        self.playerItem = nil
        self.seekTime   = 0
        self.timer?.invalidate()
        
        self.pause()
        // 移除原来的layer
        self.playerLayer?.removeFromSuperlayer()
        // 替換PlayerItem = nil
        self.player?.replaceCurrentItem(with: nil)
        player?.removeObserver(self, forKeyPath: "rate")
        // 把player清除
        self.player = nil
    }
    
    open func onTimeSliderBegan() {
        if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
            self.timer?.fireDate = Date.distantFuture
        }
    }
    
    open func seek(to seconds: TimeInterval, completion: (() -> ())?) {
        if seconds.isNaN {
            completion?()
            return
        }
        setupTimer()
        if self.player?.currentItem?.status == AVPlayerItemStatus.readyToPlay {
            let draggedTime = CMTimeMake(Int64(seconds), 1)
            self.player!.seek(to: draggedTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) in
                completion?()
            })
        } else {
            self.shouldSeekTo = seconds
            completion?()
        }
    }
    
    // MARK: - 設定計時器
    func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(playerTimerAction), userInfo: nil, repeats: true)
        timer?.fireDate = Date()
    }
    
    // MARK: - 計時器事件
    @objc fileprivate func playerTimerAction() {
        if let playerItem = playerItem {
            if playerItem.duration.timescale != 0 {
                let currentTime = CMTimeGetSeconds(self.player!.currentTime())
                let totalTime   = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
                delegate?.msPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
            }
            updateStatus(inclodeLoading: true)
        }
    }
    
    fileprivate func updateStatus(inclodeLoading: Bool = false) {
        if let player = player {
            if let playerItem = playerItem {
                if inclodeLoading {
                    if playerItem.isPlaybackLikelyToKeepUp || playerItem.isPlaybackBufferFull {
                        self.state = .bufferFinished
                    } else if playerItem.error != nil {
                        self.state = .error
                    } else {
                        self.state = .buffering
                    }
                }
            }
            if player.rate == 0.0 {
                if player.error != nil {
                    self.state = .error
                    return
                }
                if let currentItem = player.currentItem {
                    if player.currentTime() >= currentItem.duration {
//                        moviePlayDidEnd()
                        return
                    }
                    if currentItem.isPlaybackLikelyToKeepUp || currentItem.isPlaybackBufferFull {
                        
                    }
                }
            }
        }
    }
    
    fileprivate func onPlayerItemChange() {
        if lastPlayerItem == playerItem {
            return
        }
        
        if let item = lastPlayerItem {
            removePlayerObserverWith(item)
        }
        
        lastPlayerItem = playerItem
        
        if let item = playerItem {
            addPlayerObserverWith(item)
        }
    }
    
    // MARK: - Notification Event
    @objc fileprivate func moviePlayDidEnd() {
        if state != .playedToTheEnd {
            if let playerItem = playerItem {
                delegate?.msPlayer(player: self,
                                   playTimeDidChange: CMTimeGetSeconds(playerItem.duration),
                                   totalTime: CMTimeGetSeconds(playerItem.duration))
            }
            self.state = .playedToTheEnd
            self.isPlaying = false
            self.playDidEnd = true
            self.timer?.invalidate()
        }
    }
    
    func addPlayerObserverWith(_ item: AVPlayerItem) {
        NotificationCenter.default.addObserver(self, selector: #selector(moviePlayDidEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: playerItem)
        
        item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
        // 緩衝區空的，需等待數據
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
        // 緩衝區有足夠的數據能播放
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    func removePlayerObserverWith(_ item: AVPlayerItem) {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                  object: item)
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "loadedTimeRanges")
        item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }
    
    open func prepareToDeinit() {
        // reset will remove current player item and call removePlayerObserver
        self.resetPlayer()
    }
    
    deinit {
        print("MSPlayerLayerView dealloc")
    }
}
