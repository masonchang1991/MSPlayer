//
//  MSPlayerResource.swift
//  MSPlayer_Example
//
//  Created by Mason on 2018/4/23.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import Foundation
import AVFoundation

public class MSPlayerResource {
    
    public let name : String
    public var coverURL : URL?
    public var coverURLRequestHeaders: [String: String]?
    public let definitions: [MSPlayerResourceDefinition]
    
    /**
     player resource item with url, used to play single difinition video
     
     - parameter name: video name
     - parameter url: video url
     - parameter cover: video cover, will show before playing, and hide when play
     */
    public convenience init(url: URL, name: String = "", coverURL: URL? = nil, coverURLRequestHeaders: [String: String]? = nil) {
        let definition = MSPlayerResourceDefinition(url: url, definition: "")
        self.init(name: name, definitions: [definition], coverURL: coverURL, coverURLRequestHeaders: coverURLRequestHeaders)
    }
    
    /**
     play resource with multi definitions
     
     - parameter name: video name
     - parameter definitions: video definitions
     - parameter cover: video cover
     */
    public init(name: String = "", definitions: [MSPlayerResourceDefinition], coverURL: URL? = nil, coverURLRequestHeaders: [String: String]? = nil) {
        self.name = name
        self.coverURL = coverURL
        self.definitions = definitions
        self.coverURLRequestHeaders = coverURLRequestHeaders
    }
}

public class MSPlayerResourceDefinition {
    public let url: URL
    public let definition: String
    
    /** An instance of Dictionary that contains keys for specifying options for the initialization of the AVURLAsset.
     See AVURLAssetPreferPreciseDurationAndTimingKey and AVURLAssetReferenceRestrictionsKey above/
     */
    public var options: [String: Any]?
    var avURLAsset: AVURLAsset {
        get {
            return MSPM.asset(for: self)
        }
    }
    
    /**
     Video resource item with definition name and specifying options
     
     - parameter url:
     - parameter definition: url definition
     - parameter options: specifying options for the initialization of the AVURLAsset
     
     you can add http-header or other options which mentions in https://developer.apple.com/reference/avfoundation/avurlasset/initialization_options
     
     to add http-header init options like this
     ```
     let header = ["User-Agent": "MSPlayer"]
     let definition.options = ["AVURLAssetHTTPHeaderFieldsKey": header]
     ```
     */
    public init(url: URL, definition: String, options: [String: Any]? = nil) {
        self.url = url
        self.definition = definition
        self.options = options
    }
}
