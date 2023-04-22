//
//  CustomProgressView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.03.25.
//

import SwiftUI

struct CustomProgressView: View {
    var body: some View {
        ProgressView()
            .tint(.accent)
            .padding(24)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
