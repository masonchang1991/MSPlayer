# MSPlayer

[![CI Status](http://img.shields.io/travis/masonchang1991/MSPlayer.svg?style=flat)](https://travis-ci.org/masonchang1991/MSPlayer)
[![Version](https://img.shields.io/cocoapods/v/MSPlayer.svg?style=flat)](http://cocoapods.org/pods/MSPlayer)
[![License](https://img.shields.io/cocoapods/l/MSPlayer.svg?style=flat)](http://cocoapods.org/pods/MSPlayer)
[![Platform](https://img.shields.io/cocoapods/p/MSPlayer.svg?style=flat)](http://cocoapods.org/pods/MSPlayer)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

MSPlayer is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

<br>swift 3.0 use version 1.x.x <br/>
```ruby
pod 'MSPlayer', '1.0.4'
```
<br>swift 4.0 use version 2.x.x (not yet)<br/>
```ruby
pod 'MSPlayer', '2.x.x'
```

## Usage
Set MSPlayer's constraints and set video url

Example
```swift
import MSPlayer

let player = MSPlayer()
view.addSubView(player)
// setup player constraints
player.translatesAutoresizingMaskIntoConstraints = false
player.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
player.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
player.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
player.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

let videoUrl = URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!
let coverUrl = URL(string: "https://www.eta.co.uk/wp-content/uploads/2012/09/Cycling-by-water-resized-min.jpg")!
// cover will show when you set `MSPlayerConfig.shouldAutoPlay = false`
let asset = MSPlayerResource(url: videoUrl, name: "as", coverURL: coverUrl)
player.setVideoBy(asset)

// if you have navigation controller, you can detect back event
player.backBlock = { [unowned self] (isFullScreen) in
    if isFullScreen == true { return }
    let _ = self.navigationController?.popViewController(animated: true)
}
```

## Add HTTP header for request
```swift
let header = ["User-Agent":"MSPlayer"]
let options = ["AVURLAssetHTTPHeaderFieldsKey":header]

let definition = MSPlayerResourceDefinition(url: URL(string: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")!,
                                            definition: "高清",
                                            options: options)

let asset = MSPlayerResource(name: "Video Name",
                             definitions: [definition])
```
## Listening to player state changes
### Delegate
```swift
    func msPlayer(_ player: MSPlayer, stateDidChange state: MSPM.State)
    func msPlayer(_ player: MSPlayer, loadTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func msPlayer(_ player: MSPlayer, playTimeDidChange current: TimeInterval, total: TimeInterval)
    func msPlayer(_ player: MSPlayer, isPlaying: Bool)
    func msPlayer(_ player: MSPlayer, orientChanged isFullScreen: Bool)
```

## Player Config
change property before player set
```swift
// MARK: - These Property in MSPM

/// fullScreen ignore player constraint to fill screen
MSPlayerConfig.fullScreenIgnoreConstraint = true
/// loader tint color
MSPlayerConfig.loaderTintColor = UIColor.white
/// loader Type
MSPlayerConfig.loaderType = NVActivityIndicatorType.ballRotateChase
/// Change this to set should auto play or not
MSPlayerConfig.shouldAutoPlay = true
/// enable setting the brightness by touch gesture in the player
MSPlayerConfig.enableBrightnessGestures = true
/// enable setting the volume by touch gesture in the player
MSPlayerConfig.enableVolumeGestures = true
/// enable setting the playtime by touch gesture in the player
MSPlayerConfig.enablePlaytimeGestures = true
/// player Pan seek rate (horizontal pan distant * seekRate == seekDistance)
MSPlayerConfig.playerPanSeekRate = 0.4
/// player controlViewBarFadeOutDuration
MSPlayerConfig.playerControlBarAutoFadeOutDuration = 0.5
```

## Custom Asset And View Property

```swift
/// if url had someting wrong, display text you want
MSPlayerConfig.urlWrongLabelText = "Video is unavailable"
/// when controlView show, entire mask view show alpha
MSPlayerConfig.mainMaskViewShowAlpha = 0.0
/// when controlView show, other Mask view(like bottom bar) show alpha
MSPlayerConfig.otherMaskViewShowAlpha = 1.0
/// change play cover image
MSPlayerConfig.playCoverImage = yourPlayCoverImage
/// change play button image
MSPlayerConfig.playButtonImage = yourPlayButtonImage
/// change pause button image
MSPlayerConfig.pauseButtonImage = yourPauseButtonImage
/// change back button image
MSPlayerConfig.backButtonImage = yourBackButtonImage
/// change sliderThumb image
MSPlayerConfig.sliderThumbImage = yourSliderThumbImage
/// change fullScreen button image
MSPlayerConfig.fullScreenButtonImage = yourFullScreenButtonImage
/// change endFullScreen button image
MSPlayerConfig.endFullScreenButtonImage = yourEndFullScreenButtonImage
/// change seekTo(arrow) image
MSPlayerConfig.seekToViewImage = yourSeekToViewImage
/// change replay button image
MSPlayerConfig.replayButtonImage = yourReplayImage
/// change progressView Tint color
MSPlayerConfig.progressViewTintColor = UIColor.white.withAlphaComponent(0.6)
/// change progressView Track tint color
MSPlayerConfig.progressViewTrackTintColor = UIColor.white.withAlphaComponent(0.3)
/// change sliderMaxTrackTintColor
MSPlayerConfig.sliderMaxTrackTintColor = UIColor.clear
/// change sliderMinTrackTintColor
MSPlayerConfig.sliderMinTrackTintColor = UIColor.red
/// change Time label text color
MSPlayerConfig.totalTimeTextColor = UIColor.white
```

## Custom Brightness view
```swift
/// change brightness title
MSPlayerConfig.brightnessTitle = "Brightness"
/// change brightness Image
MSPlayerConfig.brightnessImage = yourBrightnessImage
```

## DEMO

![gif](https://github.com/masonchang1991/MSPlayer/blob/master/MSPlayer_Demo.gif)

not yet


## Reference
MSPlayer is based on BMPlayer.
Thanks for BMPlayer's author.

## Author

Email: masonchang1991@gmail.com
Medium: https://medium.com/@masonchang1991

## License

MSPlayer is available under the MIT license. See the LICENSE file for more info.
