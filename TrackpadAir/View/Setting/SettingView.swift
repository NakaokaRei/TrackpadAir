//
//  SettingView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI

import Foundation
import SwiftUI

struct SettingsView: View {

    private enum Tabs: Hashable {
        case general
        case hand
    }

    var body: some View {
        TabView {
            GeneralView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)

            HandSettingView()
                .tabItem {
                    Label("Hand", systemImage: "hand.raised")
                }
        }
        .padding(20)
        .frame(width: 500, height: 375)
    }
}
