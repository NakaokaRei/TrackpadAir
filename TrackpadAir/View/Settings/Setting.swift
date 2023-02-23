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
    @Published var setting: String = "Setting"
}
