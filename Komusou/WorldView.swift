//
//  WorldView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/06.
//

import Combine
import SceneKit
import SwiftUI

struct AltWorldView: View {
    @State
    private var speed = 0.0
    var speedSensor: SpeedSensor

    var body: some View {
        ZStack(alignment: .topLeading) {
            WorldView(speed: speed)
                .edgesIgnoringSafeArea(.all)
            InfoPanelView(speed: speed, cadence: 0)
                .padding([.top, .leading])
        }
        .onReceive(speedSensor.speed.compactMap { $0 }) { speed in
            self.speed = speed
        }
    }
}

struct InfoPanelView: View {
    private static let speedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 3
        formatter.maximumSignificantDigits = 3

        return formatter
    }()

    private static let cadenceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.usesSignificantDigits = true
        formatter.minimumSignificantDigits = 2
        formatter.maximumSignificantDigits = 3

        return formatter
    }()

    var speed: Double
    var cadence: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(Self.speedFormatter.string(from: .init(value: speed))!)[km/h]")
            Text("\(Self.cadenceFormatter.string(from: .init(value: cadence))!)[rpm]")
        }
        .foregroundColor(.white)
        .font(.headline)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.gray)
    }
}

struct AltWorldView_Preview: PreviewProvider {
    static var previews: some View {
        AltWorldView(speedSensor: MockSpeedSensor())
            .previewLayout(.sizeThatFits)
    }
}

struct WorldView: UIViewRepresentable {
    private let speed: Double

    init(speed: Double) {
        self.speed = speed
    }

    func makeUIView(context _: Context) -> _WorldView {
        let worldView = UINib(nibName: "WorldView", bundle: nil).instantiate(withOwner: nil).first as! _WorldView
        worldView.setupViews()

        return worldView
    }

    func updateUIView(_ view: _WorldView, context _: Context) {
        view.didChangeSpeed(speed)
    }
}

final class _WorldView: UIView {
    private static let movingKey = "movingAction"

    @IBOutlet var scnView: SCNView!

    // TODO: スピードに揃える
//    private var cadenceSensor: CadenceSensor!
//    private var cadence = 0.0 {
//        didSet {
//            controlPanel.render(speed: speed, cadence: cadence)
//        }
//    }

    private var box: SCNNode = {
        let box = SCNNode()
        box.geometry = SCNBox(width: 5, height: 2, length: 2, chamferRadius: 0)
        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue

        return box
    }()
    private var cancellables = Set<AnyCancellable>()

    let boxBase = SCNNode()

    func setupViews() {
        setupScnView()
    }

    func didChangeSpeed(_ speed: Double) {
        boxBase.removeAction(forKey: Self.movingKey)
        boxBase.runAction(.repeatForever(.moveBy(x: speed, y: 0, z: 0, duration: 1)), forKey: Self.movingKey)
    }

    private func setupScnView() {
        let scene = scnView.scene!

        let plane = SCNNode()
        plane.geometry = SCNFloor()
        plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/check.png")
        plane.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(10, 10, 0)
        plane.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        plane.geometry?.firstMaterial?.diffuse.wrapT = .repeat
        scene.rootNode.addChildNode(plane)

        scene.rootNode.addChildNode(boxBase)
        boxBase.addChildNode(box)
        boxBase.runAction(.moveBy(x: 0, y: 3, z: 0, duration: 0))

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        boxBase.addChildNode(cameraNode)
        cameraNode.runAction(.group([
            .moveBy(x: -20, y: 20, z: 0, duration: 0),
            .rotateBy(x: 0, y: -.pi / 2, z: -.pi / 6, duration: 0),
        ]))

        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        scnView.scene?.rootNode.light = ambientLight

        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        scnView.scene?.rootNode.addChildNode(directionalLightNode)
        directionalLightNode.runAction(.group([
            .moveBy(x: -100, y: 100, z: 0, duration: 0),
            .rotateBy(x: 0, y: -.pi / 4, z: -.pi / 4, duration: 0),
        ]))

        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true

        #if DEBUG
            scnView.showsStatistics = true
        #endif
    }
}

// extension _WorldView: CadenceSensorDelegate {
//    var rotatingKey: String { "rotatingAction" }
//
//    func onCadenceUpdate(_ cadence: Double) {
//        box.removeAction(forKey: rotatingKey)
//        box.runAction(.repeatForever(.rotateBy(x: cadence, y: 0, z: 0, duration: 1)), forKey: rotatingKey)
//
//        self.cadence = cadence
//    }
// }
