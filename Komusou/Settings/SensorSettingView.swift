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

    var body: some View {
        List {
            SensorRow(
                isSheetPresented: $isSpeedSensorSheetPresented,
                sensorType: "スピードセンサー",
                sensorName: connectedSpeedSensor?.name ?? "未接続"
            ) {
                SensorSelectingView(isSheetPresented: $isSpeedSensorSheetPresented, connectedSensor: BluetoothManager.shared().connectedSpeedSensor)
            }
            SensorRow(
                isSheetPresented: $isCadenceSensorSheetPresented,
                sensorType: "ケイデンスセンサー",
                sensorName: connectedCadenceSensor?.name ?? "未接続"
            ) {
                SensorSelectingView(isSheetPresented: $isCadenceSensorSheetPresented, connectedSensor: BluetoothManager.shared().connectedCadenceSensor)
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
    @ObservedObject
    private var state: SensorSelectingViewState
    @State
    private var sensorNames = [UUID: String]()
    private var connectedSensor: Peripheral?

    init(isSheetPresented: Binding<Bool>, connectedSensor: Peripheral?) {
        state = .init(isSheetPresented: isSheetPresented)
        self.connectedSensor = connectedSensor
    }

    var body: some View {
        List {
            if let connectedSensor = connectedSensor {
                Section {
                    Button {
                        state.cnacelConnection(connectedSensor)
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
                            state.connectToSpeedSensor(uuid: key)
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
        .alert("接続に失敗しました", isPresented: $state.didError) {}
        .onReceive(BluetoothManager.shared().$sensorNames) {
            sensorNames = $0
        }
        .onAppear(perform: BluetoothManager.shared().scanForSensors)
        .onDisappear(perform: BluetoothManager.shared().stopScan)
    }
}

class SensorSelectingViewState: ObservableObject {
    @Published
    var didError = false
    @Binding
    var isSheetPresented: Bool

    private var cancellables = Set<AnyCancellable>()

    init(isSheetPresented: Binding<Bool>) {
        _isSheetPresented = isSheetPresented
    }

    func connectToSpeedSensor(uuid: UUID) {
        BluetoothManager.shared().connectToSpeedSensor(uuid: uuid).sink { [unowned self] result in
            switch result {
            case .failure:
                self.didError = true
            case .finished:
                self.isSheetPresented = false
            }
        } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func cnacelConnection(_ peripheral: Peripheral) {
        BluetoothManager.shared().cancelConnection(peripheral)
    }
}

struct SensorSettingView_Previews: PreviewProvider {
    static var previews: some View {
        SensorSelectingView(isSheetPresented: .constant(false), connectedSensor: nil)
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
