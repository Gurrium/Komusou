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

/// @mockable(modifiers: delegate = weak)
protocol CentralManager: AnyObject {
    var delegate: CBCentralManagerDelegate? { get set }
    var isScanning: Bool { get }
    var state: CBManagerState { get }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String: Any]?)
    func stopScan()
    func retrievePeripherals(withIdentifiers: [UUID]) -> [Peripheral]
    func connect(_ peripheral: Peripheral, options: [String: Any]?)
    func cancelPeripheralConnection(_ peripheral: Peripheral)
}

extension CBCentralManager: CentralManager {
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        retrievePeripherals(withIdentifiers: identifiers) as [CBPeripheral]
    }

    func connect(_ peripheral: Peripheral, options: [String: Any]?) {
        connect(peripheral as! CBPeripheral, options: options)
    }

    func cancelPeripheralConnection(_ peripheral: Peripheral) {
        cancelPeripheralConnection(peripheral as! CBPeripheral)
    }
}

/// @mockable(modifiers: delegate = weak)
protocol Peripheral: AnyObject {
    var name: String? { get }
    var identifier: UUID { get }
    var delegate: CBPeripheralDelegate? { get set }
    var services: [CBService]? { get }

    func discoverServices(_ serviceUUIDs: [CBUUID]?)
    func discoverCharacteristics(_: [CBUUID]?, for service: CBService)
    func setNotifyValue(_: Bool, for: CBCharacteristic)
}

extension CBPeripheral: Peripheral {}

protocol Service: AnyObject {
    var characteristics: [CBCharacteristic]? { get }
}

extension CBService: Service {}

protocol Characteristic: AnyObject {
    var value: Data? { get }
}

extension CBCharacteristic: Characteristic {}

protocol CentralManagerDelegate: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CentralManager)
    func centralManager(_ central: CentralManager, didDiscover peripheral: Peripheral, advertisementData: [String: Any], rssi RSSI: NSNumber)
    func centralManager(_: CentralManager, didConnect: Peripheral)
    func centralManager(_: CentralManager, didFailToConnect: Peripheral, error: Error?)
}

protocol PeripheralDelegate: CBPeripheralDelegate {
    func peripheral(_: Peripheral, didDiscoverServices _: Error?)
    func peripheral(_: Peripheral, didDiscoverCharacteristicsFor service: Service, error _: Error?)
    func peripheral(_: Peripheral, didUpdateValueFor characteristic: Characteristic, error _: Error?)
}

final class BluetoothManager: NSObject {
    struct ConnectingWithPeripheralError: Error {}
    typealias ConnectingWithPeripheralFuture = Future<Void, ConnectingWithPeripheralError>

    private static var sharedBluetoothManager: BluetoothManager!

    static func shared() -> BluetoothManager {
        precondition(sharedBluetoothManager != nil, "Must call setUp(centralManager:) before use")

        return sharedBluetoothManager
    }

    static func setUp(centralManager: CentralManager) {
        sharedBluetoothManager = .init(centralManager: centralManager)
    }

    @Published
    private(set) var isBluetoothEnabled = false
    @Published
    private(set) var sensorNames = [UUID: String]()

    // MARK: Speed

    @Published
    private(set) var speed: Double?
    @Published
    private(set) var connectedSpeedSensor: Peripheral?
    private var previousWheelEventTime: UInt16?
    private var previousCumulativeWheelRevolutions: UInt32?
    private var speedMeasurementPauseCounter = 0 {
        didSet {
            if speedMeasurementPauseCounter > 2 {
                speed = 0
            }
        }
    }
    @AppStorage(UserDefaultsKey.tireSize.rawValue)
    private var tireSize: TireSize = .standard(.iso25_622)
    @AppStorage(UserDefaultsKey.savedSpeedSensorUUID.rawValue)
    private var savedSpeedSensorUUID: UUID?
    private var connectingSpeedSensorUUID: UUID?
    private var speedSensorPromise: ConnectingWithPeripheralFuture.Promise?

    // MARK: Cadence

    @Published
    private(set) var cadence: Int?
    @Published
    private(set) var connectedCadenceSensor: Peripheral?
    private var previousCrankEventTime: UInt16?
    private var previousCumulativeCrankRevolutions: UInt16?
    private var cadenceMeasurementPauseCounter = 0 {
        didSet {
            if cadenceMeasurementPauseCounter > 2 {
                cadence = 0
            }
        }
    }
    @AppStorage(UserDefaultsKey.savedCadenceSensorUUID.rawValue)
    private var savedCadenceSensorUUID: UUID?
    private var connectingCadenceSensorUUID: UUID?
    private var cadenceSensorPromise: ConnectingWithPeripheralFuture.Promise?

    private let centralManager: CentralManager
    private var cancellables = Set<AnyCancellable>()
    private var scannedSensors = [UUID: Peripheral]() {
        didSet {
            scannedSensors.forEach { key, value in
                sensorNames[key] = value.name!
            }
        }
    }

    init(centralManager: CentralManager) {
        self.centralManager = centralManager

        super.init()

        self.centralManager.delegate = self

        if let savedSpeedSensorUUID = savedSpeedSensorUUID,
           let speedSensor = self.centralManager.retrievePeripherals(withIdentifiers: [savedSpeedSensorUUID]).first
        {
            connectToSpeedSensor(speedSensor)
        }
        if let savedCadenceSensorUUID = savedCadenceSensorUUID,
           let cadenceSensor = self.centralManager.retrievePeripherals(withIdentifiers: [savedCadenceSensorUUID]).first
        {
            connectToCadenceSensor(cadenceSensor)
        }

        $connectedSpeedSensor.sink { [unowned self] sensor in
            self.savedSpeedSensorUUID = sensor?.identifier
        }
        .store(in: &cancellables)
        $connectedCadenceSensor.sink { [unowned self] sensor in
            self.savedCadenceSensorUUID = sensor?.identifier
        }
        .store(in: &cancellables)
    }

    deinit {
        if let connectedSpeedSensor = connectedSpeedSensor {
            centralManager.cancelPeripheralConnection(connectedSpeedSensor)
        }
        if let connectedCadenceSensor = connectedCadenceSensor {
            centralManager.cancelPeripheralConnection(connectedCadenceSensor)
        }

        stopScan()
    }

    func scanForSensors() {
        guard isBluetoothEnabled, !centralManager.isScanning else { return }

        // TODO: デバッグが終わったら self.centralManager.scanForPeripherals(withServices: [.cyclingSpeedAndCadence], options: nil) にする
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    func stopScan() {
        scannedSensors.removeAll()
        centralManager.stopScan()
    }

    func connectToSpeedSensor(uuid: UUID) -> ConnectingWithPeripheralFuture {
        guard let peripheral = scannedSensors[uuid] else {
            return .init { $0(.failure(.init())) }
        }

        return .init { [weak self] promise in
            self?.speedSensorPromise = promise

            self?.connectToSpeedSensor(peripheral)
        }
    }

    private func connectToSpeedSensor(_ speedSensor: Peripheral) {
        if let speedSensor = connectedSpeedSensor {
            centralManager.cancelPeripheralConnection(speedSensor)
        }

        connectingSpeedSensorUUID = speedSensor.identifier
        centralManager.connect(speedSensor, options: nil)
    }

    func connectToCadenceSensor(uuid: UUID) -> ConnectingWithPeripheralFuture {
        guard let peripheral = scannedSensors[uuid] else {
            return .init { $0(.failure(.init())) }
        }

        return .init { [weak self] promise in
            self?.cadenceSensorPromise = promise

            self?.connectToCadenceSensor(peripheral)
        }
    }

    private func connectToCadenceSensor(_ cadenceSensor: Peripheral) {
        if let cadenceSensor = connectedCadenceSensor {
            centralManager.cancelPeripheralConnection(cadenceSensor)
        }

        connectingCadenceSensorUUID = cadenceSensor.identifier
        centralManager.connect(cadenceSensor, options: nil)
    }

    func cancelConnection(_ peripheral: Peripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

extension BluetoothManager: CentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CentralManager) {
        isBluetoothEnabled = central.state == .poweredOn
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralManagerDidUpdateState(central as CentralManager)
    }

    func centralManager(_: CentralManager, didDiscover peripheral: Peripheral, advertisementData _: [String: Any], rssi _: NSNumber) {
        guard peripheral.name != nil else { return }

        scannedSensors[peripheral.identifier] = peripheral
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        centralManager(central as CentralManager, didDiscover: peripheral as Peripheral, advertisementData: advertisementData, rssi: RSSI)
    }

    func centralManager(_: CentralManager, didConnect peripheral: Peripheral) {
        switch peripheral.identifier {
        case connectingSpeedSensorUUID:
            connectingSpeedSensorUUID = nil
            connectedSpeedSensor = peripheral
            speedSensorPromise?(.success(()))

            peripheral.delegate = self
            peripheral.discoverServices([.cyclingSpeedAndCadence])
        case connectingCadenceSensorUUID:
            connectingCadenceSensorUUID = nil
            connectedCadenceSensor = peripheral
            cadenceSensorPromise?(.success(()))

            peripheral.delegate = self
            peripheral.discoverServices([.cyclingSpeedAndCadence])
        default:
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager(central as CentralManager, didConnect: peripheral as Peripheral)
    }

    func centralManager(_: CentralManager, didFailToConnect peripheral: Peripheral, error _: Error?) {
        switch peripheral.identifier {
        case connectingSpeedSensorUUID:
            connectingSpeedSensorUUID = nil
            speedSensorPromise?(.failure(.init()))
        case connectingCadenceSensorUUID:
            connectingCadenceSensorUUID = nil
            cadenceSensorPromise?(.failure(.init()))
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        centralManager(central as CentralManager, didFailToConnect: peripheral as Peripheral, error: error)
    }

    func centralManager(_: CentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error _: Error?) {
        if connectedSpeedSensor?.identifier == peripheral.identifier {
            connectedSpeedSensor = nil
        } else if connectedCadenceSensor?.identifier == peripheral.identifier {
            connectedCadenceSensor = nil
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        centralManager(central as CentralManager, didDisconnectPeripheral: peripheral, error: error)
    }
}

extension BluetoothManager: PeripheralDelegate {
    func peripheral(_ peripheral: Peripheral, didDiscoverServices _: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == .cyclingSpeedAndCadence }) else { return }

        peripheral.discoverCharacteristics([.cscMeasurement], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.peripheral(peripheral as Peripheral, didDiscoverServices: error)
    }

    func peripheral(_ peripheral: Peripheral, didDiscoverCharacteristicsFor service: Service, error _: Error?) {
        guard let characteristic = service.characteristics?.first(where: { $0.uuid == .cscMeasurement }),
              characteristic.properties.contains(.notify) else { return }

        peripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.peripheral(peripheral as Peripheral, didDiscoverCharacteristicsFor: service, error: error)
    }

    func peripheral(_: Peripheral, didUpdateValueFor characteristic: Characteristic, error _: Error?) {
        guard let data = characteristic.value else { return }

        let value = [UInt8](data)
        guard (value[0] & 0b0010) > 0 else { return }

        // ref: https://www.bluetooth.com/specifications/specs/gatt-specification-supplement-5/
        if let retrieved = calculateSpeed(from: value) {
            speedMeasurementPauseCounter = 0

            speed = retrieved
        } else if let retrieved = parseCadence(from: value) {
            cadenceMeasurementPauseCounter = 0

            cadence = retrieved
        } else {
            speedMeasurementPauseCounter += 1
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.peripheral(peripheral as Peripheral, didUpdateValueFor: characteristic, error: error)
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

    private func parseCadence(from value: [UInt8]) -> Int? {
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

        return Int((Double(cumulativeCrankRevolutions - previousCumulativeCrankRevolutions) * 60) / (Double(duration) / 1024))
    }
}
