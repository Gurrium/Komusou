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

class CentralManagerMock: CentralManager {
    var delegate: CBCentralManagerDelegate?
    var isScanning = false
    var state = CBManagerState.unknown

    private var peripherals: [Peripheral]

    init(peripherals: [Peripheral]) {
        self.peripherals = peripherals
    }

    func scanForPeripherals(withServices _: [CBUUID]?, options _: [String: Any]?) {
        print(#function)
    }

    func stopScan() {
        print(#function)
    }

    func retrievePeripherals(withIdentifiers _: [UUID]) -> [Peripheral] {
        print(#function)

        return []
    }

    func connect(_: Peripheral, options _: [String: Any]?) {
        print(#function)
    }

    func cancelPeripheralConnection(_: Peripheral) {
        print(#function)
    }
}

class CBPeripheralMock: Peripheral {
    var name: String?
    var identifier: UUID
    var delegate: CBPeripheralDelegate?
    var services: [CBService]?

    init(name: String? = nil, identifier: UUID = UUID(), delegate: CBPeripheralDelegate? = nil, services: [CBService]? = nil) {
        self.name = name
        self.identifier = identifier
        self.delegate = delegate
        self.services = services
    }

    func discoverServices(_: [CBUUID]?) {}

    func discoverCharacteristics(_: [CBUUID]?, for _: CBService) {}

    func setNotifyValue(_: Bool, for _: CBCharacteristic) {}
}

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
        let peripherals: [CBPeripheralMock] = [
            .init(name: "SPD-1", identifier: id1),
            .init(name: "SPD-2", identifier: id2),
            .init(name: "SPD-3", identifier: id3),
            .init(name: nil, identifier: id4),
        ]
        let mockCentralManager = CentralManagerMock(peripherals: peripherals)
        let manager = BluetoothManager(centralManager: mockCentralManager)
        let exp = expectation(description: "キーの配列が期待したものと同じであることがテストされる")

        manager.startScanningSensors()
        peripherals.forEach { peripheral in
            manager.centralManager(mockCentralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
        }
        manager.$discoveredNamedPeripheralNames
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
        let peripheral = CBPeripheralMock(name: "SPD-1", identifier: id)
        let mockCentralManager = CentralManagerMock(peripherals: [peripheral])
        let manager = BluetoothManager(centralManager: mockCentralManager)
        let exp = expectation(description: "期待したセンサーに接続されたことがテストされる")

        manager.centralManager(mockCentralManager, didDiscover: peripheral, advertisementData: [:], rssi: 0)
        manager.connectToSpeedSensor(uuid: id).sink { _ in
            XCTAssertEqual(manager.connectedSpeedSensor?.identifier, id)
            exp.fulfill()
        } receiveValue: { _ in }
            .store(in: &cancellables)
        manager.centralManager(mockCentralManager, didConnect: peripheral)

        wait(for: [exp], timeout: 0.1)
    }

    func test_未発見のセンサーには接続できない() {
        let id = UUID()
        let peripheral = CBPeripheralMock(name: "SPD-1", identifier: id)
        let mockCentralManager = CentralManagerMock(peripherals: [peripheral])
        let manager = BluetoothManager(centralManager: mockCentralManager)
        let exp = expectation(description: "未発見のセンサーには接続できないことがテストされる")

        manager.connectToSpeedSensor(uuid: id).sink { result in
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
