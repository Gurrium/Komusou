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
    var isSpeedSensorSheetPresented = false
    @AppStorage("speedSensorName")
    var speedSensorName: String = ""
    @State
    var isCadenceSensorSheetPresented = false
    @AppStorage("speedSensorName")
    var cadenceSensorName: String = ""

    var body: some View {
        List {
            Row(isSheetPresented: $isSpeedSensorSheetPresented, itemLabel: "スピードセンサー", valueLabel: speedSensorName) {
                // TODO: 空表示
                SensorSelectingView()
            }
            Row(isSheetPresented: $isCadenceSensorSheetPresented, itemLabel: "ケイデンスセンサー", valueLabel: cadenceSensorName) {
                Text("Cadence Sensor")
            }
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
        let items: [(UUID, String)] = state.sensors.compactMap { sensor in
            guard let name = sensor.name else { return nil }

            return (sensor.identifier, name)
        }

        List {
            Section {
                if !items.isEmpty {
                    ForEach(items, id: \.0) { item in
                        Text(item.1)
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

    private var bluetoothManager = BluetoothManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        bluetoothManager.$discoveredPeripherals.assign(to: &$sensors)
    }

    func startScanningSensorsAfterBluetoothIsEnabled() {
        bluetoothManager.$isBluetoothEnabled.first(where: { $0 }).sink { [weak self] enabled in
            if enabled {
                self?.bluetoothManager.startScanningSensors()
            }
        }
        .store(in: &cancellables)
    }

    func stopScanningSensors() {
        bluetoothManager.stopScanningSensors()
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
