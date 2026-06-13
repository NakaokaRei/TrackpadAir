//
//  TrackpadAirApp.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Cocoa
import SwiftUI

@main
struct TrackpadAirApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            HandGestureView()
        }

        MenuBarExtra {
            Label("Running", systemImage: "checkmark.circle.fill")

            Divider()

            SettingsLink {
                Label("Settings...", systemImage: "gearshape")
            }

            Divider()

            Button("Quit TrackpadAir", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image("StatusBar-icon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 18, height: 18)
                .accessibilityLabel("TrackpadAir")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}
