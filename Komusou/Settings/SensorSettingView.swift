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

// TODO: モックできるようにする
final class BluetoothManager: NSObject {
    struct ConnectingWithPeripheralError: Error {}
    typealias ConnectingWithPeripheralFuture = Future<Void, ConnectingWithPeripheralError>

    static let shared = BluetoothManager()
    private static let kSpeedSensorKey = "speed_sensor_key"

    @Published
    private(set) var discoveredPeripherals = [UUID: CBPeripheral]()

    // MARK: Speed

    @Published
    private(set) var speedData: [UInt8]?
    @Published
    private(set) var connectedSpeedSensor: CBPeripheral?
    private var connectedSpeedSensorUUID: UUID? {
        get {
            if let uuid = _connectedSpeedSensorUUID { return uuid }

            let retrieved = UUID(uuidString: userDefaults.string(forKey: Self.kSpeedSensorKey) ?? "")
            _connectedSpeedSensorUUID = retrieved

            return retrieved
        }
        set {
            _connectedSpeedSensorUUID = newValue

            if let newValue = newValue {
                userDefaults.set(newValue.uuidString, forKey: Self.kSpeedSensorKey)
            } else {
                userDefaults.removeObject(forKey: Self.kSpeedSensorKey)
            }
        }
    }
    private var _connectedSpeedSensorUUID: UUID?
    private var connectingSpeedSensorUUID: UUID?
    private var speedSensorPromise: ConnectingWithPeripheralFuture.Promise?

    private let centralManager = CBCentralManager()
    private let userDefaults = UserDefaults.standard

    private var isBluetoothEnabled: Bool {
        centralManager.state == .poweredOn
    }
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()

        // TODO: 起動時の処理
        // Bluetoothの許可の確認
        // 以前接続したセンサーに接続する

        centralManager.delegate = self
        $connectedSpeedSensor.sink { [unowned self] sensor in
            self.connectedSpeedSensorUUID = sensor?.identifier
        }
        .store(in: &cancellables)
    }

    deinit {
        // TODO: disconnect
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

extension BluetoothManager: CBPeripheralDelegate {}
