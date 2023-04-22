//
//  AuthOptionsView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.03.25.
//

import SwiftUI

struct AuthOptionsView: View {
    // MARK: - Nested Types
    struct AuthOption {
        let imageName: String
        let isInProgress: Bool
        let action: () -> Void
    }
    
    // MARK: - Properties
    let options: [AuthOption]
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                ForEach(options, id: \.imageName) { option in
                    Button {
                        option.action()
                    } label: {
                        VStack {
                            if option.isInProgress {
                                ProgressView()
                            } else {
                                Image(option.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}
