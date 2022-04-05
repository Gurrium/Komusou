//
//  BluetoothCadenceSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/17.
//

import CoreBluetooth
import Foundation

final class BluetoothCadenceSensor: NSObject, CadenceSensor {
    // CadenceSensor
    var delegate: CadenceSensorDelegate?

    // TODO: スピードでも使うので一元管理する
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
    private var cadence: Double = 0 {
        didSet {
            delegate?.onCadenceUpdate(cadence)
        }
    }

    private var previousCrankEventTime: UInt16?
    private var previousCumulativeCrankRevolutions: UInt16?
    private var cadenceMeasurementPauseCounter = 0 {
        didSet {
            if cadenceMeasurementPauseCounter > 2 {
                cadence = 0
            }
        }
    }

    override init() {
        super.init()

        centralManager.delegate = self
    }
}

extension BluetoothCadenceSensor: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothEnabled = central.state == .poweredOn
    }

    func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
        // ここで参照を保持しないと破棄される
        connectedPeripheral = peripheral

        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([.cyclingSpeedAndCadence])
    }
}

extension BluetoothCadenceSensor: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices _: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == .cyclingSpeedAndCadence }) else { return }

        peripheral.discoverCharacteristics([.cscMeasurement], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error _: Error?) {
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == .cscMeasurement }),
              characteristic.properties.contains(.notify) else { return }

        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error _: Error?) {
        guard let data = characteristic.value else { return }

        let value = [UInt8](data)
        guard (value[0] & 0b0010) > 0 else { return }

        // ref: https://www.bluetooth.com/specifications/specs/gatt-specification-supplement-5/
        if let retrieved = parseCadence(from: value) {
            cadenceMeasurementPauseCounter = 0

            cadence = retrieved
        } else {
            cadenceMeasurementPauseCounter += 1
        }
    }

    private func parseCadence(from value: [UInt8]) -> Double? {
        precondition(value[0] & 0b0010 > 0, "Crank Revolution Data Present Flag is not set")

        let cumulativeCrankRevolutions = (UInt16(value[2]) << 8) + UInt16(value[1])
        let crankEventTime = (UInt16(value[4]) << 8) + UInt16(value[3])

        defer {
            previousCumulativeCrankRevolutions = cumulativeCrankRevolutions
            previousCrankEventTime = crankEventTime
        }

        guard let previousCumulativeCrankRevolutions = previousCumulativeCrankRevolutions,
              let previousCrankEventTime = previousCrankEventTime else { return nil }

        let duration: UInt16

        if previousCrankEventTime > crankEventTime {
            duration = UInt16((UInt32(crankEventTime) + UInt32(UInt16.max) + 1) - UInt32(previousCrankEventTime))
        } else {
            duration = crankEventTime - previousCrankEventTime
        }

        guard duration > 0 else { return nil }

        return (Double(cumulativeCrankRevolutions - previousCumulativeCrankRevolutions) * 60) / (Double(duration) / 1024)
    }
}
