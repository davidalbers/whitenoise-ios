//
//  WidgetUpdater.swift
//  White Noise
//
//  Created by David Albers on 10/25/20.
//  Copyright © 2020 David Albers. All rights reserved.
//

import Foundation
import WidgetKit

class WidgetUpdater {
    public func update() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.getCurrentConfigurations { result in
                guard case .success(let widgets) = result else { return }
                if let widget = widgets.first(
                    where: { widget in
                        if let intent = widget.configuration as? PlayIntent {
                            let intentParser = IntentParser(intent: intent)
                            if intentParser.playForIntentIfNeeded() {
                                return false
                            }
                            return true
                        }
                        return false
                    }
                ) {
                    WidgetCenter.shared.reloadTimelines(ofKind: widget.kind)
                }
            }
        }
    }
}
