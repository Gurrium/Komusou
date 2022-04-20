//
//  BluetoothManagerTest.swift
//  KomusouTests
//
//  Created by gurrium on 2022/04/20.
//

import XCTest
@testable import Komusou
import Combine

class BluetoothManagerTest: XCTestCase {
    func test_初期化時に前回接続したセンサーと接続する() {
        var manager = BluetoothManager(centralManager: <#T##CBCentralManager#>)
        var cancellables = Set<AnyCancellable>()
        var identifier: UUID!

        let connectingExp = expectation(description: "センサーに接続できる")
        PassthroughSubject<UUID, Never>()
            .handleEvents(receiveOutput: { uuid in
                identifier = uuid
            })
            .flatMap { uuid in
                manager.connectToSpeedSensor(uuid: uuid)
            }
            .sink { result in
                switch result {
                case .finished:
                    connectingExp.fulfill()
                default:
                    break
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
        wait(for: [connectingExp], timeout: 0.5)

        manager = BluetoothManager()
        XCTAssertEqual(manager.connectedSpeedSensor?.identifier, identifier)
    }
}
