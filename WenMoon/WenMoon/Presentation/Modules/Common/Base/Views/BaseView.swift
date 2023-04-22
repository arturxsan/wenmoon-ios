//
//  BaseView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 19.11.24.
//

import SwiftUI

struct BaseView<Content: View>: View {
    // MARK: - Properties
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    
    @State private var showErrorAlert = false
    
    private let content: Content
    
    // MARK: - Initializers
    init(
        isLoading: Binding<Bool>,
        errorMessage: Binding<String?>,
        @ViewBuilder content: () -> Content
    ) {
        self._isLoading = isLoading
        self._errorMessage = errorMessage
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        content
            .disabled(isLoading)
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Oops!"),
                    message: Text(errorMessage ?? "Something went wrong. Please try again."),
                    dismissButton: .default(Text("OK")) {
                        errorMessage = nil
                    }
                )
            }
            .onChange(of: errorMessage) { _, newValue in
                showErrorAlert = newValue.isNotNil
            }
    }
}
