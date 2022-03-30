//
//  SensorSettingView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/25.
//

import SwiftUI
import CoreBluetooth
import Combine

struct SensorSettingView: View {
    @State
    private var isSpeedSensorSheetPresented = false
    @ObservedObject
    private var state = SensorSettingViewState()

    var body: some View {
        List {
            Row(
                isSheetPresented: $isSpeedSensorSheetPresented,
                itemLabel: "スピードセンサー",
                valueLabel: state.speedSensorName
            ) {
                SensorSelectingView()
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

    private var cancellables = Set<AnyCancellable>()

    init() {
        BluetoothManager.shared.$speedSensor.sink { [weak self] peripheral in
            self?.speedSensorName = peripheral?.name ?? ""
        }
        .store(in: &cancellables)
    }
}

struct SensorSelectingView: View {
    @ObservedObject
    var state = SensorSelectingViewState()

    var body: some View {
        List {
            Section {
                if !state.items.isEmpty {
                    ForEach(state.items, id: \.0) { item in
                        Button {
                            state.connectToSpeedSensor(uuid: item.0)
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
        .onAppear(perform: state.startScanningSensors)
        .onDisappear(perform: state.stopScanningSensors)
    }
}

final class SensorSelectingViewState: ObservableObject {
    @Published
    private var sensors = [UUID: CBPeripheral]()
    var items: [(UUID, String)] {
        sensors.compactMap { record in
            guard let name = record.value.name else { return nil }

            return (record.key, name)
        }
    }

    private var bluetoothManager = BluetoothManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        bluetoothManager.$discoveredPeripherals.assign(to: &$sensors)
    }

    func startScanningSensors() {
        bluetoothManager.startScanningSensors()
    }

    func stopScanningSensors() {
        bluetoothManager.stopScanningSensors()
    }

    func connectToSpeedSensor(uuid: UUID) {
        bluetoothManager.connectToSpeedSensor(uuid: uuid)
    }
}

struct SensorSettingView_Previews: PreviewProvider {
    static var previews: some View {
        SensorSettingView()
        SensorSelectingView()
    }
}

final class BluetoothManager: NSObject {
    static let shared = BluetoothManager()
    static private let kSpeedSensorKey = "speed_sensor_key"

    @Published
    private(set) var discoveredPeripherals = [UUID: CBPeripheral]()
    @Published
    private(set) var speedSensor: CBPeripheral?

    private var speedSensorUUID: UUID? {
        get {
            if let uuid = _speedSensorUUID { return uuid }

            let retrieved = UUID(uuidString: userDefaults.string(forKey: Self.kSpeedSensorKey) ?? "")
            _speedSensorUUID = retrieved

            return retrieved
        }
        set {
            _speedSensorUUID = newValue

            if let newValue = newValue {
                userDefaults.set(newValue.uuidString, forKey: Self.kSpeedSensorKey)
            } else {
                userDefaults.removeObject(forKey: Self.kSpeedSensorKey)
            }
        }
    }
    private var _speedSensorUUID: UUID?
    @Published
    private var isBluetoothEnabled = false
    private var isScanningPeripherals = false
    private var cancellables = Set<AnyCancellable>()

    private let centralManager = CBCentralManager()
    private let userDefaults = UserDefaults.standard

    override init() {
        super.init()

        centralManager.delegate = self
    }

    func startScanningSensors() {
        guard !isScanningPeripherals else { return }
        isScanningPeripherals = true

        $isBluetoothEnabled
            .first(where: { $0 })
            .sink { [weak self] enabled in
                if enabled {
                    self?.centralManager.scanForPeripherals(withServices: nil, options: nil)
                }
            }
            .store(in: &cancellables)
    }

    func stopScanningSensors() {
        isScanningPeripherals = true

        centralManager.stopScan()
    }

    func connectToSpeedSensor(uuid: UUID) {
        guard let peripheral = discoveredPeripherals[uuid] else { return }

        speedSensorUUID = uuid
        centralManager.connect(peripheral)
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothEnabled = central.state == .poweredOn
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripherals[peripheral.identifier] = peripheral
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        switch peripheral.identifier {
        case speedSensorUUID:
            speedSensor = peripheral
        default:
            break
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate {
}
