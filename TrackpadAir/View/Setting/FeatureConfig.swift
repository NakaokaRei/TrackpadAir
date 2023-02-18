//
//  FeatureConfig.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import Combine

@MainActor
class FeatureConfig: ObservableObject {
    @Published var state: FeatureState = .hand
}

enum FeatureState: Hashable {
    case hand
    case other
}
