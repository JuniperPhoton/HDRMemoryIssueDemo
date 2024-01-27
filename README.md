# HDR Memory issue demo

This demo illustrates a memory leak issue when loading HDR images. After building the demo and installing the app, you can recreate this issue by:

- Clicking the button above to select images.
- Once the image is loaded, tap to load the full-size image.
- By switching between different images, you'll notice the app's memory usage continually increasing.
- Tapping the "Remove all" button won't reduce memory usage as expected.
- A memory graph debug will show that no memory is leaked by this app. Turning off HDR also prevents this issue.

Please note the issue was replicated in the following environments:

- Xcode 15.2
- iPhone 15 Pro with iOS 17.2

**Still no workaround for this issue**

This repo contains minimum code to reproduce this issue. If you are interested in some key parts of this repo, please keep reading.

## Load UIImage from PHAsset with HDR enabled

```swift
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
```

## Display UIImage with HDR enabled using SwiftUI's Image view

```swift
Image(uiImage: uiImage)
    .resizable()
    .scaledToFit()
    .allowedDynamicRange(.high)
    .clipped()
```

## Display UIImage with HDR enabled using UIImageView

```swift
private struct ImageViewBridge: UIViewRepresentable {
    static func dismantleUIView(_ uiView: UIImageView, coordinator: ()) {
        uiView.image = nil
    }
    
    let uiImage: UIImage
    
    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView(image: uiImage)
        view.contentMode = .scaleAspectFit
        view.preferredImageDynamicRange = .high
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        return view
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = uiImage
    }
}
```

