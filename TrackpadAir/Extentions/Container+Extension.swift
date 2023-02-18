//
//  Container+Extension.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/18.
//

import Foundation
import Factory

extension Container {
    @MainActor
    static let featureConfig = Factory(scope: .singleton) { FeatureConfig() }
}

