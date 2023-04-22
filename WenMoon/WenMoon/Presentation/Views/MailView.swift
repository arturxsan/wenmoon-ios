//
//  MailView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 03.04.25.
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    // MARK: - Nested Types
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
            parent.dismiss()
        }
    }
    
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    
    var subject: String
    var body: String
    var recipient: String
    
    // MARK: - Methods
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setSubject(subject)
        vc.setToRecipients([recipient])
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}
}
