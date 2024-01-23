//
//  ContentView.swift
//  Instafilter
//
//  Created by Игорь Верхов on 22.10.2023.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var proccessedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedItem) {
                    if let proccessedImage {
                        proccessedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("Tap to import a photo"))
                    }
                }
                .onChange(of: selectedItem, loadImage)
                
                Spacer()
                
                VStack(spacing: 15) {
                    if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
                        HStack {
                            Text("Intensity")
                                .foregroundStyle(proccessedImage == nil ? .tertiary : .primary)
                            Slider(value: $filterIntensity)
                                .onChange(of: filterIntensity, applyProcessing)
                        }
                        .disabled(proccessedImage == nil).animation(.easeInOut(duration: 0.4), value: proccessedImage)
                    }
                    
                    if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
                        HStack {
                            Text("Radius")
                                .foregroundStyle(proccessedImage == nil ? .tertiary : .primary)
                            Slider(value: $filterRadius)
                                .onChange(of: filterRadius, applyProcessing)
                        }
                        .disabled(proccessedImage == nil).animation(.easeInOut(duration: 0.4).delay(0.4), value: proccessedImage)
                    }
                    
                    if currentFilter.inputKeys.contains(kCIInputScaleKey) {
                        HStack {
                            Text("Scale")
                                .foregroundStyle(proccessedImage == nil ? .tertiary : .primary)
                            Slider(value: $filterScale)
                                .onChange(of: filterScale, applyProcessing)
                        }
                        .disabled(proccessedImage == nil).animation(.easeInOut(duration: 0.4).delay(0.6), value: proccessedImage)
                    }
                }
                .padding(.vertical)
                
                
                HStack {
                    Button("Change Filter",action: changeFilter)
                        .disabled(proccessedImage == nil).animation(.easeInOut(duration: 0.4).delay(0.6), value: proccessedImage)
                    
                    Spacer()
                    
                    if let proccessedImage {
                        ShareLink(item: proccessedImage, preview: SharePreview("Instafilter image", image: proccessedImage))
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Pointillize") { setFilter(CIFilter.pointillize()) }
                Button("Bloom") { setFilter(CIFilter.bloom()) }
                Button("Instant") { setFilter(CIFilter.photoEffectInstant()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter () {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterScale, forKey: kCIInputScaleKey)
        }
        
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        proccessedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        if filterCount > 20 {
            requestReview()
        }
    }
}

#Preview {
    ContentView()
}
