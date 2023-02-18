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
            ContentView()
        }
        Settings {
            SettingsView()
        }
    }
}
