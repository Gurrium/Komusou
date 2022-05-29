//
//  WorldView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/06.
//

import Combine
import SceneKit
import SwiftUI

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
