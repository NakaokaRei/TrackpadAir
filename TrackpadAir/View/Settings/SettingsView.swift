//
//  SettingsView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

struct SettingsView: View {
    @State private var selectedTabIndex = 0

    var body: some View {
        TabView(selection: $selectedTabIndex) {
            GeneralSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("General")
                }
                .tag(0)
            NotificationsSettingsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
                .tag(1)
            PrivacySettingsView()
                .tabItem {
                    Image(systemName: "lock")
                    Text("Privacy")
                }
                .tag(2)
        }
        .padding(20)
        .frame(width: 500, height: 375)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        Text("General Settings")
    }
}

struct NotificationsSettingsView: View {
    var body: some View {
        Text("Notifications Settings")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
    }
}
