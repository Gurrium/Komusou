//
//  BluetoothManagerTest.swift
//  KomusouTests
//
//  Created by gurrium on 2022/04/20.
//

import Combine
import CoreBluetooth
@testable import Komusou
import XCTest

class BluetoothManagerMock: CBCentralManagerRequirement {
    var delegate: CBCentralManagerDelegate?

    var isScanning: Bool

    func connect(_ peripheral: CBPeripheral, options: [String : Any]?) {
        <#code#>
    }

    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        <#code#>
    }

    func stopScan() {
        <#code#>
    }

    func retrievePeripherals(withIdentifiers: [UUID]) -> [CBPeripheral] {
        <#code#>
    }

    func cancelPeripheralConnection(_ identifier: CBPeripheral) {
        <#code#>
    }
}

class BluetoothManagerTest: XCTestCase {
    var manager: BluetoothManager!
    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        manager = BluetoothManager(centralManager: <#T##CBCentralManagerRequirement#>)
    }

    override func tearDown() {
        cancellables = Set<AnyCancellable>()
    }

    func test_見つかったBluetoothデバイスが一覧できる() {
        let expectedKeys = [UUID]()
        let exp = expectation(description: "キーの配列が期待したものと同じであることがテストされる")

        XCTAssertEqual([1, 2, 3], [1, 2, 3])
        XCTAssertEqual([1, 2, 3], [1, 3, 2])

        manager.$discoveredPeripherals
            .map { Array($0.keys) }
            .sink { actualKeys in
                XCTAssertEqual(actualKeys, expectedKeys)
                exp.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.5)
    }

//    func test_初期化時に前回接続したセンサーと接続する() {
//        var identifier: UUID!
//
//        let connectingExp = expectation(description: "センサーに接続できる")
//        manager.scanSensors()
//            .first()
//            .handleEvents(receiveOutput: { uuid in
//                identifier = uuid
//            })
//            .flatMap { uuid in
//                manager.connectToSpeedSensor(uuid: uuid)
//            }
//            .sink { result in
//                switch result {
//                case .finished:
//                    connectingExp.fulfill()
//                default:
//                    break
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//        wait(for: [connectingExp], timeout: 0.5)
//
//        XCTAssertEqual(manager.connectedSpeedSensor?.identifier, identifier)
//    }
}
