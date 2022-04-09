//
//  SensorSettingView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/25.
//

import Combine
import CoreBluetooth
import SwiftUI

struct SensorSettingView: View {
    @ObservedObject
    private var state = SensorSettingViewState()

    var body: some View {
        List {
            Row(
                isSheetPresented: $state.isSpeedSensorSheetPresented,
                itemLabel: "スピードセンサー",
                valueLabel: state.speedSensorName
            ) {
                SensorSelectingView(didError: $state.didError, didSelectSensor: state.connectToSpeedSensor(uuid:))
            }
            // TODO: ケイデンスセンサー
        }
        .listStyle(.insetGrouped)
    }

    private struct Row<Content: View>: View {
        @Binding
        var isSheetPresented: Bool
        let itemLabel: String
        let valueLabel: String
        @ViewBuilder
        let sheetContent: () -> Content

        var body: some View {
            Button {
                isSheetPresented = true
            } label: {
                HStack {
                    Text(itemLabel)
                    Spacer()
                    Text(valueLabel)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $isSheetPresented, content: sheetContent)
            .tint(.primary)
        }
    }
}

final class SensorSettingViewState: ObservableObject {
    @Published
    private(set) var speedSensorName = ""
    @Published
    var isSpeedSensorSheetPresented = false
    @Published
    var didError = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        BluetoothManager.shared.$connectedSpeedSensor.map { $0?.name ?? "" }.assign(to: &$speedSensorName)
    }

    func connectToSpeedSensor(uuid: UUID) {
        BluetoothManager.shared.connectToSpeedSensor(uuid: uuid).sink { [unowned self] result in
            switch result {
            case .failure:
                self.didError = true
            case .finished:
                break
            }
        } receiveValue: { [unowned self] _ in
            self.isSpeedSensorSheetPresented = false
        }
        .store(in: &cancellables)
    }
}

struct SensorSelectingView: View {
    @ObservedObject
    private var state = SensorSelectingViewState()
    private var didSelectSensor: (UUID) -> Void
    @Binding
    private var didError: Bool

    init(didError: Binding<Bool>, didSelectSensor: @escaping (UUID) -> Void) {
        _didError = didError
        self.didSelectSensor = didSelectSensor
    }

    var body: some View {
        List {
            Section {
                if !state.sensors.isEmpty {
                    ForEach(state.sensors, id: \.0) { item in
                        Button {
                            didSelectSensor(item.0)
                        } label: {
                            Text(item.1)
                        }
                    }
                }
            } header: {
                HStack(spacing: 8) {
                    Text("センサー")
                    ProgressView()
                }
            }
        }
        .listStyle(.insetGrouped)
        .alert("接続に失敗しました", isPresented: $didError) {}
        .onAppear(perform: state.startScanningSensors)
        .onDisappear(perform: state.stopScanningSensors)
    }
}

final class SensorSelectingViewState: ObservableObject {
    @Published
    var sensors: [(UUID, String)] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        BluetoothManager.shared.$discoveredPeripherals.map { peripherals in
            peripherals.compactMap { peripheral in
                guard let name = peripheral.value.name else { return nil }

                return (peripheral.key, name)
            }
        }.assign(to: &$sensors)
    }

    func startScanningSensors() {
        BluetoothManager.shared.startScanningSensors()
    }

    func stopScanningSensors() {
        BluetoothManager.shared.stopScanningSensors()
    }
}

struct SensorSettingView_Previews: PreviewProvider {
    static var previews: some View {
        SensorSettingView()
    }
}

extension UUID: RawRepresentable {
    public init?(rawValue: String) {
        self.init(uuidString: rawValue)
    }

    public var rawValue: String {
        uuidString
    }
}

// TODO: モックできるようにする、別のファイルに移す
final class BluetoothManager: NSObject {
    struct ConnectingWithPeripheralError: Error {}
    typealias ConnectingWithPeripheralFuture = Future<Void, ConnectingWithPeripheralError>

    static let shared = BluetoothManager()
    private static let kSavedSpeedSensorUUIDKey = "speed_sensor_uuid_key"

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

    private let centralManager = CBCentralManager()
    private var isBluetoothEnabled: Bool {
        centralManager.state == .poweredOn
    }
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        // TODO: 起動時の処理
        // Bluetoothの許可の確認

        centralManager.delegate = self

        if let savedSpeedSensorUUID = savedSpeedSensorUUID,
           let speedSensor = centralManager.retrievePeripherals(withIdentifiers: [savedSpeedSensorUUID]).first
        {
            centralManager.connect(speedSensor)
        }
        // TODO: ケイデンスセンサー

        $connectedSpeedSensor.sink { [unowned self] sensor in
            self.savedSpeedSensorUUID = sensor?.identifier
        }
        .store(in: &cancellables)
    }

    deinit {
        // TODO: disconnect
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
        centralManager.connect(peripheral)

        return .init { [weak self] promise in
            self?.speedSensorPromise = promise
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_: CBCentralManager) {}

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
        if let retrieved = parseSpeed(from: value) {
            speedMeasurementPauseCounter = 0

            speed = retrieved
        } else {
            speedMeasurementPauseCounter += 1
        }
    }

    private func parseSpeed(from value: [UInt8]) -> Double? {
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
