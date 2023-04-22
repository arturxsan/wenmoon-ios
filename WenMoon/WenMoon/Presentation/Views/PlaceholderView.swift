//
//  PlaceholderView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.01.25.
//

import SwiftUI

struct PlaceholderView: View {
    // MARK: - Nester Types
    enum Style {
        case large
        case medium
        case small
        
        var font: Font {
            switch self {
            case .large: return .title3
            case .medium: return .body
            case .small: return .subheadline
            }
        }
        
        var imageSize: CGFloat {
            switch self {
            case .large: return 48
            case .medium: return 36
            case .small: return 24
            }
        }
    }
    
    // MARK: - Properties
    let text: String
    let style: Style
    
    init(text: String, style: Style = .medium) {
        self.text = text
        self.style = style
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            Image("moon")
                .resizable()
                .scaledToFit()
                .frame(width: style.imageSize, height: style.imageSize)
            
            Text(text)
                .font(style.font)
        }
        .foregroundStyle(.gray.opacity(0.6))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
