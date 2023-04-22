//
//  CoinImageView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 09.01.25.
//

import SwiftUI

struct CoinImageView: View {
    // MARK: - Properties
    let image: Image?
    let imageData: Data?
    let imageURL: URL?
    let placeholderText: String
    let size: CGFloat
    
    // MARK: - Initializers
    init(
        image: Image? = nil,
        imageData: Data? = nil,
        imageURL: URL? = nil,
        placeholderText: String,
        size: CGFloat
    ) {
        self.image = image
        self.imageData = imageData
        self.imageURL = imageURL
        self.placeholderText = placeholderText
        self.size = size
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
            
            if let image {
                imageView(image)
            } else if let imageData, let uiImage = UIImage(data: imageData) {
                imageView(Image(uiImage: uiImage))
            } else if let imageURL {
                AsyncImage(url: imageURL, content: { image in
                    imageView(image)
                }, placeholder: {
                    ProgressView()
                        .controlSize(.mini)
                })
            } else {
                Text(placeholderText.prefix(1).uppercased())
                    .foregroundStyle(.black)
            }
        }
        .brightness(-0.1)
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private func imageView(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: size / 2, height: size / 2)
            .clipShape(Circle())
    }
}
