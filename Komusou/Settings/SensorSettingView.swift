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
                SensorSelectingView()
//                SensorSelectingView(didError: $state.didError, didSelectSensor: state.connectToSpeedSensor(uuid:))
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

// struct SensorSelectingView: View {
//    @ObservedObject
//    private var state = SensorSelectingViewState()
//    private var didSelectSensor: (UUID) -> Void
//    @Binding
//    private var didError: Bool
//
//    init(didError: Binding<Bool>, didSelectSensor: @escaping (UUID) -> Void) {
//        _didError = didError
//        self.didSelectSensor = didSelectSensor
//    }
//
//    var body: some View {
//        List {
//            Section {
//                if !state.sensors.isEmpty {
//                    ForEach(state.sensors, id: \.0) { item in
//                        Button {
//                            didSelectSensor(item.0)
//                        } label: {
//                            Text(item.1)
//                        }
//                    }
//                }
//            } header: {
//                HStack(spacing: 8) {
//                    Text("センサー")
//                    ProgressView()
//                }
//            }
//        }
//        .listStyle(.insetGrouped)
//        .alert("接続に失敗しました", isPresented: $didError) {}
//        .onAppear(perform: state.startScanningSensors)
//        .onDisappear(perform: state.stopScanningSensors)
//    }
// }
//
// final class SensorSelectingViewState: ObservableObject {
//    @Published
//    var sensors: [(UUID, String)] = []
//
//    private var cancellables = Set<AnyCancellable>()
//
//    init() {
//        BluetoothManager.shared.$discoveredPeripherals.map { peripherals in
//            peripherals.compactMap { peripheral in
//                guard let name = peripheral.value.name else { return nil }
//
//                return (peripheral.key, name)
//            }
//        }.assign(to: &$sensors)
//    }
//
//    func startScanningSensors() {
//        BluetoothManager.shared.startScanningSensors()
//    }
//
//    func stopScanningSensors() {
//        BluetoothManager.shared.stopScanningSensors()
//    }
// }

struct SensorSelectingView: View {
    @State
    var sensorNames = [UUID: String]()

    var body: some View {
        List {
            Section {
                if !sensorNames.isEmpty {
                    ForEach(Array(sensorNames.keys), id: \.self) { key in
                        let sensorName = sensorNames[key]!
                        Button {
                            print(sensorName)
                        } label: {
                            Text(sensorName)
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
        .onReceive(BluetoothManager.shared.$discoveredNamedPeripheralNames) {
            sensorNames = $0
        }
        .onAppear(perform: BluetoothManager.shared.startScanningSensors)
        .onDisappear(perform: BluetoothManager.shared.stopScanningSensors)
    }
}

struct SensorSettingView_Previews: PreviewProvider {
    static var previews: some View {
//        SensorSettingView()
        SensorSelectingView()
            .previewLayout(.sizeThatFits)
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
