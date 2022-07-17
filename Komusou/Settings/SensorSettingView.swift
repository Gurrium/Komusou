//
//  SensorSettingView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/25.
//

import Combine
import SwiftUI

struct SensorSettingView: View {
    @State
    private var connectedSpeedSensor: Peripheral?
    @State
    private var connectedCadenceSensor: Peripheral?
    @StateObject
    private var state = ViewState()

    private class ViewState: ObservableObject {
        @Published
        var isSpeedSensorSheetPresented = false
        @Published
        var isCadenceSensorSheetPresented = false
        @Published
        var didError = false

        private var cancellables = Set<AnyCancellable>()

        func connectToSpeedSensor(uuid: UUID) {
            BluetoothManager.shared().connectToSpeedSensor(uuid: uuid).sink { [unowned self] result in
                switch result {
                case .failure:
                    self.didError = true
                case .finished:
                    isSpeedSensorSheetPresented = false
                }
            } receiveValue: { _ in }
                .store(in: &cancellables)
        }

        func connectToCadenceSensor(uuid: UUID) {
            BluetoothManager.shared().connectToCadenceSensor(uuid: uuid).sink { [unowned self] result in
                switch result {
                case .failure:
                    self.didError = true
                case .finished:
                    isCadenceSensorSheetPresented = false
                }
            } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    var body: some View {
        List {
            SensorRow(
                sensorType: "スピードセンサー",
                sensorName: connectedSpeedSensor?.name ?? "未接続",
                isSheetPresented: $state.isSpeedSensorSheetPresented
            ) {
                SensorSelectingView(
                    isSheetPresented: $state.isSpeedSensorSheetPresented,
                    connectedSensor: BluetoothManager.shared().connectedSpeedSensor,
                    didSelectSensor: state.connectToSpeedSensor
                )
            }
            SensorRow(
                sensorType: "ケイデンスセンサー",
                sensorName: connectedCadenceSensor?.name ?? "未接続",
                isSheetPresented: $state.isCadenceSensorSheetPresented
            ) {
                SensorSelectingView(
                    isSheetPresented: $state.isCadenceSensorSheetPresented,
                    connectedSensor: BluetoothManager.shared().connectedCadenceSensor,
                    didSelectSensor: state.connectToCadenceSensor
                )
            }
        }
        .listStyle(.insetGrouped)
        .alert("接続に失敗しました", isPresented: $state.didError) {}
        .onReceive(BluetoothManager.shared().$connectedSpeedSensor) { speedSensor in
            self.connectedSpeedSensor = speedSensor
        }
        .onReceive(BluetoothManager.shared().$connectedCadenceSensor) { cadenceSensor in
            self.connectedCadenceSensor = cadenceSensor
        }
    }

    private struct SensorRow<Content: View>: View {
        let sensorType: String
        let sensorName: String
        @ViewBuilder
        let sheetContent: () -> Content

        @Binding
        var isSheetPresented: Bool

        init(sensorType: String, sensorName: String, isSheetPresented: Binding<Bool>, sheetContent: @escaping () -> Content) {
            self.sensorType = sensorType
            self.sensorName = sensorName
            _isSheetPresented = isSheetPresented
            self.sheetContent = sheetContent
        }

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
    private var isSheetPresented: Bool
    private var connectedSensor: Peripheral?
    private var didSelectSensor: (UUID) -> Void

    init(isSheetPresented: Binding<Bool>, connectedSensor: Peripheral?, didSelectSensor: @escaping (UUID) -> Void) {
        _isSheetPresented = isSheetPresented
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
