//
//  KomusouApp.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import Combine
import SwiftUI

// TODO:
// - Mac対応
// - i18n

@main
struct KomusouApp: App {
    @UIApplicationDelegateAdaptor
    private var appDelegate: AppDelegate
    @State
    private var isBluetoothEnabled = BluetoothManager.shared().isBluetoothEnabled

    static let speedSensor: SpeedSensor = BluetoothSpeedSensor()
    static let cadenceSensor = MockCadenceSensor()

    var body: some Scene {
        WindowGroup {
            Group {
                if isBluetoothEnabled {
                    PlayView()
                } else {
                    VStack(spacing: 16) {
                        Text("Bluetoothを有効にしてください")
                        Button("設定画面を開く") {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }
                    }
                }
            }
            .onReceive(BluetoothManager.shared().$isBluetoothEnabled) { isBluetoothEnabled in
                self.isBluetoothEnabled = isBluetoothEnabled
            }
        }
    }
}

final class MockSpeedSensor: SpeedSensor {
    var speed: Published<Double?>.Publisher!
    @Published
    private var _speed: Double?

    init() {
        speed = $_speed

        DispatchQueue.global().async { [weak self] in
            self?.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let speed = Double((0...60).randomElement()!) / Double((1...60).randomElement()!)
            print(speed)
            self?._speed = speed

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
