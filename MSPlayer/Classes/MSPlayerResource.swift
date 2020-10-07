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
    public var definitions: [MSPlayerResourceDefinition]
    
    /**
     player resource item with url, used to play single difinition video (this method will decrypt in the future)
     
     - parameter name: video name
     - parameter url: video url
     - parameter cover: video cover, will show before playing, and hide when play
     */
    public convenience init(url: URL, name: String = "", coverURL: URL? = nil, coverURLRequestHeaders: [String: String]? = nil, coverImage: UIImage? = nil) {
        // transform cover parameter to urlRequest
        if let coverURL = coverURL {
            var coverURLRequest = URLRequest(url: coverURL)
            coverURLRequest.allHTTPHeaderFields = coverURLRequestHeaders
            let definition = MSPlayerResourceDefinition(url: url,
                                                        definition: "",
                                                        coverURLRequest: coverURLRequest,
                                                        coverImage: coverImage)
            self.init(name: name, definitions: [definition])
        } else {
            let definition = MSPlayerResourceDefinition(url: url,
                                                        definition: "",
                                                        coverImage: coverImage)
            self.init(name: name, definitions: [definition])
        }
    }
    
    /**
     play resource with multi definitions
     
     - parameter name: video name
     - parameter definitions: video definitions
     - parameter cover: video cover
     */
    public init(name: String = "", definitions: [MSPlayerResourceDefinition]) {
        self.name = name
        self.definitions = definitions
    }
    
    public func addDefinitions(_ definitions: [MSPlayerResourceDefinition]) {
        self.definitions.append(contentsOf: definitions)
    }
    
    public func removeDefinitionsAt(_ index: Int) {
        if let _ = self.definitions[exist: index] {
            self.definitions.remove(at: index)
        }
    }
}

public class MSPlayerResourceDefinition {
    
    public let videoId: String?
    public let videoName: String
    public let url: URL
    public let definition: String
    public let coverURLRequest: URLRequest?
    public let coverImage: UIImage?
    
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
    public init(videoId: String? = nil, videoName: String = "", url: URL, definition: String, options: [String: Any]? = nil, coverURLRequest: URLRequest? = nil, coverImage: UIImage? = nil) {
        self.videoId = videoId
        self.videoName = videoName
        self.url = url
        self.definition = definition
        self.options = options
        self.coverURLRequest = coverURLRequest
        self.coverImage = coverImage
    }
}
