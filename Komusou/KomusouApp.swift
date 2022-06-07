//
//  KomusouApp.swift
//  Komusou
//
//  Created by gurrium on 2022/03/05.
//

import Combine
import SwiftUI

// TODO:
// - Mac対応
// - i18n

@main
struct KomusouApp: App {
    static let bluetoothSpeedSensor = BluetoothSpeedSensor()
    static let mockSpeedSensor = MockSpeedSensor()
    static let bluetoothCadenceSensor = BluetoothCadenceSensor()
    static let mockCadenceSensor = MockCadenceSensor()

    @UIApplicationDelegateAdaptor
    private var appDelegate: AppDelegate
    @State
    private var isSettingsPresented = false
    @State
    private var isBluetoothEnabled = true
    @State
    private var speed = 0.0
    private var speedSensor: SpeedSensor {
        isBluetoothEnabled ? Self.bluetoothSpeedSensor : Self.mockSpeedSensor
    }
    @State
    private var cadence = 0
    private var cadenceSensor: CadenceSensor {
        isBluetoothEnabled ? Self.bluetoothCadenceSensor : Self.mockCadenceSensor
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .topLeading) {
                        WorldView(speed: speed, cadence: cadence)
                            .edgesIgnoringSafeArea(.all)
                        InfoPanelView(speed: speed, cadence: cadence)
                            .padding([.top, .leading])
                    }
                    .onReceive(speedSensor.speed.compactMap { $0 }) { speed in
                        self.speed = speed
                    }
                    .onReceive(cadenceSensor.cadence.compactMap { $0 }) { cadence in
                        self.cadence = cadence
                    }
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                            .resizable()
                            .padding(8)
                            .frame(width: 44, height: 44)
                            .foregroundColor(.black)
                    }
                }
                .alert("Bluetoothを有効にしてください", isPresented: .constant(!isBluetoothEnabled)) {
                    Button("設定画面を開く") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                    .keyboardShortcut(.defaultAction)
                } message: {}
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView()
                }
            }.onReceive(BluetoothManager.shared().$isBluetoothEnabled) { isBluetoothEnabled in
                self.isBluetoothEnabled = isBluetoothEnabled
            }
        }
    }
}

final class MockSpeedSensor: SpeedSensor {
    var speed: Published<Double?>.Publisher!
    @Published
    private var _speed: Double?

    init() {
        speed = $_speed

        DispatchQueue.global().async { [weak self] in
            self?.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let speed = Double((0...60).randomElement()!) / Double((1...60).randomElement()!)
            print("speed:", speed)
            self?._speed = speed

            self?.scheduleUpdate()
        }
    }
}

final class MockCadenceSensor: CadenceSensor {
    var cadence: Published<Int?>.Publisher!
    @Published
    private var _cadence: Int?

    init() {
        cadence = $_cadence

        DispatchQueue.global().async { [weak self] in
            self?.scheduleUpdate()
        }
    }

    private func scheduleUpdate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            let cadence = 90 + Int((-20...20).randomElement()!)
            print("cadence:", cadence)
            self?._cadence = cadence

            self?.scheduleUpdate()
        }
    }
}
