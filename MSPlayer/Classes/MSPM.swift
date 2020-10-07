//
//  MSPlayerManager.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/18.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import AVFoundation
import UIKit
import NVActivityIndicatorView
import CoreData

public var MSPlayerConfig: MSPM {
    return MSPM.shared()
}

public enum MSPlayerTopBarShowCase: Int {
    case always = 0          /// 始終顯示
    case horizantalOnly = 1  /// 只在橫屏介面顯示
    case none = 2            /// 不顯示
}

public class MSPM {
    
    @discardableResult
    public static func shared() -> MSPM {
        if let shared = self.sharedInstance {
            return shared
        } else {
            let shared = MSPM()
            self.sharedInstance = shared
//            let _ = BrightnessView.shared()
//            let _ = SystemSettingManager.shared
            return shared
        }
    }
    
    private static var sharedInstance: MSPM?
    
    internal static func asset(for resource: MSPlayerResourceDefinition) -> AVURLAsset {
        return AVURLAsset(url: resource.url, options: resource.options)
    }
    
    /**
     Player status emun
     
     - notSetURL:      not set url yet
     - readyToPlay:    player ready to play
     - buffering:      player buffering
     - bufferFinished: buffer finished
     - playedToTheEnd: played to the End
     - error:          error with playing
     */
    public enum State: Equatable {
        case notSetUrl
        case readyToPlay
        case buffering
        case bufferFinished
        case playedToTheEnd
        case error(Error?)
        
        public static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.error(_), .error(_)):
                return true
            case (.notSetUrl, .notSetUrl):
                return true
            case (.readyToPlay, .readyToPlay):
                return true
            case (.buffering, .buffering):
                return true
            case (.bufferFinished, .bufferFinished):
                return true
            case (.playedToTheEnd, .playedToTheEnd):
                return true
            default: return false
            }
        }
    }
    /**
     video aspect ratio types
     
     - `default`:    video default aspect
     - sixteen2NINE: 16:9
     - four2THREE:   4:3
     */
    public enum AspectRatio : Int {
        case `default`    = 0
        case sixteen2NINE
        case four2THREE
    }
    
    public enum ButtonType: Int {
        case playAndPause = 101
        case back = 103
        case fullScreen = 105
        case replay = 106
    }
    
    public static var screenRatio: CGFloat {
        return (UIScreen.main.bounds.width) / CGFloat(375)
    }
    
    public static var deviceDefaultAspectRatio: AspectRatio {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .four2THREE
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            return .sixteen2NINE
        } else {
            return .default
        }
    }
    
    open var openRecorder: Bool = true
    //Record user's watch time max number
    open var recordVideoTimeNumber: Int = 30
    
    /// is Using floating
    weak var msFloatingWindow: UIWindow?
    open var floatingViewMinSize = CGSize(width: 178 * MSPM.screenRatio, height: 100 * MSPM.screenRatio)
    open var floatingViewDecelerateVelocityRate: CGFloat = 1.0
    open var floatingViewDismissMinVelocityRate: CGFloat = 1.0
    
    /// tint color
    open var loaderTintColor = UIColor.white
    /// Loader(NVActivityIndicatorType)
    open var loaderType = NVActivityIndicatorType.ballRotateChase
    /// should auto play
    open var shouldAutoPlay = true
    open var topBarShowInCase = MSPlayerTopBarShowCase.always
    open var animateDelayTimeInterval = TimeInterval(5)
    /// should show log
    open var allowLog = false
    /// use gestures to set brightness, volume and play position
    open var enableBrightnessGestures = true
    open var enableVolumeGestures = true
    open var enablePlaytimeGestures = true
    
    // controlViewConfig
    open var controlViewAnimationDuration = 0.3
    open var mainMaskViewShowAlpha: CGFloat = 0.0
    open var otherMaskViewShowAlpha: CGFloat = 1.0
    open var urlWrongLabelText: String = "Video is unavailable"
    open var playCoverImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_playCover_image")
    open var playCoverImageViewNeedHidden: Bool = false
    open var mainMaskBackgroundColor = UIColor.black.withAlphaComponent(0.1)
    open var bottomMaskBackgroundColor = UIColor.black.withAlphaComponent(0.6)
    open var isUseBackImage: Bool = true
    open var backButtonImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_back_image")
    open var backButtonImageViewTintColor = UIColor.white
    open var downButtonImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_down_image")
    open var downButtonImageViewTintColor = UIColor.white
    open var playButtonImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_play_image")
    open var pauseButtonImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_pause_image")
    open var totalTimeTextColor = UIColor.white
    open var sliderThumbImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_slider_image")
    open var sliderMaxTrackTintColor = UIColor.clear
    open var sliderMinTrackTintColor = UIColor.red
    open var progressViewTintColor = UIColor.white.withAlphaComponent(0.6)
    open var progressViewTrackTintColor = UIColor.white.withAlphaComponent(0.3)
    open var fullScreenButtonImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_fullScreen_image")
    open var endFullScreenButtonImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_endFullScreen_image")
    open var seekToLabelTextColor = UIColor(red: 0.9098, green: 0.9098, blue: 0.9098, alpha: 1.0)
    open var seekToViewBackgroundColor = UIColor.black.withAlphaComponent(0.7)
    open var seekToViewCornerRadius = 4 * MSPM.screenRatio
    open var seekToViewImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_seekTo_image")
    open var replayButtonImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_replay_image")
    open var playNextView: MSPlayNext? = CircleProgressImageView(size: CGSize(width: 50, height: 50),
                                                                 image: MSPM.MSImageResourcePath("MSPlayer_playCover_image"))
    open var playNextTopText: String = "play next top text"
    open var playNextBottomText: String = "play next bot text"
    
    // MSPlayerConfig
    open var playerPanSeekRate: Double = 1.0
    open var playerAnimationDuration: Double = 4.0
    open var playerControlBarAutoFadeOutDuration = 0.5
    open var playerVolumeChangeRate: Float = 1.2
    open var playerBrightnessChangeRate: CGFloat = 1.0
    
    // BrightnessView
    open var brightnessTitle = MSPM.getBrightnessLocalizeTitle()
    open var brightnessImage: UIImage? = MSPM.MSImageResourcePath("MSPlayer_brightness_image")
    
    private static func getBrightnessLocalizeTitle() -> String {
        let languages = NSLocale.preferredLanguages
        let currentLanguage = languages[0]
        var title = "Brightness"
        if (currentLanguage.range(of: "Hant") != nil) {
            title = "亮度"
        } else if (currentLanguage.range(of: "Hans") != nil) {
            title = "亮度"
        } else {
            title = "Brightness"
        }
        return title
    }
    
    /**
     打印log
     
     - parameter info: log信息
     */
    func log(_ info: String) {
        if allowLog {
            print(info)
        }
    }
    
    fileprivate static func MSImageResourcePath(_ fileName: String) -> UIImage? {
        let bundle = Bundle(for: MSPlayer.self)
        let bundleURL = bundle.resourceURL?.appendingPathComponent("MSPlayer.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        let image = UIImage(named: fileName, in: resourceBundle, compatibleWith: nil)
        return image?.withRenderingMode(.alwaysOriginal)
    }
    
    //MARK: - Core Data for video recorder
    //MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let bundle = Bundle(for: MSPlayer.self)
        let modelURL = bundle.url(forResource: "VideoTimeRecord", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("MSPlayerCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            //MARK: - avoid user's coreData conflict
            //版本迁移
            var sqlPathRoot:NSString = url.absoluteString as NSString
            var shmurl:NSURL = NSURL(string: sqlPathRoot.appending("-shm"))!
            var walurl:NSURL = NSURL(string: sqlPathRoot.appending("-wal"))!
            do{
                try FileManager.default.removeItem(at: url)
            }catch{
                print(error)
            }
            do{
                try FileManager.default.removeItem(at: shmurl as URL)
            }catch{
                print(error)
            }
            do{
                try FileManager.default.removeItem(at: walurl as URL)
            }catch{
                print(error)
            }
            
            //再创建一次
            var persistentStore : NSPersistentStore?
            
            do{
                try persistentStore =  coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            }catch{
                // Report any error we got.
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
                dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
                dict[NSUnderlyingErrorKey] = error as NSError
                let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                // Replace this with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
                abort()
            }
            if persistentStore == nil
            {
                print("版本更替失败了")
            }
            else
            {
                print("版本更替成功")
            }
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    open func removeAllRecords() {
        let coreDataManager = MSCoreDataManager.shared
        coreDataManager.deleteAllVideoTimeRecords()
    }
}
