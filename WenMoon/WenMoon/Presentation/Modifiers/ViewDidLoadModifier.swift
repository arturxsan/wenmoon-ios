//
//  ViewDidLoadModifier.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 18.03.25.
//

import SwiftUI

struct ViewDidLoadModifier: ViewModifier {
    @State private var viewDidLoad = false
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content.onAppear {
            if !viewDidLoad {
                viewDidLoad = true
                action?()
            }
        }
    }
}
