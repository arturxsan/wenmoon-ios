//
//  IdentifiableLink.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 04.04.25.
//

import Foundation

struct IdentifiableLink: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}
