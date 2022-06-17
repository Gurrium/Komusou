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
    @State
    private var isSpeedSensorSheetPresented = false
    @State
    private var connectedSpeedSensor: Peripheral?
    @State
    private var isCadenceSensorSheetPresented = false
    @State
    private var connectedCadenceSensor: Peripheral?
    @State
    private var isBluetoothEnabled = true
    @StateObject
    private var state = ViewState()

    // TODO: 実装する
    private class ViewState: ObservableObject {
        private var cancellables = Set<AnyCancellable>()

        func connectToSpeedSensor(uuid: UUID) {
            BluetoothManager.shared().connectToSpeedSensor(uuid: uuid).sink { [unowned self] result in
                switch result {
                case .failure:
                    // failure
                case .finished:
                    // finished
                }
            } receiveValue: { _ in }
                .store(in: &cancellables)
        }

        func connectToCadenceSensor(uuid: UUID) {
            BluetoothManager.shared().connectedCadenceSensor(uuid: uuid).sink { [unowned self] result in
                switch result {
                case .failure:
                    // failure
                case .finished:
                    // finished
                }
            } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    var body: some View {
        List {
            SensorRow(
                isSheetPresented: $isSpeedSensorSheetPresented,
                sensorType: "スピードセンサー",
                sensorName: connectedSpeedSensor?.name ?? "未接続"
            ) {
                SensorSelectingView(
                    isSheetPresented: $isSpeedSensorSheetPresented,
                    connectedSensor: BluetoothManager.shared().connectedSpeedSensor,
                    didSelectSensor: state.connectToSpeedSensor
                )
            }
            SensorRow(
                isSheetPresented: $isCadenceSensorSheetPresented,
                sensorType: "ケイデンスセンサー",
                sensorName: connectedCadenceSensor?.name ?? "未接続"
            ) {
                SensorSelectingView(
                    isSheetPresented: $isCadenceSensorSheetPresented,
                    connectedSensor: BluetoothManager.shared().connectedCadenceSensor,
                    didSelectSensor: state.connectToCadenceSensor
                )
            }
        }
        .listStyle(.insetGrouped)
        .alertForDisabledBluetooth(isBluetoothDisabled: .constant(!isBluetoothEnabled))
        .onReceive(BluetoothManager.shared().$connectedSpeedSensor) { speedSensor in
            self.connectedSpeedSensor = speedSensor
        }
        .onReceive(BluetoothManager.shared().$connectedCadenceSensor) { cadenceSensor in
            self.connectedCadenceSensor = cadenceSensor
        }
        .onReceive(BluetoothManager.shared().$isBluetoothEnabled) { isBluetoothEnabled in
            self.isBluetoothEnabled = isBluetoothEnabled
        }
    }

    private struct SensorRow<Content: View>: View {
        @Binding
        var isSheetPresented: Bool
        let sensorType: String
        let sensorName: String
        @ViewBuilder
        let sheetContent: () -> Content

        var body: some View {
            Button {
                isSheetPresented = true
            } label: {
                HStack {
                    Text(sensorType)
                    Spacer()
                    Text(sensorName)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $isSheetPresented, content: sheetContent)
            .tint(.primary)
        }
    }
}

struct SensorSelectingView: View {
    @State
    private var sensorNames = [UUID: String]()
    @Binding
    private var isSheetPresented: Binding<Bool>
    private var didSelectSensor: (UUID) -> Void
    private var connectedSensor: Peripheral?

    init(isSheetPresented: Binding<Bool>, connectedSensor: Peripheral?, didSelectSensor: @escaping (UUID) -> Void) {
        self.isSheetPresented = isSheetPresented
        self.connectedSensor = connectedSensor
        self.didSelectSensor = didSelectSensor
    }

    var body: some View {
        List {
            if let connectedSensor = connectedSensor {
                Section {
                    Button {
                        BluetoothManager.shared().cancelConnection(connectedSensor)
                    } label: {
                        Text("切断する")
                            .foregroundColor(.blue)
                    }
                }
            }
            Section {
                if !sensorNames.isEmpty {
                    ForEach(Array(sensorNames.keys), id: \.self) { key in
                        let sensorName = sensorNames[key]!
                        Button {
                            self.didSelectSensor(key)
                        } label: {
                            HStack {
                                Text(sensorName)
                                Spacer()
                                if let connectedSensor = connectedSensor,
                                   key == connectedSensor.identifier
                                {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
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
        .onReceive(BluetoothManager.shared().$sensorNames) {
            sensorNames = $0
        }
        .onAppear(perform: BluetoothManager.shared().scanForSensors)
        .onDisappear(perform: BluetoothManager.shared().stopScan)
    }
}

struct SensorSettingView_Previews: PreviewProvider {
    static var previews: some View {
        SensorSelectingView(
            isSheetPresented: .constant(true),
            connectedSensor: nil,
            didSelectSensor: { _ in }
        )
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
