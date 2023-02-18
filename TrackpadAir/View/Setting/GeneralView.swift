//
//  GeneralView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import SwiftUI
import Factory

struct GeneralView: View {

    @StateObject private var featureConfig = Container.featureConfig()

    var body: some View {
        Picker(selection: $featureConfig.state, label: Text("Feature")) {
            Text("Hand").tag(FeatureState.hand)
            Text("Othre").tag(FeatureState.other)
        }
        .pickerStyle(.radioGroup)
    }
}

struct GeneralView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralView()
    }
}
