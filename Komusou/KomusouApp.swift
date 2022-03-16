//
//  KomusouApp.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import SwiftUI

@main
struct KomusouApp: App {
    static let speedSensor = MockSpeedSensor()

    var body: some Scene {
        WindowGroup {
            PlayView()
        }
    }
}

final class MockSpeedSensor: SpeedSensor {
    var delegate: SpeedSensorDelegate?

    init() {
        DispatchQueue.global().async { [weak self] in
            self?.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let speed = 2 * Double.pi / Double((1...4).randomElement()!)
            print(speed)
            self?.delegate?.onSpeedUpdate(speed)

            self?.scheduleUpdate()
        }
    }
}
