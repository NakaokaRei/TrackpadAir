//
//  Event.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/23.
//

import Foundation

struct Event: Codable, Hashable, Identifiable {
    enum Behavior: String, Codable {
        case moveMouse
        case scroll
        case sequence
    }

    var id: String
    var displayName: String
    var symbolName: String
    var behavior: Behavior
    var steps: [CommandStep]

    var description: String {
        switch behavior {
        case .moveMouse:
            return "Move the pointer using the index finger delta."
        case .scroll:
            return "Scroll vertically or horizontally from finger movement."
        case .sequence:
            if steps.isEmpty {
                return "No actions"
            }
            return steps.map(\.summary).joined(separator: "  →  ")
        }
    }

    static let moveMouse = Event(
        id: "move_mouse",
        displayName: "Move Mouse",
        symbolName: "cursorarrow.motionlines",
        behavior: .moveMouse,
        steps: []
    )

    static let leftClick = Event(
        id: "left_click",
        displayName: "Left Click",
        symbolName: "cursorarrow.click",
        behavior: .sequence,
        steps: [.init(kind: .leftClick)]
    )

    static let scroll = Event(
        id: "scroll",
        displayName: "Scroll",
        symbolName: "arrow.up.and.down",
        behavior: .scroll,
        steps: []
    )

    static let builtIns = [moveMouse, leftClick, scroll]

    static func newCommand() -> Event {
        Event(
            id: UUID().uuidString,
            displayName: "New Command",
            symbolName: "command",
            behavior: .sequence,
            steps: [.init(kind: .leftClick)]
        )
    }
}

struct CommandStep: Codable, Hashable, Identifiable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case leftClick
        case rightClick
        case doubleClick
        case typeText
        case shortcut
        case wait

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .leftClick: return "Left Click"
            case .rightClick: return "Right Click"
            case .doubleClick: return "Double Click"
            case .typeText: return "Type Text"
            case .shortcut: return "Keyboard Shortcut"
            case .wait: return "Wait"
            }
        }
    }

    var id = UUID()
    var kind: Kind
    var value = ""

    var summary: String {
        switch kind {
        case .leftClick, .rightClick, .doubleClick:
            return kind.displayName
        case .typeText:
            return value.isEmpty ? "Type Text" : "Type “\(value)”"
        case .shortcut:
            return value.isEmpty ? "Keyboard Shortcut" : value
        case .wait:
            return "Wait \(Double(value) ?? 0) sec"
        }
    }
}
