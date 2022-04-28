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

class BluetoothManagerTest: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
    }

    func test_見つかった名前があるBluetoothデバイスを一覧できる() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let id4 = UUID()
        let peripherals: [Peripheral] = [
            PeripheralMock(name: "SPD-1", identifier: id1),
            PeripheralMock(name: "SPD-2", identifier: id2),
            PeripheralMock(name: "SPD-3", identifier: id3),
            PeripheralMock(name: nil, identifier: id4),
        ]
        let centralManager = CentralManagerMock()
        let bluetoothManager = BluetoothManager(centralManager: centralManager)
        let exp = expectation(description: "キーの配列が期待したものと同じであることがテストされる")

        bluetoothManager.startScanningSensors()
        peripherals.forEach { peripheral in
            bluetoothManager.centralManager(centralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
        }
        bluetoothManager.$discoveredNamedPeripheralNames
            .sink { actual in
                let expected = [
                    id1: "SPD-1",
                    id2: "SPD-2",
                    id3: "SPD-3",
                ]
                XCTAssertEqual(actual, expected)
                exp.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }

    func test_発見済みのセンサーに接続できる() {
        let id = UUID()
        let peripheral: Peripheral = PeripheralMock(name: "SPD-1", identifier: id)
        let centralManager = CentralManagerMock()
        let bluetoothManager = BluetoothManager(centralManager: centralManager)
        let exp = expectation(description: "期待したセンサーに接続されたことがテストされる")

        bluetoothManager.centralManager(centralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
        bluetoothManager.connectToSpeedSensor(uuid: id).sink { _ in
            XCTAssertEqual(bluetoothManager.connectedSpeedSensor?.identifier, id)
            exp.fulfill()
        } receiveValue: { _ in }
            .store(in: &cancellables)
        bluetoothManager.centralManager(centralManager, didConnect: peripheral)

        wait(for: [exp], timeout: 0.1)
    }

    func test_未発見のセンサーには接続できない() {
        let centralManager = CentralManagerMock()
        let bluetoothManager = BluetoothManager(centralManager: centralManager)
        let exp = expectation(description: "未発見のセンサーには接続できないことがテストされる")

        bluetoothManager.connectToSpeedSensor(uuid: UUID())
            .sink { result in
                switch result {
                case .failure:
                    exp.fulfill()
                default:
                    XCTFail()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
        // TODO: mockCentralManagerのconnectが呼ばれていないことをテストしたい

        wait(for: [exp], timeout: 0.1)
    }

    func test_初期化時に前回接続したセンサーと接続する() {
        XCTFail("Not Implemented")
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
    }
}
