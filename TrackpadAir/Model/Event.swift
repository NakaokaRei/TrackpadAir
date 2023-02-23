//
//  Event.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/23.
//

import Foundation

enum Event {
    case moveMouse
    case leftClick
    case scroll

    var displayName: String {
        switch self {
        case .moveMouse:
            return "Move Mouse"
        case .leftClick:
            return "Left Click"
        case .scroll:
            return "Scroll"
        }
    }
}
