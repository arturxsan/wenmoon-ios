//
//  Data+Extensions.swift
//  WenMoon
//
//  Created by Artur Tkachenko on 12.03.25.
//

import Foundation

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
