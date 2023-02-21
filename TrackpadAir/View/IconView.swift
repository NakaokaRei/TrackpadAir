//
//  IconView.swift
//  TrackpadAir
//
//  Created by NakaokaRei on 2023/02/22.
//

import Cocoa

class IconView: NSView {

    var icon: NSImage?

    init(_ icon: NSImage, _ size: CGSize) {
        super.init(frame: NSRect(x: 0.5 * (size.width - 18.0),
                                 y: 0.5 * (size.height - 18.0),
                                 width: 18.0, height: 18.0))
        self.icon = icon
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        icon?.draw(in: NSRect(x: 0.0, y: 0.0, width: 18.0, height: 18.0))
    }

}
