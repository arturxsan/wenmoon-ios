//
//  NeonWavesBackgroundView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 02.04.25.
//

import SwiftUI

struct NeonWavesBackgroundView: View {
    // MARK: - Properties
    @State private var xOffset: CGFloat = .zero
    @State private var scrollTask: Task<Void, Never>?
    
    private let animationDuration: TimeInterval = 60
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let imageWidth = screenHeight * (2354 / 926)
            let totalWidth = imageWidth * 2
            
            HStack(spacing: -0.5) {
                Image("neon.waves")
                    .resizable()
                    .scaledToFill()
                    .frame(height: screenHeight)
                
                Image("neon.waves")
                    .resizable()
                    .scaledToFill()
                    .frame(height: screenHeight)
            }
            .frame(width: totalWidth, height: screenHeight)
            .offset(x: xOffset)
            .onAppear {
                scrollTask = Task {
                    await startLoopingScroll(imageWidth)
                }
            }
            .onDisappear {
                scrollTask?.cancel()
                scrollTask = nil
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
    }
    
    // MARK: - Private
    private func startLoopingScroll(_ imageWidth: CGFloat) async {
        guard !Task.isCancelled else { return }
        
        xOffset = .zero
        withAnimation(.linear(duration: animationDuration)) {
            xOffset = -imageWidth
        }
        
        try? await Task.sleep(for: .seconds(animationDuration))
        await startLoopingScroll(imageWidth)
    }
}

// MARK: - Preview
#Preview {
    NeonWavesBackgroundView()
}
