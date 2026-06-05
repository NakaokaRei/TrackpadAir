//
//  SettingsView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var setting = Setting.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            Divider()
            gestureAssignments
            Divider()
            footer
        }
        .padding(24)
        .frame(width: 620, height: 520)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gesture Actions")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Assign an action to each recognized pinch gesture.")
                .foregroundStyle(.secondary)
        }
    }

    private var gestureAssignments: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(HandGestureState.assignableGestures) { gesture in
                    GestureAssignmentRow(
                        gesture: gesture,
                        selectedActionID: binding(for: gesture)
                    )

                    if gesture != HandGestureState.assignableGestures.last {
                        Divider()
                            .padding(.leading, 40)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Changes are saved automatically.")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Restore Defaults") {
                setting.resetToDefaults()
            }
        }
    }

    private func binding(for gesture: HandGestureState) -> Binding<String> {
        Binding {
            setting.action(for: gesture)?.rawValue ?? GestureAssignmentRow.noneActionID
        } set: { actionID in
            setting.setAction(Event(rawValue: actionID), for: gesture)
        }
    }
}

private struct GestureAssignmentRow: View {
    static let noneActionID = "none"

    let gesture: HandGestureState
    let selectedActionID: Binding<String>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: gesture.symbolName)
                .font(.title3)
                .frame(width: 26)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(gesture.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(gesture.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 24)

            Picker("Action", selection: selectedActionID) {
                Text("None").tag(Self.noneActionID)
                ForEach(Event.allCases) { event in
                    Label(event.displayName, systemImage: event.symbolName)
                        .tag(event.rawValue)
                }
            }
            .labelsHidden()
            .frame(width: 180)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
    }
}
