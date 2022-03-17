//
//  BluetoothSpeedSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/16.
//

import Foundation
import CoreBluetooth

final class BluetoothSpeedSensor: NSObject, SpeedSensor {
    // SpeedSensor
    var delegate: SpeedSensorDelegate?

    // TODO: ケイデンスでも使うので一元管理する
    // TODO: 複数のCBCentralManagerを作ってもいいならこのまま
    private let centralManager = CBCentralManager()

    private var isBluetoothEnabled = false {
        didSet {
            if isBluetoothEnabled {
                centralManager.scanForPeripherals(withServices: [.cyclingSpeedAndCadence], options: nil)
            }
        }
    }
    private var connectedPeripheral: CBPeripheral?
    // speed measurement
    private var speed: Double = 0 {
        didSet {
            delegate?.onSpeedUpdate(speed)
        }
    }
    private var previousWheelEventTime: UInt16?
    private var previousCumulativeWheelRevolutions: UInt32?
    private var speedMeasurementPauseCounter = 0 {
        didSet {
            if speedMeasurementPauseCounter > 2 {
                speed = 0
            }
        }
    }

    override init() {
        super.init()

        centralManager.delegate = self
    }
}

extension BluetoothSpeedSensor: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothEnabled = central.state == .poweredOn
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // ここで参照を保持しないと破棄される
        connectedPeripheral = peripheral
        
        peripheral.delegate = self
        peripheral.discoverServices([.cyclingSpeedAndCadence])
    }
}

extension BluetoothSpeedSensor: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == .cyclingSpeedAndCadence }) else { return }

        peripheral.discoverCharacteristics([.cscMeasurement], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == .cscMeasurement}),
              characteristic.properties.contains(.notify) else { return }

        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }

        let value = [UInt8](data)
        guard (value[0] & 0b0001) > 0 else { return }

        // ref: https://www.bluetooth.com/specifications/specs/gatt-specification-supplement-5/
        if let retrieved = parseSpeed(from: value) {
            speedMeasurementPauseCounter = 0

            speed = retrieved
        } else {
            speedMeasurementPauseCounter += 1
        }
    }

    private func parseSpeed(from value: [UInt8]) -> Double? {
        precondition(value[0] & 0b0001 > 0, "Wheel Revolution Data Present Flag is not set")

        guard let wheelCircumference = delegate?.wheelCircumference else { return nil }

        let cumulativeWheelRevolutions = (UInt32(value[4]) << 24) + (UInt32(value[3]) << 16) + (UInt32(value[2]) << 8) + UInt32(value[1])
        let wheelEventTime = (UInt16(value[6]) << 8) + UInt16(value[5])

        defer {
            previousCumulativeWheelRevolutions = cumulativeWheelRevolutions
            previousWheelEventTime = wheelEventTime
        }

        guard let previousCumulativeWheelRevolutions = previousCumulativeWheelRevolutions,
              let previousWheelEventTime = previousWheelEventTime else { return nil }

        let duration: UInt16

        if previousWheelEventTime > wheelEventTime {
            duration = UInt16((UInt32(wheelEventTime) + UInt32(UInt16.max) + 1) - UInt32(previousWheelEventTime))
        } else {
            duration = wheelEventTime - previousWheelEventTime
        }

        guard duration > 0 else { return nil }

        let revolutionsPerSec = Double(cumulativeWheelRevolutions - previousCumulativeWheelRevolutions) / (Double(duration) / 1024)

        return revolutionsPerSec * Double(wheelCircumference) * 3600 / 1_000_000 // [km/h]
    }
}
