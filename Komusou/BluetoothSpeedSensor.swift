//
//  BluetoothSpeedSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/16.
//

import Combine
import CoreBluetooth
import Foundation

final class BluetoothSpeedSensor: SpeedSensor {
    var speed: Published<Double?>.Publisher!
    @Published
    private var _speed: Double?

    init() {
        speed = $_speed
        BluetoothManager.shared().$speed.assign(to: &$_speed)
    }
}
