//
//  SettingsView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var setting = Setting.shared
    @State private var editingCommand: Event?

    var body: some View {
        TabView {
            assignmentsView
                .tabItem { Label("Assignments", systemImage: "hand.pinch") }
            commandsView
                .tabItem { Label("Commands", systemImage: "command") }
        }
        .padding(20)
        .frame(width: 700, height: 590)
        .sheet(item: $editingCommand) { command in
            CommandEditor(command: command) {
                setting.updateCommand($0)
            }
        }
    }

    private var assignmentsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsHeader(
                title: "Gesture Actions",
                subtitle: "Assign a built-in action or one of your commands to each gesture."
            )
            Divider()
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(HandGestureState.assignableGestures) { gesture in
                        GestureAssignmentRow(
                            gesture: gesture,
                            commands: setting.availableCommands,
                            selectedActionID: binding(for: gesture)
                        )
                        if gesture != HandGestureState.assignableGestures.last {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
            Divider()
            HStack {
                Text("Changes are saved automatically.")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Restore Defaults") { setting.resetToDefaults() }
            }
        }
    }

    private var commandsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                SettingsHeader(
                    title: "Command Builder",
                    subtitle: "Combine actions in order, then assign the command to a gesture."
                )
                Spacer()
                Button {
                    editingCommand = Event.newCommand()
                } label: {
                    Label("New Command", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            Divider()

            if setting.customCommands.isEmpty {
                ContentUnavailableView(
                    "No Commands",
                    systemImage: "command",
                    description: Text("Create a command by combining clicks, text, shortcuts, and waits.")
                )
            } else {
                List {
                    ForEach(setting.customCommands) { command in
                        Button {
                            editingCommand = command
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: command.symbolName)
                                    .frame(width: 24)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(command.displayName)
                                        .fontWeight(.medium)
                                    Text(command.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: setting.deleteCommands)
                }
            }
        }
    }

    private func binding(for gesture: HandGestureState) -> Binding<String> {
        Binding {
            setting.action(for: gesture)?.id ?? GestureAssignmentRow.noneActionID
        } set: { actionID in
            setting.setAction(setting.availableCommands.first { $0.id == actionID }, for: gesture)
        }
    }
}

private struct SettingsHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.title2).fontWeight(.semibold)
            Text(subtitle).foregroundStyle(.secondary)
        }
    }
}

private struct GestureAssignmentRow: View {
    static let noneActionID = "none"

    let gesture: HandGestureState
    let commands: [Event]
    let selectedActionID: Binding<String>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: gesture.symbolName)
                .font(.title3)
                .frame(width: 26)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(gesture.displayName).fontWeight(.medium)
                Text(gesture.description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 24)
            Picker("Action", selection: selectedActionID) {
                Text("None").tag(Self.noneActionID)
                Section("Built-in") {
                    ForEach(Event.builtIns) { command in
                        Label(command.displayName, systemImage: command.symbolName).tag(command.id)
                    }
                }
                if commands.count > Event.builtIns.count {
                    Section("My Commands") {
                        ForEach(commands.filter { command in
                            !Event.builtIns.contains { $0.id == command.id }
                        }) { command in
                            Label(command.displayName, systemImage: command.symbolName).tag(command.id)
                        }
                    }
                }
            }
            .labelsHidden()
            .frame(width: 210)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
    }
}

private struct CommandEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var command: Event
    let onSave: (Event) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Command").font(.title2).fontWeight(.semibold)
            TextField("Command name", text: $command.displayName)
            Divider()

            List {
                ForEach($command.steps) { $step in
                    CommandStepRow(step: $step)
                }
                .onDelete { command.steps.remove(atOffsets: $0) }
                .onMove { command.steps.move(fromOffsets: $0, toOffset: $1) }
            }
            .frame(minHeight: 280)

            HStack {
                Menu {
                    ForEach(CommandStep.Kind.allCases) { kind in
                        Button(kind.displayName) {
                            command.steps.append(CommandStep(kind: kind))
                        }
                    }
                } label: {
                    Label("Add Action", systemImage: "plus")
                }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    command.displayName = command.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if command.displayName.isEmpty { command.displayName = "Untitled Command" }
                    onSave(command)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 620, height: 470)
    }
}

private struct CommandStepRow: View {
    @Binding var step: CommandStep

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
            Picker("Action", selection: $step.kind) {
                ForEach(CommandStep.Kind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .frame(width: 170)

            switch step.kind {
            case .typeText:
                TextField("Text to type", text: $step.value)
            case .shortcut:
                TextField("command+shift+p", text: $step.value)
            case .wait:
                TextField("Seconds", text: $step.value)
                    .frame(width: 100)
                Text("seconds").foregroundStyle(.secondary)
            case .leftClick, .rightClick, .doubleClick:
                Text(step.kind.displayName).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
