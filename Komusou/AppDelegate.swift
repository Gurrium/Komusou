//
//  AppDelegate.swift
//  Komusou
//
//  Created by gurrium on 2022/05/11.
//

import CoreBluetooth
import Foundation
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let centralManager: CentralManager
        #if DEBUG
            centralManager = CentralManagerMock()
        #else
            centralManager = CBCentralManager()
        #endif

        BluetoothManager.setUp(centralManager: centralManager)

        #if DEBUG
            (centralManager as! CentralManagerMock).state = .poweredOn
            BluetoothManager.shared().centralManagerDidUpdateState(centralManager)
        #endif

        return true
    }
}
