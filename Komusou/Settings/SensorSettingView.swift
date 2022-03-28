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

    @AppStorage("speed_sensor_uuid")
    private var speedSensorUUIDString: String?

    private var speedSensorName: String {
        guard let string = speedSensorUUIDString,
              let uuid = UUID(uuidString: string),
              let peripheral = BluetoothManager.shared.connectedPeripherals[uuid],
              let name = peripheral.name else {
            return ""
        }

        return name
    }

    var body: some View {
        List {
            Row(
                isSheetPresented: $isSpeedSensorSheetPresented,
                itemLabel: "スピードセンサー",
                valueLabel: speedSensorName
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

struct SensorSelectingView: View {
    @ObservedObject
    var state = SensorSelectingViewState()

    var body: some View {
        List {
            Section {
                if !state.items.isEmpty {
                    ForEach(state.items, id: \.0) { item in
                        Button {
                            state.saveSpeedSensor(uuid: item.0)
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
        .onAppear(perform: state.startScanningSensorsAfterBluetoothIsEnabled)
        .onDisappear(perform: state.stopScanningSensors)
    }
}

final class SensorSelectingViewState: ObservableObject {
    @Published
    var sensors = Set<CBPeripheral>()
    var items: [(UUID, String)] {
        sensors.compactMap { sensor in
            guard let name = sensor.name else { return nil }

            return (sensor.identifier, name)
        }
    }

    private var bluetoothManager = BluetoothManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        bluetoothManager.$discoveredPeripherals.assign(to: &$sensors)
    }

    func startScanningSensorsAfterBluetoothIsEnabled() {
        bluetoothManager.$isBluetoothEnabled
            .first(where: { $0 })
            .sink { [weak self] enabled in
                if enabled {
                    self?.bluetoothManager.startScanningSensors()
                }
            }
            .store(in: &cancellables)
    }

    func stopScanningSensors() {
        bluetoothManager.stopScanningSensors()
    }

    func saveSpeedSensor(uuid: UUID) {
        // TODO: 実装
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

    @Published
    private(set) var discoveredPeripherals = Set<CBPeripheral>()
    @Published
    private(set) var connectedPeripherals = [UUID: CBPeripheral]()
    @Published
    private(set) var isBluetoothEnabled = false

    private let centralManager = CBCentralManager()

    override init() {
        super.init()

        centralManager.delegate = self
    }

    func startScanningSensors() {
        centralManager.scanForPeripherals(withServices: [.cyclingSpeedAndCadence], options: nil)
    }

    func stopScanningSensors() {
        centralManager.stopScan()
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothEnabled = central.state == .poweredOn
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripherals.insert(peripheral)
    }
}

extension BluetoothManager: CBPeripheralDelegate {
}
