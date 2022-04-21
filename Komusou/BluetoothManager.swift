//
//  BluetoothManager.swift
//  Komusou
//
//  Created by gurrium on 2022/04/19.
//

import Combine
import CoreBluetooth
import Foundation
import struct SwiftUI.AppStorage

protocol CBCentralManagerRequirement: AnyObject {
    var delegate: CBCentralManagerDelegate? { get set }
    var isScanning: Bool { get }

    func connect(_ peripheral: CBPeripheral, options: [String: Any]?)
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
    func retrievePeripherals(withIdentifiers: [UUID]) -> [CBPeripheral]
    func cancelPeripheralConnection(_ identifier: CBPeripheral)
}

extension CBCentralManager: CBCentralManagerRequirement {}

// TODO: テストしたい
// TODO: Bluetooth部分をモックできるようにする?
final class BluetoothManager: NSObject {
    struct ConnectingWithPeripheralError: Error {}
    typealias ConnectingWithPeripheralFuture = Future<Void, ConnectingWithPeripheralError>

    static let shared = BluetoothManager(centralManager: CBCentralManager())
    private static let kSavedSpeedSensorUUIDKey = "speed_sensor_uuid_key"

    @Published
    private(set) var isBluetoothEnabled = false
    @Published
    private(set) var discoveredPeripherals = [UUID: CBPeripheral]()

    // MARK: Speed

    @Published
    private(set) var speed: Double?
    @Published
    private(set) var connectedSpeedSensor: CBPeripheral?
    private var previousWheelEventTime: UInt16?
    private var previousCumulativeWheelRevolutions: UInt32?
    private var speedMeasurementPauseCounter = 0 {
        didSet {
            if speedMeasurementPauseCounter > 2 {
                speed = 0
            }
        }
    }
    @AppStorage(kTireSizeKey)
    var tireSize: TireSize = .standard(.iso25_622)
    @AppStorage(kSavedSpeedSensorUUIDKey)
    private var savedSpeedSensorUUID: UUID?
    private var connectingSpeedSensorUUID: UUID?
    private var speedSensorPromise: ConnectingWithPeripheralFuture.Promise?

    private let centralManager: CBCentralManagerRequirement
    private var cancellables = Set<AnyCancellable>()

    init(centralManager: CBCentralManagerRequirement) {
        self.centralManager = centralManager

        super.init()

        self.centralManager.delegate = self

        if let savedSpeedSensorUUID = savedSpeedSensorUUID,
           let speedSensor = self.centralManager.retrievePeripherals(withIdentifiers: [savedSpeedSensorUUID]).first
        {
            self.centralManager.connect(speedSensor, options: nil)
        }
        // TODO: ケイデンスセンサー

        $connectedSpeedSensor.sink { [unowned self] sensor in
            self.savedSpeedSensorUUID = sensor?.identifier
        }
        .store(in: &cancellables)
    }

    deinit {
        // TODO:
        // ケイデンスセンサーもやる
        guard let connectedSpeedSensor = connectedSpeedSensor else { return }

        centralManager.cancelPeripheralConnection(connectedSpeedSensor)
    }

    func startScanningSensors() {
        guard isBluetoothEnabled, !centralManager.isScanning else { return }

        // TODO: デバッグが終わったら self.centralManager.scanForPeripherals(withServices: [.cyclingSpeedAndCadence], options: nil) にする
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScanningSensors() {
        discoveredPeripherals.removeAll()
        centralManager.stopScan()
    }

    func connectToSpeedSensor(uuid: UUID) -> ConnectingWithPeripheralFuture {
        guard let peripheral = discoveredPeripherals[uuid] else {
            return .init { $0(.failure(.init())) }
        }

        if let speedSensor = connectedSpeedSensor {
            centralManager.cancelPeripheralConnection(speedSensor)
        }
        connectingSpeedSensorUUID = uuid
        centralManager.connect(peripheral, options: nil)

        return .init { [weak self] promise in
            self?.speedSensorPromise = promise
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothEnabled = central.state == .poweredOn
    }

    func centralManager(_: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
        discoveredPeripherals[peripheral.identifier] = peripheral
    }

    func centralManager(_: CBCentralManager, didConnect peripheral: CBPeripheral) {
        switch peripheral.identifier {
        case connectingSpeedSensorUUID:
            connectingSpeedSensorUUID = nil
            connectedSpeedSensor = peripheral
            speedSensorPromise?(.success(()))

            peripheral.delegate = self
            peripheral.discoverServices([.cyclingSpeedAndCadence])
        default:
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func centralManager(_: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error _: Error?) {
        switch peripheral.identifier {
        case connectingSpeedSensorUUID:
            connectingSpeedSensorUUID = nil
            speedSensorPromise?(.failure(.init()))
        default:
            break
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
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
        if let retrieved = calculateSpeed(from: value) {
            speedMeasurementPauseCounter = 0

            speed = retrieved
        } else {
            speedMeasurementPauseCounter += 1
        }
    }

    private func calculateSpeed(from value: [UInt8]) -> Double? {
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

        return revolutionsPerSec * Double(tireSize.circumference) * 3600 / 1_000_000 // [km/h]
    }
}
