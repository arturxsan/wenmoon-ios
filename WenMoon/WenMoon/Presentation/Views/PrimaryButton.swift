//
//  PrimaryButton.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 01.04.25.
//

import SwiftUI

struct PrimaryButton: View {
    // MARK: - Properties
    private let title: String
    private let isDisabled: Bool
    private let isFullWidth: Bool
    private let action: () -> Void
    
    // MARK: - Initializers
    init(
        title: String,
        isDisabled: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.isFullWidth = isFullWidth
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button {
            if !isDisabled { action() }
        } label: {
            Text(title)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .padding(.vertical, 12)
                .padding(.horizontal, isFullWidth ? .zero : (16))
                .background(isDisabled ? Color.gray.opacity(0.3) : Color.white)
                .foregroundStyle(isDisabled ? Color.gray : Color.black)
                .cornerRadius(32)
        }
        .frame(height: 44)
        .disabled(isDisabled)
    }
}
