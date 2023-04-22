//
//  LinksView.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 11.02.25.
//

import SwiftUI

// MARK: - LinksView
struct LinksView: View {
    @State private var selectedLinks: [IdentifiableLink] = []
    @State private var showingActionSheet = false
    @State private var selectedLink: IdentifiableLink?
    
    let links: CoinDetails.Links
    
    var body: some View {
        FlowLayout {
            ForEach(Array(generateLinkButtons().enumerated()), id: \.offset) { _, view in
                view
            }
        }
        .confirmationDialog("Select a Link", isPresented: $showingActionSheet, titleVisibility: .visible) {
            ForEach(selectedLinks, id: \.self) { link in
                Button {
                    selectedLink = link
                } label: {
                    Text(extractDomain(from: link.url))
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(item: $selectedLink, onDismiss: {
            selectedLink = nil
        }) { link in
            SafariView(url: link.url)
        }
    }
    
    private func generateLinkButtons() -> [AnyView] {
        var buttons: [AnyView] = []
        
        if let urls = links.homepage, !urls.isEmpty {
            let links = urls.map { IdentifiableLink(url: $0) }
            appendMultiLinkButton(
                to: &buttons,
                title: "Website",
                links: links,
                showFullURL: false,
                systemImageName: "globe"
            )
        }
        
        if let url = links.whitepaper {
            let link = IdentifiableLink(url: url)
            buttons.append(
                AnyView(
                    LinkButtonView(
                        link: link,
                        title: "Whitepaper",
                        systemImageName: "doc"
                    ) {
                        selectedLink = link
                    }
                )
            )
        }
        
        if let username = links.twitterScreenName, !username.isEmpty,
           let url = URL(string: "https://twitter.com/\(username)") {
            let link = IdentifiableLink(url: url)
            buttons.append(
                AnyView(
                    LinkButtonView(
                        link: link,
                        title: "X",
                        imageName: "x.logo"
                    ) {
                        selectedLink = link
                    }
                )
            )
        }
        
        if let url = links.subredditUrl, url.absoluteString != "https://www.reddit.com" {
            let link = IdentifiableLink(url: url)
            buttons.append(
                AnyView(
                    LinkButtonView(
                        link: link,
                        title: "Reddit",
                        imageName: "reddit.logo"
                    ) {
                        selectedLink = link
                    }
                )
            )
        }
        
        if let username = links.telegramChannelIdentifier, !username.isEmpty,
           let url = URL(string: "https://t.me/\(username)") {
            let link = IdentifiableLink(url: url)
            buttons.append(
                AnyView(
                    LinkButtonView(
                        link: link,
                        title: "Telegram",
                        imageName: "telegram.logo"
                    ) {
                        selectedLink = link
                    }
                )
            )
        }
        
        let chatURLs = links.chatUrl ?? []
        let announcementURLs = links.announcementUrl ?? []
        let urls = (chatURLs + announcementURLs)
        if !urls.isEmpty {
            let links = urls.map { IdentifiableLink(url: $0) }
            appendMultiLinkButton(
                to: &buttons,
                title: "Communication",
                links: links,
                showFullURL: false,
                systemImageName: "message.fill"
            )
        }
        
        if let urls = links.blockchainSite, !urls.isEmpty {
            let links = urls.map { IdentifiableLink(url: $0) }
            appendMultiLinkButton(
                to: &buttons,
                title: "Explorer",
                links: links,
                showFullURL: false,
                systemImageName: "link"
            )
        }
        
        if let urls = links.reposUrl.github, !urls.isEmpty {
            if urls.count == 1, let url = urls.first {
                let link = IdentifiableLink(url: url)
                buttons.append(
                    AnyView(
                        LinkButtonView(
                            link: link,
                            title: "GitHub",
                            imageName: "github.logo"
                        ) {
                            selectedLink = link
                        }
                    )
                )
            } else if !urls.isEmpty {
                let links = urls.map { IdentifiableLink(url: $0) }
                buttons.append(
                    AnyView(
                        MultiLinkButtonView(
                            title: "GitHub",
                            links: links,
                            imageName: "github.logo",
                            showFullURL: true,
                            showingActionSheet: $showingActionSheet,
                            selectedLinks: $selectedLinks
                        )
                    )
                )
            }
        }
        
        return buttons
    }
    
    private func appendMultiLinkButton(
        to buttons: inout [AnyView],
        title: String,
        links: [IdentifiableLink],
        showFullURL: Bool,
        imageName: String? = nil,
        systemImageName: String? = nil
    ) {
        guard !links.isEmpty else { return }
        if links.count == 1, let link = links.first {
            buttons.append(
                AnyView(
                    LinkButtonView(
                        link: link,
                        title: title,
                        imageName: imageName,
                        systemImageName: systemImageName
                    ) {
                        selectedLink = link
                    }
                )
            )
        } else {
            buttons.append(
                AnyView(
                    MultiLinkButtonView(
                        title: title,
                        links: links,
                        imageName: imageName,
                        systemImageName: systemImageName,
                        showFullURL: showFullURL,
                        showingActionSheet: $showingActionSheet,
                        selectedLinks: $selectedLinks
                    )
                )
            )
        }
    }
    
    private func extractDomain(from url: URL) -> String {
        let absoluteString = url.absoluteString
        if absoluteString.contains("github") {
            return absoluteString.replacingOccurrences(of: "https://", with: "")
        } else {
            let domain = url.host ?? absoluteString
            return domain.replacingOccurrences(of: "www.", with: "")
        }
    }
}

// MARK: - LinkButtonView
struct LinkButtonView: View {
    let link: IdentifiableLink
    let title: String?
    let imageName: String?
    let systemImageName: String?
    let action: () -> Void
    
    init(
        link: IdentifiableLink,
        title: String? = nil,
        imageName: String? = nil,
        systemImageName: String? = nil,
        action: @escaping () -> Void
    ) {
        self.link = link
        self.title = title
        self.imageName = imageName
        self.systemImageName = systemImageName
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            LinkButtonContent(
                title: title,
                imageName: imageName,
                systemImageName: systemImageName
            )
        }
    }
}

// MARK: - MultiLinkButtonView
struct MultiLinkButtonView: View {
    let title: String
    let links: [IdentifiableLink]
    let imageName: String?
    let systemImageName: String?
    let showFullURL: Bool
    
    @Binding var showingActionSheet: Bool
    @Binding var selectedLinks: [IdentifiableLink]
    
    init(
        title: String,
        links: [IdentifiableLink],
        imageName: String? = nil,
        systemImageName: String? = nil,
        showFullURL: Bool = false,
        showingActionSheet: Binding<Bool>,
        selectedLinks: Binding<[IdentifiableLink]>
    ) {
        self.title = title
        self.links = links
        self.imageName = imageName
        self.systemImageName = systemImageName
        self.showFullURL = showFullURL
        self._showingActionSheet = showingActionSheet
        self._selectedLinks = selectedLinks
    }
    
    var body: some View {
        Button {
            selectedLinks = links
            showingActionSheet = true
        } label: {
            LinkButtonContent(
                title: title,
                imageName: imageName,
                systemImageName: systemImageName
            )
        }
    }
}

// MARK: - LinkButtonContent
struct LinkButtonContent: View {
    let title: String?
    let imageName: String?
    let systemImageName: String?
    
    var body: some View {
        HStack(spacing: 4) {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            } else if let systemImageName {
                Image(systemName: systemImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            if let title {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .if(UIDevice.current.isSmallScreen) { view in
                        view.minimumScaleFactor(0.85)
                    }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, (title.isNil) ? 8 : 12)
        .padding(.vertical, 8)
        .background(Color.obsidianGray)
        .cornerRadius(16)
        .fixedSize()
    }
}

// MARK: - FlowLayout
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if currentX + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
