//
//  SensorSettingView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/25.
//

import SwiftUI

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
        NavigationView {
            List {
                Row(isSheetPresented: $isSpeedSensorSheetPresented, itemLabel: "スピードセンサー", valueLabel: speedSensorName) {
                    Text("Speed Sensor")
                }
                Row(isSheetPresented: $isCadenceSensorSheetPresented, itemLabel: "ケイデンスセンサー", valueLabel: cadenceSensorName) {
                    Text("Cadence Sensor")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("センサー")
        }
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

struct SensorSettingView_Previews: PreviewProvider {
    static var previews: some View {
        SensorSettingView()
    }
}
