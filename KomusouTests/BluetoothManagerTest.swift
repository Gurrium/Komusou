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

class CBCentralManagerMock: CBCentralManagerRequirement {
    var delegate: CBCentralManagerDelegate?
    var isScanning = false

    private var peripheralNames: [UUID: String]

    init(peripheralNames: [UUID: String]) {
        self.peripheralNames = peripheralNames
    }

    func scanForPeripherals(withServices _: [CBUUID]?, options _: [String: Any]?) {
        isScanning = true
    }

    func stopScan() {
        isScanning = false
    }

    func retrievePeripherals(withIdentifiers _: [UUID]) -> [CBPeripheral] {
        []
    }

    func connect(_: CBPeripheral, options _: [String: Any]?) {
        // nop
    }

    func cancelPeripheralConnection(_: CBPeripheral) {
        // nop
    }
}

class BluetoothManagerTest: XCTestCase {
//    var manager: BluetoothManager!
    var cancellables = Set<AnyCancellable>()

//    override func setUp() {
//        manager = BluetoothManager(centralManager: CBCentralManagerMock())
//    }

    override func tearDown() {
        cancellables = Set<AnyCancellable>()
    }

    func test_見つかったBluetoothデバイスが一覧できる() {
        let peripheralNames = [
            UUID(): "SPD-1",
            UUID(): "SPD-2",
            UUID(): "CDC-1",
            UUID(): "CDC-2",
        ]
        let mock = CBCentralManagerMock(peripheralNames: peripheralNames)
        let manager = BluetoothManager(centralManager: mock)
        let exp = expectation(description: "キーの配列が期待したものと同じであることがテストされる")

        manager.startScanningSensors()
        manager.$discoveredNamedPeripheralNames
            .map { $0.keys }
            .sink { actualKeys in
                XCTAssertEqual(actualKeys, peripheralNames.keys)
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
