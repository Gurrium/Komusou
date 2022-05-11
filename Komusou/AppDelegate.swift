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
        BluetoothManager.setUp(centralManager: CBCentralManager())

        return true
    }
}
