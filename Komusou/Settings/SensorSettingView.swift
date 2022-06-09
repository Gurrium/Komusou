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
    private var speedSensorName: String?
    @State
    private var isCadenceSensorSheetPresented = false
    @State
    private var cadenceSensorName: String?
    @State
    private var isBluetoothEnabled = true

    var body: some View {
        List {
            SensorRow(
                isSheetPresented: $isSpeedSensorSheetPresented,
                sensorType: "スピードセンサー",
                sensorName: speedSensorName ?? "未接続"
            ) {
                SensorSelectingView(isSheetPresented: $isSpeedSensorSheetPresented)
            }
            SensorRow(
                isSheetPresented: $isCadenceSensorSheetPresented,
                sensorType: "ケイデンスセンサー",
                sensorName: cadenceSensorName ?? "未接続"
            ) {
                SensorSelectingView(isSheetPresented: $isCadenceSensorSheetPresented)
            }
        }
        .listStyle(.insetGrouped)
        .alert("Bluetoothを有効にしてください", isPresented: .constant(!isBluetoothEnabled)) {
            Button("設定画面を開く") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            .keyboardShortcut(.defaultAction)
        } message: {}
        .onReceive(BluetoothManager.shared().$connectedSpeedSensor.map { $0?.name }) { speedSensorName in
            self.speedSensorName = speedSensorName
        }
        .onReceive(BluetoothManager.shared().$connectedCadenceSensor.map { $0?.name }) { cadenceSensorName in
            self.cadenceSensorName = cadenceSensorName
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

    init(isSheetPresented: Binding<Bool>) {
        state = .init(isSheetPresented: isSheetPresented)
    }

    var body: some View {
        List {
            Section {
                if !sensorNames.isEmpty {
                    ForEach(Array(sensorNames.keys), id: \.self) { key in
                        let sensorName = sensorNames[key]!
                        Button {
                            state.connectToSpeedSensor(uuid: key)
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
}

struct SensorSettingView_Previews: PreviewProvider {
    static var previews: some View {
        SensorSelectingView(isSheetPresented: .constant(false))
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
