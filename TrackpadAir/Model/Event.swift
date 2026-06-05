//
//  Event.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/23.
//

import Foundation

enum Event: String, CaseIterable, Identifiable {
    case moveMouse = "move_mouse"
    case leftClick = "left_click"
    case scroll = "scroll"

    var id: String {
        rawValue
    }

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

    var symbolName: String {
        switch self {
        case .moveMouse:
            return "cursorarrow.motionlines"
        case .leftClick:
            return "cursorarrow.click"
        case .scroll:
            return "arrow.up.and.down"
        }
    }

    var description: String {
        switch self {
        case .moveMouse:
            return "Move the pointer using the index finger delta."
        case .leftClick:
            return "Perform a left mouse click."
        case .scroll:
            return "Scroll vertically or horizontally from finger movement."
        }
    }
}
