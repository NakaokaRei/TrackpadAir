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

    private static let assignmentStorageKey = "gestureActionAssignments"
    private static let commandStorageKey = "customGestureCommands"
    private static let noneValue = "__none__"

    private let userDefaults: UserDefaults

    @Published private(set) var assignments: [HandGestureState: String] {
        didSet { saveAssignments() }
    }

    @Published private(set) var customCommands: [Event] {
        didSet { saveCommands() }
    }

    var availableCommands: [Event] {
        Event.builtIns + customCommands
    }

    init(userDefaults: UserDefaults = .standard) {
        let loadedCommands = Self.loadCommands(userDefaults: userDefaults)
        self.userDefaults = userDefaults
        self.customCommands = loadedCommands
        self.assignments = Self.loadAssignments(
            userDefaults: userDefaults,
            validCommandIDs: Set(Event.builtIns.map(\.id) + loadedCommands.map(\.id))
        )
    }

    static var defaultAssignments: [HandGestureState: String] {
        var assignments = Dictionary(
            uniqueKeysWithValues: HandGestureState.assignableGestures.map { ($0, noneValue) }
        )
        assignments[.indexPinch] = Event.moveMouse.id
        assignments[.middlePinch] = Event.leftClick.id
        assignments[.indexMiddlePinch] = Event.scroll.id
        return assignments
    }

    func action(for gesture: HandGestureState) -> Event? {
        guard gesture != .none,
              let commandID = assignments[gesture],
              commandID != Self.noneValue else {
            return nil
        }
        return availableCommands.first { $0.id == commandID }
    }

    func setAction(_ action: Event?, for gesture: HandGestureState) {
        guard HandGestureState.assignableGestures.contains(gesture) else { return }
        assignments[gesture] = action?.id ?? Self.noneValue
    }

    func addCommand() -> Event {
        let command = Event.newCommand()
        customCommands.append(command)
        return command
    }

    func updateCommand(_ command: Event) {
        if let index = customCommands.firstIndex(where: { $0.id == command.id }) {
            customCommands[index] = command
        } else {
            customCommands.append(command)
        }
    }

    func deleteCommands(at offsets: IndexSet) {
        let deletedIDs = Set(offsets.map { customCommands[$0].id })
        for index in offsets.sorted(by: >) {
            customCommands.remove(at: index)
        }

        for gesture in HandGestureState.assignableGestures {
            guard let commandID = assignments[gesture],
                  deletedIDs.contains(commandID) else {
                continue
            }
            assignments[gesture] = Self.noneValue
        }
    }

    func resetToDefaults() {
        assignments = Self.defaultAssignments
    }

    private static func loadCommands(userDefaults: UserDefaults) -> [Event] {
        guard let data = userDefaults.data(forKey: commandStorageKey),
              let commands = try? JSONDecoder().decode([Event].self, from: data) else {
            return []
        }
        return commands.filter { $0.behavior == .sequence }
    }

    private static func loadAssignments(
        userDefaults: UserDefaults,
        validCommandIDs: Set<String>
    ) -> [HandGestureState: String] {
        guard let storedAssignments = userDefaults.dictionary(forKey: assignmentStorageKey) as? [String: String] else {
            return defaultAssignments
        }

        var assignments = defaultAssignments
        for (gestureID, commandID) in storedAssignments {
            guard let gesture = HandGestureState(rawValue: gestureID),
                  HandGestureState.assignableGestures.contains(gesture),
                  commandID == noneValue || validCommandIDs.contains(commandID) else {
                continue
            }
            assignments[gesture] = commandID
        }
        return assignments
    }

    private func saveAssignments() {
        let storedAssignments = assignments.reduce(into: [String: String]()) { result, item in
            let (gesture, commandID) = item
            guard HandGestureState.assignableGestures.contains(gesture) else { return }
            result[gesture.rawValue] = commandID
        }
        userDefaults.set(storedAssignments, forKey: Self.assignmentStorageKey)
    }

    private func saveCommands() {
        guard let data = try? JSONEncoder().encode(customCommands) else { return }
        userDefaults.set(data, forKey: Self.commandStorageKey)
    }
}
