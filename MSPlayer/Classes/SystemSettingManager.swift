//
//  SystemSettingManager.swift
//  MSPlayer
//
//  Created by Mason on 2019/5/29.
//

import Foundation
import MediaPlayer

class SystemSettingManager {
    
    static let shared = SystemSettingManager()
    
    private let brightnessController: BrightnessController
    private let volumeController: VolumeController
    
    private init() {
        self.brightnessController = BrightnessController(brightnessView: BrightnessView.shared())
        self.volumeController = VolumeController(volumeView: nil)
    }
    
    func getBrightnessController() -> BrightnessController {
        volumeController.removeView()
        return brightnessController
    }
    
    func getVolumeController() -> VolumeController {
        brightnessController.removeView()
        return volumeController
    }
}

class VolumeController {
    
    enum VolumeType {
        case system
        case custom
    }
    private var volumeView: MSVolumeView?
    private let slider: UISlider?
    public let type: VolumeType
    
    init(volumeView: MSVolumeView?) {
        self.volumeView = volumeView
        let mpVolumeView: MPVolumeView
        (self.slider, mpVolumeView) =  VolumeController.getVolumeSliderAndView()
        if volumeView == nil {
            self.type = .system
        } else {
            let keyWindow = UIApplication.shared.keyWindow
            keyWindow?.insertSubview(mpVolumeView, at: 0)
            mpVolumeView.alpha = 0.00001
            self.type = .custom
        }
    }
    
    private static func getVolumeSliderAndView() -> (UISlider?, MPVolumeView) {
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.clipsToBounds = true
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        return (slider, volumeView)
    }
    
    func setVolume(_ volume: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self = self else { return }
            self.setSliderValue(volume)
        }
    }
    
    func changeVolumeBy(_ value: Float) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            guard let self = self else { return }
            self.addSliderValue(value)
        }
    }
    
    func removeView() {
        switch type {
        case .custom:
            volumeView?.removeVolumeView()
        case .system: break
        }
    }
    
    private func addSliderValue(_ value: Float) {
        guard let slider = self.slider else { return }
        let currentValue = slider.value
        setSliderValue(currentValue + value)
    }
    
    private func setSliderValue(_ value: Float) {
        guard let slider = self.slider else { return }
        slider.value = value
        switch type {
        case .system: break
        case .custom:
            volumeView?.updateVolumeLevelWith(value)
        }
    }
}

class BrightnessController: NSObject {
    
    private let brightnessView: MSBrightnessView
    
    init(brightnessView: MSBrightnessView) {
        self.brightnessView = brightnessView
        super.init()
        
        self.addObserver()
    }
    
    private func addObserver() {
        UIScreen.main.addObserver(self,
                                  forKeyPath: "brightness",
                                  options: .new,
                                  context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard
            let dic = change,
            let levelValue = dic[NSKeyValueChangeKey.newKey] as? Float else {
                return
        }
        brightnessView.updateBrightnessLevelWith(CGFloat(levelValue))
    }
    
    func changeBrightnessByValue(_ value: CGFloat) {
        let currentValue = UIScreen.main.brightness
        let nextValue = currentValue + value
        setBrightnessValue(nextValue)
    }
    
    func setBrightnessValue(_ value: CGFloat) {
        UIScreen.main.brightness = value
    }
    
    func removeView() {
        brightnessView.removeBrightnessView()
    }
}
