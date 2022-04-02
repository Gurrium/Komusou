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
                SensorSelectingView(isSheetPresented: $isSpeedSensorSheetPresented) {
                    state.connectToSpeedSensor(uuid: $0)
                }
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

    func connectToSpeedSensor(uuid: UUID) {
        BluetoothManager.shared.connectToSpeedSensor(uuid: uuid)
    }
}

struct SensorSelectingView: View {
    @ObservedObject
    private var state = SensorSelectingViewState()
    @Binding
    private var isSheetPresented: Bool
    private var didSelectSensor: (UUID) -> Void

    init(isSheetPresented: Binding<Bool>, didSelectSensor: @escaping (UUID) -> Void) {
        _isSheetPresented = isSheetPresented
        self.didSelectSensor = didSelectSensor
    }

    var body: some View {
        List {
            Section {
                if !state.items.isEmpty {
                    ForEach(state.items, id: \.0) { item in
                        Button {
                            // TODO: 接続に成功したらsheetを閉じる
                            didSelectSensor(item.0)
                            isSheetPresented = false
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

    private var cancellables = Set<AnyCancellable>()

    init() {
        BluetoothManager.shared.$discoveredPeripherals.assign(to: &$sensors)
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
