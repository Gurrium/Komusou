//
//  BluetoothCadenceSensor.swift
//  Komusou
//
//  Created by gurrium on 2022/03/17.
//

import Combine

final class BluetoothCadenceSensor: CadenceSensor {
    private(set) var cadence: Published<Int?>.Publisher!
    @Published
    private var _cadence: Int?

    init() {
        cadence = $_cadence
        BluetoothManager.shared().$cadence.assign(to: &$_cadence)
    }
}
