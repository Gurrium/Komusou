//
//  KomusouApp.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import SwiftUI

// TODO:
// - CBCentralManagerが1つしか使えなさそうなので修正する
// - Mac対応
// - Bluetoothが有効にされていないときの対応

@main
struct KomusouApp: App {
    static let speedSensor = BluetoothSpeedSensor()
    static let cadenceSensor = BluetoothCadenceSensor()

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
            let speed = Double((0...60).randomElement()!) / Double((1...60).randomElement()!)
            print(speed)
            self?.delegate?.onSpeedUpdate(speed)

            self?.scheduleUpdate()
        }
    }
}

final class MockCadenceSensor: CadenceSensor {
    var delegate: CadenceSensorDelegate?

    init() {
        DispatchQueue.global().async { [weak self] in
            self?.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let cadence = 90 + Double((-20...20).randomElement()!)
            print(cadence)
            self?.delegate?.onCadenceUpdate(cadence)

            self?.scheduleUpdate()
        }
    }
}
