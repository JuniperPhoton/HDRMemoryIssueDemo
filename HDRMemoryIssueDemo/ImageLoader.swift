//
//  ImageLoader.swift
//  HDRMemoryIssueDemo
//
//  Created by Photon Juniper on 2024/1/28.
//

import Foundation
import Photos
import SwiftUI

class ImageLoader {
    static let shared = ImageLoader()
    
    private init() {
        // empty
    }
    
    func fetchUIImage(phAsset: PHAsset, showsHDR: Bool) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let cacheManager = PHCachingImageManager.default()
            
            cacheManager.requestImageDataAndOrientation(for: phAsset, options: nil) { data, _, orientation, _ in
                guard let data = data else {
                    return continuation.resume(returning: nil)
                }
                
                var configuration = UIImageReader.Configuration()
                configuration.prefersHighDynamicRange = showsHDR
                
                let reader = UIImageReader(configuration: configuration)
                let image = reader.image(data: data)
                
                continuation.resume(returning: image)
            }
        }
    }
    
    public func fetchThumbnailCGImage(
        phAsset: PHAsset,
        size: CGSize = CGSize(width: 400, height: 400),
        onProgressChanged: ((Double) -> Void)? = nil
    ) async -> CGImage? {
        return await withCheckedContinuation { continuation in
            let cacheManager = PHCachingImageManager.default()
            
            let o = PHImageRequestOptions()
            o.isSynchronous = true
            o.resizeMode = .fast
            
            cacheManager.requestImage(for: phAsset,
                                      targetSize: size,
                                      contentMode: .aspectFit,
                                      options: o) { platformImage, data in
#if os(macOS)
                continuation.resume(returning: platformImage?.cgImage(forProposedRect: nil, context: nil, hints: nil))
#else
                continuation.resume(returning: platformImage?.cgImage)
#endif
            }
        }
    }
}
