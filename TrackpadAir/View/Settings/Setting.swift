//
//  Setting.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import Combine

@MainActor
class Setting: ObservableObject {
    static let shared = Setting()

    private static let storageKey = "gestureActionAssignments"
    private static let noneValue = "__none__"

    private let userDefaults: UserDefaults

    @Published private(set) var assignments: [HandGestureState: Event?] {
        didSet {
            saveAssignments()
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.assignments = Self.loadAssignments(userDefaults: userDefaults)
    }

    static var defaultAssignments: [HandGestureState: Event?] {
        var assignments = Dictionary(
            uniqueKeysWithValues: HandGestureState.assignableGestures.map { ($0, Optional<Event>.none) }
        )
        assignments[.indexPinch] = .moveMouse
        assignments[.middlePinch] = .leftClick
        assignments[.indexMiddlePinch] = .scroll
        return assignments
    }

    func action(for gesture: HandGestureState) -> Event? {
        guard gesture != .none else { return nil }
        return assignments[gesture] ?? nil
    }

    func setAction(_ action: Event?, for gesture: HandGestureState) {
        guard HandGestureState.assignableGestures.contains(gesture) else { return }
        assignments[gesture] = action
    }

    func resetToDefaults() {
        assignments = Self.defaultAssignments
    }

    private static func loadAssignments(userDefaults: UserDefaults) -> [HandGestureState: Event?] {
        guard let storedAssignments = userDefaults.dictionary(forKey: storageKey) as? [String: String] else {
            return defaultAssignments
        }

        var assignments = defaultAssignments

        for (gestureID, eventID) in storedAssignments {
            guard let gesture = HandGestureState(rawValue: gestureID),
                  HandGestureState.assignableGestures.contains(gesture) else {
                continue
            }

            if eventID == noneValue {
                assignments[gesture] = nil
            } else if let event = Event(rawValue: eventID) {
                assignments[gesture] = event
            }
        }

        return assignments
    }

    private func saveAssignments() {
        let storedAssignments = assignments.reduce(into: [String: String]()) { result, item in
            let (gesture, action) = item
            guard HandGestureState.assignableGestures.contains(gesture) else { return }
            result[gesture.rawValue] = action?.rawValue ?? Self.noneValue
        }

        userDefaults.set(storedAssignments, forKey: Self.storageKey)
    }
}
