//
//  WorldView.swift
//  Komusou
//
//  Created by gurrium on 2022/03/06.
//

import SceneKit
import SwiftUI

struct WorldView: UIViewRepresentable {
    private let speed: Double
    private let cadence: Int

    init(speed: Double, cadence: Int) {
        self.speed = speed
        self.cadence = cadence
    }

    func makeUIView(context _: Context) -> _WorldView {
        let worldView = _WorldView()
        worldView.setupViews()

        return worldView
    }

    func updateUIView(_ view: _WorldView, context _: Context) {
        view.didChangeSpeed(speed)
        view.didChangeCadence(cadence)
    }
}

final class _WorldView: UIView {
    private static let moveKey = "moveAction"
    private static let rotateKey = "rotateAction"

    private let scnView = SCNView(frame: .zero)
    private let boxOrigin = SCNNode()

    func setupViews() {
        scnView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scnView)
        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: topAnchor),
            scnView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scnView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scnView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        setupScnView()
    }

    func didChangeSpeed(_ speed: Double) {
        boxOrigin.removeAction(forKey: Self.moveKey)
        boxOrigin.runAction(.repeatForever(.moveBy(x: speed, y: 0, z: 0, duration: 1)), forKey: Self.moveKey)
    }

    func didChangeCadence(_ cadence: Int) {
        boxOrigin.removeAction(forKey: Self.rotateKey)
        boxOrigin.runAction(.repeatForever(.rotateBy(x: Double(cadence), y: 0, z: 0, duration: 1)), forKey: Self.rotateKey)
    }

    private func setupScnView() {
        let scene = SCNScene(named: "art.scnassets/world.scn")!

        let plane = SCNNode()
        plane.geometry = SCNFloor()
        plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/check.png")
        plane.geometry?.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(10, 10, 0)
        plane.geometry?.firstMaterial?.diffuse.wrapS = .repeat
        plane.geometry?.firstMaterial?.diffuse.wrapT = .repeat
        scene.rootNode.addChildNode(plane)

        let box = SCNNode()
        box.geometry = SCNBox(width: 5, height: 2, length: 2, chamferRadius: 0)
        box.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        boxOrigin.addChildNode(box)
        boxOrigin.runAction(.moveBy(x: 0, y: 3, z: 0, duration: 0))

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        boxOrigin.addChildNode(cameraNode)
        cameraNode.runAction(.group([
            .moveBy(x: -20, y: 20, z: 0, duration: 0),
            .rotateBy(x: 0, y: -.pi / 2, z: -.pi / 6, duration: 0),
        ]))

        scene.rootNode.addChildNode(boxOrigin)

        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        scene.rootNode.light = ambientLight

        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 800
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        scene.rootNode.addChildNode(directionalLightNode)
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
