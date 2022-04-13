//
//  KomusouApp.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import Combine
import SwiftUI

// TODO:
// - Reconnecting to Peripherals https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/BestPracticesForInteractingWithARemotePeripheralDevice/BestPracticesForInteractingWithARemotePeripheralDevice.html#//apple_ref/doc/uid/TP40013257-CH6-SW6
//   - ユーザがセンサーを選ぶ画面を作る → ユーザが選んだセンサーがあればそれに接続する ということをすればそれぞれのセンサーを扱うクラスを安全に分離できそう
// - Mac対応
// - Bluetoothが有効にされていないときの対応
// - i18n

@main
struct KomusouApp: App {
    static let speedSensor = MockSpeedSensor()
    static let cadenceSensor = MockCadenceSensor()

    var body: some Scene {
        WindowGroup {
            PlayView()
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
