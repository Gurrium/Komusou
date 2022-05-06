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
    let bluetoothManager: BluetoothManager
    var speed: Published<Double?>.Publisher!
    @Published
    private var _speed: Double?

    init(bluetoothManager: BluetoothManager) {
        self.bluetoothManager = bluetoothManager

        speed = $_speed
        bluetoothManager.$speed.assign(to: &$_speed)
    }
}
