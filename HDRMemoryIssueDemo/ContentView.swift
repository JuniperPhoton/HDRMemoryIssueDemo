//
//  ContentView.swift
//  HDRMemoryIssueDemo
//
//  Created by Photon Juniper on 2024/1/27.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    @AppStorage("showsHDR")
    private var showsHDR = true
    
    @AppStorage("useUIImageView")
    private var useUIImageView = true

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.items.isEmpty {
                    Text(
                        """
                        Click the button above to pick images.
                        Once the images is loaded, you can tap to load the full-size image.
                        
                        By tapping different images back and forth, you will see the memories used by the app keep increase.
                        And if you tap the "Remove all" button, the memories won't go down as expected.
                        
                        By debugging memory graph, you will find that no memory is leaked by this app. Also, by turning off HDR, this issue won't arise.
                        """
                    )
                } else {
                    if let selectedItem = viewModel.selectedItem {
                        ImageDetailView(item: selectedItem)
                            .frame(maxHeight: .infinity)
                            .id(selectedItem)
                    } else {
                        Spacer()
                    }
                    ImageStripView(items: viewModel.items) { item in
                        viewModel.selectItem(item)
                    }
                }
            }
            .padding()
            .animation(.default, value: viewModel.selectedItem)
            .animation(.default, value: viewModel.items)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle("Shows HDR", isOn: $showsHDR)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle("Use UIImageView", isOn: $useUIImageView)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $viewModel.photosItem, photoLibrary: .shared()) {
                        Image(systemName: "photo.badge.plus")
                    }.onChange(of: viewModel.photosItem) { _, newValue in
                        viewModel.updateItems(photosItem: newValue)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.items.isEmpty {
                        Button("Remove all") {
                            viewModel.removeAll()
                        }
                    }
                }
            }
            .task {
                let _ = await requestForPermission()
            }
        }
    }
    
    private func requestForPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        if status == .authorized || status == .limited {
            return true
        }
        return false
    }
}

private struct ImageStripView: View {
    let items: [PhotoItem]
    
    var onClickItem: (PhotoItem) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(items) { item in
                    Button {
                        onClickItem(item)
                    } label: {
                        ImageStripItemView(item: item)
                    }.buttonStyle(.plain)
                }
            }
        }.frame(height: 80)
    }
}

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

private struct ImageDetailView: View {
    let item: PhotoItem
    
    @AppStorage("showsHDR")
    private var showsHDR = true
    
    @AppStorage("useUIImageView")
    private var useUIImageView = true
    
    @State private var uiImage: UIImage? = nil
    
    var body: some View {
        ZStack {
            if let uiImage = uiImage {
                if useUIImageView {
                    ImageViewBridge(uiImage: uiImage)
                } else {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .allowedDynamicRange(.high)
                        .clipped()
                }
            } else {
                Rectangle().fill(Color.gray)
            }
        }.task(id: showsHDR) {
            await loadImage()
        }
    }
    
    @MainActor
    private func loadImage() async {
        guard let result = await loadImageInternal() else {
            return
        }
        self.uiImage = result
    }
    
    private func loadImageInternal() async -> UIImage? {
        guard let id = item.item.itemIdentifier else {
            return nil
        }
        
        let options = PHFetchOptions()
        options.fetchLimit = 1
        
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: options).firstObject else {
            return nil
        }
        
        return await ImageLoader.shared.fetchUIImage(phAsset: asset, showsHDR: showsHDR)
    }
}

private struct ImageStripItemView: View {
    let item: PhotoItem
    
    @State private var cgImage: CGImage? = nil
    
    var body: some View {
        ZStack {
            if let cgImage = cgImage {
                Image(cgImage, scale: 1.0, label: Text(""))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Rectangle().fill(Color.gray)
            }
        }.frame(width: 80, height: 80)
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .task {
                await loadImage()
            }
    }
    
    @MainActor
    private func loadImage() async {
        self.cgImage = await loadImageInternal()
    }
    
    private func loadImageInternal() async -> CGImage? {
        guard let id = item.item.itemIdentifier else {
            return nil
        }
        
        let options = PHFetchOptions()
        options.fetchLimit = 1
        
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: options).firstObject else {
            return nil
        }
        
        return await ImageLoader.shared.fetchThumbnailCGImage(phAsset: asset)
    }
}

#Preview {
    ContentView()
}
