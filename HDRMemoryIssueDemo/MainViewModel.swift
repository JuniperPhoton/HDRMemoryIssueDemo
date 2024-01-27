//
//  MainViewModel.swift
//  HDRMemoryIssueDemo
//
//  Created by Photon Juniper on 2024/1/28.
//

import Foundation
import PhotosUI
import Photos
import SwiftUI

struct PhotoItem: Identifiable, Hashable {
    let item: PhotosPickerItem
    
    var id: String {
        self.item.itemIdentifier ?? ""
    }
}

class MainViewModel: ObservableObject {
    @Published var items: [PhotoItem] = []
    @Published var photosItem: [PhotosPickerItem] = []
    @Published var selectedItem: PhotoItem? = nil
    
    @MainActor
    func updateItems(photosItem: [PhotosPickerItem]) {
        self.items = photosItem.map { PhotoItem(item: $0) }
        self.selectedItem = self.items.first
    }
    
    @MainActor
    func selectItem(_ item: PhotoItem) {
        self.selectedItem = item
    }
    
    func removeAll() {
        self.selectedItem = nil
        self.items = []
    }
}
